-- ============================================================
-- E-COMMERCE / RETAIL SALES & INVENTORY ANALYTICS



-- ============================================================
-- 1. CREATE SALES TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.retail_sales_clean (
    "Transaction Date" DATE,
    "Sales Type" VARCHAR(100),
    "Is Return" BOOLEAN,
    "Supplier" TEXT,
    "Product No" VARCHAR(100),
    "Product Description" TEXT,
    "Product Division" TEXT,
    "Product Category" TEXT,
    "Product Subcategory" TEXT,
    "Product Segment" TEXT,
    "Store" TEXT,
    "Sales Channel" TEXT,
    "Qty Sold" NUMERIC(14,2),
    "Sales Amount" NUMERIC(14,2),
    "Cogs" NUMERIC(14,2),
    "Number of Transactions" INTEGER,
    "Data Quality Flag" TEXT
);


-- ============================================================
-- 2. CREATE INVENTORY TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.clean_inventory (
    "Start Date" DATE,
    "End Date" DATE,
    "Stock Status" TEXT,
    "Supplier" TEXT,
    "Product No" VARCHAR(100),
    "Product Description" TEXT,
    "Product Division" TEXT,
    "Product Category" TEXT,
    "Product Subcategory" TEXT,
    "Product Segment" TEXT,
    "Store" TEXT,
    "Store Type" TEXT,
    "Sales Channel" TEXT,
    "Qty on hand" NUMERIC(14,2),
    "Stocks Selling Amount" NUMERIC(14,2),
    "Cost of Stocks" NUMERIC(14,2),
    "Stock Unit Selling Price" NUMERIC(14,2),
    "Stock Unit Cost Price" NUMERIC(14,2),
    "Is Open Record" BOOLEAN,
    "Data Quality Flag" TEXT
);


-- ============================================================
-- 3. STANDARDISE EXISTING VARCHAR COLUMNS TO TEXT
-- This addresses text-length import errors.
-- It does not add missing columns or change numeric/date types.
-- ============================================================

DO $$
DECLARE
    col RECORD;
BEGIN
    FOR col IN
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'retail_sales_clean'
          AND data_type = 'character varying'
    LOOP
        EXECUTE format(
            'ALTER TABLE public.retail_sales_clean
             ALTER COLUMN %I TYPE TEXT',
            col.column_name
        );
    END LOOP;
END $$;


DO $$
DECLARE
    col RECORD;
BEGIN
    FOR col IN
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'clean_inventory'
          AND data_type = 'character varying'
    LOOP
        EXECUTE format(
            'ALTER TABLE public.clean_inventory
             ALTER COLUMN %I TYPE TEXT',
            col.column_name
        );
    END LOOP;
END $$;


-- ============================================================
-- 4. IMPORT CSV FILES USING DBEAVER
-- ============================================================
-- Import the cleaned sales CSV into:
--   public.retail_sales_clean
--
-- Import the cleaned inventory CSV into:
--   public.clean_inventory
--
-- In DBeaver:
-- Right-click table > Import Data > CSV > map columns
-- > verify data types > finish.
--
-- Do not run the analytical sections until both imports finish.


-- ============================================================
-- 5. CHECK IMPORTED RECORDS
-- ============================================================

SELECT COUNT(*) AS total_sales_records
FROM public.retail_sales_clean;

SELECT COUNT(*) AS total_inventory_records
FROM retail_inventory_clean;

-- Expected counts supplied for this project:
-- Sales:     125749
-- Inventory: 284755
-- If your counts differ, verify the import and filters.


-- ============================================================
-- 6. TOTAL SALES, COST AND GROSS PROFIT
-- ============================================================

SELECT
    SUM(COALESCE("Sales Amount", 0)) AS total_sales,
    SUM(COALESCE("Cogs", 0)) AS total_cost,
    SUM(COALESCE("Sales Amount", 0) - COALESCE("Cogs", 0))
        AS gross_profit
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE;


-- ============================================================
-- 7. MONTHLY SALES TREND
-- ============================================================

SELECT
    DATE_TRUNC('month', "Transaction Date")::DATE AS sales_month,
    SUM("Sales Amount") AS total_sales,
    SUM("Cogs") AS total_cost,
    SUM("Sales Amount" - "Cogs") AS gross_profit,
    COUNT(*) AS sales_records
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY DATE_TRUNC('month', "Transaction Date")
ORDER BY sales_month;


-- ============================================================
-- 8. SALES BY PRODUCT CATEGORY
-- ============================================================

SELECT
    "Product Category",
    SUM("Sales Amount") AS total_sales,
    SUM("Cogs") AS total_cost,
    SUM("Sales Amount" - "Cogs") AS gross_profit,
    SUM("Qty Sold") AS units_sold
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY "Product Category"
ORDER BY total_sales DESC;


-- ============================================================
-- 9. TOP 10 PRODUCTS BY SALES
-- ============================================================

SELECT
    "Product No",
    "Product Description",
    SUM("Qty Sold") AS units_sold,
    SUM("Sales Amount") AS total_sales,
    SUM("Sales Amount" - "Cogs") AS gross_profit
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY "Product No", "Product Description"
ORDER BY total_sales DESC
LIMIT 10;


-- ============================================================
-- 10. SALES PERFORMANCE BY STORE
-- ============================================================

SELECT
    "Store",
    SUM("Sales Amount") AS total_sales,
    SUM("Cogs") AS total_cost,
    SUM("Sales Amount" - "Cogs") AS gross_profit,
    COUNT(*) AS sales_records
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY "Store"
ORDER BY total_sales DESC;


-- ============================================================
-- 11. RETURNS BY PRODUCT CATEGORY
-- ============================================================

SELECT
    "Product Category",
    COUNT(*) AS return_records,
    SUM(ABS(COALESCE("Qty Sold", 0))) AS units_returned,
    SUM(ABS(COALESCE("Sales Amount", 0))) AS return_value
FROM public.retail_sales_clean
WHERE "Is Return" = TRUE
GROUP BY "Product Category"
ORDER BY return_value DESC;


-- ============================================================
-- 12. PROFIT MARGIN BY SALES TYPE
-- ============================================================

SELECT
    "Sales Type",
    SUM("Sales Amount") AS total_sales,
    SUM("Cogs") AS total_cost,
    SUM("Sales Amount" - "Cogs") AS gross_profit,
    ROUND(
        100.0 * SUM("Sales Amount" - "Cogs")
        / NULLIF(SUM("Sales Amount"), 0),
        2
    ) AS profit_margin_percentage
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY "Sales Type"
ORDER BY total_sales DESC;


-- ============================================================
-- 13. INVENTORY VALUE BY CATEGORY
-- ============================================================

SELECT
    "Product Category",
    SUM("Qty on hand") AS total_quantity,
    SUM("Stocks Selling Amount") AS stock_selling_value,
    SUM("Cost of Stocks") AS stock_cost_value
FROM public.clean_inventory
GROUP BY "Product Category"
ORDER BY stock_selling_value DESC;


-- ============================================================
-- 14. PRODUCTS WITH LOW OR ZERO STOCK
-- ============================================================

SELECT
    "Store",
    "Product No",
    "Product Description",
    "Product Category",
    "Qty on hand",
    "Stock Status"
FROM public.clean_inventory
WHERE COALESCE("Qty on hand", 0) <= 0
   OR LOWER(COALESCE("Stock Status", '')) LIKE '%out%'
   OR LOWER(COALESCE("Stock Status", '')) LIKE '%low%'
ORDER BY "Store", "Product Category", "Product No";


-- ============================================================
-- 15. SALES CHANNEL PERFORMANCE
-- ============================================================

SELECT
    "Sales Channel",
    SUM("Sales Amount") AS total_sales,
    SUM("Qty Sold") AS units_sold,
    SUM("Sales Amount" - "Cogs") AS gross_profit
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY "Sales Channel"
ORDER BY total_sales DESC;


-- ============================================================
-- 16. SUPPLIER PERFORMANCE
-- ============================================================

SELECT
    "Supplier",
    SUM("Sales Amount") AS total_sales,
    SUM("Cogs") AS total_cost,
    SUM("Sales Amount" - "Cogs") AS gross_profit
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY "Supplier"
ORDER BY total_sales DESC;


-- ============================================================
-- 17. SALES DATA QUALITY CHECK
-- ============================================================

SELECT
    "Data Quality Flag",
    COUNT(*) AS number_of_records
FROM public.retail_sales_clean
GROUP BY "Data Quality Flag"
ORDER BY number_of_records DESC;


-- ============================================================
-- 18. INVENTORY RECORD STATUS
-- ============================================================

SELECT
    "Stock Status",
    COUNT(*) AS number_of_records,
    SUM("Qty on hand") AS total_quantity
FROM public.clean_inventory
GROUP BY "Stock Status"
ORDER BY number_of_records DESC;


-- ============================================================
-- 19. QUARTERLY SALES PERFORMANCE
-- ============================================================

SELECT
    EXTRACT(YEAR FROM "Transaction Date")::INTEGER AS sales_year,
    EXTRACT(QUARTER FROM "Transaction Date")::INTEGER AS sales_quarter,
    SUM("Sales Amount") AS total_sales,
    SUM("Cogs") AS total_cost,
    SUM("Sales Amount" - "Cogs") AS gross_profit
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY
    EXTRACT(YEAR FROM "Transaction Date"),
    EXTRACT(QUARTER FROM "Transaction Date")
ORDER BY sales_year, sales_quarter;


-- ============================================================
-- 20. YEAR-ON-YEAR SALES GROWTH
-- ============================================================

WITH yearly_sales AS (
    SELECT
        EXTRACT(YEAR FROM "Transaction Date")::INTEGER AS sales_year,
        SUM("Sales Amount") AS total_sales
    FROM public.retail_sales_clean
    WHERE COALESCE("Is Return", FALSE) = FALSE
    GROUP BY EXTRACT(YEAR FROM "Transaction Date")
),
sales_growth AS (
    SELECT
        sales_year,
        total_sales,
        LAG(total_sales) OVER (ORDER BY sales_year)
            AS previous_year_sales
    FROM yearly_sales
)
SELECT
    sales_year,
    total_sales,
    previous_year_sales,
    ROUND(
        100.0 * (total_sales - previous_year_sales)
        / NULLIF(previous_year_sales, 0),
        2
    ) AS yoy_growth_percentage
FROM sales_growth
ORDER BY sales_year;


-- ============================================================
-- 21. MONTH-ON-MONTH SALES GROWTH
-- ============================================================

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', "Transaction Date")::DATE AS sales_month,
        SUM("Sales Amount") AS total_sales
    FROM public.retail_sales_clean
    WHERE COALESCE("Is Return", FALSE) = FALSE
    GROUP BY DATE_TRUNC('month', "Transaction Date")
),
monthly_growth AS (
    SELECT
        sales_month,
        total_sales,
        LAG(total_sales) OVER (ORDER BY sales_month)
            AS previous_month_sales
    FROM monthly_sales
)
SELECT
    sales_month,
    total_sales,
    previous_month_sales,
    ROUND(
        100.0 * (total_sales - previous_month_sales)
        / NULLIF(previous_month_sales, 0),
        2
    ) AS mom_growth_percentage
FROM monthly_growth
ORDER BY sales_month;


-- ============================================================
-- 22. GROSS PROFIT MARGIN BY PRODUCT CATEGORY
-- ============================================================

SELECT
    "Product Category",
    SUM("Sales Amount") AS total_sales,
    SUM("Cogs") AS total_cost,
    SUM("Sales Amount" - "Cogs") AS gross_profit,
    ROUND(
        100.0 * SUM("Sales Amount" - "Cogs")
        / NULLIF(SUM("Sales Amount"), 0),
        2
    ) AS profit_margin_percentage
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY "Product Category"
ORDER BY profit_margin_percentage DESC NULLS LAST;


-- ============================================================
-- 23. PRODUCT CATEGORY REVENUE CONTRIBUTION
-- ============================================================

WITH category_sales AS (
    SELECT
        "Product Category" AS category,
        SUM("Sales Amount") AS total_sales
    FROM public.retail_sales_clean
    WHERE COALESCE("Is Return", FALSE) = FALSE
    GROUP BY "Product Category"
)
SELECT
    category,
    total_sales,
    ROUND(
        100.0 * total_sales
        / NULLIF(SUM(total_sales) OVER (), 0),
        2
    ) AS revenue_contribution_percentage
FROM category_sales
ORDER BY total_sales DESC;


-- ============================================================
-- 24. AVERAGE SELLING PRICE BY PRODUCT
-- ============================================================

SELECT
    "Product No",
    "Product Description",
    SUM("Qty Sold") AS total_units_sold,
    SUM("Sales Amount") AS total_revenue,
    ROUND(
        SUM("Sales Amount") / NULLIF(SUM("Qty Sold"), 0),
        2
    ) AS average_selling_price
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY "Product No", "Product Description"
ORDER BY average_selling_price DESC NULLS LAST;


-- ============================================================
-- 25. SALES-TO-STOCK RATIO BY PRODUCT AND STORE
-- This is a comparison indicator, not conventional inventory
-- turnover. Inventory snapshots may cover different dates.
-- ============================================================

WITH sales_by_product AS (
    SELECT
        "Product No",
        "Store",
        SUM("Qty Sold") AS units_sold,
        SUM("Cogs") AS cost_of_goods_sold
    FROM public.retail_sales_clean
    WHERE COALESCE("Is Return", FALSE) = FALSE
    GROUP BY "Product No", "Store"
),
inventory_by_product AS (
    SELECT
        "Product No",
        "Store",
        SUM("Qty on hand") AS recorded_stock_quantity,
        SUM("Cost of Stocks") AS recorded_stock_cost
    FROM public.clean_inventory
    GROUP BY "Product No", "Store"
)
SELECT
    s."Product No",
    s."Store",
    s.units_sold,
    i.recorded_stock_quantity,
    s.cost_of_goods_sold,
    i.recorded_stock_cost,
    ROUND(
        s.units_sold / NULLIF(i.recorded_stock_quantity, 0),
        2
    ) AS sales_to_stock_ratio
FROM sales_by_product s
JOIN inventory_by_product i
    ON s."Product No" = i."Product No"
   AND s."Store" = i."Store"
ORDER BY sales_to_stock_ratio DESC NULLS LAST;


-- ============================================================
-- 26. SLOW-MOVING INVENTORY
-- Finds products with stock on hand but no recorded sales
-- during their inventory record's start/end date period.
-- ============================================================

WITH inventory_period_sales AS (
    SELECT
        i."Product No",
        i."Store",
        i."Product Description",
        i."Product Category",
        i."Start Date",
        i."End Date",
        i."Qty on hand",
        i."Stock Status",
        COALESCE(SUM(s."Qty Sold"), 0) AS units_sold_in_period
    FROM public.clean_inventory i
    LEFT JOIN public.retail_sales_clean s
        ON s."Product No" = i."Product No"
       AND s."Store" = i."Store"
       AND s."Transaction Date" >= i."Start Date"
       AND s."Transaction Date" <= i."End Date"
       AND COALESCE(s."Is Return", FALSE) = FALSE
    GROUP BY
        i."Product No",
        i."Store",
        i."Product Description",
        i."Product Category",
        i."Start Date",
        i."End Date",
        i."Qty on hand",
        i."Stock Status"
)
SELECT
    "Product No",
    "Store",
    "Product Description",
    "Product Category",
    "Start Date",
    "End Date",
    "Qty on hand",
    units_sold_in_period,
    "Stock Status"
FROM inventory_period_sales
WHERE COALESCE("Qty on hand", 0) > 0
  AND units_sold_in_period = 0
ORDER BY "Qty on hand" DESC;


-- ============================================================
-- 27. ESTIMATED STOCK COVERAGE BY PRODUCT
-- Uses the latest inventory end-date record per product/store
-- and average sales over the 90 days before the latest sales
-- date in the sales table.
--
-- Assumption: latest inventory record represents the relevant
-- stock position. Confirm this against your source data.
-- ============================================================

WITH sales_reference AS (
    SELECT MAX("Transaction Date") AS latest_sales_date
    FROM public.retail_sales_clean
),
latest_inventory AS (
    SELECT DISTINCT ON ("Product No", "Store")
        "Product No",
        "Store",
        "Product Description",
        "Product Category",
        "Qty on hand",
        "End Date"
    FROM public.clean_inventory
    ORDER BY
        "Product No",
        "Store",
        "End Date" DESC NULLS LAST
),
recent_sales AS (
    SELECT
        s."Product No",
        s."Store",
        SUM(s."Qty Sold") AS units_sold
    FROM public.retail_sales_clean s
    CROSS JOIN sales_reference r
    WHERE COALESCE(s."Is Return", FALSE) = FALSE
      AND s."Transaction Date" > r.latest_sales_date - INTERVAL '90 days'
      AND s."Transaction Date" <= r.latest_sales_date
    GROUP BY s."Product No", s."Store"
)
SELECT
    i."Product No",
    i."Store",
    i."Product Description",
    i."Product Category",
    i."End Date" AS inventory_end_date,
    i."Qty on hand",
    COALESCE(s.units_sold, 0) AS units_sold_last_90_days,
    ROUND(COALESCE(s.units_sold, 0) / 90.0, 2)
        AS average_daily_sales,
    ROUND(
        i."Qty on hand" /
        NULLIF(COALESCE(s.units_sold, 0) / 90.0, 0),
        2
    ) AS estimated_stock_coverage_days
FROM latest_inventory i
LEFT JOIN recent_sales s
    ON i."Product No" = s."Product No"
   AND i."Store" = s."Store"
ORDER BY estimated_stock_coverage_days ASC NULLS LAST;


-- ============================================================
-- 28. SALES VERSUS INVENTORY BY PRODUCT CATEGORY
-- Compares recorded sales quantities with recorded inventory.
-- Interpret alongside the inventory reporting dates.
-- ============================================================

WITH sales_summary AS (
    SELECT
        "Product Category",
        SUM("Qty Sold") AS units_sold,
        SUM("Sales Amount") AS total_sales
    FROM public.retail_sales_clean
    WHERE COALESCE("Is Return", FALSE) = FALSE
    GROUP BY "Product Category"
),
inventory_summary AS (
    SELECT
        "Product Category",
        SUM("Qty on hand") AS recorded_available_stock,
        SUM("Cost of Stocks") AS recorded_inventory_cost
    FROM public.clean_inventory
    GROUP BY "Product Category"
)
SELECT
    s."Product Category",
    s.units_sold,
    s.total_sales,
    i.recorded_available_stock,
    i.recorded_inventory_cost,
    ROUND(
        s.units_sold / NULLIF(i.recorded_available_stock, 0),
        2
    ) AS sales_to_stock_ratio
FROM sales_summary s
LEFT JOIN inventory_summary i
    ON s."Product Category" = i."Product Category"
ORDER BY sales_to_stock_ratio DESC NULLS LAST;


-- ============================================================
-- 29. STORE PROFITABILITY RANKING
-- ============================================================

SELECT
    "Store",
    SUM("Sales Amount") AS total_sales,
    SUM("Cogs") AS total_cost,
    SUM("Sales Amount" - "Cogs") AS gross_profit,
    ROUND(
        100.0 * SUM("Sales Amount" - "Cogs")
        / NULLIF(SUM("Sales Amount"), 0),
        2
    ) AS profit_margin_percentage,
    RANK() OVER (
        ORDER BY SUM("Sales Amount" - "Cogs") DESC
    ) AS profitability_rank
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY "Store"
ORDER BY profitability_rank;


-- ============================================================
-- 30. SUPPLIER PROFITABILITY RANKING
-- ============================================================

WITH supplier_summary AS (
    SELECT
        "Supplier",
        SUM("Sales Amount") AS total_sales,
        SUM("Cogs") AS total_cost,
        SUM("Sales Amount" - "Cogs") AS gross_profit
    FROM public.retail_sales_clean
    WHERE COALESCE("Is Return", FALSE) = FALSE
    GROUP BY "Supplier"
)
SELECT
    "Supplier",
    total_sales,
    total_cost,
    gross_profit,
    ROUND(
        100.0 * gross_profit / NULLIF(total_sales, 0),
        2
    ) AS profit_margin_percentage,
    RANK() OVER (
        ORDER BY gross_profit DESC
    ) AS supplier_profit_rank
FROM supplier_summary
ORDER BY supplier_profit_rank;


-- ============================================================
-- 31. ADDITIONAL DATA QUALITY CHECKS: SALES
-- ============================================================

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE "Transaction Date" IS NULL
    ) AS missing_transaction_dates,
    COUNT(*) FILTER (
        WHERE "Product No" IS NULL OR TRIM("Product No") = ''
    ) AS missing_product_numbers,
    COUNT(*) FILTER (
        WHERE "Product Description" IS NULL
           OR TRIM("Product Description") = ''
    ) AS missing_product_descriptions,
    COUNT(*) FILTER (
        WHERE "Sales Amount" IS NULL
    ) AS missing_sales_amounts,
    COUNT(*) FILTER (
        WHERE "Cogs" IS NULL
    ) AS missing_cogs,
    COUNT(*) FILTER (
        WHERE "Qty Sold" IS NULL
    ) AS missing_quantities,
    COUNT(*) FILTER (
        WHERE "Qty Sold" = 0
    ) AS zero_quantity_records,
    COUNT(*) FILTER (
        WHERE "Sales Amount" < 0
    ) AS negative_sales_amount_records,
    COUNT(*) FILTER (
        WHERE "Cogs" < 0
    ) AS negative_cogs_records
FROM public.retail_sales_clean;


-- ============================================================
-- 32. ADDITIONAL DATA QUALITY CHECKS: INVENTORY
-- ============================================================

SELECT
    COUNT(*) AS total_inventory_records,
    COUNT(*) FILTER (
        WHERE "Product No" IS NULL OR TRIM("Product No") = ''
    ) AS missing_product_numbers,
    COUNT(*) FILTER (
        WHERE "Store" IS NULL OR TRIM("Store") = ''
    ) AS missing_store_names,
    COUNT(*) FILTER (
        WHERE "Start Date" IS NULL
    ) AS missing_start_dates,
    COUNT(*) FILTER (
        WHERE "End Date" IS NULL
    ) AS missing_end_dates,
    COUNT(*) FILTER (
        WHERE "Start Date" > "End Date"
    ) AS invalid_date_ranges,
    COUNT(*) FILTER (
        WHERE "Qty on hand" < 0
    ) AS negative_stock_records,
    COUNT(*) FILTER (
        WHERE "Cost of Stocks" < 0
    ) AS negative_stock_cost_records
FROM public.clean_inventory;


-- ============================================================
-- 33. RETURN RATE BY PRODUCT CATEGORY
-- Compares returned units with sold units.
-- This is a unit-based rate, not a transaction cancellation rate.
-- ============================================================

WITH category_units AS (
    SELECT
        "Product Category",
        SUM(
            CASE
                WHEN COALESCE("Is Return", FALSE) = FALSE
                THEN GREATEST(COALESCE("Qty Sold", 0), 0)
                ELSE 0
            END
        ) AS units_sold,
        SUM(
            CASE
                WHEN "Is Return" = TRUE
                THEN ABS(COALESCE("Qty Sold", 0))
                ELSE 0
            END
        ) AS units_returned
    FROM public.retail_sales_clean
    GROUP BY "Product Category"
)
SELECT
    "Product Category",
    units_sold,
    units_returned,
    ROUND(
        100.0 * units_returned / NULLIF(units_sold, 0),
        2
    ) AS unit_return_rate_percentage
FROM category_units
ORDER BY unit_return_rate_percentage DESC NULLS LAST;


-- ============================================================
-- 34. DAILY SALES PERFORMANCE
-- ============================================================

SELECT
    "Transaction Date",
    SUM("Sales Amount") AS total_sales,
    SUM("Qty Sold") AS units_sold,
    SUM("Sales Amount" - "Cogs") AS gross_profit,
    COUNT(*) AS sales_records
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY "Transaction Date"
ORDER BY "Transaction Date";


-- ============================================================
-- 35. PRODUCT PERFORMANCE: BOTTOM 10 BY REVENUE
-- ============================================================

SELECT
    "Product No",
    "Product Description",
    SUM("Qty Sold") AS units_sold,
    SUM("Sales Amount") AS total_sales,
    SUM("Sales Amount" - "Cogs") AS gross_profit
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY "Product No", "Product Description"
ORDER BY total_sales ASC
LIMIT 10;


-- ============================================================
-- 36. SALES BY PRODUCT DIVISION AND SUBCATEGORY
-- ============================================================

SELECT
    "Product Division",
    "Product Category",
    "Product Subcategory",
    SUM("Sales Amount") AS total_sales,
    SUM("Qty Sold") AS units_sold,
    SUM("Sales Amount" - "Cogs") AS gross_profit
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY
    "Product Division",
    "Product Category",
    "Product Subcategory"
ORDER BY total_sales DESC;


-- ============================================================
-- 37. INVENTORY VALUE BY STORE
-- ============================================================

SELECT
    "Store",
    "Store Type",
    SUM("Qty on hand") AS total_units_on_hand,
    SUM("Stocks Selling Amount") AS stock_selling_value,
    SUM("Cost of Stocks") AS stock_cost_value
FROM public.clean_inventory
GROUP BY "Store", "Store Type"
ORDER BY stock_cost_value DESC;


-- ============================================================
-- 38. SALES TYPE AND CHANNEL COMPARISON
-- ============================================================

SELECT
    "Sales Type",
    "Sales Channel",
    SUM("Sales Amount") AS total_sales,
    SUM("Qty Sold") AS units_sold,
    SUM("Sales Amount" - "Cogs") AS gross_profit
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY "Sales Type", "Sales Channel"
ORDER BY total_sales DESC;


-- ============================================================
-- 39. SALES BY DAY OF WEEK
-- ============================================================

SELECT
    EXTRACT(ISODOW FROM "Transaction Date") AS day_number,
    TO_CHAR("Transaction Date", 'FMDay') AS day_of_week,
    SUM("Sales Amount") AS total_sales,
    SUM("Qty Sold") AS units_sold,
    COUNT(*) AS sales_records
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY
    EXTRACT(ISODOW FROM "Transaction Date"),
    TO_CHAR("Transaction Date", 'FMDay')
ORDER BY day_number;


-- ============================================================
-- 40. EXECUTIVE KPI SUMMARY
-- One-row overview for a high-level dashboard.
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE COALESCE("Is Return", FALSE) = FALSE
    ) AS non_return_sales_records,

    COUNT(*) FILTER (
        WHERE "Is Return" = TRUE
    ) AS return_records,

    SUM("Sales Amount") FILTER (
        WHERE COALESCE("Is Return", FALSE) = FALSE
    ) AS total_sales,

    SUM("Cogs") FILTER (
        WHERE COALESCE("Is Return", FALSE) = FALSE
    ) AS total_cogs,

    SUM("Sales Amount" - "Cogs") FILTER (
        WHERE COALESCE("Is Return", FALSE) = FALSE
    ) AS gross_profit,

    ROUND(
        100.0 *
        SUM("Sales Amount" - "Cogs") FILTER (
            WHERE COALESCE("Is Return", FALSE) = FALSE
        )
        /
        NULLIF(
            SUM("Sales Amount") FILTER (
                WHERE COALESCE("Is Return", FALSE) = FALSE
            ),
            0
        ),
        2
    ) AS gross_profit_margin_percentage,

    SUM("Qty Sold") FILTER (
        WHERE COALESCE("Is Return", FALSE) = FALSE
    ) AS total_units_sold,

    COUNT(DISTINCT "Product No") FILTER (
        WHERE COALESCE("Is Return", FALSE) = FALSE
    ) AS distinct_products_sold,

    COUNT(DISTINCT "Store") FILTER (
        WHERE COALESCE("Is Return", FALSE) = FALSE
    ) AS stores_with_sales

FROM public.retail_sales_clean;


-- ============================================================
-- END OF RETAIL SALES & INVENTORY ANALYTICS SCRIPT
-- ============================================================


-- 41.1 Detailed sales records (use for Tableau filters and drill-down)
CREATE OR REPLACE VIEW public.vw_tableau_sales_detail AS
SELECT
    "Transaction Date",
    DATE_TRUNC('month', "Transaction Date")::DATE AS sales_month,
    "Sales Type",
    "Is Return",
    "Supplier",
    "Product No",
    "Product Description",
    "Product Division",
    "Product Category",
    "Product Subcategory",
    "Product Segment",
    "Store",
    "Sales Channel",
    "Qty Sold",
    "Sales Amount",
    "Cogs",
    ("Sales Amount" - "Cogs") AS gross_profit,
    ROUND(
        100.0 * ("Sales Amount" - "Cogs") / NULLIF("Sales Amount", 0), 2
    ) AS profit_margin_percentage,
    "Number of Transactions",
    "Data Quality Flag"
FROM public.retail_sales_clean;

-- 41.2 Executive KPI summary (one row for dashboard KPI cards)
CREATE OR REPLACE VIEW public.vw_tableau_executive_kpis AS
SELECT
    COUNT(*) FILTER (WHERE COALESCE("Is Return", FALSE) = FALSE)
        AS non_return_sales_records,
    COUNT(*) FILTER (WHERE "Is Return" = TRUE) AS return_records,
    COALESCE(SUM("Sales Amount") FILTER (
        WHERE COALESCE("Is Return", FALSE) = FALSE
    ), 0) AS total_sales,
    COALESCE(SUM("Cogs") FILTER (
        WHERE COALESCE("Is Return", FALSE) = FALSE
    ), 0) AS total_cogs,
    COALESCE(SUM("Sales Amount" - "Cogs") FILTER (
        WHERE COALESCE("Is Return", FALSE) = FALSE
    ), 0) AS gross_profit,
    ROUND(
        100.0 * SUM("Sales Amount" - "Cogs") FILTER (
            WHERE COALESCE("Is Return", FALSE) = FALSE
        )
        / NULLIF(SUM("Sales Amount") FILTER (
            WHERE COALESCE("Is Return", FALSE) = FALSE
        ), 0), 2
    ) AS gross_profit_margin_percentage,
    COALESCE(SUM("Qty Sold") FILTER (
        WHERE COALESCE("Is Return", FALSE) = FALSE
    ), 0) AS total_units_sold,
    COUNT(DISTINCT "Product No") FILTER (
        WHERE COALESCE("Is Return", FALSE) = FALSE
    ) AS distinct_products_sold,
    COUNT(DISTINCT "Store") FILTER (
        WHERE COALESCE("Is Return", FALSE) = FALSE
    ) AS stores_with_sales
FROM public.retail_sales_clean;

-- 41.3 Monthly sales and profit trend
CREATE OR REPLACE VIEW public.vw_tableau_monthly_sales AS
SELECT
    DATE_TRUNC('month', "Transaction Date")::DATE AS sales_month,
    SUM("Sales Amount") AS total_sales,
    SUM("Cogs") AS total_cost,
    SUM("Sales Amount" - "Cogs") AS gross_profit,
    SUM("Qty Sold") AS units_sold,
    COUNT(*) AS sales_records
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY DATE_TRUNC('month', "Transaction Date");

-- 41.4 Sales and profit by product category
CREATE OR REPLACE VIEW public.vw_tableau_category_performance AS
SELECT
    "Product Category",
    SUM("Sales Amount") AS total_sales,
    SUM("Cogs") AS total_cost,
    SUM("Sales Amount" - "Cogs") AS gross_profit,
    SUM("Qty Sold") AS units_sold,
    ROUND(
        100.0 * SUM("Sales Amount" - "Cogs")
        / NULLIF(SUM("Sales Amount"), 0), 2
    ) AS profit_margin_percentage
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY "Product Category";

-- 41.5 Store performance
CREATE OR REPLACE VIEW public.vw_tableau_store_performance AS
SELECT
    "Store",
    SUM("Sales Amount") AS total_sales,
    SUM("Cogs") AS total_cost,
    SUM("Sales Amount" - "Cogs") AS gross_profit,
    SUM("Qty Sold") AS units_sold,
    COUNT(*) AS sales_records,
    ROUND(
        100.0 * SUM("Sales Amount" - "Cogs")
        / NULLIF(SUM("Sales Amount"), 0), 2
    ) AS profit_margin_percentage
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY "Store";

-- 41.6 Sales channel performance
CREATE OR REPLACE VIEW public.vw_tableau_channel_performance AS
SELECT
    "Sales Channel",
    SUM("Sales Amount") AS total_sales,
    SUM("Qty Sold") AS units_sold,
    SUM("Sales Amount" - "Cogs") AS gross_profit,
    COUNT(*) AS sales_records
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY "Sales Channel";

-- 41.7 Product performance
CREATE OR REPLACE VIEW public.vw_tableau_product_performance AS
SELECT
    "Product No",
    "Product Description",
    "Product Division",
    "Product Category",
    "Product Subcategory",
    "Product Segment",
    SUM("Qty Sold") AS units_sold,
    SUM("Sales Amount") AS total_sales,
    SUM("Cogs") AS total_cost,
    SUM("Sales Amount" - "Cogs") AS gross_profit
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY
    "Product No", "Product Description", "Product Division",
    "Product Category", "Product Subcategory", "Product Segment";

-- 41.8 Returns analysis by category
CREATE OR REPLACE VIEW public.vw_tableau_returns AS
SELECT
    "Product Category",
    COUNT(*) AS return_records,
    SUM(ABS(COALESCE("Qty Sold", 0))) AS units_returned,
    SUM(ABS(COALESCE("Sales Amount", 0))) AS return_value
FROM public.retail_sales_clean
WHERE "Is Return" = TRUE
GROUP BY "Product Category";

-- 41.9 Inventory value by category
CREATE OR REPLACE VIEW public.vw_tableau_inventory_category AS
SELECT
    "Product Category",
    SUM("Qty on hand") AS total_quantity,
    SUM("Stocks Selling Amount") AS stock_selling_value,
    SUM("Cost of Stocks") AS stock_cost_value
FROM public.clean_inventory
GROUP BY "Product Category";

-- 41.10 Inventory value by store
CREATE OR REPLACE VIEW public.vw_tableau_inventory_store AS
SELECT
    "Store",
    "Store Type",
    SUM("Qty on hand") AS total_units_on_hand,
    SUM("Stocks Selling Amount") AS stock_selling_value,
    SUM("Cost of Stocks") AS stock_cost_value
FROM public.clean_inventory
GROUP BY "Store", "Store Type";

-- 41.11 Daily sales trend
CREATE OR REPLACE VIEW public.vw_tableau_daily_sales AS
SELECT
    "Transaction Date",
    SUM("Sales Amount") AS total_sales,
    SUM("Qty Sold") AS units_sold,
    SUM("Sales Amount" - "Cogs") AS gross_profit,
    COUNT(*) AS sales_records
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY "Transaction Date";

-- 41.12 Supplier performance
CREATE OR REPLACE VIEW public.vw_tableau_supplier_performance AS
SELECT
    "Supplier",
    SUM("Sales Amount") AS total_sales,
    SUM("Cogs") AS total_cost,
    SUM("Sales Amount" - "Cogs") AS gross_profit,
    SUM("Qty Sold") AS units_sold,
    ROUND(
        100.0 * SUM("Sales Amount" - "Cogs")
        / NULLIF(SUM("Sales Amount"), 0), 2
    ) AS profit_margin_percentage
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY "Supplier";

-- 41.13 Sales type and channel comparison
CREATE OR REPLACE VIEW public.vw_tableau_sales_type_channel AS
SELECT
    "Sales Type",
    "Sales Channel",
    SUM("Sales Amount") AS total_sales,
    SUM("Qty Sold") AS units_sold,
    SUM("Sales Amount" - "Cogs") AS gross_profit
FROM public.retail_sales_clean
WHERE COALESCE("Is Return", FALSE) = FALSE
GROUP BY "Sales Type", "Sales Channel";

-- 41.14 Low / zero stock records
CREATE OR REPLACE VIEW public.vw_tableau_low_stock AS
SELECT
    "Store",
    "Product No",
    "Product Description",
    "Product Category",
    "Qty on hand",
    "Stock Status"
FROM public.clean_inventory
WHERE COALESCE("Qty on hand", 0) <= 0
   OR LOWER(COALESCE("Stock Status", '')) LIKE '%out%'
   OR LOWER(COALESCE("Stock Status", '')) LIKE '%low%';

-- 41.15 Return rate by product category (unit-based)
CREATE OR REPLACE VIEW public.vw_tableau_category_return_rate AS
WITH category_units AS (
    SELECT
        "Product Category",
        SUM(CASE
            WHEN COALESCE("Is Return", FALSE) = FALSE
            THEN GREATEST(COALESCE("Qty Sold", 0), 0)
            ELSE 0
        END) AS units_sold,
        SUM(CASE
            WHEN "Is Return" = TRUE
            THEN ABS(COALESCE("Qty Sold", 0))
            ELSE 0
        END) AS units_returned
    FROM public.retail_sales_clean
    GROUP BY "Product Category"
)
SELECT
    "Product Category",
    units_sold,
    units_returned,
    ROUND(
        100.0 * units_returned / NULLIF(units_sold, 0), 2
    ) AS unit_return_rate_percentage
FROM category_units;

-- 41.16 Confirm the views created
SELECT table_schema, table_name
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name LIKE 'vw_tableau_%'
ORDER BY table_name;

-- ============================================================
-- END OF TABLEAU VIEW DEFINITIONS
-- ============================================================
