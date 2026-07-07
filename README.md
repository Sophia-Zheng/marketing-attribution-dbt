# Marketing Attribution Pipeline (dbt + BigQuery/DuckDB)

A rules-based marketing attribution engine built with dbt: raw GA4-style event data
is transformed into customer conversion paths, and four attribution rule sets
(last-click, first-click, linear, position-based) are applied to compare how
channel credit shifts under each model.

Built as a working miniature of the tracked-attribution layer used by marketing
science teams: attribution logic lives in version-controlled, tested SQL, and
changing the rules changes the credit downstream.

## Data flow

```
raw_events (seed, GA4-style)
  └─ stg_events            clean, type, derive channel grouping
      ├─ int_touchpoints    session_start touches per user
      ├─ int_conversions    first purchase per user
      └─ int_conversion_paths   touches joined to conversions
                                within a 30-day lookback window
          └─ attribution_by_model   4 rule sets, unioned
              └─ channel_summary    one row per channel — dashboard-ready
```

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

## Design choices worth discussing

- **Lookback window** is a dbt var (`lookback_days: 30`) — change it in one place,
  every model downstream respects it.
- **First conversion per user only**, to keep path definitions unambiguous.
- **Position-based weighting**: 40/40/20 with explicit handling of 1- and 2-touch paths.
- **Tests**: uniqueness/not-null on keys, accepted_values on channel grouping and
  model names — the failure modes that silently corrupt attribution numbers.

## Known limitations (deliberate scope)

- Rules-based only: no data-driven (Markov/Shapley) attribution — that would be the
  natural extension.
- No identity stitching across devices; `user_pseudo_id` is trusted as-is.
- Direct traffic is credited naively; real engines often exclude or down-weight it.
- staging deduplicates identical events on the surrogate key, keeping one row per (user, timestamp, event) to prevent double-counted touchpoints.
