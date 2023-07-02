CREATE OR REPLACE TABLE
dwh_labor_dataset.rpt_labor_dashboard
AS

WITH conv_table AS (
SELECT PARSE_DATE('%Y%m%d', CONCAT(SUBSTR(CAST(time_code AS STRING), 1, 4), SUBSTR(CAST(time_code AS STRING), 9, 2), '01')) AS survey_date
, employment_status AS employment_status
, gender AS gender
, CAST(value AS INTEGER) AS population
FROM my_project.my_dataset.my_table
WHERE value != '…'
AND time NOT LIKE '2022年%'
)
, avg_population_table AS (
SELECT DATE_TRUNC(survey_date, YEAR) AS survey_year
, employment_status AS employment_status
, gender AS gender
, AVG(population) AS avg_population
FROM conv_table
GROUP BY survey_year, employment_status, gender
)
, labor_population AS (
SELECT survey_year AS survey_year
, gender AS gender
, avg_population AS avg_labor_population
FROM avg_population_table
WHERE employment_status = '労働力人口'
)
, unemployed_population AS (
SELECT survey_year AS survey_year
, gender AS gender
, avg_population AS avg_unemployed_population
FROM avg_population_table
WHERE employment_status = '完全失業者'
)
, unemployment_rate_table AS (
SELECT lp.survey_year AS survey_year
, lp.gender AS gender
, (up.avg_unemployed_population / lp.avg_labor_population)*100 AS unemployment_rate
FROM labor_population AS lp
INNER JOIN unemployed_population AS up USING (survey_year, gender)
)
 
 
SELECT apt.survey_year AS survey_year
, apt.gender AS gender
, apt.employment_status AS employment_status
, apt.avg_population AS avg_population
, urt.unemployment_rate AS unemployment_rate
FROM avg_population_table AS apt
INNER JOIN unemployment_rate_table AS urt USING(survey_year, gender)