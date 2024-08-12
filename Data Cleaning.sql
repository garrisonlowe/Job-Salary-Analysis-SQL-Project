-- Active: 1712538144975@@localhost@3306@healthcare

-- I will start by creating a backup of all of the raw data.
CREATE TABLE healthcare_raw LIKE healthcare;
INSERT healthcare_raw SELECT * FROM healthcare;

-- DATA CLEANING

-- First thing I notice are the column names, some of them have spaces. Let's standardize them and make them easier to use.

ALTER TABLE healthcare RENAME COLUMN `Name` TO name;
ALTER TABLE healthcare RENAME COLUMN `Age` TO age;
ALTER TABLE healthcare RENAME COLUMN `Gender` TO gender;
ALTER TABLE healthcare RENAME COLUMN `Blood Type` TO blood_type;
ALTER TABLE healthcare RENAME COLUMN `Medical Condition` TO medical_condition;
ALTER TABLE healthcare RENAME COLUMN `Date of Admission` TO date_of_admission;
ALTER TABLE healthcare RENAME COLUMN `Doctor` TO doctor;
ALTER TABLE healthcare RENAME COLUMN `Hospital` TO hospital;
ALTER TABLE healthcare RENAME COLUMN `Insurance Provider` TO insurance_provider;
ALTER TABLE healthcare RENAME COLUMN `Billing Amount` TO billing_amount;
ALTER TABLE healthcare RENAME COLUMN `Room Number` TO room_number;
ALTER TABLE healthcare RENAME COLUMN `Admission Type` TO admission_type;
ALTER TABLE healthcare RENAME COLUMN `Discharge Date` TO discharge_date;
ALTER TABLE healthcare RENAME COLUMN `Medication` TO medication;
ALTER TABLE healthcare RENAME COLUMN `Test Results` TO test_results;


-- Next, there are a few things wrong with the name column and doctor column. 
--  1. Random Capitalization
--  2. Some names have 'Mr' and 'Mrs' prefixes
--  3. Some names have a 'MD', 'DDS', 'PhD', etc. suffix
--Let's standardize this column.


-- First, Im going to just set all of the letters to lower case for now.
UPDATE healthcare
SET name = LOWER(name);

-- Getting rid of all of the prefixes and suffixes.
UPDATE healthcare
SET name = replace(name, 'mr. ', '')
WHERE name LIKE 'mr. %';
UPDATE healthcare
SET name = replace(name, 'ms. ', '')
WHERE name LIKE 'ms. %';
UPDATE healthcare
SET name = replace(name, 'mrs. ', '')
WHERE name LIKE 'mrs. %';
UPDATE healthcare
SET name = replace(name, 'dr. ', '')
WHERE name LIKE 'dr. %';
UPDATE healthcare
SET name = replace(name, ' dds', '')
WHERE name LIKE '% dds';
UPDATE healthcare
SET name = replace(name, ' md', '')
WHERE name LIKE '% md';
UPDATE healthcare
SET name = replace(name, ' phd', '')
WHERE name LIKE '% phd';
UPDATE healthcare
SET name = replace(name, ' jr.', '')
WHERE name LIKE '% jr.';
UPDATE healthcare
SET doctor = replace(doctor, ' PhD', '')
WHERE doctor LIKE '% PhD';
UPDATE healthcare
SET doctor = replace(doctor, ' MD', '')
WHERE doctor LIKE '% MD';
UPDATE healthcare
SET doctor = replace(doctor, ' Jr.', '')
WHERE doctor LIKE '% Jr.';
UPDATE healthcare
SET doctor = replace(doctor, 'Mr. ' , '')
WHERE doctor LIKE 'Mr. %';
UPDATE healthcare
SET doctor = replace(doctor, 'Ms. ', '')
WHERE doctor LIKE 'Ms. %';
UPDATE healthcare
SET doctor = replace(doctor, 'Mrs. ', '')
WHERE doctor LIKE 'Mrs. %';

-- For creating a name fun
DELIMITER $$

CREATE FUNCTION CapitalizeName(str VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE len INT;
    DECLARE new_str VARCHAR(255);
    SET len = CHAR_LENGTH(str);
    SET new_str = '';
    
    WHILE i <= len DO
        SET new_str = CONCAT(new_str, 
            IF(
                SUBSTRING(str, i - 1, 1) = ' ' OR i = 1, 
                UPPER(SUBSTRING(str, i, 1)), 
                LOWER(SUBSTRING(str, i, 1))
            )
        );
        SET i = i + 1;
    END WHILE;
    
    RETURN new_str;
END $$

DELIMITER ;

-- Checking to see if function is working.
SELECT CapitalizeName(name) as new_name 
FROM healthcare;

-- Updating the table using the new function.
UPDATE healthcare
SET name = CapitalizeName(name);


-- Second thing I notice, the date fields have a time, I would like it to just show the date as the time is not necessary.
ALTER TABLE healthcare MODIFY date_of_admission DATE;
ALTER TABLE healthcare MODIFY discharge_date DATE;

-- Third, I notice there are negative numbers in the billing amount column, I am unsure if this is just an error or possibly refunds being issued. Since I don't have anyone to ask and this is a personal project, I'm going to assume they are errors and get the absolute value of the number and replace it.
SELECT ABS(billing_amount) as abs_number
FROM healthcare;

-- Update statement, will also include a ROUND in there to get rid of all the decimal places the raw data came with.
UPDATE healthcare
SET billing_amount = ROUND(ABS(billing_amount),2);


-- Fourth, the Hospital column seems useless to me as there is almost 40k distinct values in here and data is very dirty and incomplete, I don't see a way to accurately fix it. I will not be using this column for analysis due to this.ABORT
SELECT DISTINCT hospital FROM healthcare;



-- Final Tests: Checking other columns for bad data.ABORT


-- Gender; everything looks good here.
SELECT DISTINCT gender
FROM healthcare;

-- Blood Type; everything looks good here too.
SELECT DISTINCT blood_type
FROM healthcare;

-- Medical Condition; only 6 medical conditions but everything looks good.
SELECT DISTINCT medical_condition
FROM healthcare;

-- Admission Type; everything looks good.
SELECT DISTINCT admission_type
FROM healthcare;

-- Medication; everything looks good.
SELECT DISTINCT medication
FROM healthcare;

-- Test Results; everything looks good.
SELECT DISTINCT test_results
FROM healthcare;








