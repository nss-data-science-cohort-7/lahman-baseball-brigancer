-- ## Lahman Baseball Database Exercise
-- - this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by Sean Lahman
-- - you can find a data dictionary [here](http://www.seanlahman.com/files/database/readme2016.txt)

-- ✅1. Find all players in the database who played at Vanderbilt University. Create a list showing each player's first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT pe.namefirst,
	pe.namelast,
	SUM (sa.salary) AS total_salary
FROM people AS pe
INNER JOIN salaries AS sa USING (playerid)
WHERE playerid IN
		(SELECT DISTINCT playerid
			FROM schools
			INNER JOIN collegeplaying USING (schoolid)
			WHERE schoolname = 'vanderbilt university')
GROUP BY 1, 2
ORDER BY total_salary DESC;

-- SELECT DISTINCT p.playerid, p.namefirst, p.namelast, SUM(s.salary) AS total_salary
-- FROM (
--     SELECT DISTINCT playerid
--     FROM collegeplaying
--     WHERE schoolid = 'vandy'
-- ) AS sub
-- INNER JOIN people AS p 
-- USING(playerid)
-- INNER JOIN salaries AS s 
-- USING(playerid)
-- GROUP BY 1,2,3
-- ORDER BY total_salary DESC;
	
	--💻David Price	from Vanderbilt had career earning of $81,851,296

-- ✅2. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

--FROM fielding SELECT playerid, yearid, pos, po
--FROM fieldingofsplit SELECT po, yearid, playerid

SELECT COUNT(playerid)AS player,
	COUNT(pos) AS pos_count,
	SUM(po) AS total_putouts,
	CASE
		WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos = 'SS' OR pos = '1B' OR pos = '2B' OR pos = '3B' THEN 'Infield'
		WHEN pos = 'P' OR pos = 'C' THEN 'Battery'
	END AS field
FROM fielding
WHERE yearid = '2016'
GROUP BY field
ORDER BY SUM(po) DESC;

	--💻 Infield had 58,934 putouts, followed by Battery with 41,424 and Outfield with 29,560.
	
-- 3. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends? (Hint: For this question, you might find it helpful to look at the **generate_series** function (https://www.postgresql.org/docs/9.1/functions-srf.html). If you want to see an example of this in action, check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6)

SELECT yearid, hr, so
FROM teams
WHERE yearid>=1920

--Generate series:
WITH decase AS (
	SELECT GENERATE_SERIES(1920, 2010, 10) AS start_year,
	GENERATE_SERIES(1929, 1916, 10)AS end_year;
	
	--
	
-- ✅4. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases. Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.

--FROM batting SELECT playerid, yearid, sb, cs
--FROM people SELECT playerid, namefirst, namelast

SELECT playerid,
	p.namefirst,
	p.namelast, 
	SUM (sb) AS sum_sb,
	SUM (cs) AS sum_cs,
	round((SUM (sb) * 1.0 / (SUM (sb) + SUM (cs)) * 100),2) AS success_pct
FROM people AS p
INNER JOIN batting AS b USING (playerid)
WHERE yearid = '2016'
GROUP BY 1, 2, 3
HAVING SUM(sb + cs) >= 20
ORDER BY success_pct DESC;
	
	--💻Chris Owings had the highest percentage of stolen bases at 91.30
	
-- 5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

--World Series winners: FROM seriespost SELECT yearid, round, teamidwinner
SELECT teamidwinner, yearid
FROM seriespost
WHERE round='WS' AND
	yearid BETWEEN '1970' AND '2016'
--Reg season wins: FROM teams SELECT teamid, yearid, w
SELECT teamid, yearid, MAX(w) AS wins
FROM teams
WHERE yearid BETWEEN '1970' AND '2016'
GROUP BY 1, 2
ORDER BY wins


	--💻

-- 6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

FROM managers SELECT playerid, teamid, yearid, lgid
FROM awardsmanagers SELECT playerid, awardid, lgid, yearid

-- 7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? Only consider pitchers who started at least 10 games (across all teams). Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player.

FROM pitching SELECT playerID, yearID='2016', W, GS>10, SO
FROM salaries SELECT yearid, playerid, teamid?, salary


	
	--
-- 8. Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, and the year they were inducted into the hall of fame (If they were not inducted into the hall of fame, put a null in that column.) Note that a player being inducted into the hall of fame is indicated by a 'Y' in the **inducted** column of the halloffame table.

FROM people SELECT playerid, namefirst, namelast
FROM batting SELECT playerid, SUM (h) WHEN h>3000
FROM halloffame SELECT playerid, yearid, inducted

-- 9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names.

FROM people SELECT playerdid, namefirst, namelast
FROM batting SELECT playerid, h
FROM salaries SELECT playerid, yearid, teamid

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

--FROM people SELECT playerid, namefirst, namelast, debut, finalgame, (finalgame-debut)AS career, WHERE career>=10
--FROM batting SELECT playerid, yearid='2016', hr>=1

WITH c AS (SELECT playerid, namefirst, namelast,
				 DATE_PART('Year', CAST (finalgame AS DATE))-DATE_PART('Year', CAST (debut AS DATE)) AS career 
				FROM people),
	h AS (SELECT playerid, SUM(hr) AS single_year
		  FROM batting
		  WHERE yearid='2016'
		  AND hr>=1
		  GROUP BY playerid)
SELECT c.*, MAX(b.hr)as high_hr, h.single_year
FROM c
INNER JOIN batting AS b
USING (playerid)
INNER JOIN h
USING (playerid)
WHERE c.career>=10
GROUP BY 1,2,3,4,6
HAVING h.single_year=MAX(b.hr)
ORDER BY playerid, high_hr;


	
-- After finishing the above questions, here are some open-ended questions to consider.
-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.


-- 12. In this question, you will explore the connection between number of wins and attendance.

--     a. Does there appear to be any correlation between attendance at home games and number of wins?

--     b. Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

