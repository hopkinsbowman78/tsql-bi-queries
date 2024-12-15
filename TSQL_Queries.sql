
-- Use the database
USE NonProfitCRM;



--1. Monthly Donation Trend
--Generate a report showing total donations by month over the last year.

SELECT 
    FORMAT(LastDonationDate, 'yyyy-MM') AS DonationMonth,
    SUM(DonationAmount) AS TotalDonations
FROM CRM_Dataset
WHERE LastDonationDate >= DATEADD(YEAR, -1, GETDATE())
GROUP BY FORMAT(LastDonationDate, 'yyyy-MM')
ORDER BY DonationMonth;



--2. Revenue Breakdown by Region
--Show a breakdown of total donations and product order revenue by region.

SELECT 
    c.Region,
    SUM(c.DonationAmount) AS TotalDonations,
    SUM(ISNULL(p.TotalAmount, 0)) AS TotalOrderRevenue,
    SUM(c.DonationAmount + ISNULL(p.TotalAmount, 0)) AS TotalRevenue
FROM CRM_Dataset c
LEFT JOIN ProductOrders p ON c.DonorID = p.DonorID
GROUP BY c.Region
ORDER BY TotalRevenue DESC;



--3. Top 5 Donors by Total Revenue
--Rank the top 5 donors based on their total contributions (donations + product orders).

SELECT TOP 5
    c.DonorID,
    c.FirstName,
    c.LastName,
    SUM(c.DonationAmount + ISNULL(p.TotalAmount, 0)) AS TotalRevenue
FROM CRM_Dataset c
LEFT JOIN ProductOrders p ON c.DonorID = p.DonorID
GROUP BY c.DonorID, c.FirstName, c.LastName
ORDER BY TotalRevenue DESC;



--4. Donor Segmentation by Age Group
--Segment donors based on their age group and calculate key metrics like total donations, average donation, and total event participation.

SELECT 
    AgeGroup,
    COUNT(DISTINCT DonorID) AS TotalDonors,
    SUM(DonationAmount) AS TotalDonations,
    AVG(DonationAmount) AS AvgDonation,
    SUM(EventParticipationCount) AS TotalEventParticipation
FROM CRM_Dataset
GROUP BY AgeGroup
ORDER BY TotalDonations DESC;



--5. Churn Analysis: Inactive Donors
--Identify donors who have been inactive for more than a year (no donations in the last 12 months).

SELECT 
    DonorID,
    FirstName,
    LastName,
    MAX(LastDonationDate) AS LastDonationDate,
    DATEDIFF(DAY, MAX(LastDonationDate), GETDATE()) AS DaysSinceLastDonation
FROM CRM_Dataset
GROUP BY DonorID, FirstName, LastName
HAVING MAX(LastDonationDate) < DATEADD(YEAR, -1, GETDATE())
ORDER BY DaysSinceLastDonation DESC;



--6. Product Popularity Analysis
--Determine which products generate the most revenue and quantity sold.

SELECT 
    Product,
    SUM(Quantity) AS TotalQuantitySold,
    SUM(TotalAmount) AS TotalRevenue,
    AVG(TotalAmount) AS AvgOrderValue
FROM ProductOrders
GROUP BY Product
ORDER BY TotalRevenue DESC;



--7. Customer Loyalty Score Report
--Calculate a loyalty score for each donor based on donations and event participation.

SELECT 
    DonorID,
    FirstName,
    LastName,
    Region,
    SUM(DonationAmount) / NULLIF(SUM(EventParticipationCount), 0) AS LoyaltyScore
FROM CRM_Dataset
GROUP BY DonorID, FirstName, LastName, Region
ORDER BY LoyaltyScore DESC;



--8. Year-over-Year Growth in Donations
--Calculate the percentage growth in total donations between the current year and the previous year.

WITH YearlyDonations AS (
    SELECT 
        YEAR(LastDonationDate) AS DonationYear,
        SUM(DonationAmount) AS TotalDonations
    FROM CRM_Dataset
    GROUP BY YEAR(LastDonationDate)
)
SELECT 
    CurrentYear.DonationYear AS Year,
    CurrentYear.TotalDonations AS CurrentYearDonations,
    PreviousYear.TotalDonations AS PreviousYearDonations,
    CASE 
        WHEN PreviousYear.TotalDonations IS NULL THEN NULL
        ELSE ((CurrentYear.TotalDonations - PreviousYear.TotalDonations) * 100.0 / PreviousYear.TotalDonations)
    END AS YoYGrowthPercentage
FROM YearlyDonations CurrentYear
LEFT JOIN YearlyDonations PreviousYear ON CurrentYear.DonationYear = PreviousYear.DonationYear + 1;



--9. RFM Analysis (Recency, Frequency, Monetary Value)
--Perform an RFM (Recency, Frequency, Monetary Value) analysis to categorize donors.

SELECT 
    DonorID,
    MAX(LastDonationDate) AS LastDonationDate,
    DATEDIFF(DAY, MAX(LastDonationDate), GETDATE()) AS Recency,
    COUNT(LastDonationDate) AS Frequency,
    SUM(DonationAmount) AS MonetaryValue
FROM CRM_Dataset
GROUP BY DonorID
ORDER BY MonetaryValue DESC, Recency ASC;



--10. Predictive Insights: Donation and Purchase Behavior
--Identify correlations between event participation, donations, and product orders.

SELECT 
    c.DonorID,
    c.FirstName,
    c.LastName,
    c.EventParticipationCount,
    c.DonationAmount,
    ISNULL(SUM(p.TotalAmount), 0) AS TotalProductRevenue,
    c.EventParticipationCount * c.DonationAmount AS CorrelationFactor
FROM CRM_Dataset c
LEFT JOIN ProductOrders p ON c.DonorID = p.DonorID
GROUP BY c.DonorID, c.FirstName, c.LastName, c.EventParticipationCount, c.DonationAmount
ORDER BY CorrelationFactor DESC;



--11. Drill-Down: Revenue by Region and Product
--Analyze the total revenue for each region and product combination.

SELECT 
    c.Region,
    p.Product,
    SUM(ISNULL(p.TotalAmount, 0)) AS TotalRevenue
FROM CRM_Dataset c
JOIN ProductOrders p ON c.DonorID = p.DonorID
GROUP BY c.Region, p.Product
ORDER BY TotalRevenue DESC;



--12. Data Quality Check
--Identify missing or inconsistent data in the CRM_Dataset table.

SELECT 
    DonorID,
    CASE WHEN FirstName IS NULL THEN 'Missing FirstName' ELSE 'Valid' END AS FirstNameStatus,
    CASE WHEN LastName IS NULL THEN 'Missing LastName' ELSE 'Valid' END AS LastNameStatus,
    CASE WHEN Email NOT LIKE '%@%.%' THEN 'Invalid Email' ELSE 'Valid' END AS EmailStatus
FROM CRM_Dataset
WHERE FirstName IS NULL OR LastName IS NULL OR Email NOT LIKE '%@%.%';



--13. Sales Funnel: Donations and Orders
--Compare the number of donors, donors with orders, and total revenue.

SELECT 
    'Total Donors' AS Stage,
    COUNT(DISTINCT DonorID) AS Count
FROM CRM_Dataset
UNION ALL
SELECT 
    'Donors with Orders',
    COUNT(DISTINCT p.DonorID)
FROM ProductOrders p
JOIN CRM_Dataset c ON p.DonorID = c.DonorID
UNION ALL
SELECT 
    'Total Revenue',
    SUM(DonationAmount + ISNULL(p.TotalAmount, 0))
FROM CRM_Dataset c
LEFT JOIN ProductOrders p ON c.DonorID = p.DonorID;



--14. Top Products by Region
--Identify the most popular product in each region based on total revenue.

WITH RankedProducts AS (
    SELECT 
        c.Region,
        p.Product,
        SUM(p.TotalAmount) AS TotalRevenue,
        RANK() OVER (PARTITION BY c.Region ORDER BY SUM(p.TotalAmount) DESC) AS Rank
    FROM CRM_Dataset c
    JOIN ProductOrders p ON c.DonorID = p.DonorID
    GROUP BY c.Region, p.Product
)
SELECT 
    Region,
    Product,
    TotalRevenue,
    Rank
FROM RankedProducts
WHERE Rank = 1
ORDER BY Region, TotalRevenue DESC;

