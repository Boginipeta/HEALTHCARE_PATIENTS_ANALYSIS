-- MySQL script. Step 3: load the cleaned data and run analysis queries.

CREATE DATABASE IF NOT EXISTS healthcare_db;
USE healthcare_db;

DROP TABLE IF EXISTS patients;
CREATE TABLE patients (
    patient_id          VARCHAR(10) PRIMARY KEY,
    full_name           VARCHAR(100),
    first_name          VARCHAR(50),
    last_name           VARCHAR(50),
    date_of_birth       DATE,
    birth_year          INT,
    age                 INT,
    age_group           VARCHAR(10),
    gender              VARCHAR(20),
    blood_type          VARCHAR(3),
    abo_group           VARCHAR(2),
    rh_factor           VARCHAR(10),
    possible_duplicate  VARCHAR(5)      -- 'True' / 'False' text from the CSV
);

-- Update the path to where your cleaned CSV is saved.
-- If LOAD DATA is blocked, use MySQL Workbench: right-click table > Table Data Import Wizard.
SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE 'C:\Users\sowji\Downloads\healthcare-patient-analysis\healthcare-patient-analysis'
INTO TABLE patients
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

select count(*) from petients;

-- Q1. Row count and basic profile
SELECT COUNT(*) AS total_patients,
       MIN(age) AS youngest, MAX(age) AS oldest, ROUND(AVG(age), 1) AS avg_age
FROM patients;

-- Q2. Patients by gender with % share
SELECT gender,
       COUNT(*) AS patients,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM patients
GROUP BY gender
ORDER BY patients DESC;

-- Q3. Patients by age group
SELECT age_group, COUNT(*) AS patients
FROM patients
GROUP BY age_group
ORDER BY MIN(age);

-- Q4. Blood type distribution with ranking (window function)
SELECT blood_type,
       COUNT(*) AS patients,
       RANK() OVER (ORDER BY COUNT(*) DESC) AS popularity_rank
FROM patients
GROUP BY blood_type;

-- Q5. Most common blood type within each gender (CTE + window function)
WITH counts AS (
    SELECT gender, blood_type, COUNT(*) AS patients
    FROM patients
    GROUP BY gender, blood_type
),
ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY gender ORDER BY patients DESC) AS rn
    FROM counts
)
SELECT gender, blood_type, patients
FROM ranked
WHERE rn = 1;

-- Q6. Rh-negative share by age group
SELECT age_group,
       COUNT(*) AS patients,
       ROUND(100 * SUM(rh_factor = 'Negative') / COUNT(*), 1) AS pct_rh_negative
FROM patients
GROUP BY age_group
ORDER BY MIN(age);

-- Q7. Possible duplicate patients (same name and date of birth, different ID)
SELECT p1.patient_id, p2.patient_id AS matching_id, p1.full_name, p1.date_of_birth,
       p1.blood_type AS blood_type_1, p2.blood_type AS blood_type_2
FROM patients p1
JOIN patients p2
  ON p1.full_name = p2.full_name
 AND p1.date_of_birth = p2.date_of_birth
 AND p1.patient_id < p2.patient_id;

-- Q8. Most common first names (top 5)
SELECT first_name, COUNT(*) AS patients
FROM patients
GROUP BY first_name
ORDER BY patients DESC
LIMIT 5;
