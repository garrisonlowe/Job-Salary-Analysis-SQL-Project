-- Active: 1712538144975@@localhost@3306@salary


-- Data Cleaning


-- Fixing column names.

ALTER TABLE salary_data RENAME COLUMN `ï»¿Age` TO age;
ALTER TABLE salary_data RENAME COLUMN `Gender` TO gender;
ALTER TABLE salary_data RENAME COLUMN `Education Level` TO education_level;
ALTER TABLE salary_data RENAME COLUMN `Job Title` TO job_title;
ALTER TABLE salary_data RENAME COLUMN `Years of Experience` TO years_of_experience;
ALTER TABLE salary_data RENAME COLUMN `Salary` TO salary;


--Checking the education level column and how many there are for each.

SELECT DISTINCT education_level, count(education_level)
FROM salary_data
GROUP BY education_level;

-- Removing the 1 row that is empty for education level.

DELETE FROM salary_data
WHERE education_level = '';

-- Some of the education levels have the word 'Degree', lets remove this word from those rows to standardize the data.

UPDATE salary_data
SET education_level = replace(education_level, ' Degree', '')
WHERE education_level LIKE '% Degree';

-- Nothing else needs to be done at this time.