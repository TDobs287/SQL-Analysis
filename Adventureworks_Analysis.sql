
-- 1. Show each country's sales by customer age group.

WITH CTE_1 AS (
	SELECT T1.SalesOrderNumber, DATEDIFF(MONTH, T2.BirthDate, T1.OrderDate)/12 AS Age, T3.EnglishCountryRegionName
	FROM AdventureWorksDW2019.dbo.FactInternetSales T1
	JOIN AdventureWorksDW2019.dbo.DimCustomer T2
	ON T1.CustomerKey = T2.CustomerKey
	JOIN AdventureWorksDW2019.dbo.DimGeography T3
	ON T2.GeographyKey = T3.GeographyKey
	)

SELECT EnglishCountryRegionName,
	CASE WHEN Age < 30 THEN 'Under 30'
		WHEN Age BETWEEN 30 AND 40 THEN '30 - 40'
		WHEN Age BETWEEN 40 AND 50 THEN '40 - 50'
		WHEN Age BETWEEN 50 AND 60 THEN '50 - 60'
		WHEN Age > 60 THEN 'Over 60'
		ELSE 'Other'
		END AS Age_Group,
		COUNT(SalesOrderNumber) AS Sales
FROM CTE_1
GROUP BY EnglishCountryRegionName,
	CASE WHEN Age < 30 THEN 'Under 30'
		WHEN Age BETWEEN 30 AND 40 THEN '30 - 40'
		WHEN Age BETWEEN 40 AND 50 THEN '40 - 50'
		WHEN Age BETWEEN 50 AND 60 THEN '50 - 60'
		WHEN Age > 60 THEN 'Over 60'
		ELSE 'Other'
		END
ORDER BY EnglishCountryRegionName, Age_Group




-- 2. Show each Product sales by age group

WITH CTE_2 AS (
	SELECT T2.SalesOrderNumber, DATEDIFF(MONTH, T3.BirthDate, T2.OrderDate)/12 AS Age, T4.EnglishProductSubcategoryName
	FROM AdventureWorksDW2019.dbo.DimProduct T1
	JOIN AdventureWorksDW2019.dbo.FactInternetSales T2
	ON T1.ProductKey = T2.ProductKey
	JOIN AdventureWorksDW2019.dbo.DimCustomer T3
	ON T3.CustomerKey = T2.CustomerKey
	JOIN AdventureWorksDW2019.dbo.DimProductSubcategory T4
	ON T1.ProductSubcategoryKey = T4.ProductSubcategoryKey
	)

SELECT EnglishProductSubcategoryName AS Product_Type,
	CASE WHEN Age < 30 THEN 'Under 30'
		WHEN Age BETWEEN 30 AND 40 THEN '30 - 40'
		WHEN Age BETWEEN 40 AND 50 THEN '40 - 50'
		WHEN Age BETWEEN 50 AND 60 THEN '50 - 60'
		WHEN Age > 60 THEN 'Over 60'
		ELSE 'Other'
		END AS Age_Group,
		COUNT(SalesOrderNumber) AS Sales
FROM CTE_2
GROUP BY EnglishProductSubcategoryName,
	CASE WHEN Age < 30 THEN 'Under 30'
		WHEN Age BETWEEN 30 AND 40 THEN '30 - 40'
		WHEN Age BETWEEN 40 AND 50 THEN '40 - 50'
		WHEN Age BETWEEN 50 AND 60 THEN '50 - 60'
		WHEN Age > 60 THEN 'Over 60'
		ELSE 'Other'
		END
ORDER BY EnglishProductSubcategoryName, Age_Group




-- 3. Show monthly sales for Australia and USA compared for the year 2012

SELECT T1.SalesOrderNumber, T1.OrderDate, T2.SalesTerritoryCountry
FROM AdventureWorksDW2019.dbo.FactInternetSales T1
JOIN AdventureWorksDW2019.dbo.DimSalesTerritory T2
ON T1.SalesTerritoryKey = T2.SalesTerritoryKey
WHERE SalesTerritoryCountry IN ('Australia', 'United States')
AND SUBSTRING(CAST(T1.OrderDate AS CHAR), 8, 4) = '2012'




-- 4. Display each products first reorder date, then add a column to show the days between the products first order and first re-order date. Show products which took over one year to need to be reordered.

WITH CTE_4 AS (
	SELECT T1.EnglishProductName, T1.SafetyStockLevel, T1.ReorderPoint, T2.OrderDateKey, SUM(T2.OrderQuantity) AS Sales
	FROM AdventureWorksDW2019.dbo.DimProduct T1
	JOIN AdventureWorksDW2019.dbo.FactInternetSales T2
	ON T1.ProductKey = T2.ProductKey
	GROUP BY T1.EnglishProductName, T1.SafetyStockLevel, T1.ReorderPoint, T2.OrderDateKey
	),

ReorderDateCTE_4 AS (	
	SELECT *, CASE WHEN (SafetyStockLevel - RunningTotal) <= ReorderPoint THEN 1 ELSE 0 END AS ReorderFlag
	FROM (SELECT *, SUM(Sales) OVER (PARTITION BY EnglishProductName ORDER BY OrderDateKey) AS RunningTotal	
			FROM CTE_4
			GROUP BY EnglishProductName, SafetyStockLevel, ReorderPoint, OrderDateKey, Sales
		 ) SubQuery4_1	
	)

SELECT EnglishProductName, MAX(ProductsFirstOrderDate) AS ProductsFirstOrderDate, MAX(FirstReorderDate) AS FirstReorderDate, DATEDIFF(DAY, MAX(CAST(CAST(ProductsFirstOrderDate AS CHAR) AS DATE)), MAX(CAST(CAST(FirstReorderDate AS CHAR) AS DATE))) AS DaysToReorder
FROM (SELECT EnglishProductName, MIN(OrderDateKey) AS ProductsFirstOrderDate, NULL AS FirstReorderDate
		FROM CTE_4
		GROUP BY EnglishProductName
			UNION ALL	
		SELECT EnglishProductName, NULL AS ProductsFirstOrderDate, MIN(OrderDateKey) AS First_Reorder_Date
		FROM ReorderDateCTE_4
		WHERE ReorderFlag = 1
		GROUP BY EnglishProductName
		) SubQuery4_2
GROUP BY EnglishProductName
HAVING DATEDIFF(DAY, MAX(CAST(CAST(ProductsFirstOrderDate AS CHAR) AS DATE)), MAX(CAST(CAST(FirstReorderDate AS CHAR) AS DATE))) > 365




-- 5. Show all sales on promotion and add a column showing their new sales value if 25% discount is applied.

SELECT T1.OrderDate, T3.SalesReasonName, T1.SalesOrderNumber, ROUND(T1.SalesAmount, 2) AS SalesAmount, CONVERT(DECIMAL(10,2), ROUND(T1.SalesAmount * 0.75, 2)) AS SalesAmountDiscount
FROM AdventureWorksDW2019.dbo.FactInternetSales T1
JOIN AdventureWorksDW2019.dbo.FactInternetSalesReason T2
ON T1.SalesOrderNumber = T2.SalesOrderNumber
JOIN AdventureWorksDW2019.dbo.DimSalesReason T3
ON T2.SalesReasonKey = T3.SalesReasonKey
WHERE SalesReasonName = 'On Promotion'




-- 6. Show each customer key, the sales value of their first sale, and the sales value of their last sale including the difference between the two.

WITH CTE_6_FirstPurchase AS (
	SELECT CustomerKey, SalesAmount, OrderDate, ROW_NUMBER() OVER (PARTITION BY CustomerKey ORDER BY OrderDate ASC)	AS SalesNumber
	FROM AdventureWorksDW2019.dbo.FactInternetSales
	),

CTE_6_LastPurchase AS (
	SELECT CustomerKey, SalesAmount, OrderDate, ROW_NUMBER() OVER (PARTITION BY CustomerKey ORDER BY OrderDate DESC) AS SalesNumber
	FROM AdventureWorksDW2019.dbo.FactInternetSales
	)

SELECT CustomerKey, MAX(FirstPurchaseValue) AS FirstPurchaseValue, MAX(LastPurchaseValue) AS LastPurchaseValue, ABS(MAX(LastPurchaseValue) - MAX(FirstPurchaseValue)) AS PurchaseDiff
FROM (SELECT CustomerKey, SalesAmount AS FirstPurchaseValue, NULL AS LastPurchaseValue
		FROM CTE_6_FirstPurchase
		WHERE SalesNumber = 1		
		UNION ALL
		SELECT CustomerKey, NULL AS FirstPurchaseValue, SalesAmount AS LastPurchaseValue
		FROM CTE_6_LastPurchase
		WHERE SalesNumber = 1
		) SubQuery6
GROUP BY CustomerKey
HAVING MAX(LastPurchaseValue) - MAX(FirstPurchaseValue) <> 0
ORDER BY CustomerKey


