/* =====================================================
   Project: HighCloud Airline Data Analysis
   Database: highcloud
   Description:
   SQL analysis to evaluate airline performance using
   load factor, passenger trends, routes, carriers,
   and time-based insights.
   ===================================================== */

--------------------------------------------------------
-- Database Setup
--------------------------------------------------------
CREATE DATABASE highcloud;
USE highcloud;

-- Basic data checks
SELECT COUNT(*) AS total_records FROM maindata;
DESCRIBE maindata;


--------------------------------------------------------
-- Q1: Create Calendar View (Date Dimension)
--------------------------------------------------------
-- This view enriches raw data with date attributes
-- like month, quarter, weekday, and financial calendar

CREATE OR REPLACE VIEW kpi AS
SELECT 
    `Year`,

    -- Full Date
    STR_TO_DATE(CONCAT(`Year`, '-', `Month (#)`, '-', `Day`), '%Y-%m-%d') AS Order_Date,

    -- Month Details
    MONTH(STR_TO_DATE(CONCAT(`Year`, '-', `Month (#)`, '-', `Day`), '%Y-%m-%d')) AS Month_Number,
    MONTHNAME(STR_TO_DATE(CONCAT(`Year`, '-', `Month (#)`, '-', `Day`), '%Y-%m-%d')) AS Month_Name,

    -- Quarter
    CONCAT('Q', QUARTER(STR_TO_DATE(CONCAT(`Year`, '-', `Month (#)`, '-', `Day`), '%Y-%m-%d'))) AS Quarter,

    -- Year-Month Format
    DATE_FORMAT(
        STR_TO_DATE(CONCAT(`Year`, '-', `Month (#)`, '-', `Day`), '%Y-%m-%d'),
        '%Y-%b'
    ) AS YearMonth,

    -- Weekday Info
    WEEKDAY(STR_TO_DATE(CONCAT(`Year`, '-', `Month (#)`, '-', `Day`), '%Y-%m-%d')) AS Weekday_Number,
    DAYNAME(STR_TO_DATE(CONCAT(`Year`, '-', `Month (#)`, '-', `Day`), '%Y-%m-%d')) AS Day_Name,

    -- Financial Quarter Mapping
    CASE 
        WHEN QUARTER(STR_TO_DATE(CONCAT(`Year`, '-', `Month (#)`, '-', `Day`), '%Y-%m-%d')) = 1 THEN 'FQ4'
        WHEN QUARTER(STR_TO_DATE(CONCAT(`Year`, '-', `Month (#)`, '-', `Day`), '%Y-%m-%d')) = 2 THEN 'FQ1'
        WHEN QUARTER(STR_TO_DATE(CONCAT(`Year`, '-', `Month (#)`, '-', `Day`), '%Y-%m-%d')) = 3 THEN 'FQ2'
        WHEN QUARTER(STR_TO_DATE(CONCAT(`Year`, '-', `Month (#)`, '-', `Day`), '%Y-%m-%d')) = 4 THEN 'FQ3'
    END AS Financial_Quarter,

    -- Financial Month Mapping
    CASE MONTH(STR_TO_DATE(CONCAT(`Year`, '-', `Month (#)`, '-', `Day`), '%Y-%m-%d'))
        WHEN 1 THEN '10' WHEN 2 THEN '11' WHEN 3 THEN '12'
        WHEN 4 THEN '01' WHEN 5 THEN '02' WHEN 6 THEN '03'
        WHEN 7 THEN '04' WHEN 8 THEN '05' WHEN 9 THEN '06'
        WHEN 10 THEN '07' WHEN 11 THEN '08' WHEN 12 THEN '09'
    END AS Financial_Month,

    -- Weekday / Weekend
    CASE 
        WHEN WEEKDAY(STR_TO_DATE(CONCAT(`Year`, '-', `Month (#)`, '-', `Day`), '%Y-%m-%d')) IN (5,6)
        THEN 'WEEKEND'
        ELSE 'WEEKDAY'
    END AS Day_Type,

    -- Metrics & Dimensions
    `# Transported Passengers`,
    `# Available Seats`,
    `%Distance Group ID`,
    `From - To City`,
    `Carrier Name`

FROM maindata;

-- Validate View
SELECT COUNT(*) AS total_records FROM kpi;


--------------------------------------------------------
-- Q2: Load Factor Analysis (Time-Based)
--------------------------------------------------------

-- Yearly Load Factor
SELECT 
    Year,
    CONCAT(
        ROUND(SUM(`# Transported Passengers`) / SUM(`# Available Seats`) * 100, 2),
        ' %'
    ) AS Load_Factor_Percentage
FROM kpi
GROUP BY Year;


-- Quarterly Load Factor
SELECT 
    Quarter,
    CONCAT(
        ROUND(SUM(`# Transported Passengers`) / SUM(`# Available Seats`) * 100, 2),
        ' %'
    ) AS Load_Factor_Percentage
FROM kpi
GROUP BY Quarter;


-- Monthly Load Factor
SELECT 
    Month_Name,
    CONCAT(
        ROUND(SUM(`# Transported Passengers`) / SUM(`# Available Seats`) * 100, 2),
        ' %'
    ) AS Load_Factor_Percentage
FROM kpi
GROUP BY Month_Name
ORDER BY Load_Factor_Percentage DESC;


--------------------------------------------------------
-- Q3: Load Factor by Carrier
--------------------------------------------------------
SELECT 
    `Carrier Name`,
    ROUND(
        SUM(`# Transported Passengers`) / NULLIF(SUM(`# Available Seats`), 0) * 100,
        2
    ) AS Load_Factor_Percentage
FROM maindata
GROUP BY `Carrier Name`
ORDER BY Load_Factor_Percentage DESC;


--------------------------------------------------------
-- Q4: Top 10 Carriers by Passenger Preference
--------------------------------------------------------
SELECT 
    `Carrier Name`,
    CONCAT(
        ROUND(SUM(`# Transported Passengers`) / 1000000, 2),
        ' M'
    ) AS Passengers_Preference
FROM kpi
GROUP BY `Carrier Name`
ORDER BY SUM(`# Transported Passengers`) DESC
LIMIT 10;


--------------------------------------------------------
-- Q5: Top Routes by Number of Flights
--------------------------------------------------------
SELECT 
    `From - To City` AS Route,
    COUNT(*) AS Number_of_Flights
FROM maindata
GROUP BY `From - To City`
ORDER BY Number_of_Flights DESC;


--------------------------------------------------------
-- Q6: Load Factor on Weekdays vs Weekends
--------------------------------------------------------
SELECT 
    CASE 
        WHEN DAYNAME(STR_TO_DATE(CONCAT(Year, '-', `Month (#)`, '-', Day), '%Y-%m-%d'))
             IN ('Saturday', 'Sunday')
        THEN 'Weekend'
        ELSE 'Weekday'
    END AS Day_Type,
    ROUND(
        AVG(`# Transported Passengers` / NULLIF(`# Available Seats`, 0) * 100),
        2
    ) AS Load_Factor
FROM maindata
GROUP BY Day_Type;


--------------------------------------------------------
-- Q7: Number of Flights by Distance Group
--------------------------------------------------------
SELECT 
    `%Distance Group ID`,
    COUNT(*) AS Number_of_Flights
FROM maindata
GROUP BY `%Distance Group ID`
ORDER BY Number_of_Flights DESC;
