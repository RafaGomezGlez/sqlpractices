-- First Query
SELECT school, first_name
FROM teachers
ORDER BY school, first_name ASC;

-- Second Query
SELECT *
FROM teachers WHERE first_name
LIKE 'S%' AND
salary > 40000;

-- Third Query
SELECT *
FROM teachers WHERE first_name
LIKE 'S%' AND
salary > 40000;