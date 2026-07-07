# Marketing Attribution Pipeline (dbt + BigQuery, GA4 data)

A rules-based marketing attribution engine built with dbt: raw GA4 event data (Google's public e-commerce sample) is transformed into customer conversion paths, and four attribution rule sets
(last-click, first-click, linear, position-based) are applied to compare how
channel credit shifts under each model.

Built as a working miniature of the tracked-attribution layer used by marketing
science teams: attribution logic lives in version-controlled, tested SQL, and
changing the rules changes the credit downstream.

## Data flow

```
GA4 events (bigquery-public-data, declared as dbt source) 
  └─ stg_events            clean, type, derive channel grouping
      ├─ int_touchpoints    session_start touches per user
      ├─ int_conversions    first purchase per user
      └─ int_conversion_paths   touches joined to conversions
                                within a 30-day lookback window
          └─ attribution_by_model   4 rule sets, unioned
              └─ channel_summary    one row per channel — dashboard-ready
```
*Note: A synthetic seed with the same schema is retained for local DuckDB development — the models run unchanged on both.*

## Run it locally (DuckDB — no cloud account needed)

```bash
pip install dbt-duckdb
cd marketing-attribution-dbt
DBT_PROFILES_DIR=. dbt build        # runs seed + models + tests
```

Inspect results:
```bash
python3 -c "import duckdb; print(duckdb.connect('attribution.duckdb').execute('select * from channel_summary').df())"
```

## Run on BigQuery (GA4 public data)

Prerequisites: a GCP project and the [gcloud CLI](https://cloud.google.com/sdk) installed.

```bash
pip install dbt-bigquery

# authenticate and set the quota project
gcloud auth application-default login
gcloud auth application-default set-quota-project YOUR_PROJECT_ID

# point dbt at BigQuery: edit profiles.yml, replacing the duckdb output with
#   type: bigquery
#   method: oauth
#   project: YOUR_PROJECT_ID
#   dataset: attribution_dev
#   threads: 4
#   location: US        # GA4 public data lives in the US multi-region

dbt debug     # verify the connection before building
dbt build     # builds all models + tests against the GA4 public dataset
```

The pipeline reads `bigquery-public-data.ga4_obfuscated_sample_ecommerce`
(declared as a dbt source) — nothing is copied; only the transformed models are
created in your dataset. One month of sample data is selected via `_table_suffix`
in `stg_events.sql`. Cost: well within BigQuery's free tier (~a few GB processed).

## Design choices worth discussing

- **Lookback window** is a dbt var (`lookback_days: 30`) — change it in one place,
  every model downstream respects it.
- **First conversion per user only**, to keep path definitions unambiguous.
- **Position-based weighting**: 40/40/20 with explicit handling of 1- and 2-touch paths.
- **Tests**: uniqueness/not-null on keys, accepted_values on channel grouping and
  model names — the failure modes that silently corrupt attribution numbers.

## Data quality findings (real GA4 data)

- **Surrogate key collisions**: ~327k rows shared a (user, timestamp) key because
  batched GA4 events land on the same microsecond — caught by the uniqueness test.
  Fixed by widening the surrogate key to (user, timestamp, event_name) and
  deduplicating identical events in staging.
- **Missing purchase revenue**: 254 purchases in the sample month have no revenue
  recorded — caught by a not_null test. Retained as conversions with revenue
  coalesced to 0, so conversion counts stay complete while revenue reflects only
  tracked amounts.

## Known limitations (deliberate scope)

- Rules-based only: no data-driven (Markov/Shapley) attribution — that would be the
  natural extension.
- No identity stitching across devices; `user_pseudo_id` is trusted as-is.
- Direct traffic is credited naively; real engines often exclude or down-weight it.
- The channel grouping uses a catch-all 'Other' bucket, so the accepted_values test guards label integrity rather than detecting novel mediums; in production I'd monitor the Other share as an early-warning signal.