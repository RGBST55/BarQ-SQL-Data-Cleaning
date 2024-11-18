CREATE TABLE temp_TransactionHeader (
    Order_ID VARCHAR(50),
    Store_Grp_Id VARCHAR(5),
    Profit_Center_ID VARCHAR(50),
    Table_ID VARCHAR(50),
    Server_Emp_ID VARCHAR(50),
    Guest_Check_ID VARCHAR(50),
    Order_Txn_Start_Dttm TEXT,
    Order_Txn_End_Dttm TEXT,
    Order_Process_Dttm TEXT,
    Guest_Cnt INT,
    Menu_Item_Total_price FLOAT,
    Menu_Item_Total_tax FLOAT,
    Total_Tip FLOAT
);
CREATE TABLE TransactionDetails (
    Order_ID VARCHAR(50),
    Table_ID VARCHAR(50),
    Menu_Item_ID VARCHAR(50),
    Menu_Item_Qty INT,
    Menu_Item_Total_price FLOAT,
    Menu_Item_Total_tax FLOAT
);

CREATE TABLE TransactionHeader (
    Order_ID VARCHAR(50),
    Store_Grp_Id VARCHAR(5),
    Profit_Center_ID VARCHAR(50),
    Table_ID VARCHAR(50),
    Server_Emp_ID VARCHAR(50),
    Guest_Check_ID VARCHAR(50),
    Order_Txn_Start_Dttm TIMESTAMP,
    Order_Txn_End_Dttm TIMESTAMP,
    Order_Process_Dttm TIMESTAMP,
    Guest_Cnt INT,
    Menu_Item_Total_price FLOAT,
    Menu_Item_Total_tax FLOAT,
    Total_Tip FLOAT
);



INSERT INTO TransactionHeader (
    Order_ID, Store_Grp_Id, Profit_Center_ID, Table_ID, Server_Emp_ID,
    Guest_Check_ID, Order_Txn_Start_Dttm, Order_Txn_End_Dttm,
    Order_Process_Dttm, Guest_Cnt, Menu_Item_Total_price,
    Menu_Item_Total_tax, Total_Tip
)
SELECT
    Order_ID,
    Store_Grp_Id,
    Profit_Center_ID,
    Table_ID,
    Server_Emp_ID,
    Guest_Check_ID,
    TO_TIMESTAMP(Order_Txn_Start_Dttm, 'MM/DD/YYYY HH24:MI'),
    TO_TIMESTAMP(Order_Txn_End_Dttm, 'MM/DD/YYYY HH24:MI'),
    TO_TIMESTAMP(Order_Process_Dttm, 'MM/DD/YYYY HH24:MI'),
    Guest_Cnt,
    Menu_Item_Total_price,
    Menu_Item_Total_tax,
    Total_Tip
FROM
    Staging_TransactionHeader;

	Select count(*) from transactionheader


