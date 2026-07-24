WITH s AS (
    SELECT set_id, actual_cash,
           CAST(start_time AS time) AS st, CAST(end_time AS time) AS et,
           DATEDIFF(MINUTE, start_time, end_time) AS dur
    FROM master_sets
    WHERE end_time IS NOT NULL AND end_time <> ''
),
hours AS (
    SELECT 12 AS h UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
    UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19
    UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23
),
slices AS (
    SELECT s.set_id, h.h,
           -- minutes of this set falling inside hour h
           DATEDIFF(MINUTE,
               CASE WHEN s.st > DATEADD(HOUR, h.h, CAST('00:00' AS time)) THEN s.st
                    ELSE DATEADD(HOUR, h.h, CAST('00:00' AS time)) END,
               CASE WHEN s.et < DATEADD(HOUR, h.h + 1, CAST('00:00' AS time)) THEN s.et
                    ELSE DATEADD(HOUR, h.h + 1, CAST('00:00' AS time)) END
           ) AS mins_in_hour,
           s.actual_cash, s.dur
    FROM s
    CROSS JOIN hours h
)
SELECT
    h AS hour_of_day,
    SUM(mins_in_hour)                                            AS minutes_played,
    CAST(SUM(actual_cash * CAST(mins_in_hour AS FLOAT) / dur) AS DECIMAL(7,2)) AS cash_apportioned,
    CAST(SUM(actual_cash * CAST(mins_in_hour AS FLOAT) / dur)
         / SUM(mins_in_hour) AS DECIMAL(5,2))                    AS cash_per_minute
FROM slices
WHERE mins_in_hour > 0
GROUP BY h
ORDER BY h;
