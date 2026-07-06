-- Four attribution rule sets applied to the same conversion paths,
-- unioned so channel credit can be compared side by side.
-- This mirrors a rules-based attribution engine: change the rules here,
-- credit moves downstream.

with paths as (
    select * from {{ ref('int_conversion_paths') }}
),

last_click as (
    select
        'last_click' as attribution_model,
        channel,
        count(*)                        as credited_conversions,
        round(sum(revenue), 2)          as credited_revenue
    from paths
    where path_position = path_length          -- only the final touch
    group by channel
),

first_click as (
    select
        'first_click' as attribution_model,
        channel,
        count(*)                        as credited_conversions,
        round(sum(revenue), 2)          as credited_revenue
    from paths
    where path_position = 1                    -- only the first touch
    group by channel
),

linear as (
    select
        'linear' as attribution_model,
        channel,
        round(sum(1.0 / path_length), 2)       as credited_conversions,
        round(sum(revenue / path_length), 2)   as credited_revenue
    from paths
    group by channel
),

position_based as (
    -- 40% first touch, 40% last touch, 20% split across middle touches.
    -- Single-touch paths get 100%; two-touch paths split 50/50.
    select
        'position_based' as attribution_model,
        channel,
        round(sum(weight), 2)                  as credited_conversions,
        round(sum(revenue * weight), 2)        as credited_revenue
    from (
        select
            *,
            case
                when path_length = 1 then 1.0
                when path_length = 2 then 0.5
                when path_position = 1 then 0.4
                when path_position = path_length then 0.4
                else 0.2 / (path_length - 2)
            end as weight
        from paths
    ) weighted
    group by channel
)

select * from last_click
union all
select * from first_click
union all
select * from linear
union all
select * from position_based
