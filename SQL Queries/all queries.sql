CREATE TABLE matches (
    match_id BIGINT PRIMARY KEY,                  -- Unique match ID 
    match_type VARCHAR(20),                       -- T20, ODI, etc.
    date DATE,                                    -- Match date
    team1 VARCHAR(50),                            -- First team
    team2 VARCHAR(50),                            -- Second team
    venue TEXT,                                   -- Venue name 
    toss_winner VARCHAR(50),                      -- Team that won the toss
    toss_decision VARCHAR(10)                     -- 'bat' or 'field'
);

SELECT * FROM matches;
COPY matches
FROM 'C:/Program Files/PostgreSQL/17/data/matches.csv'
DELIMITER ','
CSV HEADER;

--------------------------

CREATE TABLE deliveries (
    match_id BIGINT,                       -- Match identifier (joins with matches table)
    match_type VARCHAR(20),                -- Format of the match (e.g., T20, ODI)
    date DATE,                             -- Date of the match
    team1 VARCHAR(50),                     -- Team batting first (or listed as team1)
    team2 VARCHAR(50),                     -- Team bowling first (or listed as team2)
    venue TEXT,                            -- Stadium or location of the match
    toss_winner VARCHAR(50),              -- Team that won the toss
    toss_decision VARCHAR(10),            -- 'bat' or 'field' decision
    inning INT,                            -- 1 or 2 (innings number)
    over INT,                             -- Over number (quoted because it's a reserved SQL keyword)
    ball INT,                              -- Ball number within the over (0–6)
    batsman VARCHAR(50),                  -- Name of the batsman on strike
    bowler VARCHAR(50),                   -- Name of the bowler
    batsman_runs INT,                      -- Runs scored by batsman on this ball
    extra_runs INT,                        -- Extras on this ball (wides, no-balls, etc.)
    total_runs INT,                        -- Total runs scored including extras
    wicket_type VARCHAR(30)               -- Type of dismissal (e.g., bowled, caught), if any
);

SELECT * FROM deliveries;

COPY deliveries
FROM 'C:/Program Files/PostgreSQL/17/data/deliveries.csv'
DELIMITER ','
CSV HEADER;

-----------------------------------------

SELECT COUNT(*) AS total_rows FROM matches;       -- Total row count

SELECT column_name, data_type                     -- Column names and data types
FROM information_schema.columns
WHERE table_name = 'matches';

SELECT * FROM matches LIMIT 10;                   -- Displaying the first 10 rows

SELECT team, COUNT(*) AS match_count              -- Count of Matches per team
FROM (
    SELECT team1 AS team FROM matches
    UNION ALL
    SELECT team2 AS team FROM matches
) AS all_teams
GROUP BY team
ORDER BY match_count DESC;

------------------------------------------

-- Total row count in the deliveries table
SELECT COUNT(*) AS total_rows FROM deliveries;


-- Column names and data types in the deliveries table
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'deliveries';


-- Preview the first 10 rows from deliveries
SELECT * FROM deliveries LIMIT 10;


-- Count of deliveries per match (helpful for identifying unusually short/long matches)
SELECT match_id, COUNT(*) AS deliveries_per_match
FROM deliveries
GROUP BY match_id
ORDER BY deliveries_per_match DESC;


-- Count of deliveries per team (batting side only)
SELECT team1 AS batting_team, COUNT(*) AS total_deliveries
FROM deliveries
GROUP BY team1
ORDER BY total_deliveries DESC;


-- Total runs scored by each team (batting side)
SELECT team1 AS batting_team, SUM(total_runs) AS total_runs_scored
FROM deliveries
GROUP BY team1
ORDER BY total_runs_scored DESC;


-- Wicket types and their counts (to understand how dismissals are distributed)
SELECT wicket_type, COUNT(*) AS occurrences
FROM deliveries
WHERE wicket_type IS NOT NULL
GROUP BY wicket_type
ORDER BY occurrences DESC;


-----------------------------------------

CREATE INDEX IF NOT EXISTS idx_deliveries_match_inning ON deliveries(match_id, inning);

# STEP 1: Create match_scores Table (Fast Run Summary)

DROP TABLE IF EXISTS match_scores;

CREATE TABLE match_scores AS
SELECT
    match_id,
    inning,
    SUM(total_runs) AS total_runs
FROM deliveries
GROUP BY match_id, inning;

# STEP 2: Create match_winners Table (Quick Match Result Lookup)

DROP TABLE IF EXISTS match_winners;

CREATE TABLE match_winners AS
SELECT
    m.match_id,
    m.date,
    m.team1,
    m.team2,
    CASE
        WHEN s1.total_runs > s2.total_runs THEN m.team1
        ELSE m.team2
    END AS winner
FROM matches m
JOIN match_scores s1 ON m.match_id = s1.match_id AND s1.inning = 1
JOIN match_scores s2 ON m.match_id = s2.match_id AND s2.inning = 2;

DROP TABLE IF EXISTS match_features;

CREATE TABLE match_features AS
SELECT
    m.match_id,
    m.date,
    m.team1,
    m.team2,
    m.venue,
    m.toss_winner,
    m.toss_decision,

# STEP 3: Create match_features Table (Fast + Complete)

    -- Feature 1: Powerplay runs (overs 1-6)
    (
        SELECT SUM(d.total_runs)
        FROM deliveries d
        WHERE d.match_id = m.match_id AND d.inning = 1 AND d."over" BETWEEN 1 AND 6
    ) AS powerplay_runs,

    -- Feature 2: Death overs runs (overs 16-20)
    (
        SELECT SUM(d.total_runs)
        FROM deliveries d
        WHERE d.match_id = m.match_id AND d.inning = 1 AND d."over" BETWEEN 16 AND 20
    ) AS death_overs_runs,

    -- Feature 3: Toss helped win (1 if toss winner == actual winner)
    CASE
        WHEN mw.winner = m.toss_winner THEN 1 ELSE 0
    END AS toss_win_helped,

    -- Feature 4: Outcome label (1 if team1 won, 0 if team2)
    CASE
        WHEN mw.winner = m.team1 THEN 1 ELSE 0
    END AS outcome_label,

    -- Feature 5: Head-to-head win % of team1 before this match
    (
        SELECT ROUND(
            100.0 * COUNT(*) FILTER (WHERE previous.winner = m.team1)::NUMERIC / NULLIF(COUNT(*), 0), 2
        )
        FROM match_winners previous
        WHERE previous.date < m.date
          AND (
            (previous.team1 = m.team1 AND previous.team2 = m.team2)
            OR (previous.team1 = m.team2 AND previous.team2 = m.team1)
          )
    ) AS head_to_head_win_pct

FROM matches m
JOIN match_winners mw ON m.match_id = mw.match_id;

# STEP 4: Check Output

SELECT * FROM match_features LIMIT 10;

SELECT COUNT(*) FROM match_features;

-----------------------------------------------------

-- Drop old versions if they exist
DROP TABLE IF EXISTS match_features_train;
DROP TABLE IF EXISTS match_features_test;

-- Create training set: matches before 2021
CREATE TABLE match_features_train AS
SELECT *
FROM match_features
WHERE date < '2021-01-01';

-- Create test set: matches from 2021 and later
CREATE TABLE match_features_test AS
SELECT *
FROM match_features
WHERE date >= '2021-01-01';

--To check the count for each table
SELECT COUNT(*) AS train_count FROM match_features_train;
SELECT COUNT(*) AS test_count FROM match_features_test;

-- Check min/max dates
SELECT MIN(date), MAX(date) FROM match_features_train;
SELECT MIN(date), MAX(date) FROM match_features_test;

-- Select everything from training dataset
SELECT * FROM match_features_train;
-- Select everything from testing dataset
SELECT * FROM match_features_test;

-----------------------------------------------

-- To Create a predictions table that allows multiple models per match (SVM)
CREATE TABLE IF NOT EXISTS ml_predictions_test (
    match_id              BIGINT NOT NULL,
    model_name            TEXT   NOT NULL,          -- e.g., 'SVM', 'LogReg', 'RF'
    predicted_label       SMALLINT NOT NULL CHECK (predicted_label IN (0,1)),
    predicted_probability NUMERIC(6,4),             -- 0.0000–1.0000, nullable if not available
    predicted_winner      TEXT,                     -- optional, human-readable
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (match_id, model_name)
);

SELECT * FROM ml_predictions_test;

-- indexes for slicers/filters in Power BI
CREATE INDEX IF NOT EXISTS idx_mlpred_test_model_name ON ml_predictions_test(model_name);
CREATE INDEX IF NOT EXISTS idx_mlpred_test_match_id   ON ml_predictions_test(match_id);

COPY ml_predictions_test(match_id, model_name, predicted_label, predicted_probability, predicted_winner)
FROM 'C:\\Program Files\\PostgreSQL\\17\\data\\svm_predictions.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');
-------------------------------------------------------------