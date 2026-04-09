# Olist Analytics dbt Project

This project builds a modular analytics warehouse using dbt on top of the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), transforming raw transactional data into analytics-ready models for revenue, customer, and delivery performance analysis.

---

## Project Overview

This project implements a layered dbt architecture:

**Staging → Intermediate → Marts (Star Schema)**

It transforms raw source data into clean, tested, and reusable models that support:

- Revenue analysis
- Customer lifetime value (CLV)
- Delivery performance tracking
- Product and seller analytics

---

## Architecture

### 1. Staging Layer

Standardizes raw source data into clean, well-documented models.

**Key transformations:**
- Text normalization (`trim`, `lower`, `upper`)
- Type casting (numeric and timestamp fields)
- Null handling (e.g., empty review text → NULL)
- Column renaming for analytics clarity

**Example models:**
- `stg_olist__orders`
- `stg_olist__order_items`
- `stg_olist__payments`
- `stg_olist__customers`
- `stg_olist__products`
- `stg_olist__sellers`

---

### 2. Intermediate Layer

Combines staged data into reusable business logic models.

#### `int_olist__order_details`
**Grain:** one row per order item  

Enriches transactional data by joining:
- orders
- order items
- payments
- customers

**Key features:**
- Revenue calculations (item + freight)
- Aggregated payment metrics
- Delivery timing metrics
- KPI flags (`is_delivered`, `is_late`)

---

#### `int_olist__customer_orders`
**Grain:** one row per customer  

Builds customer-level lifetime metrics:
- First and last order timestamps
- Lifetime revenue
- Order count and average order value
- Delivery performance metrics
- Late delivery percentage
- Repeat customer flag

---

### 3. Marts Layer (Star Schema)

Final analytics-ready models structured for reporting and BI.

---

#### Fact Tables

##### `fct_orders`
**Grain:** one row per order  
**Materialization:** incremental  

Central fact table for:
- Order revenue (`order_revenue`, `product_revenue`, `freight_revenue`)
- Item counts and product diversity
- Delivery performance KPIs
- Customer linkage

---

##### `fct_order_items`
**Grain:** one row per order item  
**Materialization:** incremental  

Supports:
- Product-level analysis
- Seller-level performance
- Detailed pricing and shipping insights

---

#### Dimension Tables

##### `dim_customers`
- Customer location data  
- Lifetime metrics (CLV, order count, AOV)  
- Delivery experience metrics  

##### `dim_products`
- Product attributes and physical characteristics  
- Category translation (Portuguese → English)  

##### `dim_sellers`
- Seller geographic data  
- Marketplace segmentation  

---

## Model Materialization Strategy

The project uses different materializations based on model purpose:

- **Staging & Intermediate:** views (lightweight, fast iteration)  
- **Marts:** tables (optimized for query performance)  
- **Fact tables:** incremental models for scalable processing  

---

## Incremental Processing

Fact tables are built using dbt incremental models:

- Uses `loaded_at` for change tracking  
- Prevents full table rebuilds  
- Improves scalability for larger datasets  

Example:

```sql
{% if is_incremental() %}
where loaded_at > (
    select coalesce(max(loaded_at), '1900-01-01')
    from {{ this }}
)
{% endif %}
