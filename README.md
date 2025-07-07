This project is structured into three main phases:
1. Building the data warehouse
2. Performing advanced SQL-based analysis on the prepared dataset
3. Visualizing the analytical insights using Power BI

PHASE 1: **BUILDING THE DATAWAREHOUSE**

We adopted a data warehouse approach, as our data was structured and our primary goal was to build a robust foundation for reporting and business intelligence.Datawarehouse is basically a subject oriented, integrated, time variant and non-volatile cllection of data in support of management's decision making process.
![https://acuto.io/blog/data-warehouse-architecture-types/](documents/Datawarehouse_architecture.png)

We used the Medallion Architecture to structure our project’s data pipeline.
![https://www.oreilly.com/library/view/delta-lake-up/9781098139711/ch01.html](documents/Medallion_architecture.png)

STEP 1: We created 3 different schemas(namely, bronze, silver and gold).

STEP 2: Create DDL scripts for all CSV files in the CRM and ERP Systems in the bronze schema.

STEP 3: Load data into the tables of bronze schema. We wanted to do bulk inserts inside a store procedure but MySQL doesn't actually supports bulk insertion inside a stored procedure to avoid SQL injection, so we shifted to running the script instead to do the desired work.

STEP 4: In order to identify bottlenecks and optimize performance, we declared required variables to track duration of each ETL step.

STEP 5: We now moved to silver schema and created table accordingly with the same structure like that in the bronze schema.

STEP 6: Here, we added an extra metadata column called dwh_create_date in order to have an eye on when was the current data loaded.

STEP 7:


   
