use final
select * from transactions_info

-- 1	список клиентов с непрерывной историей за год, то есть каждый месяц на регулярной основе без пропусков за указанный годовой период, средний чек за период с 01.06.2015 по 01.06.2016, средняя сумма покупок за месяц, количество всех операций по клиенту за период;
SELECT 
    c.Id_client,
    COUNT(t.Id_check) AS Total_transactions,
    AVG(t.Sum_payment) AS Average_check,
    AVG(t.Sum_payment) * 12 AS Average_monthly_spending,
    MIN(t.date_new) AS First_transaction_date,
    MAX(t.date_new) AS Last_transaction_date
FROM 
    customer_info c
JOIN 
    transactions_info t ON c.Id_client = t.ID_client
WHERE 
    t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY 
    c.Id_client
HAVING 
    COUNT(DISTINCT DATE_FORMAT(t.date_new, '%Y-%m')) = 12
ORDER BY 
    c.Id_client;

-- 2A. a)	средняя сумма чека в месяц;
SELECT 
    DATE_FORMAT(t.date_new, '%Y-%m') AS Month,
    AVG(t.Sum_payment) AS Average_check
FROM 
    transactions_info t
GROUP BY 
    Month
ORDER BY 
    Month;
    
-- 2B. Cреднее количество операций в месяц;
SELECT 
    DATE_FORMAT(t.date_new, '%Y-%m') AS Month,
    COUNT(t.Id_check) / COUNT(DISTINCT DATE_FORMAT(t.date_new, '%Y-%m')) AS Average_transactions_per_month
FROM 
    transactions_info t
GROUP BY 
    Month
ORDER BY 
    Month;
    
-- 2C. c)	среднее количество клиентов, которые совершали операции;
SELECT 
    DATE_FORMAT(t.date_new, '%Y-%m') AS Month,
    COUNT(DISTINCT t.ID_client) AS Average_clients
FROM 
    transactions_info t
GROUP BY 
    Month
ORDER BY 
    Month;

-- 2D. d)	долю от общего количества операций за год и долю в месяц от общей суммы операций;
WITH Monthly_Stats AS (
    SELECT 
        DATE_FORMAT(t.date_new, '%Y-%m') AS Month,
        COUNT(t.Id_check) AS Monthly_transactions,
        SUM(t.Sum_payment) AS Monthly_total
    FROM 
        transactions_info t
    GROUP BY 
        Month
)
SELECT 
    Month,
    Monthly_transactions,
    Monthly_total,
    (Monthly_transactions / SUM(Monthly_transactions) OVER ()) * 100 AS Transaction_share,
    (Monthly_total / SUM(Monthly_total) OVER ()) * 100 AS Total_amount_share
FROM 
    Monthly_Stats
ORDER BY 
    Month;
    
-- 2E. e)	вывести % соотношение M/F/NA в каждом месяце с их долей затрат; 
SELECT 
    DATE_FORMAT(t.date_new, '%Y-%m') AS Month,
    SUM(CASE WHEN c.Gender = 'M' THEN t.Sum_payment ELSE 0 END) AS Male_spending,
    SUM(CASE WHEN c.Gender = 'F' THEN t.Sum_payment ELSE 0 END) AS Female_spending,
    SUM(CASE WHEN c.Gender IS NULL THEN t.Sum_payment ELSE 0 END) AS NA_spending,
    COUNT(CASE WHEN c.Gender = 'M' THEN 1 END) AS Male_count,
    COUNT(CASE WHEN c.Gender = 'F' THEN 1 END) AS Female_count,
    COUNT(CASE WHEN c.Gender IS NULL THEN 1 END) AS NA_count
FROM 
    transactions_info t
JOIN 
    customer_info c ON t.ID_client = c.Id_client
GROUP BY 
    Month
ORDER BY 
    Month;
-- 3a
SELECT 
    CASE 
        WHEN c.Age IS NULL THEN 'Unknown'
        WHEN c.Age < 10 THEN '0-9'
        WHEN c.Age < 20 THEN '10-19'
        WHEN c.Age < 30 THEN '20-29'
        WHEN c.Age < 40 THEN '30-39'
        WHEN c.Age < 50 THEN '40-49'
        WHEN c.Age < 60 THEN '50-59'
        WHEN c.Age < 70 THEN '60-69'
        WHEN c.Age < 80 THEN '70-79'
        ELSE '80+' 
    END AS Age_Group,
    SUM(t.Sum_payment) AS Total_amount,
    COUNT(t.Id_check) AS Total_transactions
FROM 
    customer_info c
LEFT JOIN 
    transactions_info t ON c.Id_client = t.ID_client
GROUP BY 
    Age_Group
ORDER BY 
    Age_Group;
    
-- 3BСредние показатели и % поквартально
WITH Quarterly_Stats AS (
    SELECT 
        DATE_FORMAT(t.date_new, '%Y-%m') AS Month,
        CASE 
            WHEN c.Age IS NULL THEN 'Unknown'
            WHEN c.Age < 10 THEN '0-9'
            WHEN c.Age < 20 THEN '10-19'
            WHEN c.Age < 30 THEN '20-29'
            WHEN c.Age < 40 THEN '30-39'
            WHEN c.Age < 50 THEN '40-49'
            WHEN c.Age < 60 THEN '50-59'
            WHEN c.Age < 70 THEN '60-69'
            WHEN c.Age < 80 THEN '70-79'
            ELSE '80+' 
        END AS Age_Group,
        SUM(t.Sum_payment) AS Total_amount,
        COUNT(t.Id_check) AS Total_transactions
    FROM 
        customer_info c
    LEFT JOIN 
        transactions_info t ON c.Id_client = t.ID_client
    GROUP BY 
        Month, Age_Group
)
SELECT 
    Age_Group,
    SUM(Total_amount) AS Total_amount,
    SUM(Total_transactions) AS Total_transactions,
    AVG(Total_amount) AS Average_amount_per_quarter,
    (SUM(Total_amount) / (SELECT SUM(Total_amount) FROM Quarterly_Stats)) * 100 AS Percentage_of_total_amount,
    (SUM(Total_transactions) / (SELECT SUM(Total_transactions) FROM Quarterly_Stats)) * 100 AS Percentage_of_total_transactions
FROM 
    Quarterly_Stats
GROUP BY 
    Age_Group
ORDER BY 
    Age_Group;
