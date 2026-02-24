-- HANDLING MIXED DATE FORMATS
CREATE TABLE staging_layer.procurement_clean AS
SELECT
*,
CAST(order_date AS DATE) AS order_date_clean,
CAST(shipping_date AS DATE) AS shipping_date_clean
FROM raw_layer.dataco_supplychain_raw;

-- COMPUTING ACTUAL LEAD TIME
ALTER TABLE staging_layer.procurement_clean
ADD COLUMN actual_lead_time INT;

UPDATE staging_layer.procurement_clean
SET actual_lead_time =
shipping_date_clean - order_date_clean;

-- LEAD TIME VARIANCE CALCULATION
ALTER TABLE staging_layer.procurement_clean
ADD COLUMN lead_time_variance INT;

UPDATE staging_layer.procurement_clean
SET lead_time_variance =
actual_lead_time - days_for_shipment_scheduled;

-- DELIVERY DELAY FLAG CREATION
ALTER TABLE staging_layer.procurement_clean
ADD COLUMN delay_flag INT;

UPDATE staging_layer.procurement_clean
SET delay_flag =
CASE
WHEN lead_time_variance > 0 THEN 1
ELSE 0
END;

-- SLA FAILURE CLASSIFICATION
ALTER TABLE staging_layer.procurement_clean
ADD COLUMN sla_failure_flag INT;

UPDATE staging_layer.procurement_clean
SET sla_failure_flag =
CASE
WHEN delivery_status = 'Late delivery' THEN 1
ELSE 0
END;

-- COST PER UNIT CALCULATION
ALTER TABLE staging_layer.procurement_clean
ADD COLUMN cost_per_unit NUMERIC;

UPDATE staging_layer.procurement_clean
SET cost_per_unit =
order_item_total / NULLIF(order_item_quantity,0);

-- PROCUREMENT PROFIT MARGIN
ALTER TABLE staging_layer.procurement_clean
ADD COLUMN profit_margin NUMERIC;

UPDATE staging_layer.procurement_clean
SET profit_margin =
order_profit_per_order / NULLIF(order_item_total,0);


-- REMOVAL OF LEAD TIME OUTLIERS
DELETE FROM staging_layer.procurement_clean
WHERE actual_lead_time < 0
OR actual_lead_time > 30;


