WITH crowd_per_set AS (
    SELECT set_id,
           SUM(CASE WHEN crowd_reaction = 'TRUE' THEN 1 ELSE 0 END) AS crowd_count,
           COUNT(*) AS plays
    FROM master_songs
    GROUP BY set_id
),
s AS (
    SELECT ms.set_id, c.crowd_count, c.plays,
           CAST(ms.start_time AS time) AS st, CAST(ms.end_time AS time) AS et,
           DATEDIFF(MINUTE, ms.start_time, ms.end_time) AS dur
    FROM master_sets ms
    JOIN crowd_per_set c ON c.set_id = ms.set_id
    WHERE ms.end_time IS NOT NULL AND ms.end_time <> ''
),
hours AS (
    SELECT 12 AS h UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
    UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19
    UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23
),
slices AS (
    SELECT s.set_id, h.h, s.crowd_count, s.plays, s.dur,
           DATEDIFF(MINUTE,
               CASE WHEN s.st > DATEADD(HOUR, h.h, CAST('00:00' AS time)) THEN s.st
                    ELSE DATEADD(HOUR, h.h, CAST('00:00' AS time)) END,
               CASE WHEN s.et < DATEADD(HOUR, h.h + 1, CAST('00:00' AS time)) THEN s.et
                    ELSE DATEADD(HOUR, h.h + 1, CAST('00:00' AS time)) END
           ) AS mins_in_hour
    FROM s
    CROSS JOIN hours h
)
SELECT
    h AS hour_of_day,
    SUM(mins_in_hour)                                                        AS minutes_played,
    CAST(SUM(crowd_count * CAST(mins_in_hour AS FLOAT) / dur) AS DECIMAL(6,1)) AS crowd_apportioned,
    CAST(SUM(crowd_count * CAST(mins_in_hour AS FLOAT) / dur)
         / SUM(mins_in_hour) * 60 AS DECIMAL(5,2))                           AS crowd_per_hour_played
FROM slices
WHERE mins_in_hour > 0
GROUP BY h
ORDER BY h;

