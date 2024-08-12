# Introduction

This project uses SQL to perform data cleaning and exploratory data analysis for a Salary based data set. This readMe is a full summary of my findings and thought processes for each question.

## Questions

**1. Age vs. Salary**
- How does salary vary with age?

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
From this, we can see an exact correlation between age and salary, the average salary goes up directly with the age.
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
