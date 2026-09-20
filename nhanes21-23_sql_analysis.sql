/* ================================
	Set up and Initial Exploration
   ================================*/
CREATE DATABASE nhanes2123_project;
USE nhanes2123_project;

-- Inspect the demographics dataset
DESCRIBE demographics;

-- Inspect a sample of the demographics dataset
-- Notice that children are included in the data
SELECT
	SEQN,
    RIAGENDR,
    RIDAGEYR
FROM demographics
LIMIT 20;

-- Check the body_measurements dataset
-- Notice that the bmi values are saved as text
DESCRIBE body_measurements;

-- Inspect a sample of body_measurements dataset
SELECT
	SEQN,
    BMXBMI
FROM body_measurements
LIMIT 10;

-- Further inspect the formatting of bmi values
-- All existing bmi values are of the same length (4 characters long)
-- All existing bmi values are in a valid numerical format
SELECT
	BMXBMI,
    LENGTH(BMXBMI) AS character_length
FROM body_measurements
WHERE BMXBMI IS NOT NULL
ORDER BY character_length DESC -- Sort with highest character length at the top
LIMIT 10;

SELECT
	BMXBMI,
    LENGTH(BMXBMI) AS character_length
FROM body_measurements
WHERE BMXBMI IS NOT NULL
	AND BMXBMI <> ''
ORDER BY character_length -- Sort with smallest character length at the top (excluding empty entries)
LIMIT 10;

SELECT BMXBMI
FROM body_measurements
WHERE BMXBMI IS NOT NULL
	AND BMXBMI <> ''
    AND BMXBMI NOT REGEXP '^[0-9]+(\\.[0-9]+)?$'
LIMIT 20;


-- Calculate what percent of adult (20+) survey participants have their bmi recorded
-- 99.83% of adult (20+) survey participants have their bmi recorded
SELECT COUNT(*) AS total_records,
	SUM(CASE WHEN b.BMXBMI IS NOT NULL AND b.BMXBMI <> '' THEN 1 ELSE 0 END) AS bmi_available,
    COUNT(*) - SUM(CASE WHEN b.BMXBMI IS NOT NULL AND b.BMXBMI <> '' THEN 1 ELSE 0 END) AS bmi_missing,
    ROUND(SUM(CASE WHEN b.BMXBMI IS NOT NULL AND b.BMXBMI <> '' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS BMI_data_completeness_pct
FROM body_measurements AS b
INNER JOIN demographics AS d
	ON b.SEQN = d.SEQN
WHERE d.RIDAGEYR >= 20;

/* ===============
	Data Cleaning
   ===============*/
   
-- Create a new column where the bmi values will be numeric rather than text
ALTER TABLE body_measurements
ADD COLUMN BMI_numeric DECIMAL(5,2);    

-- Populate new column with numeric bmi values, leaving out the missing values
UPDATE body_measurements
SET BMI_numeric = CAST(BMXBMI AS DECIMAL(5,2))
WHERE BMXBMI IS NOT NULL
	AND BMXBMI <> '';
 
-- Encountered an error about not using the primary key while trying to populate the new column
-- Try to identify primary key and learn that it does not have one
SHOW INDEX FROM body_measurements;

-- Turn off the setting preventing me from populating the new bmi column
SET SQL_SAFE_UPDATES = 0;

-- Turn the setting back on after populating the new bmi column
SET SQL_SAFE_UPDATES = 1;

-- Verify that the new column looks correct
SELECT BMXBMI,
	BMI_numeric
FROM body_measurements
LIMIT 20;
    
/* =====================
	Data Quality Checks
   =====================*/
   
-- Check that RIAGENDR only has the expected sex codes 
SELECT
    d.RIAGENDR AS sex_code,
    COUNT(*) AS number_of_people
FROM body_measurements AS b
INNER JOIN demographics AS d
    ON b.SEQN = d.SEQN
WHERE b.BMI_numeric IS NOT NULL
  AND d.RIDAGEYR >= 20
GROUP BY d.RIAGENDR
ORDER BY d.RIAGENDR;

-- Check that every adult (20+) participant with a recorded bmi is being accouted for
SELECT
	COUNT(*) AS total_adults_with_bmi,
    SUM(CASE WHEN b.BMI_numeric < 18.5 THEN 1 ELSE 0 END) AS Underweight,
    SUM(CASE WHEN b.BMI_numeric >= 18.5 AND b.BMI_numeric < 25 THEN 1 ELSE 0 END) AS Normal_weight,
    SUM(CASE WHEN b.BMI_numeric >= 25 AND b.BMI_numeric < 30 THEN 1 ELSE 0 END) AS Overweight,
    SUM(CASE WHEN b.BMI_numeric >= 30 THEN 1 ELSE 0 END) AS Obesity,
    SUM(
		CASE
			WHEN b.BMI_numeric < 18.5 THEN 1
            WHEN b.BMI_numeric >= 18.5 AND b.BMI_numeric < 25 THEN 1
            WHEN b.BMI_numeric >= 25 AND b.BMI_numeric < 30 THEN 1
            WHEN b.BMI_numeric >= 30 THEN 1
		END) AS Calculated_total
	FROM body_measurements AS b
    INNER JOIN demographics AS d
		ON b.SEQN = d.SEQN
	WHERE b.BMI_numeric IS NOT NULL
		AND d.RIDAGEYR >= 20;
   
/* ======================
	Demographic Analysis
   ======================*/

-- Calculate the average bmi for male and female participants
SELECT
	CASE
		WHEN d.RIAGENDR = 1 THEN 'Male'
        WHEN d.RIAGENDR = 2 THEN 'Female'
	END AS sex,
    COUNT(*) AS number_of_people,
    ROUND(AVG(b.BMI_numeric), 2) AS average_bmi
FROM body_measurements AS b
INNER JOIN demographics AS d
	ON b.SEQN = d.SEQN
WHERE b.BMI_numeric IS NOT NULL
	AND d.RIDAGEYR >= 20
GROUP BY d.RIAGENDR;

-- Calculate percentage of bmi category per sex
SELECT
	CASE
		WHEN d.RIAGENDR = 1 THEN 'Male'
        WHEN d.RIAGENDR = 2 THEN 'Female'
	END AS sex,
    COUNT(*) AS number_of_people,
	ROUND(SUM(CASE WHEN b.BMI_numeric < 18.5 THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS Underweight_pct,
    ROUND(SUM(CASE WHEN b.BMI_numeric >= 18.5 AND b.BMI_numeric < 25 THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS Normal_weight_pct,
    ROUND(SUM(CASE WHEN b.BMI_numeric >= 25 AND b.BMI_numeric < 30 THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS Overweight_pct,
    ROUND(SUM(CASE WHEN b.BMI_numeric >= 30 THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS Obesity_pct
FROM body_measurements AS b
INNER JOIN demographics AS d
	ON b.SEQN = d.SEQN
WHERE b.BMI_numeric IS NOT NULL
GROUP BY sex;

-- Calculate average bmi for each age group
SELECT
    CASE
        WHEN d.RIDAGEYR BETWEEN 20 AND 39 THEN '20-39'
        WHEN d.RIDAGEYR BETWEEN 40 AND 59 THEN '40-59'
        WHEN d.RIDAGEYR >= 60 THEN '60+'
    END AS age_group,
    COUNT(*) AS number_of_people,
    ROUND(AVG(b.BMI_numeric), 2) AS average_bmi
FROM body_measurements AS b
INNER JOIN demographics AS d
    ON b.SEQN = d.SEQN
WHERE b.BMI_numeric IS NOT NULL
  AND d.RIDAGEYR >= 20
GROUP BY
    CASE
        WHEN d.RIDAGEYR BETWEEN 20 AND 39 THEN '20-39'
        WHEN d.RIDAGEYR BETWEEN 40 AND 59 THEN '40-59'
        WHEN d.RIDAGEYR >= 60 THEN '60+'
    END
ORDER BY age_group;

-- Calculate percentage of people within a bmi category per age group
SELECT
	CASE
		WHEN d.RIDAGEYR BETWEEN 20 AND 39 THEN '20-39'
        WHEN d.RIDAGEYR BETWEEN 40 AND 59 THEN '40-59'
        WHEN d.RIDAGEYR >= 60 THEN '60+'
	END AS age_group,
    COUNT(*) AS number_of_people,
    ROUND(SUM(CASE WHEN b.BMI_numeric < 18.5 THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS Underweight_pct,
    ROUND(SUM(CASE WHEN b.BMI_numeric >= 18.5 AND b.BMI_numeric < 25 THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS Normal_weight_pct,
    ROUND(SUM(CASE WHEN b.BMI_numeric >= 25 AND b.BMI_numeric < 30 THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS Overweight_pct,
    ROUND(SUM(CASE WHEN b.BMI_numeric >= 30 THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS Obesity_pct
FROM body_measurements AS b
INNER JOIN demographics AS d
	ON b.SEQN = d.SEQN
WHERE b.BMI_numeric IS NOT NULL
	AND d.RIDAGEYR >= 20
GROUP BY age_group
ORDER BY age_group;

-- Calculate the avg bmi per age group and sex
SELECT
	CASE
		WHEN d.RIDAGEYR BETWEEN 20 AND 39 THEN '20-39'
        WHEN d.RIDAGEYR BETWEEN 40 AND 59 THEN '40-59'
        WHEN d.RIDAGEYR >= 60 THEN '60+'
	END AS age_group,
    COUNT(*) AS number_of_people,
    ROUND(AVG(CASE WHEN d.RIAGENDR = 1 THEN b.BMI_numeric END), 2) AS Male_average,
    ROUND(AVG(CASE WHEN d.RIAGENDR = 2 THEN b.BMI_numeric END), 2) AS Female_average
FROM body_measurements AS b
INNER JOIN demographics AS d
	ON b.SEQN = d.SEQN
WHERE b.BMI_numeric IS NOT NULL
	AND d.RIDAGEYR >= 20
GROUP BY 
	CASE
		WHEN d.RIDAGEYR BETWEEN 20 AND 39 THEN '20-39'
        WHEN d.RIDAGEYR BETWEEN 40 AND 59 THEN '40-59'
        WHEN d.RIDAGEYR >= 60 THEN '60+'
	END
ORDER BY
	age_group;
   
/* ========================
	Final Analysis Dataset
   ========================*/
   
-- Final summary: BMI by age group and sex
SELECT
    CASE
        WHEN d.RIDAGEYR BETWEEN 20 AND 39 THEN '20-39'
        WHEN d.RIDAGEYR BETWEEN 40 AND 59 THEN '40-59'
        WHEN d.RIDAGEYR >= 60 THEN '60+'
    END AS age_group,
    CASE
        WHEN d.RIAGENDR = 1 THEN 'Male'
        WHEN d.RIAGENDR = 2 THEN 'Female'
    END AS sex,
    COUNT(*) AS number_of_people,
    ROUND(AVG(b.BMI_numeric), 2) AS average_bmi,
    ROUND(SUM(CASE WHEN b.BMI_numeric < 18.5 THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS underweight_pct,
    ROUND(SUM(CASE WHEN b.BMI_numeric >= 18.5 AND b.BMI_numeric < 25 THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS normal_weight_pct,
    ROUND(SUM(CASE WHEN b.BMI_numeric >= 25 AND b.BMI_numeric < 30 THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS overweight_pct,
    ROUND(SUM(CASE WHEN b.BMI_numeric >= 30 THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS obesity_pct
FROM body_measurements AS b
INNER JOIN demographics AS d
    ON b.SEQN = d.SEQN
WHERE b.BMI_numeric IS NOT NULL
  AND d.RIDAGEYR >= 20
GROUP BY
    CASE
        WHEN d.RIDAGEYR BETWEEN 20 AND 39 THEN '20-39'
        WHEN d.RIDAGEYR BETWEEN 40 AND 59 THEN '40-59'
        WHEN d.RIDAGEYR >= 60 THEN '60+'
    END,
    d.RIAGENDR
ORDER BY
    age_group,
    sex;
    
/*PROJECT FINDINGS
Analysis population: NHANES 2021-2023 participants aged 20+ with recorded BMI.

1. 98.83%  of participants aged 20+ have their BMI recorded.
2. Average BMI varied across age and sex groups.
3. In every age group, females had a higher average BMI than males.
3. The highest average BMI in this analysis was 31.06 among females ages 40-59.
4. The lowest average BMI was 28.56 among males ages 20-39.
5. Obesity was the largest BMI category in every age/sex group except males aged between 20-39 and aged 60+. In these cases the largest BMI category was overweight.

Limitation:
These results are descriptive of the survey participants and are not survey-weighted national estimates.*/