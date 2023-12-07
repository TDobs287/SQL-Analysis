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





