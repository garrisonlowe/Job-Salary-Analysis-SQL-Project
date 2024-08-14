
# Introduction

This project uses SQL to perform data cleaning and exploratory data analysis for a Salary based data set. This readMe is a full summary of my findings and thought processes for each question.

# Questions

### **Age vs. Salary**
**1. How does salary vary with age and is there a peak age where salaries are highest?**

For this, I think it would help if we created some bins for age groups. Then collected the average salary at every age group, regardless of experience level.

```sql
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
```
From this, we can see an exact correlation between age and salary, the average salary goes up directly with the age. I do not see a peak age before retirement for salary.
| avg_sal    | age_groups |
|------------|------------|
| 194221.83  | 60+        |
| 193047.00  | 55-59      |
| 191080.52  | 50-54      |
| 179425.91  | 45-49      |
| 158033.01  | 40-44      |
| 135943.01  | 35-39      |
| 117990.23  | 30-34      |
| 76537.23   | 25-29      |
| 48021.68   | 20-24      |


     
### **Gender vs Salary**
**1. What is the average salary for different genders?**

Let's first look at the average salary per gender.

```sql
SELECT ROUND(AVG(salary), 2), gender
FROM salary_data
GROUP BY gender;
```
We can see that males make about 14k more than females on average with 121k and 107k, respectively.
The gender 'Other' makes more than both Male and Female at 125k.

| avg_sal    | gender  |
|------------|---------|
| 121395.70  | Male    |
| 107889.00  | Female  |
| 125869.86  | Other   |

**2. Is there a gender pay gap? and how does it vary across job titles?**

This query takes the average salary per gender and per job title and excludes the job titles that only have 1 gender for them.

```sql
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
```

This one looks at the average salary disparity for each job title and which gender is the higher of the two.

```sql
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
```

In this query, we are looking to see the number of jobs that each gender has the higher salary in. 

```sql
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
```
| higher_salary_gender | cnt |
|----------------------|-----|
| Male                 | 37  |
| Female               | 29  |
| Equal                | 2   |

Males have the higher salary in 37 jobs, while Females have the higher salary in 29 jobs, they are equal in 2. There seems to be a slight gender pay gap advantage for Males in certain jobs when not accounting for years of experience.


### **Education Level vs Salary**
**1. How does salary correlate with different levels of education?**

```sql
SELECT ROUND(AVG(salary), 2) as avg_sal, education_level
FROM salary_data
GROUP BY education_level
ORDER BY avg_sal
;
```

| avg_sal    | education_level |
|------------|-----------------|
| 36706.69   | High School     |
| 95082.91   | Bachelor's      |
| 130112.06  | Master's        |
| 165651.46  | PhD             |

From this we can see that salary directly correlates with education level, the higher the educaiton level; the higher the salary.

### **Years of Experience vs Salary**
**1. How does salary increase with years of experience?**

For this one, I think it would be best to create small bins for years of experience to condense the data.

```sql
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
SELECT ROUND(AVG(salary), 2) as avg_sal, age_groups
FROM sal_by_yoe
GROUP BY age_groups
ORDER BY avg_sal DESC
;
```

From this we can see a very strong correlation between salary and years of experience. 22 - 24 years of experience has the highest average salary, followed by 31+.

| avg_sal    | age_groups |
|------------|------------|
| 193143.72  | 22 - 24    |
| 188532.61  | 31+        |
| 183737.71  | 16 - 18    |
| 182167.06  | 28 - 30    |
| 182106.02  | 25 - 27    |
| 181323.74  | 19 - 21    |
| 161365.82  | 13 - 15    |
| 148092.90  | 10 - 12    |
| 128944.31  | 7 - 9      |
| 98343.63   | 4 - 6      |
| 57892.48   | 0 - 3      |


**2. Is there diminishing returns on experience in terms of salary growth?**

For this, we can use the same query as before, but add in a LAG window function to help calculate the percent change from the previous age group. I'm also going to change the age group names so I can order by them.

```sql
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
```
From this, we can see that there are big jumps early on into the career, it slowly starts to go down around the 18 year mark with a decent amount of stagnation from 18-30+ years.

| max_years | avg_sal    | pct_change_from_previous |
|-----------|------------|--------------------------|
| 3         | 57892.48   | -                        |
| 6         | 98343.63   | 69.87%                   |
| 9         | 128944.31  | 31.12%                   |
| 12        | 148092.90  | 14.85%                   |
| 15        | 161365.82  | 8.96%                    |
| 18        | 183737.71  | 13.86%                   |
| 21        | 181323.74  | -1.31%                   |
| 24        | 193143.72  | 6.52%                    |
| 27        | 182106.02  | -5.71%                   |
| 30        | 182167.06  | 0.03%                    |
| 33        | 188532.61  | 3.49%                    |



### **Job Title vs Salary**
**1. What are the average salaries for each job title?**

```sql
SELECT ROUND(AVG(salary), 2) as avg_sal, job_title
FROM salary_data
GROUP BY job_title
ORDER BY avg_sal DESC
;
```
Output is too long for a readMe.

**2. Which job titles have the highest and lowest salaries?**

For this question, I'm only going to show the top 10 jobs as the list is over 100 jobs using the previous query. The list looks about how you would expect, CEO, CTO, CDO, Directors, and VP positions.

```sql
SELECT ROUND(AVG(salary), 2) as avg_sal, job_title
FROM salary_data
GROUP BY job_title
ORDER BY avg_sal DESC
LIMIT 10
;
```

| avg_sal    | job_title                    |
|------------|------------------------------|
| 250000.00  | CEO                          |
| 250000.00  | Chief Technology Officer     |
| 220000.00  | Chief Data Officer           |
| 204561.40  | Director of Data Science     |
| 200000.00  | Director                     |
| 200000.00  | VP of Finance                |
| 190000.00  | VP of Operations             |
| 190000.00  | Operations Director          |
| 187500.00  | Director of Human Resources  |
| 183984.38  | Marketing Director           |

Since a lot of these positions are 1-person positions, for a more accurate analysis I'm going to take the top 10 jobs that have at **least 5 rows** in the data.

```sql
SELECT ROUND(AVG(salary), 2) as avg_sal, job_title
FROM salary_data
GROUP BY job_title
HAVING COUNT(job_title) >= 5
ORDER BY avg_sal DESC
LIMIT 10
;
```

| avg_sal    | job_title                  |
|------------|----------------------------|
| 204561.40  | Director of Data Science   |
| 183984.38  | Marketing Director         |
| 172727.27  | Director of Operations     |
| 172502.17  | Software Engineer Manager  |
| 166224.75  | Senior Project Engineer    |
| 166105.96  | Data Scientist             |
| 165362.32  | Research Scientist         |
| 163333.33  | Research Director          |
| 151326.69  | Senior Software Engineer   |
| 151147.54  | Senior Data Scientist      |


Now let's look at the **bottom 10** jobs.

```sql
SELECT ROUND(AVG(salary), 2) as avg_sal, job_title
FROM salary_data
GROUP BY job_title
HAVING COUNT(job_title) >= 5
ORDER BY avg_sal ASC
LIMIT 10
;
```

| avg_sal   | job_title                             |
|-----------|---------------------------------------|
| 25000.00  | Receptionist                          |
| 28000.00  | Delivery Driver                       |
| 28211.27  | Junior Sales Associate                |
| 33333.33  | Customer Service Representative       |
| 35810.34  | Junior Software Developer             |
| 35857.14  | Sales Associate                       |
| 36951.22  | Junior Sales Representative           |
| 37017.24  | Junior HR Coordinator                 |
| 38250.00  | Junior HR Generalist                  |
| 40714.29  | Junior Business Development Associate |

### **Gender Distribution Across Job Titles**
**1. What is the gender distribution across different job titles?**

I'm going to show the list of jobs and their respective percentages of male and female occupants. I'm only going to show 10 as the list is long, but you can check the full list in the *"Exploratory Analysis.sql"* file!

```sql
SELECT job_title, 
       CONCAT(ROUND(COUNT(CASE WHEN gender = 'Male' THEN gender END)/COUNT(gender)*100,0), '%') as pct_male,
       CONCAT(ROUND(COUNT(CASE WHEN gender = 'Female' THEN gender END)/COUNT(gender)*100,0), '%') as pct_female
FROM salary_data
GROUP BY job_title
HAVING COUNT(job_title) > 5
;
```

| job_title              | pct_male | pct_female |
|------------------------|----------|------------|
| Software Engineer      | 63%      | 37%        |
| Data Analyst           | 64%      | 36%        |
| Sales Associate        | 31%      | 69%        |
| Marketing Analyst      | 63%      | 37%        |
| Product Manager        | 67%      | 33%        |
| Sales Manager          | 73%      | 27%        |
| Marketing Coordinator  | 1%       | 99%        |
| Software Developer     | 66%      | 34%        |
| Financial Analyst      | 92%      | 8%         |
| Project Manager        | 95%      | 5%         |


**2. Are certain job titles dominated by one gender, and how does this relate to salary?**

First, let's look at the top 10 male dominated professions.

```sql
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
```

| job_title                | pct_male | pct_female | job_count |
|--------------------------|----------|------------|-----------|
| Product Designer         | 100      | 0          | 75        |
| Junior Data Analyst      | 100      | 0          | 25        |
| Junior Business Analyst  | 100      | 0          | 8         |
| Operations Manager       | 98       | 2          | 114       |
| Project Manager          | 95       | 5          | 22        |
| Senior Data Scientist    | 93       | 7          | 61        |
| Financial Analyst        | 92       | 8          | 39        |
| Sales Director           | 92       | 8          | 62        |
| Senior Product Manager   | 83       | 17         | 6         |
| Marketing Director       | 78       | 22         | 64        |

This gives some interesting numbers, of the 75 Product Designers in the data set, all 75 are male. Of the 114 Operations Managers, all but 2 are male.

Now, let's look at the top 10 female dominated professions.

```sql
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
```
| job_title                        | pct_male | pct_female | job_count |
|----------------------------------|----------|------------|-----------|
| Senior Marketing Manager         | 0        | 100        | 9         |
| Receptionist                     | 0        | 100        | 57        |
| Digital Marketing Specialist     | 0        | 100        | 15        |
| Human Resources Manager          | 0        | 100        | 104       |
| Human Resources Coordinator      | 0        | 100        | 49        |
| Social Media Manager             | 0        | 100        | 14        |
| Customer Service Representative  | 0        | 100        | 6         |
| Marketing Coordinator            | 1        | 99         | 158       |
| Junior Software Developer        | 3        | 97         | 58        |
| Senior Marketing Analyst         | 11       | 89         | 9         |

This one gives even more crazy numbers, females have 100% occupancy of 7 different jobs. 

From these two findings, we can see that males tend to dominate the technical and managerial aspect of the businesses through jobs like Software Engineering, Manager Roles, and Director Roles.

Women tend to dominate the people side of businesses including HR, Social Media, Marketing, and Customer Service.

Let's add in an average salary for these positions and see the average salary across the top 10 jobs for each Male and Female.

Male:
```sql
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

```
| male_avg_salary |
|-----------------|
| 104119.331000   |

Female:

```sql
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
```
| female_avg_salary |
|-------------------|
| 66782.071000      |


The average salary of male dominated jobs is 104119.33, while the average salary of female dominated jobs is 66782.07. There is a large disparity between male dominated jobs and female dominated jobs. I suspect this is due to male dominated jobs being more technology and managerial based, which will lead to higher salaries. While female dominated jobs are more HR and Marketing based.
