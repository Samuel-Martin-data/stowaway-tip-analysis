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