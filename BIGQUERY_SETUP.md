# Switching this project to BigQuery (GA4 public sample data)

The models are written in portable SQL. To run against BigQuery's free public
GA4 e-commerce dataset (`bigquery-public-data.ga4_obfuscated_sample_ecommerce`):

## 1. Install the adapter
```bash
pip install dbt-bigquery
```

## 2. Replace profiles.yml
```yaml
marketing_attribution:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth            # run `gcloud auth application-default login` first
      project: YOUR_GCP_PROJECT_ID
      dataset: attribution_dev
      threads: 4
      location: US
```

## 3. Point staging at the GA4 source instead of the seed
Replace the seed reference in `models/staging/stg_events.sql` with a source on the
public dataset, and adapt the field mapping — GA4 exports are nested, so the
staging model becomes the place you flatten them, e.g.:

```sql
select
    concat(user_pseudo_id, cast(event_timestamp as string)) as event_id,
    user_pseudo_id,
    timestamp_micros(event_timestamp)                        as event_ts,
    event_name,
    traffic_source.source                                    as source,
    traffic_source.medium                                    as medium,
    traffic_source.name                                      as campaign,
    ecommerce.purchase_revenue                               as revenue
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix between '20210101' and '20210131'
```

Declare it properly as a dbt **source** in a `sources.yml` for lineage.

## 4. Dialect notes
- DuckDB `interval '{{ var("lookback_days") }}' day` →
  BigQuery `timestamp_sub(conversion_ts, interval {{ var("lookback_days") }} day)`
- Everything else (CTEs, window functions, union all) runs unchanged.

Doing this migration yourself is the best possible dbt learning exercise — and it
turns the project into "attribution modelling on real GA4 data in BigQuery".
