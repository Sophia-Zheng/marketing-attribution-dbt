# SQL patterns this project uses (= what to refresh for Wise interviews)

Every pattern below appears in the models — read the model, then drill the pattern.

1. **CTEs (`with ... as`)** — every model. Practice: rewrite a nested query as CTEs.
2. **Window functions** — the heart of attribution:
   - `row_number() over (partition by user order by ts)` → touch ordering (int_touchpoints)
   - `count(*) over (partition by user)` → path length (int_conversion_paths)
   - Drill also: `rank`, `lag/lead`, `sum() over` running totals.
3. **Conditional aggregation** — `max(case when ... then ... end)` pivots long → wide
   (channel_summary). Extremely common in analyst interviews.
4. **Joins with inequality conditions** — `on t.ts <= c.ts and t.ts >= c.ts - interval`
   (int_conversion_paths). Time-window joins are a classic fintech interview question.
5. **`union all` vs `union`**, **`nullif`/`coalesce`**, **`group by` with expressions**.

Suggested practice: StrataScratch or LeetCode SQL (medium level), 45–60 min/day,
focusing on window functions and funnel-style questions.
