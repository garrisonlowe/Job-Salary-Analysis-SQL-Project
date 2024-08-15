-- Active: 1712538144975@@localhost@3306@salary


-- Age vs Salary:
--      1. How does salary vary with age and is there a peak age where salaries are highest?

-- For this, I think it would help if we created some bins for age groups. Then collected the average salary at every age group, regardless of experience level.


WITH age_groups_cte AS (
    SELECT age,
        CASE 
            WHEN age >= 20 AND age <=24 THEN '20-24'  
            WHEN age >= 25 AND age <=29 THEN '25-29'
            WHEN age >= 30 AND age <=34 THEN '30-34'
            WHEN age >= 35 AND age <=39 THEN '35-39'
            WHEN age >= 40 AND age <=44 THEN '40-44'
            WHEN age >= 45 AND age <=49 THEN '45-49'
            WHEN age >= 50 AND age <=54 THEN '50-54'
            WHEN age >= 55 AND age <=59 THEN '55-59'
            WHEN age >= 60 THEN '60+'
        END as 'age_groups',
        salary
    FROM salary_data
)
SELECT ROUND(AVG(salary), 2) as avg_sal, age_groups
FROM age_groups_cte
GROUP BY age_groups 
ORDER BY ROUND(AVG(salary), 2) DESC;

-- From this, we can see an exact correlation between age and salary, the average salary goes up directly with the age.

-- Gender vs Salary:
--      1. What is the average salary for different genders?
-- Avg Salary per Gender

SELECT ROUND(AVG(salary), 2) AS avg_sal, gender
FROM salary_data
GROUP BY gender;

-- We can see that males make about 14k more than females on average with 121k and 107k, respectively.
-- The gender 'Other' makes more than both Male and Female at 125k.

--      2. Is there a gender pay gap? and how does it vary across job titles?

SELECT ROUND(AVG(salary), 2) AS average_salary, gender, job_title
FROM salary_data
WHERE job_title IN (
    SELECT job_title
    FROM salary_data
    GROUP BY job_title
    HAVING COUNT(DISTINCT gender) >= 2
)
GROUP BY job_title, gender
ORDER BY job_title ASC, gender DESC;

-- ^ This query takes the average salary per gender and per job title and excludes the job titles that only have 1 gender for them.

SELECT job_title,
       ABS(male_avg_salary - female_avg_salary) AS salary_disparity,
       CASE
           WHEN male_avg_salary > female_avg_salary THEN 'Male'
           WHEN female_avg_salary > male_avg_salary THEN 'Female'
           ELSE 'Equal'
       END AS higher_salary_gender
FROM (
    SELECT job_title,
           AVG(CASE WHEN gender = 'Male' THEN salary END) AS male_avg_salary,
           AVG(CASE WHEN gender = 'Female' THEN salary END) AS female_avg_salary
    FROM salary_data
    GROUP BY job_title
    HAVING COUNT(DISTINCT gender) = 2
) AS salary_diff
ORDER BY salary_disparity DESC;

-- ^ This one looks at the average salary disparity for each job title and which gender is the higher of the two.

WITH avg_sal_disp AS (
    SELECT job_title,
        ABS(male_avg_salary - female_avg_salary) AS salary_disparity,
        CASE
            WHEN male_avg_salary > female_avg_salary THEN 'Male'
            WHEN female_avg_salary > male_avg_salary THEN 'Female'
            ELSE 'Equal'
        END AS higher_salary_gender
    FROM (
        SELECT job_title,
            AVG(CASE WHEN gender = 'Male' THEN salary END) AS male_avg_salary,
            AVG(CASE WHEN gender = 'Female' THEN salary END) AS female_avg_salary
        FROM salary_data
        GROUP BY job_title
        HAVING COUNT(DISTINCT gender) = 2
    ) AS salary_diff
    ORDER BY salary_disparity DESC
)
SELECT higher_salary_gender, COUNT(higher_salary_gender) AS cnt
FROM avg_sal_disp
GROUP BY higher_salary_gender
ORDER BY COUNT(higher_salary_gender) DESC
;

-- ^ In this query, we are looking to see the number of jobs that each gender has the higher salary in.
-- Males have the higher salary in 37 jobs, while Females have the higher salary in 29 jobs, they are equal in 2.
-- There seems to be a slight gender pay gap advantage for Males in certain jobs when not accounting for years of experience.


-- Education Level vs Salary
--      1. How does salary correlate with different levels of education?

SELECT ROUND(AVG(salary), 2) as avg_sal, education_level
FROM salary_data
GROUP BY education_level
ORDER BY avg_sal
;

-- From this we can see that salary directly correlates with education level, the higher the educaiton level; the higher the salary.


-- Years of Experience vs Salary
--      1. How does salary increase with years of experience?

-- For this one, I think it would be best to create small bins for years of experience to condense the data.

WITH sal_by_yoe AS (
    SELECT years_of_experience, 
        CASE 
            WHEN years_of_experience >= 0 AND years_of_experience <=3 THEN '0 - 3'
            WHEN years_of_experience >= 4 AND years_of_experience <=6 THEN '4 - 6' 
            WHEN years_of_experience >= 7 AND years_of_experience <=9 THEN '7 - 9' 
            WHEN years_of_experience >= 10 AND years_of_experience <=12 THEN '10 - 12' 
            WHEN years_of_experience >= 13 AND years_of_experience <=15 THEN '13 - 15' 
            WHEN years_of_experience >= 16 AND years_of_experience <=18 THEN '16 - 18' 
            WHEN years_of_experience >= 19 AND years_of_experience <=21 THEN '19 - 21' 
            WHEN years_of_experience >= 22 AND years_of_experience <=24 THEN '22 - 24' 
            WHEN years_of_experience >= 25 AND years_of_experience <=27 THEN '25 - 27'
            WHEN years_of_experience >= 28 AND years_of_experience <=30 THEN '28 - 30'
            WHEN years_of_experience >= 31 THEN '31+'
        END as 'age_groups',
        salary
    FROM salary_data
)
SELECT ROUND(AVG(salary), 2) AS avg_sal, age_groups
FROM sal_by_yoe
GROUP BY age_groups
ORDER BY avg_sal DESC
;


-- From this we can see a very strong correlation between salary and years of experience. 22 - 24 years of experience has the highest average salary, followed by 31+.


--      2. Is there diminishing returns on experience in terms of salary growth?

-- For this, we can use the same query as before, but add in a LAG window function to help calculate the percent change from the previous age group. I'm also going to change the age group names so I can order by them.

WITH sal_by_yoe AS (
    SELECT years_of_experience, 
        CASE 
            WHEN years_of_experience >= 0 AND years_of_experience <= 3 THEN 3
            WHEN years_of_experience >= 4 AND years_of_experience <= 6 THEN 6 
            WHEN years_of_experience >= 7 AND years_of_experience <= 9 THEN 9 
            WHEN years_of_experience >= 10 AND years_of_experience <= 12 THEN 12 
            WHEN years_of_experience >= 13 AND years_of_experience <= 15 THEN 15 
            WHEN years_of_experience >= 16 AND years_of_experience <= 18 THEN 18 
            WHEN years_of_experience >= 19 AND years_of_experience <= 21 THEN 21 
            WHEN years_of_experience >= 22 AND years_of_experience <= 24 THEN 24 
            WHEN years_of_experience >= 25 AND years_of_experience <= 27 THEN 27
            WHEN years_of_experience >= 28 AND years_of_experience <= 30 THEN 30
            WHEN years_of_experience >= 31 THEN 33
        END AS max_years,
        salary
    FROM salary_data
)
SELECT 
    max_years,
    ROUND(AVG(salary), 2) AS avg_sal,
    CONCAT(ROUND((AVG(salary) - LAG(AVG(salary)) 
        OVER (ORDER BY max_years)) / LAG(AVG(salary)) 
        OVER (ORDER BY max_years) * 100, 2), '%') AS pct_change_from_previous
FROM sal_by_yoe
GROUP BY max_years
ORDER BY max_years;

-- From this we can see that there are big jumps early on into the career, it slowly starts to go down around the 18 year mark with a decent amount of stagnation from 18-30+ years.



-- Job Specific Analysis

-- Job Title vs Salary
--      1. What are the average salaries for each job title?

SELECT ROUND(AVG(salary), 2) as avg_sal, job_title
FROM salary_data
GROUP BY job_title
ORDER BY avg_sal DESC
;

--      2. Which job titles have the highest and lowest salaries?

SELECT ROUND(AVG(salary), 2) as avg_sal, job_title
FROM salary_data
GROUP BY job_title
ORDER BY avg_sal DESC
LIMIT 10
;

-- The top 10 jobs by average salary looks about how you might expect. CEO, CT0, CDO, Directors, and VP positions.
-- A lot of these positions only have 1 row in the data set, mainly due to them being a 1-person title like CEO.
-- Let's filter the list to only show jobs that have at least 5 rows in the table.

SELECT ROUND(AVG(salary), 2) as avg_sal, job_title
FROM salary_data
GROUP BY job_title
HAVING COUNT(job_title) >= 5
ORDER BY avg_sal DESC
LIMIT 10
;

-- Now we can see that the top 10 jobs having more than 5 entries are:
--  1. Director of Data Science
--  2. Marketing Director
--  3. Director of Operations
--  4. Software Engineer Manager
--  5. Senior Project Engineer
--  6. Data Scientist
--  7. Research Scientist
--  8. Research Director
--  9. Senior Software Engineer
-- 10. Senior Data Scientist

-- Now lets look at the bottom 10 jobs.
SELECT ROUND(AVG(salary), 2) as avg_sal, job_title
FROM salary_data
GROUP BY job_title
HAVING COUNT(job_title) >= 5
ORDER BY avg_sal ASC
LIMIT 10
;

-- Now we can see that the bottom 10 jobs having more than 5 entries are:
--  1. Receptionist
--  2. Delivery Driver
--  3. Junior Sales Associate
--  4. Customer Service Representative
--  5. Junior Software Developer
--  6. Sales Associate
--  7. Junior Sales Representative
--  8. Junior HR Coordinator
--  9. Junior HR Generalist
-- 10. Junior Business Development Associate


-- Gender Distribution Across Job Titles
--      1. What is the gender distribution across different job titles?
--      2. Are certain job titles dominated by one gender, and how does this relate to salary?

SELECT job_title, 
       CONCAT(ROUND(COUNT(CASE WHEN gender = 'Male' THEN gender END)/COUNT(gender)*100,0), '%') as pct_male,
       CONCAT(ROUND(COUNT(CASE WHEN gender = 'Female' THEN gender END)/COUNT(gender)*100,0), '%') as pct_female
FROM salary_data
GROUP BY job_title
HAVING COUNT(job_title) > 5
;

-- This query shows the percentage of male and females per job, as long as the job has 5 or more entries to not skew the data for jobs that only have 1 row.
-- Lets look at the top 10 male dominated jobs.

SELECT job_title, 
       ROUND(COUNT(CASE WHEN gender = 'Male' THEN gender END)/COUNT(gender)*100,0) as pct_male,
       ROUND(COUNT(CASE WHEN gender = 'Female' THEN gender END)/COUNT(gender)*100,0) as pct_female,
       COUNT(job_title) AS job_count
FROM salary_data
GROUP BY job_title
HAVING COUNT(job_title) > 5
ORDER BY pct_male DESC
LIMIT 10
;

-- I took off the percent sign as it was messing up the order by function, changing it from a number to a string.
-- The top 10 male dominated jobs are:
--  1. Product Designer: 100% male
--  2. Junior Data Analyst: 100% male
--  3. Junior Business Analyst: 100% male
--  4. Operations Manager: 98% male
--  5. Project Manager: 95% male
--  6. Senior Data Scientist: 93% male
--  7. Financial Analyst: 92% male
--  8. Sales Director: 92% male
--  9. Senior Product Manager: 83% male
-- 10. Marketing Director: 78% male

-- Now lets look at the top 10 female dominated jobs.
SELECT job_title, 
       ROUND(COUNT(CASE WHEN gender = 'Male' THEN gender END)/COUNT(gender)*100,0) as pct_male,
       ROUND(COUNT(CASE WHEN gender = 'Female' THEN gender END)/COUNT(gender)*100,0) as pct_female,
       COUNT(job_title) AS job_count
FROM salary_data
GROUP BY job_title
HAVING COUNT(job_title) > 5
ORDER BY pct_female DESC
LIMIT 10
;

-- The top 10 female dominated jobs are:
--  1. Senior Marketing Manager: 100% female
--  2. Receptionist: 100% female
--  3. Digital Marketing Specialist: 100% female
--  4. Human Resources Manager: 100% female
--  5. Human Resources Coordinator: 100% female
--  6. Social Media Manager: 100% female
--  7. Customer Service Rep: 100% female
--  8. Marketing Coordinator: 99% female
--  9. Junior Software Developer: 97% female
-- 10. Senior Marketing Analyst: 89% female

-- From these views, we can see that males dominate the technical and management side of businesses through Data Science,
-- Software Development, Manager roles, and Director Roles.

-- Women tend to dominate the people side of businesses including HR, Social Media, Marketing, and Customer Service.

-- For question 2; Lets add in an average salary for these positions and see the average salary across the top 10 jobs for each Male and Female.

-- Male
SELECT AVG(avg_salary) AS male_avg_salary
FROM (
    WITH selected_jobs AS (
        SELECT job_title, 
            ROUND(SUM(CASE WHEN gender = 'Male' THEN 1 ELSE 0 END) / COUNT(gender) * 100, 0) AS pct_male,
            ROUND(SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) / COUNT(gender) * 100, 0) AS pct_female,
            COUNT(job_title) AS job_count
        FROM salary_data
        GROUP BY job_title
        HAVING COUNT(job_title) > 5
        ORDER BY pct_male DESC
        LIMIT 10
    )
    SELECT sj.job_title,
        sj.pct_male,
        sj.pct_female,
        sj.job_count,
        ROUND(AVG(sd.salary), 2) AS avg_salary
    FROM selected_jobs sj
    JOIN salary_data sd
        ON sj.job_title = sd.job_title
    GROUP BY sj.job_title, sj.pct_male, sj.pct_female, sj.job_count
    ORDER BY sj.pct_male DESC
) avg_salary

-- Female
SELECT AVG(avg_salary) AS female_avg_salary
FROM (
    WITH selected_jobs AS (
        SELECT job_title, 
            ROUND(SUM(CASE WHEN gender = 'Male' THEN 1 ELSE 0 END) / COUNT(gender) * 100, 0) AS pct_male,
            ROUND(SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) / COUNT(gender) * 100, 0) AS pct_female,
            COUNT(job_title) AS job_count
        FROM salary_data
        GROUP BY job_title
        HAVING COUNT(job_title) > 5
        ORDER BY pct_female DESC
        LIMIT 10
    )
    SELECT sj.job_title,
        sj.pct_male,
        sj.pct_female,
        sj.job_count,
        ROUND(AVG(sd.salary), 2) AS avg_salary
    FROM selected_jobs sj
    JOIN salary_data sd
        ON sj.job_title = sd.job_title
    GROUP BY sj.job_title, sj.pct_male, sj.pct_female, sj.job_count
    ORDER BY sj.pct_female DESC
) avg_salary
    

-- The average salary of male dominated jobs is 104119.33
-- The average salary of female dominated jobs is 66782.07
-- There is a large disparity between male dominated jobs and female dominated jobs. I suspect this is due to male dominated
-- jobs being more technology and managerial based, which will lead to higher salaries. While female dominated jobs are more
-- HR and Marketing based.


-- Experience and Education Within Job Titles
--      1. How do years of experience and education level affect salary within a specfic job title?

-- First lets look at how education levels affect average salary, I'm going to pick the Data Scientist role.

SELECT job_title, education_level, AVG(salary) as avg_sal
FROM salary_data
WHERE job_title = "Data Scientist"
GROUP BY education_level
ORDER BY avg_sal DESC
;

-- For this, it seems that people with Bachelor's degrees tend to make 13k - 16k more than PhD and Master's respectively.

-- Now lets do it for Years of Experience
SELECT job_title,  
        AVG(salary) as avg_sal,
        CASE 
            WHEN years_of_experience >= 0 AND years_of_experience <=3 THEN '0 - 3'
            WHEN years_of_experience >= 4 AND years_of_experience <=6 THEN '4 - 6' 
            WHEN years_of_experience >= 7 AND years_of_experience <=9 THEN '7 - 9' 
            WHEN years_of_experience >= 10 AND years_of_experience <=12 THEN '10 - 12' 
            WHEN years_of_experience >= 13 AND years_of_experience <=15 THEN '13 - 15' 
            WHEN years_of_experience >= 16 AND years_of_experience <=18 THEN '16 - 18' 
            WHEN years_of_experience >= 19 AND years_of_experience <=21 THEN '19 - 21' 
            WHEN years_of_experience >= 22 AND years_of_experience <=24 THEN '22 - 24' 
            WHEN years_of_experience >= 25 AND years_of_experience <=27 THEN '25 - 27'
            WHEN years_of_experience >= 28 AND years_of_experience <=30 THEN '28 - 30'
            WHEN years_of_experience >= 31 THEN '31+'
        END as 'age_groups'
FROM salary_data
WHERE job_title = "Data Scientist"
GROUP BY age_groups
ORDER BY avg_sal DESC
;

-- This went about how I expected, 22-24 years leads the group and it goes down pretty linearly with 0-3 at the bottom. 
-- There is an odd outlier here, with 13-15 years being second to last, below 4-6 and 7-9.


--      2. Do individuals with higher education levels see a faster salary progression over time?

-- For this lets look at the Software Engineer.

-- Let's look at the progression of salary for a Bachelors's degree from 0-5 years experience, 5-10 years experience, 10-15 years experience, and 15-20 years of experience.

(WITH cte AS (
    SELECT job_title, education_level, years_of_experience, salary
    FROM salary_data
    WHERE job_title = "Software Engineer" 
        AND education_level = "Bachelor's" 
        AND years_of_experience BETWEEN 0 and 5 
)
SELECT AVG(salary)
FROM cte)
UNION ALL
(WITH cte AS (
    SELECT job_title, education_level, years_of_experience, salary
    FROM salary_data
    WHERE job_title = "Software Engineer" 
        AND education_level = "Bachelor's" 
        AND years_of_experience BETWEEN 5 and 10
)
SELECT AVG(salary)
FROM cte)
UNION ALL
(WITH cte AS (
    SELECT job_title, education_level, years_of_experience, salary
    FROM salary_data
    WHERE job_title = "Software Engineer" 
        AND education_level = "Bachelor's" 
        AND years_of_experience BETWEEN 10 and 15
)
SELECT AVG(salary)
FROM cte)
UNION ALL
(WITH cte AS (
    SELECT job_title, education_level, years_of_experience, salary
    FROM salary_data
    WHERE job_title = "Data Scientist" 
        AND education_level = "Bachelor's" 
        AND years_of_experience BETWEEN 15 and 20
)
SELECT AVG(salary)
FROM cte)

-- Salary Progression of Software Engineer's with a Bachelor's.
--  0-5: 99,942
--  5-10: 152,529
--  10-15: 192,461
--  15-20: (null)



-- For Master's
(WITH cte AS (
    SELECT job_title, education_level, years_of_experience, salary
    FROM salary_data
    WHERE job_title = "Software Engineer" 
        AND education_level = "Master's" 
        AND years_of_experience BETWEEN 0 and 5 
)
SELECT AVG(salary)
FROM cte)
UNION ALL
(WITH cte AS (
    SELECT job_title, education_level, years_of_experience, salary
    FROM salary_data
    WHERE job_title = "Software Engineer" 
        AND education_level = "Master's" 
        AND years_of_experience BETWEEN 5 and 10
)
SELECT AVG(salary)
FROM cte)
UNION ALL
(WITH cte AS (
    SELECT job_title, education_level, years_of_experience, salary
    FROM salary_data
    WHERE job_title = "Software Engineer" 
        AND education_level = "Master's" 
        AND years_of_experience BETWEEN 10 and 15
)
SELECT AVG(salary)
FROM cte)
UNION ALL
(WITH cte AS (
    SELECT job_title, education_level, years_of_experience, salary
    FROM salary_data
    WHERE job_title = "Data Scientist" 
        AND education_level = "Master's" 
        AND years_of_experience BETWEEN 15 and 20
)
SELECT AVG(salary)
FROM cte)

-- Salary Progression of Software Engineer's with a Bachelor's.
--  0-5: 60,535
--  5-10: 142,916
--  10-15: (null)
--  15-20: 198,000

-- For PhD's
(WITH cte AS (
    SELECT job_title, education_level, years_of_experience, salary
    FROM salary_data
    WHERE job_title = "Software Engineer" 
        AND education_level = "PhD" 
        AND years_of_experience BETWEEN 0 and 5 
)
SELECT AVG(salary)
FROM cte)
UNION ALL
(WITH cte AS (
    SELECT job_title, education_level, years_of_experience, salary
    FROM salary_data
    WHERE job_title = "Software Engineer" 
        AND education_level = "PhD" 
        AND years_of_experience BETWEEN 5 and 10
)
SELECT AVG(salary)
FROM cte)
UNION ALL
(WITH cte AS (
    SELECT job_title, education_level, years_of_experience, salary
    FROM salary_data
    WHERE job_title = "Software Engineer" 
        AND education_level = "PhD" 
        AND years_of_experience BETWEEN 10 and 15
)
SELECT AVG(salary)
FROM cte)
UNION ALL
(WITH cte AS (
    SELECT job_title, education_level, years_of_experience, salary
    FROM salary_data
    WHERE job_title = "Data Scientist" 
        AND education_level = "PhD" 
        AND years_of_experience BETWEEN 15 and 20
)
SELECT AVG(salary)
FROM cte)

-- Salary Progression of Software Engineer's with a Bachelor's.
--  0-5: (null)
--  5-10: (null)
--  10-15: (null)
--  15-20: 169,220

--In summary, we see something odd occuring for software engineers. The Bachelor's have the highest starting salary (no data 
--for PhD's) and almost eclipse Master's at 15-20 years experience. While the Master's have a much lower starting pay, but 
--triple that pay by 15-20 years. And the most odd thing, PhD's with more than 15 years of experience make the least out of 
--all of them at the same experience level.