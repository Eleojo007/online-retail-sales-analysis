-- Exploratory Data Analysis SQL Script
/*
Project: Online Retail Sales Analysis
Dataset: UCI Online Retail Dataset

Description:
Exploratory Data Analysis covering:
- Revenue KPIs
- Product Performance
- Customer Performance
- Market Performance
- Returns Analysis
*/
-- EXPLORATORY DATA ANALYSIS

SELECT *
FROM online_retail_cleaned;


-- KPIs (Summary)

SELECT 
	COUNT(DISTINCT(InvoiceNo)) AS Total_Unique_Invoice,
    COUNT(DISTINCT(StockCode)) AS Total_Unique_Products,
    COUNT(DISTINCT(CustomerId)) AS Total_Customers,
    SUM(CASE
    WHEN QuantityBehaviourFlag = 'Standard_Sale' 
    AND TransactionCategory = 'Standard_Transaction' THEN LineRevenue ELSE 0 
    END) AS Gross_Product_Sales,
    SUM(LineRevenue) AS All_Transaction_Line_Revenue
FROM online_retail_cleaned;

-- gross product total of company without operational charges/non-product charges and cancellation/return sales

SELECT 
	SUM(LineRevenue) AS Gross_Product_Total
FROM online_retail_cleaned
WHERE TransactionCategory = 'Standard_Transaction'
AND QuantityBehaviourFlag = 'Standard_Sale';

-- Monthly Revenue Trends

SELECT 
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS Sales_Month,
    COUNT(DISTINCT InvoiceNo) AS Order_Count,
    ROUND(SUM(LineRevenue), 2) AS Monthly_Revenue
FROM online_retail_cleaned
WHERE QuantityBehaviourFlag = 'Standard_Sale'
AND TransactionCategory = 'Standard_Transaction'
GROUP BY Sales_Month
ORDER BY Sales_Month;

-- Avg Monthly Sale

WITH monthly_total AS (
SELECT 
	DATE_FORMAT(InvoiceDate, '%Y-%m') AS Sales_Month, 
    ROUND(SUM(LineRevenue), 2) AS Monthly_Revenue
FROM online_retail_cleaned
WHERE TransactionCategory = 'Standard_Transaction'
AND QuantityBehaviourFlag = 'Standard_Sale'
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
)
SELECT
	ROUND(AVG(Monthly_Revenue), 2) AS Avg_Monthly_Revenue
FROM monthly_total;

-- Monthly_Running Total

WITH monthly_total AS (
SELECT DATE_FORMAT(InvoiceDate, '%Y-%m') AS Sales_Month, SUM(LineRevenue) AS Monthly_Revenue
FROM online_retail_cleaned
WHERE TransactionCategory = 'Standard_Transaction'
AND QuantityBehaviourFlag = 'Standard_Sale'
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
)
SELECT Sales_Month, monthly_revenue, SUM(Monthly_Revenue) OVER(ORDER BY Sales_Month) AS Running_Total
FROM monthly_total
ORDER BY Sales_Month;

-- Change in Monthly Revenue

WITH monthly_total AS (
SELECT DATE_FORMAT(InvoiceDate, '%Y-%m') AS Sales_Month, 
ROUND(SUM(LineRevenue), 2) AS Monthly_Revenue
FROM online_retail_cleaned
WHERE TransactionCategory = 'Standard_Transaction'
AND QuantityBehaviourFlag = 'Standard_Sale'
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
),
previous_month AS (
SELECT
	Sales_Month,
    Monthly_Revenue,
    LAG(Monthly_Revenue) OVER(ORDER BY Sales_Month) AS Previous_Revenue,
    Monthly_Revenue - LAG(Monthly_Revenue) OVER(ORDER BY Sales_Month) AS Difference
FROM monthly_total
)
SELECT 
	Sales_Month,
    Monthly_Revenue,
    Previous_Revenue,
    Difference,
    ROUND(100.0 * Difference/NULLIF(Previous_Revenue, 0), 2) AS Percent_Change
FROM previous_month
ORDER BY Sales_Month;

-- percentage of revenue made by each month

WITH monthly_total AS (
SELECT 
	DATE_FORMAT(InvoiceDate, '%Y-%m') AS Sales_Month, 
	ROUND(SUM(LineRevenue), 2) AS Monthly_Revenue
FROM online_retail_cleaned
WHERE TransactionCategory = 'Standard_Transaction'
AND QuantityBehaviourFlag = 'Standard_Sale'
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
),
net_revenue AS (
SELECT 
	ROUND(SUM(LineRevenue), 2) AS Total_Revenue
FROM online_retail_cleaned
WHERE TransactionCategory = 'Standard_Transaction'
AND QuantityBehaviourFlag = 'Standard_Sale'
)
SELECT 
	t1.Sales_Month,
	t1.Monthly_Revenue,
    ROUND(100.0 * t1.Monthly_Revenue/NULLIF(t2.Total_Revenue, 0), 2) AS Percent
FROM monthly_total t1
CROSS JOIN net_revenue t2
ORDER BY Sales_Month;

-- Top 10 Performing Months

SELECT 
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS Sales_Month,
    COUNT(DISTINCT InvoiceNo) AS Order_Count,
    SUM(LineRevenue) AS Monthly_Revenue
FROM online_retail_cleaned
WHERE QuantityBehaviourFlag = 'Standard_Sale'
AND TransactionCategory = 'Standard_Transaction'
GROUP BY Sales_Month
ORDER BY Monthly_Revenue DESC
LIMIT 10;

-- Top 10 Perfoming Products By Revenue

SELECT 
	StockCode,
    `Description`,
    SUM(Quantity) AS Total_Units_Sold,
    SUM(LineRevenue) AS Total_Revenue
FROM online_retail_cleaned
WHERE TransactionCategory = 'Standard_Transaction'
  AND QuantityBehaviourFlag = 'Standard_Sale'
GROUP BY StockCode, `Description`
ORDER BY Total_Revenue DESC
LIMIT 10;

-- Top 10 Performing Products By Quantity

SELECT 
	StockCode,
    `Description`,
    SUM(Quantity) AS Total_Units_Sold,
    SUM(LineRevenue) AS Total_Revenue
FROM online_retail_cleaned
WHERE TransactionCategory = 'Standard_Transaction'
  AND QuantityBehaviourFlag = 'Standard_Sale'
GROUP BY StockCode, `Description`
ORDER BY Total_Units_Sold DESC
LIMIT 10;

-- Top 10 Countries By Revenue

SELECT 
	Country,
    COUNT(DISTINCT InvoiceNo) AS Total_Orders,
    SUM(LineRevenue) AS Total_Revenue
FROM online_retail_cleaned
WHERE TransactionCategory = 'Standard_Transaction'
  AND QuantityBehaviourFlag = 'Standard_Sale'
GROUP BY Country
ORDER BY Total_Revenue DESC
LIMIT 10;

-- Top 10 Countries By Total Orders

SELECT 
	Country,
    COUNT(DISTINCT InvoiceNo) AS Total_Orders,
    SUM(LineRevenue) AS Total_Revenue
FROM online_retail_cleaned
WHERE TransactionCategory = 'Standard_Transaction'
  AND QuantityBehaviourFlag = 'Standard_Sale'
GROUP BY Country
ORDER BY Total_Orders DESC
LIMIT 10;

-- Registered Vs Unknown Customers Revenue

SELECT 
	CustomerType,
    ROUND(SUM(LineRevenue), 2) AS Total_Revenue
FROM online_retail_cleaned
WHERE TransactionCategory = 'Standard_Transaction'
AND QuantityBehaviourFlag = 'Standard_Sale'
GROUP BY CustomerType
ORDER BY CustomerType;

-- Percentage of Revenue by CustomerType

WITH customertype_revenue AS (
SELECT 
	CustomerType,
    ROUND(SUM(LineRevenue), 2) AS Total_Revenue
FROM online_retail_cleaned
WHERE TransactionCategory = 'Standard_Transaction'
AND QuantityBehaviourFlag = 'Standard_Sale'
GROUP BY CustomerType
),
total_revenue AS (
SELECT
	ROUND(SUM(LineRevenue), 2) AS Overall_Revenue
FROM online_retail_cleaned
WHERE TransactionCategory = 'Standard_Transaction'
AND QuantityBehaviourFlag = 'Standard_Sale' 
)
SELECT
	t1.CustomerType,
    t1.Total_Revenue,
    ROUND(100.0 * Total_Revenue/NULLIF(Overall_Revenue, 0), 2) AS Percentage
FROM customertype_revenue t1
CROSS JOIN total_revenue t2;

-- Transaction Behaviour
-- financial impact of order returns or cancellation

SELECT 
    QuantityBehaviourFlag,
    COUNT(DISTINCT InvoiceNo) AS Transaction_Count,
    ROUND(SUM(LineRevenue), 2) AS Financial_Impact
FROM online_retail_cleaned
GROUP BY QuantityBehaviourFlag;

-- count of invoice containing cancellation (C prefix)

SELECT 
	COUNT(DISTINCT InvoiceNo) AS Cancellation_Invoice 
FROM online_retail_cleaned
WHERE InvoiceNo LIKE 'C%';

-- Percentage of orders and cancellation/return orders

WITH orders_count AS (
SELECT 
    QuantityBehaviourFlag,
    COUNT(DISTINCT InvoiceNo) AS Transaction_Count
FROM online_retail_cleaned
WHERE QuantityBehaviourFlag = 'Customer_Return_or_Credit'
GROUP BY QuantityBehaviourFlag
),
total_transactions AS (
SELECT
	COUNT(DISTINCT InvoiceNo) AS Total_Orders
FROM online_retail_cleaned
)
SELECT 
	t1.QuantityBehaviourFlag,
    t1.Transaction_Count,
    t2.Total_Orders,
    ROUND(100.0 * t1.Transaction_Count/NULLIF(t2.Total_Orders, 0), 2) AS Invoices_With_Credit_Percentage
FROM orders_count t1
CROSS JOIN total_transactions t2;

-- Percentage of sold units returned

WITH returned_quantity AS (
    SELECT
        SUM(ABS(Quantity)) AS Total_Returned_Units
    FROM online_retail_cleaned
    WHERE QuantityBehaviourFlag = 'Customer_Return_or_Credit'
      AND TransactionCategory = 'Standard_Transaction'
),
gross_quantity AS (
    SELECT
        SUM(Quantity) AS Total_Units_Sold
    FROM online_retail_cleaned
    WHERE QuantityBehaviourFlag = 'Standard_Sale'
      AND TransactionCategory = 'Standard_Transaction'
)
SELECT
    r.Total_Returned_Units,
    g.Total_Units_Sold,
    ROUND(
        100.0 * r.Total_Returned_Units /
        NULLIF(g.Total_Units_Sold, 0),
        2
    ) AS Returned_Units_Percentage
FROM returned_quantity r
CROSS JOIN gross_quantity g;

-- Percentage of revenue against gross sales revenue

WITH sum_revenue AS (
SELECT 
    QuantityBehaviourFlag,
    ROUND(ABS(SUM(LineRevenue)), 2) AS Cancellation_Total
FROM online_retail_cleaned
WHERE QuantityBehaviourFlag = 'Customer_Return_or_Credit'
AND TransactionCategory = 'Standard_Transaction'
GROUP BY QuantityBehaviourFlag
),
overall_revenue_total AS (
SELECT
	ROUND(SUM(LineRevenue), 2) AS Gross_Sales_Total
FROM online_retail_cleaned
WHERE TransactionCategory = 'Standard_Transaction'
AND QuantityBehaviourFlag = 'Standard_Sale'
)
SELECT 
	t1.QuantityBehaviourFlag,
    t1.Cancellation_Total,
    t2.Gross_Sales_Total,
    ROUND(100.0 * t1.Cancellation_Total/NULLIF(t2.Gross_Sales_Total, 0), 2) AS Cancellation_Value_Percent
FROM sum_revenue t1
CROSS JOIN overall_revenue_total t2;

-- Average order value

WITH order_summary AS (
SELECT 
	DATE_FORMAT(InvoiceDate, '%Y-%m') AS Sales_Month,
    SUM(DISTINCT InvoiceNo) AS Monthly_Order_Count
FROM online_retail_cleaned
WHERE TransactionCategory = 'Standard_Transaction'
AND QuantityBehaviourFlag = 'Standard_Sale'
GROUP BY Sales_Month
)
SELECT 
	Sales_Month,
	AVG(Monthly_Order_Count) AS tt
FROM order_summary
GROUP BY Sales_Month;

-- Average Order Value

SELECT
    ROUND(SUM(LineRevenue), 2) AS Total_Revenue,
    COUNT(DISTINCT InvoiceNo) AS Total_Orders,
    ROUND(
        SUM(LineRevenue) / NULLIF(COUNT(DISTINCT InvoiceNo), 0),
        2
    ) AS Average_Order_Value
FROM online_retail_cleaned
WHERE TransactionCategory = 'Standard_Transaction'
  AND QuantityBehaviourFlag = 'Standard_Sale';
  
-- Average order value per month

SELECT
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS Sales_Month,
    ROUND(SUM(LineRevenue), 2) AS Monthly_Revenue,
    COUNT(DISTINCT InvoiceNo) AS Total_Orders,
    ROUND(
        SUM(LineRevenue) / NULLIF(COUNT(DISTINCT InvoiceNo), 0),
        2
    ) AS Average_Order_Value
FROM online_retail_cleaned
WHERE TransactionCategory = 'Standard_Transaction'
  AND QuantityBehaviourFlag = 'Standard_Sale'
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
ORDER BY Sales_Month;  

-- Number of orders per customer

SELECT
    CustomerID,
    COUNT(DISTINCT InvoiceNo) AS Total_Orders,
    MIN(InvoiceDate) AS First_Purchase,
    MAX(InvoiceDate) AS Most_Recent_Purchase,
    ROUND(SUM(LineRevenue), 2) AS Total_Customer_Revenue
FROM online_retail_cleaned
WHERE CustomerID IS NOT NULL
  AND TransactionCategory = 'Standard_Transaction'
  AND QuantityBehaviourFlag = 'Standard_Sale'
GROUP BY CustomerID
ORDER BY Total_Orders DESC;

-- Customer purchase frequency distribution

WITH customer_orders AS (
    SELECT
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS Total_Orders
    FROM online_retail_cleaned
    WHERE CustomerID IS NOT NULL
      AND TransactionCategory = 'Standard_Transaction'
      AND QuantityBehaviourFlag = 'Standard_Sale'
    GROUP BY CustomerID
),
frequency_groups AS (
SELECT
	CustomerID,
	Total_Orders,
	CASE
		WHEN Total_Orders = 1 THEN 'One-Time Customer'
		WHEN Total_Orders BETWEEN 2 AND 5 THEN '2-5 Orders'
		WHEN Total_Orders BETWEEN 6 AND 10 THEN '6-10 Orders'
		ELSE 'More Than 10 Orders'
	END AS Purchase_Frequency
FROM customer_orders
)
SELECT
    Purchase_Frequency,
    COUNT(*) AS Total_Customers,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER(),
        2
    ) AS Customer_Percentage
FROM frequency_groups
GROUP BY Purchase_Frequency
ORDER BY Purchase_Frequency;

-- Top 10% Registered Customers revenue percentage 

WITH customer_revenue AS (
SELECT
	CustomerID,
	SUM(LineRevenue) AS Total_Revenue
FROM online_retail_cleaned
WHERE CustomerID IS NOT NULL
AND TransactionCategory = 'Standard_Transaction'
AND QuantityBehaviourFlag = 'Standard_Sale'
GROUP BY CustomerID
),
ranked_customers AS (
SELECT
	CustomerID,
	Total_Revenue,
	ROW_NUMBER() OVER (
		ORDER BY Total_Revenue DESC
	) AS Customer_Rank,
	COUNT(*) OVER() AS Total_Customers
FROM customer_revenue
),
customer_concentration AS (
SELECT
	CustomerID,
	Total_Revenue,
	Customer_Rank,
	Total_Customers,
	CEIL(Total_Customers * 0.10) AS Top_10_Percent_Count
FROM ranked_customers
)
SELECT
    MAX(Total_Customers) AS Total_Customers,
    MAX(Top_10_Percent_Count) AS Top_10_Percent_Customers,
    ROUND(SUM(Total_Revenue), 2) AS Total_Identifiable_Revenue,
    ROUND(
        SUM(
            CASE
                WHEN Customer_Rank <= Top_10_Percent_Count
                THEN Total_Revenue
                ELSE 0
            END
        ), 2
    ) AS Top_10_Percent_Revenue,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN Customer_Rank <= Top_10_Percent_Count
                THEN Total_Revenue
                ELSE 0
            END
        ) / NULLIF(SUM(Total_Revenue), 0),
        2
    ) AS Revenue_Contribution_Percentage
FROM customer_concentration;
