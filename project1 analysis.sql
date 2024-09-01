---------------------------------------------analyzing employees scheme----------------------------------------------

----------1 how many employees we have ?-----------------------------------------------------------------------------
SELECT 
    COUNT(distinct BusinessEntityID) AS NumberOfSalesPersons
FROM HumanResources.Employee

----------2 best 10 employee by sales-------------------------------------------------------------------------------
SELECT 
    e.BusinessEntityID,
    P.FirstName + ' ' + P.LastName AS FullName, hv.department,
	GENDER,
    SUM(SOH.TotalDue) AS TotalSales,
    (SUM(SOH.TotalDue) * 100.0) / SUM(SUM(SOH.TotalDue)) OVER () AS SalesPercentage
FROM HumanResources.vEmployeeDepartmentHistory hv join 
    HumanResources.Employee E on hv.BusinessEntityID=e.BusinessEntityID
JOIN 
    Person.Person P ON E.BusinessEntityID = P.BusinessEntityID
JOIN 
    Sales.SalesOrderHeader SOH ON e.BusinessEntityID = SOH.SalesPersonID
GROUP BY 
    e.BusinessEntityID, P.FirstName, P.LastName,hv.department,GENDER
ORDER BY 
    TotalSales DESC;


----------3 Distribution the percentage of employees according to their ages ----------------------------------
SELECT 
    CASE 
        WHEN DATEDIFF(YEAR, BirthDate, GETDATE()) < 20 THEN 'Less than 20'
        WHEN DATEDIFF(YEAR, BirthDate, GETDATE()) BETWEEN 20 AND 29 THEN '20-29'
        WHEN DATEDIFF(YEAR, BirthDate, GETDATE()) BETWEEN 30 AND 39 THEN '30-39'
        WHEN DATEDIFF(YEAR, BirthDate, GETDATE()) BETWEEN 40 AND 49 THEN '40-49'
        WHEN DATEDIFF(YEAR, BirthDate, GETDATE()) BETWEEN 50 AND 59 THEN '50-59'
        ELSE '60 and above'
    END AS Age_Group,
    COUNT(*) AS Number_of_Employees,
    (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM HumanResources.Employee)) AS Percentage
FROM HumanResources.Employee
GROUP BY 
    CASE 
        WHEN DATEDIFF(YEAR, BirthDate, GETDATE()) < 20 THEN 'Less than 20'
        WHEN DATEDIFF(YEAR, BirthDate, GETDATE()) BETWEEN 20 AND 29 THEN '20-29'
        WHEN DATEDIFF(YEAR, BirthDate, GETDATE()) BETWEEN 30 AND 39 THEN '30-39'
        WHEN DATEDIFF(YEAR, BirthDate, GETDATE()) BETWEEN 40 AND 49 THEN '40-49'
        WHEN DATEDIFF(YEAR, BirthDate, GETDATE()) BETWEEN 50 AND 59 THEN '50-59'
        ELSE '60 and above'
    END;


-----------4 percentage of male and female in position of manager-------------------------------------------------------
SELECT 
    CASE 
        WHEN hre.Gender = 'M' THEN 'Male'
        WHEN hre.Gender = 'F' THEN 'Female'
    END AS Gender,
    COUNT(CASE WHEN hre.JobTitle LIKE '%Manager%' THEN 1 END) AS Number_of_Managers,
    ROUND(
        (COUNT(CASE WHEN hre.JobTitle LIKE '%Manager%' THEN 1 END) * 100.0) / 
        (SELECT COUNT(*) FROM HumanResources.Employee WHERE JobTitle LIKE '%Manager%'), 2
    ) AS Percentage_of_Managers
FROM 
    HumanResources.Employee hre
GROUP BY 
    hre.Gender;

--------------5 sales performance by age category and gender-------------------------------------------------------------
	SELECT 
    CASE 
       WHEN DATEDIFF(YEAR, e.BirthDate, GETDATE()) BETWEEN 20 AND 29 THEN '20-29'
        WHEN DATEDIFF(YEAR, e.BirthDate, GETDATE()) BETWEEN 30 AND 39 THEN '30-39'
        WHEN DATEDIFF(YEAR, e.BirthDate, GETDATE()) BETWEEN 40 AND 49 THEN '40-49'
        WHEN DATEDIFF(YEAR, e.BirthDate, GETDATE()) BETWEEN 50 AND 59 THEN '50-59'
        ELSE '60+'
    END AS Age,
    CASE 
        WHEN E.Gender = 'M' THEN 'Male'
        WHEN E.Gender = 'F' THEN 'Female'
    END AS Gender,
    COUNT(SOD.orderqty)  orderqty ,
    SUM(SOD.LineTotal)  TotalSales 
FROM 
    HumanResources.Employee E
JOIN 
    Person.Person P ON E.BusinessEntityID = P.BusinessEntityID
JOIN 
    Sales.SalesOrderHeader SOH ON E.BusinessEntityID = SOH.SalesPersonID
JOIN 
    Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
GROUP BY 
    CASE 
       WHEN DATEDIFF(YEAR, e.BirthDate, GETDATE()) BETWEEN 20 AND 29 THEN '20-29'
        WHEN DATEDIFF(YEAR, e.BirthDate, GETDATE()) BETWEEN 30 AND 39 THEN '30-39'
        WHEN DATEDIFF(YEAR, e.BirthDate, GETDATE()) BETWEEN 40 AND 49 THEN '40-49'
        WHEN DATEDIFF(YEAR, e.BirthDate, GETDATE()) BETWEEN 50 AND 59 THEN '50-59'
        ELSE '60+'
    END,
    CASE 
        WHEN E.Gender = 'M' THEN 'Male'
        WHEN E.Gender = 'F' THEN 'Female'
    END
ORDER BY 
    Age,  orderqty desc,TotalSales 

------------6 analysis sales performance by gender and experience----------------------------------------------------------------
SELECT 
    CASE 
        WHEN DATEDIFF(YEAR, E.HireDate, GETDATE()) < 5 THEN 'Experience (Less than 5 years)'
        WHEN DATEDIFF(YEAR, E.HireDate, GETDATE()) BETWEEN 5 AND 10 THEN 'Experience (5-10 years)'
        ELSE 'Experience (More than 10 years)'
    END AS ExperienceLevel,
    E.Gender,
    SUM(SOH.TotalDue)  TotalSales,
	count(sod.OrderQty)  qty
FROM Sales.SalesOrderDetail sod join
    Sales.SalesOrderHeader SOH on sod.SalesOrderID=soh.SalesOrderID
JOIN 
    Sales.SalesPerson SP ON SOH.SalesPersonID = SP.BusinessEntityID
JOIN 
    HumanResources.Employee E ON SP.BusinessEntityID = E.BusinessEntityID
GROUP BY 
    CASE 
        WHEN DATEDIFF(YEAR, E.HireDate, GETDATE()) < 5 THEN 'Experience (Less than 5 years)'
        WHEN DATEDIFF(YEAR, E.HireDate, GETDATE()) BETWEEN 5 AND 10 THEN 'Experience (5-10 years)'
        ELSE 'Experience (More than 10 years)'
    END, 
    E.Gender
ORDER BY 
    TotalSales DESC;

------------7 running total for each employee over years-----------------------------------------------------------------------------

WITH SalesData AS (
    SELECT 
        YEAR(SOH.OrderDate)  Years,
        P.FirstName + ' ' + P.LastName  fullName,
        SUM(SOH.SubTotal) AS TotalSales
    FROM 
        Sales.SalesOrderHeader SOH
    JOIN 
        Sales.SalesPerson SP ON SOH.SalesPersonID = SP.BusinessEntityID
    JOIN 
        Person.Person P ON SP.BusinessEntityID = P.BusinessEntityID
    GROUP BY 
        YEAR(SOH.OrderDate), P.FirstName, P.LastName
)
SELECT 
    Years,
    fullName,
    TotalSales,
    SUM(TotalSales) OVER (PARTITION BY fullName ORDER BY Years)  runningSales
FROM 
    SalesData
ORDER BY 
   fullname,  Years;
-------------8 how many employee in each department--------------------------------------------------------------------------------
SELECT 
    D.Name AS DepartmentName, 
    COUNT(EH.BusinessEntityID) AS employee
FROM 
    HumanResources.EmployeeDepartmentHistory EH
JOIN 
    HumanResources.Department D ON EH.DepartmentID = D.DepartmentID
WHERE 
    EH.EndDate IS NULL
GROUP BY 
    D.Name
ORDER BY 
    employee DESC;

----------------9 employees performance with their vacation and sick leave---------------------------------------------------------------
SELECT 
    P.FirstName + ' ' + P.LastName AS EmployeeName, e.JobTitle,
    (E.VacationHours + E.SickLeaveHours) AS TotalLeaveHours,
   SUM(SOH.subtotal) AS TotalSales
FROM 
    HumanResources.Employee E
JOIN 
    Person.Person P ON E.BusinessEntityID = P.BusinessEntityID
LEFT JOIN 
    Sales.SalesOrderHeader SOH ON E.BusinessEntityID = SOH.SalesPersonID
	where JobTitle like '%sales%'
GROUP BY 
    P.FirstName,
    P.LastName,
    E.VacationHours,
    E.SickLeaveHours,
	e.JobTitle
ORDER BY 
      TotalSales desc

-----------10 percentage of total sales by marital status--------------------------------------------------------------------------------
SELECT 
    e.MaritalStatus AS MaritalStatus,
    SUM(SOH.TotalDue) AS TotalSales,
    (SUM(SOH.TotalDue) * 100.0) / SUM(SUM(SOH.TotalDue)) OVER () AS SalesPercentage
FROM 
    HumanResources.Employee E
JOIN 
    Person.Person P ON E.BusinessEntityID = P.BusinessEntityID
LEFT JOIN 
    Sales.SalesOrderHeader SOH ON E.BusinessEntityID = SOH.SalesPersonID
GROUP BY 
    e.MaritalStatus
ORDER BY 
    TotalSales DESC;
---------11 percentage of total sales by sales year---------------------------------------------------------------------------------------------
SELECT 
    YEAR(SOH.OrderDate) AS SalesYear,
    SUM(SOH.TotalDue) AS TotalSales,
	    (SUM(SOH.TotalDue) * 100.0) / SUM(SUM(SOH.TotalDue)) OVER () AS SalesPercentage
FROM 
    Sales.SalesOrderHeader SOH
GROUP BY 
    YEAR(SOH.OrderDate)
ORDER BY 
    TotalSales DESC;

--------12 best 10 employee by orderqty-------------------------------------------------------------------------------------------------
	SELECT 
    e.BusinessEntityID,
    P.FirstName + ' ' + P.LastName AS FullName, hv.department,
	GENDER,
	count(sod.OrderQty) total
FROM HumanResources.vEmployeeDepartmentHistory hv join 
    HumanResources.Employee E on hv.BusinessEntityID=e.BusinessEntityID
JOIN 
    Person.Person P ON E.BusinessEntityID = P.BusinessEntityID
JOIN 
    Sales.SalesOrderHeader SOH ON e.BusinessEntityID = SOH.SalesPersonID
	join Sales.SalesOrderDetail sod on soh.SalesOrderID=sod.SalesOrderID
GROUP BY 
    e.BusinessEntityID, P.FirstName, P.LastName,hv.department,GENDER
ORDER BY 
    total DESC ;
-------13 how many jop title in each department------------------------------------------------------------------------------------------
SELECT 
    D.Name AS DepartmentName,
    COUNT(DISTINCT E.JobTitle) AS NumberOfJobTitles
FROM 
    HumanResources.Department D
JOIN 
    HumanResources.EmployeeDepartmentHistory EH ON D.DepartmentID = EH.DepartmentID
JOIN 
    HumanResources.Employee E ON EH.BusinessEntityID = E.BusinessEntityID
WHERE 
    EH.EndDate IS NULL 
GROUP BY 
    D.Name
ORDER BY 
    NumberOfJobTitles desc;
-------------------------------------------------------------------------------------------------------------------------------------------
