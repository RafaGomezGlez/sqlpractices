-- WITH OPERATIONS
-- 1. Use sum function
SELECT sum(pop_est_2019) AS county_sum,
       round(avg(pop_est_2019), 0) AS county_average
FROM us_counties_pop_est_2019;

-- 2. Use percentile function
CREATE TABLE percentile_test (
    numbers integer
);

-- 2.1 Insert vaues into percentile table
INSERT INTO percentile_test (numbers) VALUES
    (1), (2), (3), (4), (5), (6);
    
-- 2.2 SELECT THE PERCENTILE OUTSIDE 95% 
SELECT
    percentile_cont(.5)
    WITHIN GROUP (ORDER BY numbers),
    percentile_disc(.5)
    WITHIN GROUP (ORDER BY numbers)
FROM percentile_test;

-- 3 USE PERCENTAGE
SELECT department,
       spend_2019,
       spend_2022,
       round( (spend_2022 - spend_2019) /
                    spend_2019 * 100, 1) AS pct_change
FROM percent_change;

