# The Stowaway Piano Player Data Project

A self-tracked data experiment testing whether song choice and crowd reaction predict tip income during live piano performances on a cruise ship elevator circuit.

## Business Questions

- Does song choice affect the amount of tips earned?
- Does crowd reaction correlate with tips earned?
- Do other factors — location, time, cruise itinerary, and tipper generation — affect tips or crowd reaction?

## Key Findings

- Among 27 songs with 10+ plays, tip rate ranged from 1.00 (Take It Easy) down to 0.24, against a 0.36 baseline — Take It Easy's rate is unlikely to be chance (p=0.0007)
- A song's tendency to draw a crowd reaction doesn't predict its tip tier (r=0.05 across 35 songs) — reaction and earning power are separate things
- A play that does get a reaction earns more in that specific moment (0.45 vs 0.33 average tips), even though a song's overall reputation for reactions doesn't predict its earnings
- Aft locations outperform forward ones (12.6 vs 8.4 tips/hour, p=0.008); ship itinerary (port vs. sea day) didn't predict earnings at all
- Gen X and Millennial tippers account for 77% of total tips

## Tools Used

SQL Server (T-SQL) — charts built directly from SQL query outputs

## Contents

- `/sql` — queries behind the analysis above
- `The Stowaway Piano Player Data Project.pdf` — full write-up with dataset stats, charts, and conclusions
