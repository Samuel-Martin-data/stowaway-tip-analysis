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