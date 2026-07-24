WITH s AS (
  SELECT set_id, actual_cash,
         DATEDIFF(MINUTE, start_time, end_time) AS duration_minutes,
         CAST(actual_cash AS FLOAT) / NULLIF(DATEDIFF(MINUTE, start_time, end_time), 0) AS cash_per_minute
  FROM master_sets
)
SELECT set_id, actual_cash, duration_minutes,
       CAST(cash_per_minute AS DECIMAL(5,2)) AS cash_per_minute,
       RANK() OVER (ORDER BY cash_per_minute DESC) AS rank
       
FROM s
WHERE actual_cash > 0 AND actual_cash IS NOT NULL