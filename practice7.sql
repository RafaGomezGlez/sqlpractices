-- ANALIZING DATA AND CORRECTING PROBLEMS + TRANSACTIONS

CREATE TABLE meat_poultry_egg_establishments (
    establishment_number text CONSTRAINT est_number_key PRIMARY KEY,
    company text,
    street text,
    city text,
    st text,
    zip text,
    phone text,
    grant_date date,
    activities text,
    dbas text
);

COPY meat_poultry_egg_establishments
FROM 'C:\YourDirectory\MPI_Directory_by_Establishment_Name.csv'
WITH (FORMAT CSV, HEADER);

CREATE INDEX company_idx ON meat_poultry_egg_establishments (company);

-- Count the rows imported:
SELECT count(*) FROM meat_poultry_egg_establishments;

-----------------------------FINDING DUPLICATES USING GROUP BY AND HAVING---------------------------------------

-- Listing 10-2: Finding multiple companies at the same address
SELECT company,
       street,
       city,
       st,
       count(*) AS address_count
FROM meat_poultry_egg_establishments
GROUP BY company, street, city, st
HAVING count(*) > 1
ORDER BY company, street, city, st;

-- Listing 10-3: Grouping and counting states
SELECT st, 
       count(*) AS st_count
FROM meat_poultry_egg_establishments
GROUP BY st
ORDER BY st;

------------------------FINDING NULL RECORDS (Missing data)------------------------------------------------
-- 1. Group and count
-- 2. Use nulls first on the order by
-- Listing 10-4: Using IS NULL to find missing values in the st column
SELECT establishment_number,
       company,
       city,
       st,
       zip
FROM meat_poultry_egg_establishments
WHERE st IS NULL;

-- Listing 10-5: Using GROUP BY and count() to find inconsistent company names

SELECT company,
       count(*) AS company_count
FROM meat_poultry_egg_establishments
GROUP BY company
ORDER BY company ASC;

---------------------------CONSTRAINTS FOR SOME COLUMNS--------------------------------------------
-- Listing 10-6: Using length() and count() to test the zip column

SELECT length(zip),
       count(*) AS length_count
FROM meat_poultry_egg_establishments
GROUP BY length(zip)
ORDER BY length(zip) ASC;

-- Listing 10-7: Filtering with length() to find short zip values

SELECT st,
       count(*) AS st_count
FROM meat_poultry_egg_establishments
WHERE length(zip) < 5
GROUP BY st
ORDER BY st ASC;

--------------------------FIX THE PROBLEMS------------------------
-- After we found the problems, we have to fix them
-- STEPS:

-- 1. Always Create a backup table -> create table <table_name> as select <>
-- Listing 10-8: Backing up a table

CREATE TABLE meat_poultry_egg_establishments_backup AS
SELECT * FROM meat_poultry_egg_establishments;

--2. If possible, create a new column and work with it -> in this case to fix the missing values

-- Listing 10-9: Creating and filling the st_copy column with ALTER TABLE and UPDATE

ALTER TABLE meat_poultry_egg_establishments ADD COLUMN st_copy text;

UPDATE meat_poultry_egg_establishments

-- Listing 10-10: Checking values in the st and st_copy columns

SELECT st,
       st_copy
FROM meat_poultry_egg_establishments
WHERE st IS DISTINCT FROM st_copy
ORDER BY st;
SET st_copy = st;

-------------------------**FIXING MISSING DATA PROBLEM (STATE)**---------------------------------
-- Listing 10-11: Updating the st column for three establishments

UPDATE meat_poultry_egg_establishments
SET st = 'MN'
WHERE establishment_number = 'V18677A';

UPDATE meat_poultry_egg_establishments
SET st = 'AL'
WHERE establishment_number = 'M45319+P45319';

UPDATE meat_poultry_egg_establishments
SET st = 'WI'
WHERE establishment_number = 'M263A+P263A+V263A'
RETURNING establishment_number, company, city, st, zip;


-- Listing 10-12: Restoring original st column values

-- Restoring from the column backup
UPDATE meat_poultry_egg_establishments
SET st = st_copy;

-- Restoring from the table backup
UPDATE meat_poultry_egg_establishments original
SET st = backup.st
FROM meat_poultry_egg_establishments_backup backup
WHERE original.establishment_number = backup.establishment_number; 

--------------------FIXING ZIP PROBLEM-----------------------------
-- Listing 10-15: Creating and filling the zip_copy column

ALTER TABLE meat_poultry_egg_establishments ADD COLUMN zip_copy text;

UPDATE meat_poultry_egg_establishments
SET zip_copy = zip;

-- Listing 10-16: Modify codes in the zip column missing two leading zeros

UPDATE meat_poultry_egg_establishments
SET zip = '00' || zip
WHERE st IN('PR','VI') AND length(zip) = 3;

-- Listing 10-17: Modify codes in the zip column missing one leading zero

UPDATE meat_poultry_egg_establishments
SET zip = '0' || zip
WHERE st IN('CT','MA','ME','NH','NJ','RI','VT') AND length(zip) = 4;

--------------CHALLENGE------------------------
--1. Add a new column, ex: meat_processing (boolean)
-- Set the column to true if the company has "Meat processing"

ALTER TABLE meat_poultry_egg_establishments ADD COLUMN meat_processing bool;

UPDATE meat_poultry_egg_establishments
SET meat_processing = 'true'
WHERE activities LIKE '%Meat Processing%'

SELECT * 
from meat_poultry_egg_establishments 
WHERE activities LIKE '%Meat Processing%'

--------------------KEEP ONLY ONE RECORD OF DUPLICATES-------------------

SELECT max(establishment_number) as maxid, company
FROM meat_poultry_egg_establishments
GROUP BY company, street, city, st
HAVING count(*) > 1
ORDER BY company, street, city, st;

-----------------DELETE DUPLICATES---------------------------------
-- We use an aggregate function

DELETE FROM meat_poultry_egg_establishments
WHERE establishment_number not in (
	SELECT max(establishment_number)
	FROM meat_poultry_egg_establishments
	GROUP BY company, street, city, st
)

---------------------------TRANSACTIONS-------------------------
--Help us to group database operations, rollback, commit
-- We use them when we are updating data

START TRANSACTION 
update meat_poultry_egg_establishments
SET company = 'Gdl'

SELECT company,* FROM meat_poultry_egg_establishments

ROLLBACK;
COMMIT;


------------------PRACTICE EXERCISES------------------------------

-- Listing 10-18: Creating and filling a state_regions table

CREATE TABLE state_regions (
    st text CONSTRAINT st_key PRIMARY KEY,
    region text NOT NULL
);

COPY state_regions
FROM '/tmp/state_regions.csv'
WITH (FORMAT CSV, HEADER);

-- Listing 10-19: Adding and updating an inspection_deadline column

ALTER TABLE meat_poultry_egg_establishments
    ADD COLUMN inspection_deadline timestamp with time zone;

UPDATE meat_poultry_egg_establishments establishments
SET inspection_deadline = '2022-12-01 00:00 EST'
WHERE EXISTS (SELECT state_regions.region
              FROM state_regions
              WHERE establishments.st = state_regions.st 
                    AND state_regions.region = 'New England');

-- Listing 10-20: Viewing updated inspection_deadline values

SELECT st, inspection_deadline
FROM meat_poultry_egg_establishments
GROUP BY st, inspection_deadline
ORDER BY st;

-- Listing 10-21: Deleting rows matching an expression

DELETE FROM meat_poultry_egg_establishments
WHERE st IN('AS','GU','MP','PR','VI');

-- Listing 10-22: Removing a column from a table using DROP

ALTER TABLE meat_poultry_egg_establishments DROP COLUMN zip_copy;

-- Listing 10-23: Removing a table from a database using DROP

DROP TABLE meat_poultry_egg_establishments_backup;

-- Listing 10-24: Demonstrating a transaction block

-- Start transaction and perform update
START TRANSACTION;

UPDATE meat_poultry_egg_establishments
SET company = 'AGRO Merchantss Oakland LLC'
WHERE company = 'AGRO Merchants Oakland, LLC';

-- view changes
SELECT company
FROM meat_poultry_egg_establishments
WHERE company LIKE 'AGRO%'
ORDER BY company;

-- Revert changes
ROLLBACK;

-- See restored state
SELECT company
FROM meat_poultry_egg_establishments
WHERE company LIKE 'AGRO%'
ORDER BY company;

-- Alternately, commit changes at the end:
START TRANSACTION;

UPDATE meat_poultry_egg_establishments
SET company = 'AGRO Merchants Oakland LLC'
WHERE company = 'AGRO Merchants Oakland, LLC';

COMMIT;

-- Listing 10-25: Backing up a table while adding and filling a new column

CREATE TABLE meat_poultry_egg_establishments_backup AS
SELECT *,
       '2023-02-14 00:00 EST'::timestamp with time zone AS reviewed_date
FROM meat_poultry_egg_establishments;

-- Listing 10-26: Swapping table names using ALTER TABLE

ALTER TABLE meat_poultry_egg_establishments 
    RENAME TO meat_poultry_egg_establishments_temp;
ALTER TABLE meat_poultry_egg_establishments_backup 
    RENAME TO meat_poultry_egg_establishments;
ALTER TABLE meat_poultry_egg_establishments_temp 
    RENAME TO meat_poultry_egg_establishments_backup;
