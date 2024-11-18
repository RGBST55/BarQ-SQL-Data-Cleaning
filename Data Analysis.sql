/* Checking for nulls*/
Select * from transactionheader head
where store_grp_id is null
/* Check one by on for all cols, only blanks occur in guest_check_id which makes sense, but always done better in Excel

/* Checking whether all order IDs from Header table exist in details*/*/
Select t.order_id, t.guest_cnt from transactionheader t 
join transactiondetails  d on t.order_id = d.order_id 
where t.guest_cnt = null

/* checked whether end time is greater than start time for all orders */
select order_txn_start_dttm, order_txn_end_dttm from transactionheader head
where order_txn_start_dttm >= order_txn_end_dttm

/* check whether payment time is between end and start time of orders */
select order_txn_start_dttm, order_txn_end_dttm, order_process_dttm from transactionheader head
where order_process_dttm Not between order_txn_start_dttm  and order_txn_end_dttm

/*Checking for Dupes in Order ID for TransHead*/
SELECT order_id, COUNT(*) AS order_count
FROM transactionheader t
GROUP BY Order_ID
HAVING COUNT(*) > 1;

/*Analyzing Range for all variables which should fall within a set range
Guest count*/
SELECT MIN(Guest_Cnt) AS min_guest_count, MAX(Guest_Cnt) AS max_guest_count,
MAX(Guest_Cnt) - Min(Guest_Cnt) as range_gc
FROM transactionheader t

/*Total Price*/
SELECT MIN(menu_item_total_price) AS min_bill, MAX(menu_item_total_price) AS max_bill,
MAX(menu_item_total_price) - Min(menu_item_total_price) as range_bill
FROM transactionheader t

/*total tax*/
SELECT MIN(menu_item_total_tax) AS min_tax, MAX(menu_item_total_tax) AS max_tax,
MAX(menu_item_total_tax) - Min(menu_item_total_tax) as range_tax
FROM transactionheader t

/*Outliers since total tax exeeds total bill*/

/*total tip check if negative
Checking range of total tip does not make sense as much since tips are subjective, they just should not be negative*/
Select min(total_tip) from transactionheader

/* Checking similarly for Transaction details table*/
SELECT MIN(menu_item_qty) AS min_qty, MAX(menu_item_qty) AS max_qty,
MAX(menu_item_qty) - Min(menu_item_qty) as range_qty
FROM transactiondetails d

SELECT MIN(menu_item_total_tax) AS min_tax, MAX(menu_item_total_tax) AS max_tax,
MAX(menu_item_total_tax) - Min(menu_item_total_tax) as range_tax
FROM transactiondetails d
/*raises questions as tax can neither be 0 not more than max bill*/

SELECT MIN(menu_item_total_price) AS min_bill, MAX(menu_item_total_price) AS max_bill,
MAX(menu_item_total_price) - Min(menu_item_total_price) as range_bill
FROM transactiondetails d

/* Trying to figure out the issues with taxes and prices in sql*/
WITH median_values AS (
    SELECT 
        Table_ID,
        Menu_Item_ID,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY Menu_Item_Total_price / Menu_Item_Qty) AS median_price_per_item,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY Menu_Item_Total_tax / Menu_Item_Qty) AS median_tax_per_item
    FROM 
        transactiondetails
    GROUP BY 
        Table_ID, Menu_Item_ID
)
UPDATE transactiondetails AS td
SET 
    Menu_Item_Total_price = (mv.median_price_per_item * td.Menu_Item_Qty)::NUMERIC(10, 2),
    Menu_Item_Total_tax = (mv.median_tax_per_item * td.Menu_Item_Qty)::NUMERIC(10, 2)
FROM 
    median_values AS mv
WHERE 
    td.Table_ID = mv.Table_ID 
    AND td.Menu_Item_ID = mv.Menu_Item_ID
    AND (
        (td.Menu_Item_Total_price / td.Menu_Item_Qty) <> mv.median_price_per_item
        OR
        (td.Menu_Item_Total_tax / td.Menu_Item_Qty) <> mv.median_tax_per_item
        OR
        td.Menu_Item_Total_tax > td.Menu_Item_Total_price
    );


Select * from transactiondetails where menu_item_total_tax = 00

-- Checking the consistency of the amount of data for each store

select count(order_id) from transactionheader
group by profit_center_id

-- Checking for outliers based on number of customers and transaction amount

WITH customer_price_stats AS (
    SELECT 
        Table_ID,
        AVG(Menu_Item_Total_price / Guest_Cnt) AS mean_price_per_customer,
        STDDEV(Menu_Item_Total_price / Guest_Cnt) AS sd_price_per_customer
    FROM transactionheader
    GROUP BY Table_ID
),
customer_price_check AS (
    SELECT 
        th.Order_ID,
        th.Table_ID,
        th.Menu_Item_Total_price,
        th.Guest_Cnt,
        (th.Menu_Item_Total_price / th.Guest_Cnt) AS price_per_customer,
        c.mean_price_per_customer,
        c.sd_price_per_customer
    FROM transactionheader th
    JOIN customer_price_stats c ON th.Table_ID = c.Table_ID
)
SELECT 
    Order_ID,
    Table_ID,
    Menu_Item_Total_price,
    Guest_Cnt,
    price_per_customer,
    mean_price_per_customer - (3 * sd_price_per_customer) AS lower_threshold,
    mean_price_per_customer + (3 * sd_price_per_customer) AS upper_threshold
FROM customer_price_check
WHERE price_per_customer > (mean_price_per_customer - 3 * sd_price_per_customer)
   OR price_per_customer < (mean_price_per_customer + 3 * sd_price_per_customer)
ORDER BY price_per_customer;
-- this makes no sense so will drop this idea

-- Changing the tax amounts in the trans header table based on tax amounts calculated after fixing them in the trans details table
ALTER TABLE transactionheader
ADD COLUMN taxes_new FLOAT;

WITH tax_totals AS (
    SELECT 
        Order_ID,
        SUM(Menu_Item_Total_tax) AS total_tax
    FROM 
        transactiondetails
    GROUP BY 
        Order_ID
)
UPDATE transactionheader th
SET taxes_new = tt.total_tax
FROM tax_totals tt
WHERE th.Order_ID = tt.Order_ID;

Select order_id, menu_item_total_tax, taxes_new from transactionheader 

-- Figuring out the Store_grp_ID's accuracy

-- Step 1: Calculate total sales for each store (Profit_Center_ID)
WITH Store_Sales AS (
    SELECT 
        Profit_Center_ID,
        Store_Grp_Id,
        SUM(Menu_Item_Total_price + Menu_Item_Total_tax) AS Total_Sales
    FROM 
        transactionheader
    GROUP BY 
        Profit_Center_ID, Store_Grp_Id
),

-- Step 2: Calculate median sales per store group
Median_Sales_Per_Store AS (
    SELECT 
        Store_Grp_Id,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Total_Sales) AS Median_Sales_Per_Store
    FROM 
        Store_Sales
    GROUP BY 
        Store_Grp_Id
),

-- Step 3: Calculate other aggregate metrics (average, min, max)
Sales_Stats AS (
    SELECT
        Store_Grp_Id,
        AVG(Total_Sales) AS Avg_Sales_Per_Store,
        MIN(Total_Sales) AS Min_Sales_Per_Store,
        MAX(Total_Sales) AS Max_Sales_Per_Store,
        COUNT(*) AS Number_Of_Stores
    FROM 
        Store_Sales
    GROUP BY 
        Store_Grp_Id
)

-- Final output combining median and other statistics
SELECT 
    s.Store_Grp_Id,
    s.Avg_Sales_Per_Store,
    m.Median_Sales_Per_Store,
    s.Min_Sales_Per_Store,
    s.Max_Sales_Per_Store,
    s.Number_Of_Stores
FROM 
    Sales_Stats s
JOIN 
    Median_Sales_Per_Store m ON s.Store_Grp_Id = m.Store_Grp_Id
ORDER BY 
    s.Store_Grp_Id;

--Tip Analysis
WITH tip_analysis AS (
    SELECT 
        td.server_emp_id, 
        td.Profit_center_id,
        SUM(td.total_tip) AS total_tips,
        SUM(td.menu_item_total_price) AS total_bill,
        COUNT(td.order_id) AS total_transactions,
        (SUM(td.total_tip) / SUM(td.menu_item_total_price)) * 100 AS tip_percentage
    FROM 
        transactionHeader td
    GROUP BY 
        td.server_emp_id, td.Profit_center_id
)

-- Now let's get the average tip percentage per server and per store location
SELECT
    ta.server_emp_id,
    ta.Profit_center_id,
    ta.total_tips,
    ta.total_bill,
    ta.total_transactions,
    ta.tip_percentage,
    AVG(ta.tip_percentage) OVER (PARTITION BY ta.server_emp_id) AS avg_tip_percentage_server,
    AVG(ta.tip_percentage) OVER (PARTITION BY ta.Profit_center_id) AS avg_tip_percentage_store
FROM 
    tip_analysis ta
ORDER BY 
    ta.tip_percentage DESC;
