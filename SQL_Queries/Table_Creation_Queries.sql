CREATE TABLE staging_layer.dataco_clean AS
SELECT

transaction_type,
CAST(days_for_shopping_real AS INT),
CAST(days_for_shipment_scheduled AS INT),
CAST(benefit_per_order AS NUMERIC),
CAST(sales_per_customer AS NUMERIC),
delivery_status,
CAST(late_delivery_risk AS INT),
CAST(category_id AS INT),
category_name,
customer_city,
customer_country,
CAST(customer_id AS INT),
customer_segment,
customer_state,
CAST(department_id AS INT),
department_name,
CAST(latitude AS NUMERIC),
CAST(longitude AS NUMERIC),
market,
order_city,
order_country,
CAST(order_customer_id AS INT),
CAST(order_date AS DATE),
CAST(order_id AS INT),
CAST(order_item_cardprod_id AS INT),
CAST(order_item_discount AS NUMERIC),
CAST(order_item_discount_rate AS NUMERIC),
CAST(order_item_id AS INT),
CAST(order_item_product_price AS NUMERIC),
CAST(order_item_profit_ratio AS NUMERIC),
CAST(order_item_quantity AS INT),
CAST(sales AS NUMERIC),
CAST(order_item_total AS NUMERIC),
CAST(order_profit_per_order AS NUMERIC),
order_region,
order_state,
order_status,
CAST(product_card_id AS INT),
CAST(product_category_id AS INT),
product_name,
CAST(product_price AS NUMERIC),
product_status,
CAST(shipping_date AS DATE),
shipping_mode

FROM raw_layer.dataco_temp_raw

WHERE
order_item_quantity IS NOT NULL
AND product_price IS NOT NULL
AND order_date IS NOT NULL
AND shipping_date IS NOT NULL;




CREATE TABLE feature_layer.procurement_behavior AS
SELECT

order_id,
order_region,
shipping_mode,
category_name,
market,
order_date,
shipping_date,

(shipping_date - order_date) AS actual_lead_time,

days_for_shipment_scheduled AS scheduled_lead_time,

((shipping_date - order_date)
- days_for_shipment_scheduled) AS lead_time_variance,

CASE
WHEN late_delivery_risk = 1 THEN 1
ELSE 0
END AS delay_flag,

CASE
WHEN (shipping_date - order_date)
> days_for_shipment_scheduled
THEN 1
ELSE 0
END AS sla_failure_flag,

(order_item_total /
NULLIF(order_item_quantity,0))
AS cost_per_unit,

(order_profit_per_order /
NULLIF(order_item_total,0))
AS profit_margin,

(order_item_product_price /
NULLIF(product_price,0))
AS logistics_cost_ratio,

CASE
WHEN delivery_status = 'Late delivery'
THEN 1
ELSE 0
END AS high_priority_delay

FROM staging_layer.dataco_clean;


SELECT COUNT(*) FROM feature_layer.procurement_behavior;



