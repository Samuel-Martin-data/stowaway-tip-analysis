/* ============================================================
   THE STOWAWAY PIANO PLAYER DATA PROJECT
   All analysis scripts in one file.
   Tables: master_sets (one row per set), master_songs (one row per song play)
   Run sections independently; each is self-contained.
   ============================================================ */


/* ------------------------------------------------------------
   1. TOTALS AND AVERAGES
   Headline dataset numbers: sets, songs, hours, cash, tips, and per-set/hour/song rates
   ------------------------------------------------------------ */

WITH totals AS (
    SELECT
        COUNT(*)                                         AS sets_played,
        SUM(songs_played)                                AS total_songs_played,
        (SELECT COUNT(DISTINCT song) FROM master_songs)  AS unique_songs_played,
        DATEDIFF(DAY, MIN(date), MAX(date))              AS experiment_length_days,
        COUNT(DISTINCT date)                             AS days_played,
        CAST(CAST(SUM(duration_mins) AS FLOAT) / 60
             AS DECIMAL(5,1))                            AS total_hours,
        SUM(actual_cash)                                 AS total_cash_usd,
        SUM(total_tips)                                  AS total_tip_count
    FROM master_sets
)
SELECT 'Sets played'         AS metric, CAST(sets_played           AS VARCHAR(20)) AS value FROM totals
UNION ALL
SELECT 'Songs played',                  CAST(total_songs_played    AS VARCHAR(20)) FROM totals
UNION ALL
SELECT 'Unique songs',                  CAST(unique_songs_played   AS VARCHAR(20)) FROM totals
UNION ALL
SELECT 'Experiment length (days)',      CAST(experiment_length_days AS VARCHAR(20)) FROM totals
UNION ALL
SELECT 'Days played',                   CAST(days_played           AS VARCHAR(20)) FROM totals
UNION ALL
SELECT 'Total hours',                   CAST(total_hours           AS VARCHAR(20)) FROM totals
UNION ALL
SELECT 'Total cash (USD)',              CAST(total_cash_usd        AS VARCHAR(20)) FROM totals
UNION ALL
SELECT 'Total tips',                    CAST(total_tip_count       AS VARCHAR(20)) FROM totals
UNION ALL
SELECT 'Songs / set',
       CAST(CAST(CAST(total_songs_played AS FLOAT) / sets_played           AS DECIMAL(5,2)) AS VARCHAR(20)) FROM totals
UNION ALL
SELECT 'Songs / hour',
       CAST(CAST(CAST(total_songs_played AS FLOAT) / total_hours           AS DECIMAL(5,2)) AS VARCHAR(20)) FROM totals
UNION ALL
SELECT 'Songs / day played',
       CAST(CAST(CAST(total_songs_played AS FLOAT) / days_played           AS DECIMAL(5,2)) AS VARCHAR(20)) FROM totals
UNION ALL
SELECT 'Cash / set (USD)',
       CAST(CAST(CAST(total_cash_usd     AS FLOAT) / sets_played           AS DECIMAL(6,2)) AS VARCHAR(20)) FROM totals
UNION ALL
SELECT 'Cash / hour (USD)',
       CAST(CAST(CAST(total_cash_usd     AS FLOAT) / total_hours           AS DECIMAL(6,2)) AS VARCHAR(20)) FROM totals
UNION ALL
SELECT 'Cash / song (USD)',
       CAST(CAST(CAST(total_cash_usd     AS FLOAT) / total_songs_played    AS DECIMAL(5,2)) AS VARCHAR(20)) FROM totals
UNION ALL
SELECT 'Tips / set',
       CAST(CAST(CAST(total_tip_count    AS FLOAT) / sets_played           AS DECIMAL(5,2)) AS VARCHAR(20)) FROM totals
UNION ALL
SELECT 'Tips / song',
       CAST(CAST(CAST(total_tip_count    AS FLOAT) / total_songs_played    AS DECIMAL(5,2)) AS VARCHAR(20)) FROM totals;


/* ------------------------------------------------------------
   2. PER-SONG METRICS
   Tips per play and crowd reactions per play for songs with 10+ plays
   ------------------------------------------------------------ */

SELECT
song,
COUNT(*) AS song_play_count,
SUM(CASE WHEN crowd_reaction = 'TRUE' THEN 1 ELSE 0 END) AS crowd_reaction_count,
SUM(tips) AS total_tips,
CAST(CAST(SUM(tips) AS FLOAT) / COUNT(*) AS DECIMAL (5,2)) AS tips_per_play,
CAST(CAST(SUM(CASE WHEN crowd_reaction = 'TRUE' THEN 1 ELSE 0 END) AS FLOAT) /
COUNT(*) AS DECIMAL (5,2)) AS crowd_reactions_per_play
FROM master_songs
GROUP BY song
HAVING COUNT(*) > 10
ORDER BY tips_per_play DESC


/* ------------------------------------------------------------
   3. LOCATION SCORES
   Cash, tips per minute, and crowd reactions per set by elevator location
   ------------------------------------------------------------ */

SELECT ms.location,
       SUM(ms.actual_cash)                                                       AS total_cash_usd,
       CAST(CAST(SUM(ms.total_tips) AS FLOAT) / NULLIF(SUM(ms.duration_mins), 0)
            AS DECIMAL(5,2))                                                     AS tips_per_minute,
       CAST(CAST(SUM(sng.crowd_reactions) AS FLOAT) / COUNT(DISTINCT ms.set_id)
            AS DECIMAL(5,2))                                                     AS avg_crowd_reactions_per_set
FROM master_sets ms
JOIN (
    SELECT set_id,
           SUM(CASE WHEN crowd_reaction = 'TRUE' THEN 1 ELSE 0 END) AS crowd_reactions
    FROM master_songs
    GROUP BY set_id
) sng ON sng.set_id = ms.set_id
WHERE ms.location IS NOT NULL AND ms.location <> ''
GROUP BY ms.location;


/* ------------------------------------------------------------
   4. SET RANKINGS
   Completed sets ranked by cash per minute
   ------------------------------------------------------------ */

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


/* ------------------------------------------------------------
   5. CASH BY HOUR PLAYED
   Cash apportioned to each clock hour a set overlapped
   ------------------------------------------------------------ */

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


/* ------------------------------------------------------------
   6. CROWD REACTIONS BY HOUR
   Crowd reactions apportioned to each clock hour a set overlapped
   ------------------------------------------------------------ */

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
