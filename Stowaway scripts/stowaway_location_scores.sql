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