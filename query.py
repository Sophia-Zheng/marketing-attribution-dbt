import duckdb

con = duckdb.connect("attribution.duckdb")

sql = """
select
    c.channel,
    sum(c.credited_revenue) as campaign_total,
    max(s.linear_revenue)   as channel_linear
from campaign_summary c
join channel_summary s using (channel)
group by c.channel
"""

print(con.execute(sql).df().to_string(index=False))