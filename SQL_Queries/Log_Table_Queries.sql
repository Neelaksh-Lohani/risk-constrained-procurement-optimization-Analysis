-- LOG TABLES QUERIES

-- Create Raw Table for Logs
CREATE TABLE raw_layer.tokenized_logs_raw (
product TEXT,
category TEXT,
access_date TEXT,
month TEXT,
access_hour TEXT,
department TEXT,
ip TEXT,
url TEXT
);

COPY raw_layer.tokenized_logs_raw
FROM 'C:\Temp\Predictive_Supplier_Risk_Based_Procurement_Optimization_System\Dataset\encoded-tokenized_access_logs.csv'
WITH (
FORMAT csv,
HEADER true,
DELIMITER ',',
QUOTE '"',
ESCAPE '"',
NULL ''
);


-- Clean + Cast Logs
CREATE TABLE staging_layer.tokenized_logs_clean AS
SELECT
product,
category,
CAST(access_date AS DATE),

CASE
WHEN month = 'Jan' THEN 1
WHEN month = 'Feb' THEN 2
WHEN month = 'Mar' THEN 3
WHEN month = 'Apr' THEN 4
WHEN month = 'May' THEN 5
WHEN month = 'Jun' THEN 6
WHEN month = 'Jul' THEN 7
WHEN month = 'Aug' THEN 8
WHEN month = 'Sep' THEN 9
WHEN month = 'Oct' THEN 10
WHEN month = 'Nov' THEN 11
WHEN month = 'Dec' THEN 12
END AS month,

CAST(access_hour AS INT),
department

FROM raw_layer.tokenized_logs_raw
WHERE access_date IS NOT NULL;


-- Demand Volatility Signal
CREATE TABLE feature_layer.product_demand_variability AS
SELECT
category,
COUNT(*) AS total_access_events,
ROUND(STDDEV(access_hour)::numeric,2)
AS demand_hour_volatility
FROM staging_layer.tokenized_logs_clean
GROUP BY category;


-- Department Demand Risk
CREATE TABLE feature_layer.department_demand_risk AS
SELECT
department,
ROUND(AVG(access_hour)::numeric,2)
AS avg_peak_access_time,
ROUND(STDDEV(access_hour)::numeric,2)
AS access_time_volatility
FROM staging_layer.tokenized_logs_clean
GROUP BY department;


-- Merge Demand Signals into MART
CREATE TABLE datamart_layer.procurement_risk_mart_v2 AS
SELECT
prm.*,
pdv.demand_hour_volatility,
ddr.access_time_volatility

FROM datamart_layer.procurement_risk_mart prm

LEFT JOIN feature_layer.product_demand_variability pdv
ON prm.category_name = pdv.category

LEFT JOIN feature_layer.department_demand_risk ddr
ON prm.category_name = ddr.department;


SELECT COUNT(*) FROM staging_layer.tokenized_logs_clean;


