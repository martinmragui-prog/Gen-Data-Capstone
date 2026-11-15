# Retail Sales and Inventory Analytics: Turning Data into Business Insights

This capstone analyses retail sales and inventory data to understand revenue, profitability, product performance, returns, and stock levels. It follows the six **CRISP-DM** phases, from business understanding through deployment.

The project uses **Excel and Power Query** for data preparation, **PostgreSQL and DBeaver** for data storage and SQL analysis, and **Tableau** for interactive dashboards.

## Capstone deliverables

1. **[GitHub Repository](https://github.com/martinmragui-prog/Gen-Data-Capstone/tree/main)** — project source files, datasets, SQL scripts, and documentation.
2. **[Live Tableau Dashboard](https://public.tableau.com/app/profile/martin.mbugua/viz/Tableau_Gen_Data_Dashboard1/RetailSalesDashboard)** — interactive dashboards covering sales, products, inventory, and returns.
3. **[CRISP-DM Presentation — View Online](https://view.officeapps.live.com/op/view.aspx?src=https%3A%2F%2Fraw.githubusercontent.com%2Fmartinmragui-prog%2FGen-Data-Capstone%2Fmain%2FPowerPoint%2520Slides%2FRetail%2520Sales%252C%2520Inventory%2520%2526%2520Business%2520Performance%2520Analysis.pptx)** — opens the PowerPoint presentation. The original file is in [`PowerPoint Slides`](https://github.com/martinmragui-prog/Gen-Data-Capstone/tree/main/PowerPoint%20Slides).
4. **[Published Substack Article](https://mattragui.substack.com/p/turning-125749-retail-sales-records)** — project insights, findings, and business recommendations.

## Research question

How can retail sales and inventory data help evaluate business performance and identify opportunities to improve profitability and stock management?

The project examines:
- Sales, COGS, gross profit, and profit margins.
- Daily and monthly sales trends.
- Product and category performance.
- Store and sales channel comparisons.
- Product returns and return rates.
- Inventory quantities and values.

## Data

The project uses retail sales and inventory datasets prepared using Excel and Power Query.

| Dataset | Cleaned records |
|---|---:|
| Sales | 125,749 |
| Inventory | 284,755 |

Sales data covers **1 June 2025 to 24 April 2026**.

Sales fields include transaction dates, products, stores, sales channels, quantities, sales amounts, and COGS.

Inventory fields include products, stores, stock dates, quantities on hand, and stock values.

## CRISP-DM methodology

1. **Business Understanding** — define the business questions around sales, profitability, returns, and inventory.
2. **Data Understanding** — inspect datasets, fields, record counts, and data quality.
3. **Data Preparation** — clean and organise the data using Excel and Power Query.
4. **Analysis** — use PostgreSQL and SQL to calculate metrics and create analytical views.
5. **Evaluation** — validate calculations, review findings, and assess business relevance.
6. **Deployment** — connect PostgreSQL to Tableau and present findings through interactive dashboards.

## Tools and technologies

- **Excel & Power Query:** Data cleaning and transformation.
- **PostgreSQL:** Data storage and SQL analysis.
- **DBeaver:** Database management and SQL execution.
- **Tableau:** Data visualisation and dashboard development.

## Database setup

The PostgreSQL database contains:

- `public.retail_sales_clean` — cleaned sales records.
- `public.clean_inventory` — cleaned inventory records.

Export the cleaned Excel worksheets as CSV files, import them into their respective PostgreSQL tables using DBeaver, and execute the SQL analysis script.

Expected records:

- Sales: 125,749
- Inventory: 284,755

## Tableau dashboards

The project focuses on four dashboards:

1. **Sales Performance** — revenue, costs, gross profit, margins, and sales trends.
2. **Product Performance** — top and low-performing products and categories.
3. **Inventory Management** — stock quantities and inventory values by store and product.
4. **Returns & Business Operations** — returns, sales channels, stores, and operational performance.

Connect Tableau Desktop to PostgreSQL using **Connect → To a Server → PostgreSQL**, then select the relevant tables or analytical views.

## Key performance indicators

- Total Sales
- Cost of Goods Sold (COGS)
- Gross Profit
- Gross Profit Margin
- Units Sold
- Return Rate
- Inventory Quantity
- Stock Cost and Selling Value

## Project files

- `retail_raw_and_cleaned(1).xlsx` — raw and cleaned datasets.
- `SQL_GEN_DATA_with_tableau_views.sql` — SQL analysis and Tableau views.
- `SQL_GEN_DATA.sql` — SQL analysis script.
- `retail_sales_clean.csv` — cleaned sales export.
- `clean_inventory.csv` — cleaned inventory export.
- Tableau workbook (`.twb` or `.twbx`) — dashboards.
- PowerPoint presentation — CRISP-DM methodology, analysis, findings, and recommendations; [view it online](https://view.officeapps.live.com/op/view.aspx?src=https%3A%2F%2Fraw.githubusercontent.com%2Fmartinmragui-prog%2FGen-Data-Capstone%2Fmain%2FPowerPoint%2520Slides%2FRetail%2520Sales%252C%2520Inventory%2520%2526%2520Business%2520Performance%2520Analysis.pptx).

## Limitations and conclusion

The analysis is limited to the supplied datasets and their date coverage. Customer-level analysis is outside the project scope because customer IDs are not available. Findings describe observed patterns and trends in the provided data.

Overall, this project demonstrates an end-to-end retail analytics process, combining Excel, Power Query, PostgreSQL, SQL, and Tableau to generate insights that support better-informed retail business decisions.
