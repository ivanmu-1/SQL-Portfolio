

USE [PortfolioProject]

/*Question 1: How many employees are in each department */
SELECT Department, COUNT(EmployeeNumber) AS Total_Employees
FROM Employees
GROUP BY Department;

/*Question 2: What is the average monthly income per department */
SELECT Department, AVG(MonthlyIncome) AS 'Average Monthly Income'
FROM Employees AS e 
LEFT JOIN Money AS m 
ON e.EmployeeNumber = m.EmployeeNumber 
GROUP BY Department;

/*Question 3: List all employees who are required to travel frequently for business */

SELECT EmployeeNumber
FROM Employees
WHERE BusinessTravel LIKE 'Travel_Frequently';

/*Question 4: What is the gender distribution of employees across different job roles */

SELECT JobRole, Gender, 
    COUNT(*) AS EmployeeCount,
    CAST(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY JobRole), 1) as float) AS Percentage
FROM Employees
GROUP BY JobRole, Gender
ORDER BY JobRole, Gender;

/*Question 5: What is the distribution of employees' performance ratings in each department*/

SELECT e.Department, r.PerformanceRating, CAST(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY Department), 2) as float) AS 'Distribution of Employees Rating'
FROM Employees AS e JOIN Responses AS r 
ON e.EmployeeNumber = r.EmployeeNumber 
GROUP BY Department, r.PerformanceRating
ORDER BY Department;

/* Question 6: List Employees with more than 5 years at the company but less than 3 years with their current manager */

SELECT e.EmployeeNumber, r.YearsatCompany, r.YearsWithCurrManager
FROM Employees e JOIN Responses AS r 
ON e.EmployeeNumber = r.EmployeeNumber
WHERE r.YearsAtCompany > 5 and r.YearsWithCurrManager < 3;

/*Question 7: Find the top 5 highest-paid employees in each department*/

WITH RankedSalaries AS (SELECT Department, e.EmployeeNumber, MonthlyIncome, ROW_NUMBER() OVER(PARTITION BY Department ORDER BY MonthlyIncome DESC) AS Ranking
FROM Employees e LEFT JOIN Money m 
ON e.EmployeeNumber = m.EmployeeNumber )

SELECT Department, EmployeeNumber, MonthlyIncome, Ranking 
FROM RankedSalaries
WHERE Ranking <= 5;


/* Question 8: Identify the number of employees who have worked for more than two companies but have not received a promotion in over three years.*/

SELECT COUNT(e.EmployeeNumber) AS Num_of_employees
FROM Employees e INNER JOIN Responses AS r 
ON e.EmployeeNumber = r.EmployeeNumber
WHERE numCompaniesWorked > 2 AND YearsSinceLastPromotion > 3;

/* Question 9: How do overtime impact attrition*/

SELECT CASE WHEN Overtime = 1 THEN 'True'
			WHEN Overtime = 0 THEN 'False' 
			END AS Overtime , 
			COUNT(*) AS EmployeeCount,
		    SUM(CASE WHEN Attrition = 'True' THEN 1 ELSE 0 END) AS EmployeesWhoLeft,
			CAST(ROUND(SUM(CASE WHEN Attrition = 'True' THEN 1 ELSE 0 END) * 100.0/ COUNT(*),1)as float) AS AttritionRate
FROM Employees AS e JOIN Responses AS r
ON e.EmployeeNumber = r.EmployeeNumber
GROUP BY Overtime
ORDER BY AttritionRate DESC;

/* Question 10: Are Employees with higher performance ratings less likely to leave the company?*/

SELECT PerformanceRating, COUNT(*) AS EmployeeCount, 
	SUM(CASE WHEN Attrition = 'True' THEN 1 ELSE 0 END) AS EmployeesWhoLeft,
    CAST(ROUND(SUM(CASE WHEN Attrition = 'True' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) as float) AS AttritionRate
FROM Employees AS e JOIN Responses AS r
ON e.EmployeeNumber = r.EmployeeNumber
GROUP BY PerformanceRating
ORDER BY PerformanceRating;

/* Question 11: Find each department total salaries?*/

SELECT Department, SUM(MonthlyIncome * 12) AS Total_Salaries
FROM Employees AS e JOIN Money AS m
ON e.EmployeeNumber = m.EmployeeNumber
GROUP BY Department
ORDER BY Total_Salaries DESC

/* Question 12: What is the relationship between environment satisfaction and job satisfaction across employees */

SELECT EnvironmentSatisfaction, JobSatisfaction, COUNT(*) AS EmployeeTotal,
    CAST(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as float) AS Percentage
FROM Employees e JOIN Responses r 
ON e.EmployeeNumber = r.EmployeeNumber
GROUP BY EnvironmentSatisfaction, JobSatisfaction
ORDER BY EnvironmentSatisfaction, JobSatisfaction ASC

/* Question 13: Which Employees have lower job satisfaction than the average for their department */

SELECT EmployeeNumber, JobSatisfaction, Department
FROM Employees E1
WHERE JobSatisfaction < (SELECT AVG(JobSatisfaction) FROM Employees E2 WHERE E2.Department = E1.Department);

			  
/* Question 14: Which Employees have performance rating higher than the average for their job role */

SELECT 
    r.EmployeeNumber, r.PerformanceRating,
    (SELECT ROUND(AVG(r2.PerformanceRating), 2) AS AveragePerformanceRating
     FROM Responses r2
     JOIN Employees e2 ON r2.EmployeeNumber = e2.EmployeeNumber
     WHERE e2.JobRole = e.JobRole
     GROUP BY e2.JobRole) AS AveragePerformanceRating, e.JobRole
FROM Responses r
JOIN Employees e ON r.EmployeeNumber = e.EmployeeNumber
WHERE r.PerformanceRating > (
        SELECT ROUND(AVG(r2.PerformanceRating), 2) AS AveragePerformanceRating
        FROM Responses r2
        JOIN Employees e2 ON r2.EmployeeNumber = e2.EmployeeNumber
        WHERE e2.JobRole = e.JobRole
        GROUP BY e2.JobRole
    )
ORDER BY r.EmployeeNumber;

/* Question 15: Which employees has the highest salary in each department*/

WITH Maxsalaries AS ( 
	SELECT e.EmployeeNumber, e.Department, MAX(m.MonthlyIncome * 12) AS Salary
	FROM Employees e JOIN Money m 
	ON e.EmployeeNumber = m.EmployeeNumber
    GROUP BY e.EmployeeNumber, e.Department), RankedSalaries AS (
	SELECT EmployeeNumber, Department, Salary, ROW_NUMBER() OVER (PARTITION BY Department ORDER BY Salary DESC) AS SalaryRanked
	FROM Maxsalaries )

SELECT EmployeeNumber, Department, Salary 
FROM RankedSalaries
WHERE SalaryRanked = 1
ORDER BY Salary; 

