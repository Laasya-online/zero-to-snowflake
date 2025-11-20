# Zero-to-Snowflake
This project is a complete, practical walkthrough of Snowflake concepts using a single SQL workspace.  

---
## What This Project Covers

### 1. Setup & Core Objects
- Creating databases, schemas, tables
- Managing warehouses

### 2. Data Ingestion
- Internal stage ingestion
- External stage ingestion using Snowflake public S3 bucket
- `COPY INTO` usage

### 3. Data Transformation
- CTAS (Create Table As Select)
- Column derivation (`tax`, `total_with_tax`)
- Filtering (`BIG_ORDERS`)
- Aggregation (`MONTHLY_SALES`)
- Data cleaning views (`CLEAN_ORDERS`)

### 4. Semi-Structured Data
- Working with JSON (`VARIANT`)
- Accessing nested fields
- Flattening arrays with `LATERAL FLATTEN`

### 5. Advanced Snowflake Features
- UDFs (SQL)
- Stored Procedures (JavaScript)
- Dynamic Tables
- Zero-copy cloning
- Time Travel & UNDROP
- Resource Monitors & Budgets

### 6. Access Control & Governance
- Creating custom roles
- Granting permissions
- Warehouse-level security
