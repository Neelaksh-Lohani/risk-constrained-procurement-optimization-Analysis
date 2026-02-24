 -- Advanced Feature Engineering (Risk Intelligence Layer)

 -- Region-Level Delay Probability -> “How risky is sourcing from this region?”

 CREATE TABLE feature_layer.region_risk AS
SELECT
    order_region,
    COUNT(*) AS total_orders,
    SUM(delay_flag) AS delayed_orders,
    ROUND(AVG(delay_flag)::numeric, 4) AS region_delay_probability,
    ROUND(AVG(sla_failure_flag)::numeric, 4) AS region_sla_failure_rate,
    ROUND(AVG(lead_time_variance)::numeric, 2) AS avg_lead_time_variance
FROM feature_layer.procurement_behavior
GROUP BY order_region;


-- Shipment Mode Risk -> “Which logistics channel increases SLA breach?”

CREATE TABLE feature_layer.shipping_mode_risk AS
SELECT
    shipping_mode,
    COUNT(*) AS total_orders,
    ROUND(AVG(delay_flag)::numeric, 4) AS mode_delay_probability,
    ROUND(AVG(sla_failure_flag)::numeric, 4) AS mode_sla_failure_rate,
    ROUND(AVG(actual_lead_time)::numeric, 2) AS avg_actual_lead_time
FROM feature_layer.procurement_behavior
GROUP BY shipping_mode;


-- Category-Level Disruption Risk -> “Which product categories are disruption-sensitive?”

CREATE TABLE feature_layer.category_risk AS
SELECT
    category_name,
    COUNT(*) AS total_orders,
    ROUND(AVG(delay_flag)::numeric, 4) AS category_delay_probability,
    ROUND(AVG(lead_time_variance)::numeric, 2) AS avg_lead_time_variance
FROM feature_layer.procurement_behavior
GROUP BY category_name;


-- Cost Volatility Signal -> Cost instability is important in procurement.

CREATE TABLE feature_layer.cost_volatility AS
SELECT
    order_region,
    ROUND(STDDEV(cost_per_unit)::numeric, 2) AS cost_per_unit_volatility,
    ROUND(STDDEV(profit_margin)::numeric, 4) AS profit_margin_volatility
FROM feature_layer.procurement_behavior
GROUP BY order_region;

-- Create Final Risk Mart -> This merges all intelligence into one analytical table.

CREATE TABLE datamart_layer.procurement_risk_mart AS
SELECT
    pb.*,
    rr.region_delay_probability,
    rr.region_sla_failure_rate,
    rr.avg_lead_time_variance AS region_avg_variance,
    smr.mode_delay_probability,
    smr.mode_sla_failure_rate,
    cr.category_delay_probability,
    cv.cost_per_unit_volatility,
    cv.profit_margin_volatility

FROM feature_layer.procurement_behavior pb

LEFT JOIN feature_layer.region_risk rr
    ON pb.order_region = rr.order_region

LEFT JOIN feature_layer.shipping_mode_risk smr
    ON pb.shipping_mode = smr.shipping_mode

LEFT JOIN feature_layer.category_risk cr
    ON pb.category_name = cr.category_name

LEFT JOIN feature_layer.cost_volatility cv
    ON pb.order_region = cv.order_region;


/* 

✔ Order-level operational features
✔ Region-level risk signals
✔ Mode-level SLA risk
✔ Category disruption probability
✔ Cost volatility measures
✔ Unified analytical risk mart

*/



