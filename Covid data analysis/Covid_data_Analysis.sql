--Creating database for covid data
create database covid_db

--Importing covid data

--during importing data there are multiple problems with data like:
--1.some cloumns like death count perc,weekly perc and others are in nvarchar data type converted to float
--2.start date and end date data getting deleted during importing due to some date are are form of text in csv file
-- so imported every start & end date data as nvarchar later after coverting date format i converted it into date datatype

---sorting start date and end date format
ALTER TABLE covid_data
ALTER COLUMN data_period_start DATE;  

ALTER TABLE covid_data
ALTER COLUMN data_period_end DATE;  


UPDATE covid_data
SET data_period_start = COALESCE(
        TRY_CONVERT(DATE, data_period_start, 103), 
        TRY_CONVERT(DATE, data_period_start, 101)
    ),
    data_period_end = COALESCE(
        TRY_CONVERT(DATE, data_period_end, 103), 
        TRY_CONVERT(DATE, data_period_end, 101)
    )
WHERE TRY_CONVERT(DATE, data_period_start, 103) IS NOT NULL 
   OR TRY_CONVERT(DATE, data_period_start, 101) IS NOT NULL;
 
-- checking date format
SELECT data_period_start, data_period_end FROM covid_data
order by data_period_start, data_period_end ;

-- Deleting footnote column
ALTER TABLE covid_data  
DROP COLUMN footnote;

--changing cloumn name group to group_type because group is a keyword word sql
EXEC sp_rename 'covid_data.[Group]', 'group_type', 'COLUMN';

-- for better data understanding and to analyze i am creating 3 new tables on group_type

-- Create tables with the same structure as covid_data
SELECT * INTO covid_total FROM covid_data WHERE 1=0;
SELECT * INTO covid_weekly FROM covid_data WHERE 1=0;
SELECT * INTO covid_3months FROM covid_data WHERE 1=0;
SELECT * INTO latest_total_data FROM covid_data WHERE 1=0;

-- Insert data based on group_type
INSERT INTO covid_total SELECT * FROM covid_data WHERE group_type = 'total';
INSERT INTO covid_weekly SELECT * FROM covid_data WHERE group_type = 'weekly';
INSERT INTO covid_3months SELECT * FROM covid_data WHERE group_type = '3 month period';
INSERT INTO latest_total_data SELECT * FROM covid_data WHERE group_type = 'total' AND data_period_end = '2023-04-08';

--deleting the columns pct_change_wk and pct_diff_wk from the tables covid_total and covid_3months because its not required for those 2 tables

ALTER TABLE total_latest_data
DROP COLUMN pct_change_wk, pct_diff_wk;

ALTER TABLE covid_3months
DROP COLUMN pct_change_wk, pct_diff_wk;

select * from covid_data;

select * from covid_total;

select * from covid_weekly ;

select * from covid_3months ;

select * from latest_total_data;

---ANALYSIS PART

--1.Retrieve the jurisdiction residence with the highest number of COVID deaths for the latest  data period end date.

WITH LatestData AS (
    SELECT 
        Jurisdiction_Residence, 
        data_period_end, 
        COVID_deaths,
        RANK() OVER (ORDER BY data_period_end DESC) AS rn
    FROM covid_data
)
SELECT TOP 1 Jurisdiction_Residence, COVID_deaths, data_period_end
FROM LatestData
WHERE rn = 1
ORDER BY COVID_deaths DESC;

--OR

SELECT TOP 1 Jurisdiction_Residence, data_period_end,COVID_deaths 
FROM latest_total_data 
ORDER BY COVID_deaths DESC;

--2.Retrieve the top 5 jurisdictions with the highest percentage difference in aa_COVID_rate  
-- compared to the overall crude COVID rate for the latest data period end date.

WITH LatestData AS (
    SELECT 
        Jurisdiction_Residence, 
        data_period_end, 
        aa_COVID_rate, 
        crude_COVID_rate,
        ( (aa_COVID_rate - crude_COVID_rate) / NULLIF(crude_COVID_rate, 0) ) * 100 AS pct_diff,
        RANK() OVER (ORDER BY data_period_end DESC) AS rn
    FROM latest_total_data
)
SELECT TOP 5 
    Jurisdiction_Residence, 
    data_period_end, 
    aa_COVID_rate, 
    crude_COVID_rate, 
    pct_diff AS percentage_difference
FROM LatestData
WHERE rn = 1
ORDER BY pct_diff DESC;

-- 3.Calculate the average COVID deaths per week for each jurisdiction residence and group,
-- for the latest 4 data period end dates.

SELECT Jurisdiction_Residence,AVG(covid_deaths) as 'Avg_covid_death_last_4_weeks' from covid_weekly
WHERE data_period_end in ('2023-04-08','2023-04-01','2023-03-25','2023-03-18')
GROUP BY Jurisdiction_Residence
ORDER BY 2 DESC;

-- 4.Retrieve the data for the latest data period end date,
-- but exclude any jurisdictions that had  zero COVID deaths and have missing values in any other column.

-- for total group data 
WITH LatestData AS (
    SELECT *, 
           RANK() OVER (ORDER BY data_period_end DESC) AS rn
    FROM covid_total
)
SELECT * 
FROM LatestData
WHERE rn = 1 
AND COVID_deaths > 0 
AND COVID_deaths IS NOT NULL
AND COVID_pct_of_total IS NOT NULL 
AND crude_COVID_rate IS NOT NULL 
AND aa_COVID_rate IS NOT NULL;

-- for 3 months group data 

WITH LatestData AS (
    SELECT *, 
           RANK() OVER (ORDER BY data_period_end DESC) AS rn
    FROM covid_3months
)
SELECT * 
FROM LatestData
WHERE rn = 1 
AND COVID_deaths > 0 
AND COVID_deaths IS NOT NULL
AND COVID_pct_of_total IS NOT NULL 
AND crude_COVID_rate IS NOT NULL 
AND aa_COVID_rate IS NOT NULL;

-- for weekly group data

WITH LatestData AS (
    SELECT *, 
           RANK() OVER (ORDER BY data_period_end DESC) AS rn
    FROM covid_weekly
)
SELECT * 
FROM LatestData
WHERE rn = 1 
AND COVID_deaths > 0 
AND COVID_deaths IS NOT NULL
AND COVID_pct_of_total IS NOT NULL
AND pct_change_wk IS NOT NULL
AND pct_diff_wk IS NOT NULL 
AND crude_COVID_rate IS NOT NULL 
AND aa_COVID_rate IS NOT NULL;

-- 5.Calculate the week-over-week percentage change in COVID_pct_of_total for all jurisdictions , 
-- but only for the data period start dates after March 1, 2020.

SELECT 
    Jurisdiction_Residence,
	data_period_start,
	data_period_end,
    COVID_pct_of_total,
	pct_change_wk as 'weekly change %',
    pct_diff_wk as 'weekly % difference'
FROM covid_weekly
WHERE data_period_start > '2020-03-01' and pct_change_wk is not null and pct_diff_wk is not null
ORDER BY Jurisdiction_Residence, data_period_start;

-- 6.Group the data by jurisdiction residence and calculate the cumulative COVID deaths for each  jurisdiction,
-- but only up to the latest data period end date.

-- for total 
WITH CumulativeDeaths AS (
    SELECT *,
        SUM(COVID_deaths) OVER (
            PARTITION BY group_type 
            ORDER BY jurisdiction_residence 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_deaths_count
    FROM covid_total
    WHERE data_period_end = '2023-04-08'
)
SELECT Jurisdiction_Residence,group_type,data_period_start,data_period_end,COVID_deaths,cumulative_deaths_count FROM CumulativeDeaths


-- for 3 months 
WITH CumulativeDeaths3 AS (
    SELECT *,
        SUM(COVID_deaths) OVER (
            PARTITION BY group_type 
            ORDER BY jurisdiction_residence 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_deaths_count
    FROM covid_3months
    WHERE data_period_end = '2023-04-08'
)
SELECT Jurisdiction_Residence,group_type,data_period_start,data_period_end,COVID_deaths,cumulative_deaths_count FROM CumulativeDeaths3


-- for weekly 

WITH CumulativeDeathsW AS (
    SELECT *,
        SUM(COVID_deaths) OVER (
            PARTITION BY group_type 
            ORDER BY jurisdiction_residence 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_deaths_count
    FROM covid_weekly
    WHERE data_period_end = '2023-04-08'
)
SELECT Jurisdiction_Residence,group_type,data_period_start,data_period_end,COVID_deaths,cumulative_deaths_count FROM CumulativeDeathsW


-- STORED PROCEDURE that takes in a date  range and calculates the average weekly percentage change in COVID deaths 
-- for each  jurisdiction. The procedure should return the average weekly percentage change along with  the jurisdiction 
--and date range as output

CREATE PROCEDURE Get_Avg_Weekly_Change
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        Jurisdiction_Residence,
        @StartDate AS Start_Date,
        @EndDate AS End_Date,
        AVG(pct_change_wk) AS Avg_Weekly_Change
    FROM covid_data
    WHERE data_period_start = @StartDate AND data_period_end = @EndDate
    GROUP BY Jurisdiction_Residence;
END;

select * from covid_weekly

EXEC Get_Avg_Weekly_Change '2022-07-03', '2022-07-09';

-- create a USER DEFFINED FUNCTION that  takes in a jurisdiction as input and 
-- returns the average crude COVID rate for that jurisdiction  over the entire dataset. 

CREATE FUNCTION dbo.Get_Avg_Crude_COVID_Rate (@Jurisdiction VARCHAR(255))
RETURNS FLOAT
AS
BEGIN
    DECLARE @AvgCrudeRate FLOAT;
    
    SELECT @AvgCrudeRate = ROUND(AVG(crude_COVID_rate),2)
    FROM covid_data
    WHERE Jurisdiction_Residence = @Jurisdiction;

    RETURN @AvgCrudeRate;
END;

SELECT dbo.Get_Avg_Crude_COVID_Rate('California') AS Avg_Crude_COVID_Rate;

-- Use both the stored procedure and the user-defined function to  compare the average weekly percentage change 
-- in COVID deaths for each jurisdiction to the  average crude COVID rate for that jurisdiction.

CREATE PROCEDURE Compare_Avg_Weekly_Change_With_Crude_Rate
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        c.Jurisdiction_Residence,
        @StartDate AS Start_Date,
        @EndDate AS End_Date,
        AVG(c.pct_change_wk) AS Avg_Weekly_Change,
        dbo.Get_Avg_Crude_COVID_Rate(c.Jurisdiction_Residence) AS Avg_Crude_COVID_Rate
    FROM covid_data c
    WHERE c.data_period_end BETWEEN @StartDate AND @EndDate
    GROUP BY c.Jurisdiction_Residence;
END;

EXEC Compare_Avg_Weekly_Change_With_Crude_Rate '2022-07-17', '2022-07-23';

select * from covid_weekly

