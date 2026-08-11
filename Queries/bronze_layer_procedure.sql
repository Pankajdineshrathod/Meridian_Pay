CREATE OR ALTER PROCEDURE dbo.bronze_load_bronze AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '===================================================';
        PRINT 'Loading Bronze layer - fetching data into tables';
        PRINT '===================================================';
        -- Getting data into the "bronze_api_logs" table from 'E:\Meridian_Pay\Raw_Files\Logs\api_logs.jsonl'
        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        PRINT '>>> Truncating: bronze_api_logs table';
        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze_api_logs;

        PRINT '>>> Loading: bronze_api_logs table';
        --Load the raw JSON file text into a variable
        DECLARE @JsonData NVARCHAR(MAX);

        SELECT @JsonData = BulkColumn
        FROM OPENROWSET (BULK 'E:\Meridian_Pay\Raw_Files\Logs\api_logs.jsonl', SINGLE_CLOB) AS j;

        -- NEW STEP: Convert the .jsonl (JSON Lines) format into a standard JSON Array.
        -- This replaces the line breaks between objects with commas, and wraps everything in [ ]

        -- Since I don't know the origina OS of the file
        SET @JsonData = REPLACE(@JsonData, '}' + CHAR(13) + CHAR(10) + '{', '},{'); -- Handles Windows line breaks
        SET @JsonData = REPLACE(@JsonData, '}' + CHAR(10) + '{', '},{');            -- Handles Linux/Mac line breaks
        SET @JsonData = '[' + @JsonData + ']';

        -- 2. Parse and map keys directly into your existing table
        INSERT INTO Bronze_api_logs (
            log_id, 
            [period], 
            bank_name, 
            integration_type, 
            total_calls, 
            successful_calls, 
            failed_calls, 
            avg_response_time_ms, 
            source_system, 
            extracted_at
        )
        SELECT 
            log_id, 
            [period], 
            bank_name, 
            integration_type, 
            total_calls, 
            successful_calls, 
            failed_calls, 
            avg_response_time_ms, 
            source_system, 
            extracted_at
        FROM OPENJSON(@JsonData)
        WITH (
            log_id INT '$.log_id',
            period DATETIME2 '$.period',
            bank_name VARCHAR(255) '$.bank.name',
            integration_type VARCHAR(100) '$.integration_type',
            total_calls INT '$.metrics.total_calls',
            successful_calls INT '$.metrics.successful_calls',
            failed_calls INT '$.metrics.failed_calls',
            avg_response_time_ms FLOAT '$.avg_response_time_ms',
            source_system VARCHAR(100) '$.meta.source_system',
            extracted_at DATETIME2 '$.meta.extracted_at'
        );
        SET @end_time = GETDATE();

        PRINT '>>> Loaded: bronze_api_logs table';
        PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        PRINT ' ';

        --==================================================================================================
        -- Getting data into the "bronze_system_incidents" table from 'E:\Meridian_Pay\Raw_Files\Logs\system_incidents.csv'
        --==================================================================================================
        SET @start_time = GETDATE();
        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        PRINT '>>> Truncating: bronze_system_incidents table';
        TRUNCATE TABLE bronze_system_incidents;

        PRINT '>>> Loading: bronze_system_incidents table';


        BULK INSERT bronze_system_incidents
        FROM 'E:\Meridian_Pay\Raw_Files\Logs\system_incidents.csv'
        WITH (
            FIRSTROW = 2,           -- Skips the header row
            FIELDTERMINATOR = ',',  -- Specifies comma as the column delimiter
            ROWTERMINATOR = '0x0A',   -- Specifies newline as the row delimiter (use '\r\n' for Windows files)
            FORMAT = 'CSV',
            TABLOCK                 -- Improves performance by locking the table during insert
            );
        SET @end_time = GETDATE();

        PRINT '>>> Loaded: bronze_system_incidents table';
        PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        PRINT ' ';
        --==================================================================================================
        -- Getting data into the "bronze_company_financials" table from 'E:\Meridian_Pay\Raw_Files\Other\company_financials.csv'
        --==================================================================================================

        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        SET @start_time = GETDATE();
        PRINT '>>> Truncating: bronze_company_financials table';


        TRUNCATE TABLE bronze_company_financials;

        PRINT '>>> Loading: bronze_company_financials table';


        BULK INSERT bronze_company_financials
        FROM 'E:\Meridian_Pay\Raw_Files\Other\company_financials.csv'
        WITH (
            FIRSTROW = 5,           -- Skips the header row
            FIELDTERMINATOR = ',',  -- Specifies comma as the column delimiter
            ROWTERMINATOR = '0x0A',   -- Specifies newline as the row delimiter (use '\r\n' for Windows files)
            FORMAT = 'CSV',
            TABLOCK                 -- Improves performance by locking the table during insert
            );

        -- Error; Bulk load data conversion error (type mismatch or invalid character for the specified codepage) for row 29, column 1 (Month_Year).
        -- Upon checking the filethe last row is totals (written in first column) 
        -- Thus we will first need to change the data type of the column "Month_Year" to VARCHAR(20) and change it to date in the next stages 
        -- Then delete the row with total in month_year column

        DELETE FROM bronze_company_financials 
        WHERE Month_Year LIKE '%Total%' 
           OR Month_Year IS NULL;
        SET @end_time = GETDATE();
        PRINT '>>> Loaded: bronze_company_financials table';
        PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        PRINT ' ';
        --==================================================================================================
        -- Getting data into the "bronze_country_reference" table from 'E:\Meridian_Pay\Raw_Files\Other\country_reference.csv'
        --==================================================================================================

        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        SET @start_time = GETDATE();
        PRINT '>>> Truncating: bronze_country_reference table';

        TRUNCATE TABLE bronze_country_reference;

        PRINT '>>> Loading: bronze_country_reference table';

        BULK INSERT bronze_country_reference
        FROM 'E:\Meridian_Pay\Raw_Files\Other\country_reference.csv'
        WITH (
            FIRSTROW = 2,           -- Skips the header row
            FIELDTERMINATOR = ',',  -- Specifies comma as the column delimiter
            ROWTERMINATOR = '0x0A',   -- Specifies newline as the row delimiter (use '\r\n' for Windows files)
            FORMAT = 'CSV',
            TABLOCK                 -- Improves performance by locking the table during insert
            );
        SET @end_time = GETDATE();
        PRINT '>>> Loaded: bronze_system_incidents table';
        PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        PRINT ' ';
        --==================================================================================================
        -- Getting data into the "bronze_card_master_system_A" table from 'E:\Meridian_Pay\Raw_Files\Card\card_master_system_A.csv'
        --==================================================================================================

        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        SET @start_time = GETDATE();
        PRINT '>>> Truncating: bronze_card_master_system_A table';

        TRUNCATE TABLE bronze_card_master_system_A;

        PRINT 'Loading: bronze_card_master_system_A table';

        BULK INSERT bronze_card_master_system_A
        FROM 'E:\Meridian_Pay\Raw_Files\Card\card_master_system_A.csv'
        WITH (
            FIRSTROW = 2,           -- Skips the header row
            FIELDTERMINATOR = ',',  -- Specifies comma as the column delimiter
            ROWTERMINATOR = '0x0A',   -- Specifies newline as the row delimiter (use '\r\n' for Windows files)
            FORMAT = 'CSV',
            TABLOCK                 -- Improves performance by locking the table during insert
            );
        SET @end_time = GETDATE();
        PRINT '>>> Loaded: bronze_card_master_system_A table';
        PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        PRINT ' ';
        --==================================================================================================
        -- Getting data into the "bronze_card_status_feed" table from 'E:\Meridian_Pay\Raw_Files\Card\card_status_feed.tsv'
        --==================================================================================================

        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        SET @start_time = GETDATE();
        PRINT '>>> Truncating: bronze_card_status_feed table';

        TRUNCATE TABLE bronze_card_status_feed;

        PRINT '>>> Loading: bronze_card_status_feed table';

        BULK INSERT bronze_card_status_feed
        FROM 'E:\Meridian_Pay\Raw_Files\Card\card_status_feed.tsv'
        WITH (
            FIRSTROW = 2,           -- Skips the header row
            FIELDTERMINATOR = '\t',  -- Specifies Tab as the column delimiter
            ROWTERMINATOR = '0x0A',   -- Specifies newline as the row delimiter (use '\r\n' for Windows files)
            TABLOCK                 -- Improves performance by locking the table during insert
            );
        SET @end_time = GETDATE();
        PRINT '>>> Loaded: bronze_card_status_feed table';
        PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        PRINT ' ';
        --==================================================================================================
        -- Getting data into the "bronze_merchant_incremental" table from 'E:\Meridian_Pay\Raw_Files\Merchant\merchant_incremental.csv'
        --==================================================================================================

        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        SET @start_time = GETDATE();
        PRINT '>>> Truncating: bronze_merchant_incremental table';

        TRUNCATE TABLE bronze_merchant_incremental;

        PRINT '>>> Loading: bronze_merchant_incremental table';


        BULK INSERT bronze_merchant_incremental
        FROM 'E:\Meridian_Pay\Raw_Files\Merchant\merchant_incremental.csv'
        WITH (
            FIRSTROW = 2,           -- Skips the header row
            FIELDTERMINATOR = ',',  -- Specifies comma as the column delimiter
            ROWTERMINATOR = '0x0A',   -- Specifies newline as the row delimiter (use '\r\n' for Windows files)
            TABLOCK                 -- Improves performance by locking the table during insert
            );
        SET @end_time = GETDATE();
        PRINT '>>> Loaded: bronze_merchant_incremental table';
        PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        PRINT ' ';
        --==================================================================================================
        -- Getting data into the "bronze_merchant_master" table from 'E:\Meridian_Pay\Raw_Files\Merchant\merchant_master.csv'
        --==================================================================================================

        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        SET @start_time = GETDATE();
        PRINT '>>> Truncating: bronze_merchant_master incremental table';

        TRUNCATE TABLE bronze_merchant_master;

        PRINT '>>> Loading: bronze_merchant_master table';


        BULK INSERT bronze_merchant_master
        FROM 'E:\Meridian_Pay\Raw_Files\Merchant\merchant_master.csv'
        WITH (
            FIRSTROW = 2,           -- Skips the header row
            FIELDTERMINATOR = ',',  -- Specifies comma as the column delimiter
            ROWTERMINATOR = '0x0A',   -- Specifies newline as the row delimiter (use '\r\n' for Windows files)
            TABLOCK                 -- Improves performance by locking the table during insert
            );
        SET @end_time = GETDATE();
        PRINT '>>> Loaded: bronze_merchant_master table';
        PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        PRINT ' ';
        --==================================================================================================
        -- Getting data into the "bronze_revenue_amer_apac" table from 'E:\Meridian_Pay\Raw_Files\Revenue\revenue_amer_apac.csv'
        --==================================================================================================

        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        SET @start_time = GETDATE();
        PRINT '>>> Truncating: bronze_revenue_amer_apac table';

        TRUNCATE TABLE bronze_revenue_amer_apac;

        PRINT '>>> Loading: bronze_revenue_amer_apac table';


        BULK INSERT bronze_revenue_amer_apac
        FROM 'E:\Meridian_Pay\Raw_Files\Revenue\revenue_amer_apac.csv'
        WITH (
            FIRSTROW = 2,           -- Skips the header row
            FIELDTERMINATOR = ',',  -- Specifies comma as the column delimiter
            ROWTERMINATOR = '0x0A',   -- Specifies newline as the row delimiter (use '\r\n' for Windows files)
            TABLOCK                 -- Improves performance by locking the table during insert
            );
        SET @end_time = GETDATE();
        PRINT '>>> Loaded: bronze_revenue_amer_apac table';
        PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        PRINT ' ';
        --==================================================================================================
        -- Getting data into the "bronze_revenue_emea" table from 'E:\Meridian_Pay\Raw_Files\Revenue\revenue_emea.csv'
        --==================================================================================================

        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        SET @start_time = GETDATE();
        PRINT '>>> Truncating: bronze_revenue_emea table';

        TRUNCATE TABLE bronze_revenue_emea;

        PRINT '>>> Loading: bronze_revenue_emea table';


        BULK INSERT bronze_revenue_emea
        FROM 'E:\Meridian_Pay\Raw_Files\Revenue\revenue_emea.csv'
        WITH (
            FIRSTROW = 2,           -- Skips the header row
            FIELDTERMINATOR = ';',  -- Specifies comma as the column delimiter
            ROWTERMINATOR = '0x0A',   -- Specifies newline as the row delimiter (use '\r\n' for Windows files)
            TABLOCK                 -- Improves performance by locking the table during insert
            );
        SET @end_time = GETDATE();
        PRINT '>>> Loaded: bronze_revenue_emea table';
        PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        PRINT ' ';
        --==================================================================================================
        -- Getting data into the "transactions_2024H2_2025" table from 'E:\Meridian_Pay\Raw_Files\Transactions\transactions_2024H2_2025.csv'
        --==================================================================================================

        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        PRINT '>>> Truncating: bronze_transactions_2024H2_2025 table';
        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze_transactions_2024H2_2025;

        PRINT '>>> Loading: bronze_transactions_2024H2_2025 table';


        BULK INSERT bronze_transactions_2024H2_2025
        FROM 'E:\Meridian_Pay\Raw_Files\Transactions\transactions_2024H2_2025.csv'
        WITH (
            FIRSTROW = 2,           -- Skips the header row
            FIELDTERMINATOR = ',',  -- Specifies comma as the column delimiter
            ROWTERMINATOR = '0x0A',   -- Specifies newline as the row delimiter (use '\r\n' for Windows files)
            TABLOCK                 -- Improves performance by locking the table during insert
            );
        SET @end_time = GETDATE();
        PRINT '>>> Loaded: bronze_transactions_2024H2_2025 table';
        PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        PRINT ' ';
        --==================================================================================================
        -- Getting data into the "transactions_legacy_2024H1" table from 'E:\Meridian_Pay\Raw_Files\Transactions\transactions_legacy_2024H1.csv'
        --==================================================================================================

        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        PRINT '>>> Truncating: bronze_transactions_legacy_2024H1 table';
        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze_transactions_legacy_2024H1;

        PRINT '>>> Loading: bronze_transactions_legacy_2024H1 table';


        BULK INSERT bronze_transactions_legacy_2024H1
        FROM 'E:\Meridian_Pay\Raw_Files\Transactions\transactions_legacy_2024H1.csv'
        WITH (
            FIRSTROW = 2,           -- Skips the header row
            FIELDTERMINATOR = ',',  -- Specifies comma as the column delimiter
            ROWTERMINATOR = '0x0A',   -- Specifies newline as the row delimiter (use '\r\n' for Windows files)
            TABLOCK                 -- Improves performance by locking the table during insert
            );
        SET @end_time = GETDATE();
        PRINT '>>> Loaded: bronze_transactions_legacy_2024H1 table';
        PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
        PRINT ' ';
        PRINT ' ';
        SET @batch_end_time = GETDATE();
        PRINT '===================================================';
        PRINT 'Successfully fetched bronze layer, have a good day';
        PRINT '>>> BRONZE Layer Load Duration ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '===================================================';
    END TRY
    BEGIN CATCH 
        PRINT 'X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-';
        PRINT 'An Error Occured During the loadof bronze layer';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR)
        PRINT 'X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-';
    END CATCH
END;