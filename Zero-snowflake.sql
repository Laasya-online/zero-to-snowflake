USE DATABASE WORKSHOP_DB;
USE SCHEMA PUBLIC;

CREATE OR REPLACE TABLE orders (
    ORDER_ID        INT,
    AMOUNT          NUMBER(10,2),
    ORDER_DATE      DATE,
    CUSTOMER_ID     INT
);

CREATE OR REPLACE STAGE my_internal_stage;

LIST @my_internal_stage;

COPY INTO orders
FROM @my_internal_stage/orders_100.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY='"' SKIP_HEADER=1)
ON_ERROR = 'CONTINUE';

SELECT * FROM orders LIMIT 10;

SELECT COUNT(*) FROM orders;

SELECT * FROM orders;

SELECT SUM(amount) AS total_sales
FROM orders;

SELECT COUNT(*) AS number_of_orders
FROM orders;

SELECT *
FROM orders
WHERE customer_id = 2020;

SELECT *
FROM orders
ORDER BY amount DESC
LIMIT 5;

CREATE OR REPLACE VIEW large_orders AS
SELECT
    order_id,
    amount,
    order_date,
    customer_id
FROM orders
WHERE amount > 300;

SELECT * FROM large_orders;

CREATE OR REPLACE FUNCTION add_ten_percent(x NUMBER)
RETURNS NUMBER
LANGUAGE SQL
AS
$$
    x * 1.10
$$;

SELECT add_ten_percent(200);

SELECT 
    order_id,
    amount,
    add_ten_percent(amount) AS increased_amount
FROM orders
LIMIT 10;

CREATE OR REPLACE PROCEDURE count_orders()
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
    var sql_cmd = "SELECT COUNT(*) AS cnt FROM orders";
    var stmt = snowflake.createStatement({sqlText: sql_cmd});
    var res = stmt.execute();
    res.next();
    var count = res.getColumnValue("CNT");
    return "Total orders in ORDERS table: " + count;
$$;

CALL count_orders();

USE ROLE SECURITYADMIN;

CREATE OR REPLACE ROLE ANALYST_ROLE;

GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ANALYST_ROLE;

GRANT USAGE ON DATABASE WORKSHOP_DB TO ROLE ANALYST_ROLE;
GRANT USAGE ON SCHEMA WORKSHOP_DB.PUBLIC TO ROLE ANALYST_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA WORKSHOP_DB.PUBLIC TO ROLE ANALYST_ROLE;

GRANT SELECT ON FUTURE TABLES IN SCHEMA WORKSHOP_DB.PUBLIC TO ROLE ANALYST_ROLE;

GRANT ROLE ANALYST_ROLE TO USER LAASYAV;

USE ROLE ANALYST_ROLE;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA PUBLIC;

SELECT COUNT(*) FROM orders;

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE DATABASE WORKSHOP_DB_CLONE
CLONE WORKSHOP_DB;

USE DATABASE WORKSHOP_DB_CLONE;
SELECT COUNT(*) FROM PUBLIC.ORDERS;

INSERT INTO PUBLIC.ORDERS
VALUES (9999, 123.45, '2023-12-31', 1111);

SELECT COUNT(*) FROM PUBLIC.ORDERS;

USE DATABASE WORKSHOP_DB;
USE SCHEMA PUBLIC;

CREATE OR REPLACE TABLE tt_demo AS
SELECT * FROM orders;

SELECT COUNT(*) FROM tt_demo;

DROP TABLE tt_demo;

SHOW TABLES LIKE 'TT_DEMO';

UNDROP TABLE tt_demo;

SELECT COUNT(*) FROM tt_demo;

SELECT *
FROM orders
WHERE amount > 400;

SELECT *
FROM orders
WHERE order_date >= '2023-02-01'
  AND order_date < '2023-03-01';


USE WAREHOUSE COMPUTE_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA PUBLIC;

SELECT
    customer_id,
    COUNT(*)        AS num_orders,
    SUM(amount)     AS total_amount
FROM orders
GROUP BY customer_id
ORDER BY total_amount DESC
LIMIT 10;

SELECT
    customer_id,
    COUNT(*)        AS num_orders,
    SUM(amount)     AS total_amount
FROM orders
GROUP BY customer_id
ORDER BY total_amount DESC
LIMIT 10;

SELECT
    customer_id,
    COUNT(*)        AS num_orders,
    SUM(amount)     AS total_amount
FROM orders
GROUP BY customer_id
ORDER BY total_amount DESC
LIMIT 5;

CREATE OR REPLACE TABLE orders_transformed AS
SELECT 
    order_id,
    amount,
    amount * 0.10 AS tax,
    amount + (amount * 0.10) AS total_with_tax,
    order_date,
    customer_id
FROM orders;

SELECT * FROM orders_transformed LIMIT 5;

CREATE OR REPLACE TABLE big_orders AS
SELECT *
FROM orders
WHERE amount > 300;

SELECT COUNT(*) FROM big_orders;

CREATE OR REPLACE TABLE monthly_sales AS
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    SUM(amount) AS total_sales,
    COUNT(*) AS num_orders
FROM orders
GROUP BY 1
ORDER BY 1;

SELECT * FROM monthly_sales;

ALTER TABLE orders ADD COLUMN order_size STRING;

UPDATE orders
SET order_size =
    CASE 
        WHEN amount < 150 THEN 'SMALL'
        WHEN amount < 300 THEN 'MEDIUM'
        ELSE 'LARGE'
    END;

SELECT order_id, amount, order_size FROM orders LIMIT 10;

CREATE OR REPLACE VIEW clean_orders AS
SELECT 
    order_id,
    amount,
    order_size,
    DATE(order_date) AS order_date,
    customer_id
FROM orders
WHERE amount IS NOT NULL;

SELECT * FROM clean_orders LIMIT 10;

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE RESOURCE MONITOR rm_compute_wh
WITH CREDIT_QUOTA = 5
TRIGGERS ON 80 PERCENT DO NOTIFY
         ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE COMPUTE_WH
SET RESOURCE_MONITOR = rm_compute_wh;

USE ROLE ANALYST_ROLE;  -- or SYSADMIN/ACCOUNTADMIN if that’s what you use
USE WAREHOUSE COMPUTE_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA PUBLIC;

SELECT * FROM orders LIMIT 1000;

SELECT
    customer_id,
    COUNT(*) AS num_orders,
    SUM(amount) AS total_amount
FROM orders
GROUP BY customer_id;

LIST @my_internal_stage;

COPY INTO orders
FROM @my_internal_stage/orders_100.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY='"' SKIP_HEADER=1)
ON_ERROR = 'CONTINUE';

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE STAGE public.demo_ext_stage
  URL='s3://snowflake-workshop-lab/demo/data/'
  FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1);

LIST @public.demo_ext_stage;

CREATE OR REPLACE TABLE ext_sales_raw (
    col1 STRING,
    col2 STRING,
    col3 STRING,
    col4 STRING
);

COPY INTO ext_sales_raw
FROM @public.demo_ext_stage/sales_10k.csv
ON_ERROR = 'CONTINUE';

SELECT COUNT(*) FROM ext_sales_raw;

USE DATABASE WORKSHOP_DB;
USE SCHEMA PUBLIC;

CREATE OR REPLACE TABLE json_orders (
    id NUMBER,
    payload VARIANT
);

INSERT INTO json_orders (id, payload)
SELECT 1, PARSE_JSON('{
  "order_id": 101,
  "amount": 250.75,
  "currency": "USD",
  "customer": {
    "id": 2001,
    "name": "Alice"
  },
  "items": [
    {"sku": "A100", "qty": 2},
    {"sku": "B200", "qty": 1}
  ]
}')
UNION ALL
SELECT 2, PARSE_JSON('{
  "order_id": 102,
  "amount": 99.99,
  "currency": "USD",
  "customer": {
    "id": 2002,
    "name": "Bob"
  },
  "items": [
    {"sku": "C300", "qty": 5}
  ]
}');

SELECT * FROM json_orders;

SELECT
    id,
    payload:"order_id"          AS order_id_raw,
    payload:"amount"            AS amount_raw,
    payload:"customer":"name"   AS customer_name_raw
FROM json_orders;

SELECT
    id,
    payload:"order_id"::NUMBER           AS order_id,
    payload:"amount"::NUMBER             AS amount,
    payload:"customer":"id"::NUMBER      AS customer_id,
    payload:"customer":"name"::STRING    AS customer_name
FROM json_orders;

SELECT
    j.id,
    j.payload:"order_id"::NUMBER          AS order_id,
    j.payload:"customer":"name"::STRING   AS customer_name,
    item.value:"sku"::STRING              AS sku,
    item.value:"qty"::NUMBER              AS qty
FROM json_orders AS j,
     LATERAL FLATTEN(input => j.payload:"items") AS item;

USE DATABASE WORKSHOP_DB;
USE SCHEMA PUBLIC;

CREATE OR REPLACE DYNAMIC TABLE monthly_sales_dt
  TARGET_LAG = '1 minute'
  WAREHOUSE = COMPUTE_WH
AS
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    SUM(amount) AS total_sales,
    COUNT(*) AS num_orders
FROM orders
GROUP BY 1;

SELECT * 
FROM monthly_sales_dt
ORDER BY month;

INSERT INTO orders (order_id, amount, order_date, customer_id, order_size)
VALUES (99999, 500.00, '2023-12-15', 7777, 'LARGE');

ALTER DYNAMIC TABLE monthly_sales_dt REFRESH;

SELECT * 
FROM monthly_sales_dt
ORDER BY month;

CREATE OR REPLACE TABLE orders_transformed AS
SELECT 
    order_id,
    amount,
    amount * 0.10 AS tax,
    amount + (amount * 0.10) AS total_with_tax,
    order_date,
    customer_id
FROM orders;

CREATE OR REPLACE VIEW monthly_sales_summary AS
SELECT 
    m.month,
    m.total_sales,
    m.num_orders
FROM monthly_sales_dt AS m
ORDER BY m.month;

SELECT * FROM monthly_sales_summary;

USE DATABASE WORKSHOP_DB;
USE SCHEMA PUBLIC;

CREATE OR REPLACE TABLE order_notes AS
SELECT
    order_id,
    amount,
    order_size,
    CASE 
        WHEN order_size = 'LARGE' THEN 'High value customer order, priority handling.'
        WHEN order_size = 'MEDIUM' THEN 'Standard order with average value.'
        ELSE 'Small, low-value order.'
    END AS note
FROM orders
LIMIT 20;


SELECT * FROM order_notes;
