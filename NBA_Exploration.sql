-- check out dataset 

SELECT *
FROM nba;

-- Find number of players drafted who didn't play in college

SELECT COUNT(*)
FROM nba
WHERE college IS NULL;

-- Find every top 10 draft pick who didn't attend college

SELECT draft_rank, player_name, draft_year
FROM nba
WHERE college IS NULL AND draft_rank BETWEEN 1 AND 10
ORDER BY draft_rank;

-- Find colleges who have had the most players drafted

SELECT COUNT(id), college
FROM nba
WHERE college IS NOT NULL
GROUP BY college
ORDER BY 1 DESC;

-- Find every first overall pick for each year sorted by total points 

SELECT draft_year, player_name, total_points
FROM nba
WHERE draft_rank = 1
ORDER BY 3  DESC;

-- Find total amount of draftees who played 0 or 1 year

SELECT COUNT(*)
FROM nba
WHERE years_in_league = 1 OR years_in_league IS NULL;

-- Find percentage of draftees who played 1 year or less

SELECT CONCAT(ROUND(
	((COUNT(CASE WHEN years_in_league = 1 THEN CAST(1.0  as DECIMAL) END))+
	(COUNT(CASE WHEN years_in_league IS NULL THEN CAST(1.0 as DECIMAL) END)))
	/ CAST(COUNT(*) AS DECIMAL) * 100,0),'%') AS "Pct Players <= 1 yr"
FROM nba;

-- Find longest tenured player within dataset 

SELECT draft_year, player_name, years_in_league
FROM nba
WHERE years_in_league = (SELECT MAX(years_in_league) FROM nba);

-- Find teams with the most draft picks 

SELECT COUNT(id), team
FROM nba
GROUP BY team
ORDER BY 1 DESC;

-- Find # of teams within each range of total draft picks

WITH total AS (SELECT count(id), team
FROM nba
GROUP BY team) 

SELECT COUNT(CASE WHEN count > 50 THEN 1 END) AS LOW,
	COUNT(CASE WHEN count BETWEEN 50 AND 70 THEN 1 END) AS MID,
	COUNT(CASE WHEN count > 70 THEN 1 END) AS HIGH
FROM total;

-- Find exactly which teams fall within each range 

WITH total AS (SELECT count(id), team
FROM nba
GROUP BY team) 

SELECT team, CASE
	WHEN count < 50 THEN 'LOW'
	WHEN count BETWEEN 50 AND 70 THEN 'MID'
	WHEN count > 70 THEN 'HIGH'
	ELSE 'OUTLIER' END AS "Draft # Range"
FROM total
ORDER BY 2;

-- Explore correlation between number of draft picks and total points

SELECT team, SUM(total_points) "Total Points", COUNT(id) "Total Draftees", 
RANK() OVER (ORDER BY COUNT(id) DESC) "Draft # Rank"
FROM nba
GROUP BY team
ORDER BY 2 DESC;

-- Explore correlation between total minutes played and # of draft picks

SELECT team, SUM(total_minutes) "Total Minutes", COUNT(id) "Total Draftees", 
RANK() OVER (ORDER BY COUNT(id) DESC) "Draft # Rank",
RANK () OVER (ORDER BY SUM(total_minutes) DESC) "Total Min Rank"
FROM nba
GROUP BY team
ORDER BY 2 DESC;

-- Find most productive players when combining all three stats

SELECT  player_name, draft_year, 
(total_points + total_rebounds + total_assists) as "FG/AST/RB Total"
FROM nba
WHERE (total_points, total_rebounds, total_assists) IS NOT NULL
ORDER BY 3 desc
LIMIT 10;

-- Find most efficient shooters who played more than one season 

SELECT years_in_league, player_name, 
		CONCAT(ROUND(((fg_percentage + three_point_percentage +
		free_throw_percentage) / 3 *100),0),'%') AS "Total Shooting %"
FROM nba
WHERE years_in_league > 1
ORDER BY 3 DESC;

-- Find the least efficient shooters who played a decade or more 

SELECT years_in_league, player_name, 
		CONCAT(ROUND(((fg_percentage + three_point_percentage +
		free_throw_percentage) / 3 *100),0),'%') AS "Total Shooting %",
		total_points
FROM nba
WHERE years_in_league > 10
ORDER BY 3;

-- Find each team's top scorer 

SELECT n.team, n.player_name, n.total_points
FROM nba n
WHERE total_points = (SELECT MAX(total_points) FROM nba WHERE team = n.team)
ORDER BY 3 DESC;

-- Find each team's lowest scorer 

WITH bottom AS (
	SELECT team, years_in_league, player_name, total_points, 
		ROW_NUMBER() OVER (PARTITION BY team ORDER BY total_points ) AS row_num
	FROM nba
	WHERE total_points >= 1 AND years_in_league >= 1)

SELECT team, years_in_league, player_name, total_points
FROM bottom
WHERE row_num = 1
ORDER BY total_points;

-- Find each team's top scorer percentage of total points using 2 views

SELECT top.team, top.player_name, ROUND(((CAST(top.total_points AS DECIMAL) /
CAST(team.sum AS DECIMAL)) * 100), 0) AS "% of Teams Points"
FROM team_total team, top_scorers top
WHERE team.team = top.team
ORDER BY 3 DESC;

-- Find draft rank for each draft class top scorer

SELECT n.draft_rank, n.draft_year, n.player_name, n.total_points
FROM nba n
JOIN (SELECT draft_year, MAX(total_points) AS total
	 FROM nba GROUP BY draft_year) b
ON n.draft_year = b.draft_year AND n.total_points = b.total
ORDER BY 4 desc;

-- Find percent of each draft classes top scorer being a #1 draft pick 

WITH top AS(
SELECT n.draft_rank, n.draft_year, n.player_name, n.total_points
FROM nba n
JOIN (SELECT draft_year, MAX(total_points) AS total
	 FROM nba GROUP BY draft_year) b
ON n.draft_year = b.draft_year AND n.total_points = b.total
ORDER BY 4 desc)

SELECT 
	CONCAT(
	ROUND(
		((SELECT (CAST(COUNT(draft_rank) AS DECIMAL)) FROM top WHERE draft_rank = 1)
		/(CAST(COUNT(draft_rank) AS DECIMAL)) * 100),0),'%') AS "#1 Draftees as Top Scorer"
FROM top




















