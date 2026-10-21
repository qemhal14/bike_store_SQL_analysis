# Bike Store Sales Analysis with PostgreSQL

An end-to-end SQL analysis of a bike retailer with three stores in the United States, covering revenue, customers, products and inventory, and shipping performance.

**Business question:** *How can the business grow revenue and improve shipping performance across its three stores?*

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Dataset](#dataset)
3. [Tools and Techniques](#tools-and-techniques)
4. [Repository Structure](#repository-structure)
5. [Approach](#approach)
6. [Data Overview and Quality (EDA)](#data-overview-and-quality-eda)
7. [Key Findings](#key-findings)
8. [Recommendations](#recommendations)
9. [Limitations](#limitations)
10. [How to Run](#how-to-run)

---

## Project Overview

This project analyses sales, customer, inventory, and shipping data from a fictional bike retailer to answer four questions:

| Theme | Question |
|---|---|
| A. Revenue | Where does the money come from, and is it growing? |
| B. Customers | Who are the most valuable customers? |
| C. Products and Inventory | What sells, and is stock in the right place? |
| D. Shipping | Are orders shipped on time? |

Every query answers a business question, and every finding is followed by what it means for the business.

---

## Dataset

The **BikeStores** sample database, originally published by [SQL Server Tutorial](https://www.sqlservertutorial.net/getting-started/sql-server-sample-database/), adapted for PostgreSQL.

The database has **9 related tables**:

| Table | Description |
|---|---|
| `orders` | Order header: customer, store, staff, status, and order, required, and shipped dates |
| `order_items` | Order lines: product, quantity, list price, and discount |
| `customers` | Customer contact and location details |
| `products` | Product name, brand, category, model year, and list price |
| `brands` | Product brands |
| `categories` | Product categories |
| `stores` | The three store locations |
| `staffs` | Store staff and their managers |
| `stocks` | Current stock per product per store |

**Order status codes:** 1 = Pending, 2 = Processing, 3 = Rejected, 4 = Completed

---

## Tools and Techniques

- **Database:** PostgreSQL, pgAdmin 4
- **SQL techniques:** multi-table `JOIN`s, `GROUP BY` and aggregation, `CASE WHEN`, `FILTER`, CTEs (`WITH`), views, and window functions (`RANK`, `LAG`, `SUM() OVER`)

---

## Repository Structure

```
bike_store_sql_analysis/
├── data/                         # Source CSV files (9 tables)
│──  01_create_tables.sql      # Table setup and import checks
│──  02_eda.sql                # Exploratory analysis and data quality checks
│──  03_main_analysis.sql      # Main analysis (themes A to D)                      
└── README.md
```

---

## Approach

1. **Setup:** created the 9 tables and imported the CSV files.
2. **EDA and data quality:** profiled every table, checked missing values, duplicates, date logic, and relationships between tables.
3. **Definitions:** fixed how revenue and late shipments are measured, based on what the EDA revealed (see below).
4. **Main analysis:** answered 14 business questions across four themes.
5. **Findings and recommendations:** summarised results and linked each recommendation to a finding.

### Definitions used throughout

| Metric | Definition |
|---|---|
| **Revenue** | `quantity × list_price × (1 − discount)`, using the price recorded in `order_items` |
| **Revenue scope** | Completed orders only (`order_status = 4`) |
| **Late shipment** | `shipped_date > required_date`, calculated on shipped orders only |

A shared view, `completed_sales`, holds the revenue definition so every query uses the same logic.

---

## Data Overview and Quality (EDA)

**Overview**
- The database contains 9 tables, including [n] orders, [n] order lines, 1,445 customers, and 321 products.
- Orders range from [first date] to [last date]. The data covers [n] months of 2018, so 2018 is not a full year.
- Product list prices range from **$89.99 to $11,999.99**, with an average of **$1,520.59** and a median of **$[X]**. The gap between the average and the median shows a small number of premium bikes pulling the average up.

**Data quality**
- **1,267 of 1,445 customers (87.7%)** have no phone number. The column is not used in the analysis, so results are not affected.
- **14 of 321 products (4.4%)** have never appeared in any order.
- **[n] orders** have no shipped date, all of them in Pending, Processing, or Rejected status. [Adjust if your result differs.]
- All relationship checks between tables passed: every order links to a valid customer, store, and staff member, and every order line links to a valid order and product. [Adjust if your result differs.]
- No duplicate customer emails were found. [Adjust if your result differs.]

**Decisions taken from the EDA**
- Revenue counts **completed orders only**, so pending and rejected orders do not inflate results.
- Late shipments are measured on **shipped orders only**. Including unshipped orders would have understated the late rate.
- Years are compared with caution, because 2018 is incomplete.

---

## Key Findings

### A. Revenue

- Revenue grew **41.05%** from $2.37M in 2016 to $3.35M in 2017, while completed orders grew only **8.2%** (620 to 671). Growth came mainly from **larger orders**: revenue per order rose about **30%**, from $3,827 to $4,988.
- 2018 shows 154 completed orders and $0.94M in revenue, but it is **not comparable** with full years, because the data covers only [n] months of 2018 and many of its orders were still pending or processing.
- **Baldwin Bikes** (New York) generated **$4.70M, or 70.56%** of total revenue, making the business heavily dependent on a single store.
- **Mountain bikes** are the top category, contributing **$2.49M (37.32%)** of revenue.

<!-- Add chart: images/monthly_revenue_by_store.png -->

### B. Customers

- The top 10 customers each spent between **$18,500 and $27,000** in a single order, and **8 of them are in New York**.
- Every customer has exactly **one completed order** (1,445 orders for 1,445 customers). This appears to be a feature of the sample dataset, so repeat purchasing cannot be analysed reliably.
- New York has by far the most customers (1,019), but **Texas customers spend the most per person** ($4,971), ahead of New York ($4,614) and California ($4,421). Because each customer buys from the store in their own state, state results mirror store results.

### C. Products and Inventory

- **Trek accounts for 8 of the top 10 products** by revenue, led by the Trek Slash 8 27.5 (2016) with 151 bikes sold and $544K in revenue. Surly takes the other two spots.
- Higher-priced 2017 models reached the top 10 with only **28 to 37 units sold**, consistent with customers shifting toward more expensive bikes.
- Larger discounts did **not** lead to more bikes per order line: the average quantity stayed around [X] at every discount level.
- **272 of 321 products (84.7%)** hold more than six months of stock at the current sales pace, accounting for **11,908 units, or 88.1%** of all stock. Another **35 products** have stock but no completed sales, and no product is at risk of running out.

> The 35 products without completed sales differ from the 14 products that never appeared in any order, because the inventory analysis counts completed orders only.

### D. Shipping Performance

- **Santa Cruz Bikes** has the highest late shipment rate at **36.62%**.
- The late shipment rate rose slightly from **30.81% in 2016 to 33.77% in 2018**, showing no improvement over time.
- Most late shipments miss the deadline by **only one day** (305 orders), followed by two days (153 orders) and [n] at three days or more.

<!-- Add chart: images/late_shipment_rate_by_store.png -->

---

## Recommendations

1. **Reduce dependence on Baldwin Bikes.** Study what drives its sales, such as product mix, staffing, and local demand, and test those practices in Santa Cruz and Rowlett.
2. **Cut overstock with targeted actions.** Slow purchasing of slow-moving products and run focused promotions on the 35 unsold items, rather than broad discounts, which did not increase quantity per order.
3. **Fix late shipments at Santa Cruz first.** Since most late orders miss the deadline by only one day, a small improvement in dispatch speed could bring many of them back on time.

---

## Limitations

- **Late shipment** is defined as an order shipped after its required date. The dataset has no delivery date, so this measures late dispatch from the store, not late arrival to the customer.
- Revenue and sales figures include **completed orders only**, so 2018 is understated.
- Stock levels are a **single snapshot** with no date. The one-month and six-month thresholds for understock and overstock are assumptions based on average monthly sales across the whole period.
- This is a **sample dataset**, and some patterns, such as every customer having exactly one completed order, may not reflect real customer behaviour.

---

## How to Run

1. Install [PostgreSQL](https://www.postgresql.org/download/) and pgAdmin 4.
2. Create a database named `bikestores`.
3. Run **part 1** of `sql/01_create_tables.sql` to create the tables.
4. Import each CSV in `data/` into its table (pgAdmin: right-click the table, **Import/Export Data**, with **Header** enabled). Import in this order: brands, categories, products, customers, stores, staffs, orders, order_items, stocks.
5. Run the rest of `01_create_tables.sql` to check row counts and add foreign keys.
6. Run `sql/02_eda.sql`, then `sql/03_main_analysis.sql`, one block at a time.

---

## Author

**Qemhal Haritskhayru**
Data Analyst | [Portfolio](https://qemhalh.com) | [LinkedIn](#)