/*
===============================================================================
Stored Procedure: dbo.silver_load_silver
Description:      Executes the ETL pipeline to populate the Silver layer. 
                  Reads raw data from the Bronze layer and applies structural 
                  transformations, data cleansing, and validation to create a 
                  standardized, high-quality analytical foundation.

Design Pattern:   Truncate and Load (Full Refresh)

Key Transformations Applied:
    - Deduplication: Removes duplicate records using ROW_NUMBER() partitioning.
    - Data Cleansing: Trims excess whitespaces and strips unwanted characters 
      (e.g., '$', ',' from currency strings).
    - Data Type Conversion: Safely casts strings to native formats (DATE, DATETIME, 
      FLOAT) using TRY_CONVERT/TRY_CAST hierarchies to handle varied date formats.
    - Standardization: Normalizes categorical values using CASE statements 
      (e.g., standardizing Region names, Country codes, and API Integration types).
    - Boolean Normalization: Maps fragmented binary flags (Y/N, 1/0, TRUE/FALSE) 
      into standard 'Yes'/'No' string values.
    - Auditing: Appends an `import_time` timestamp to all processed records.
===============================================================================
*/

CREATE OR ALTER PROCEDURE dbo.silver_load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME
    BEGIN TRY
                SET @batch_start_time = GETDATE();
                PRINT '===================================================';
                PRINT 'Loading Silver layer - fetching data into tables';
                PRINT '===================================================';

/*
============================================================================================ 
Getting data into the "silver_api_logs" table
==============================================================================================
*/
                PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
                PRINT '>>> Truncating: silver_api_logs table';
                SET @start_time = GETDATE();

        TRUNCATE TABLE silver_api_logs;

                PRINT '>>> Loading: silver_api_logs table';

        INSERT INTO silver_api_logs
        SELECT log_id
              ,CAST(period as date) as record_date
              ,bank_name
              ,CASE 
	                WHEN TRIM(UPPER(integration_type)) IN ('FRAUD SCREENING API','FRAUD', 'FRAUD SCREENING') then 'Fraud Screening'
	                WHEN TRIM(UPPER(integration_type)) IN ('TOKENIZATION API', 'TOKENIZATION') then 'Tokenization'
	                WHEN TRIM(UPPER(integration_type)) IN ('CARD ISSUANCE API', 'CARD ISSUANCE') then 'Card Issuance'
	                WHEN TRIM(UPPER(integration_type)) IN ('CORE BANKING API', 'CORE BANKING') then 'Core Banking'
	                ELSE integration_type
	                END as integration_api
              ,successful_calls + failed_calls as total_api_calls
              ,successful_calls as successful_api_calls
              ,failed_calls as failed_api_calls
              ,avg_response_time_ms as average_response_time
              ,CASE WHEN source_system IS NULL THEN 'N/A' ELSE source_system END as source_system
              ,CAST(extracted_at AS DATE) as extraction_date
              ,getdate() as import_time
        FROM dbo.Bronze_api_logs;

                SET @end_time = GETDATE();

                PRINT '>>> Loaded: silver_api_logs table';
                PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
                PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
                PRINT ' ';

/*
============================================================================================ 
Getting data into the "silver_system_incidents" table
==============================================================================================
*/
                PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
                PRINT '>>> Truncating: silver_system_incidents table';
                SET @start_time = GETDATE();

        TRUNCATE TABLE silver_system_incidents;

                PRINT '>>> Loading: silver_system_incidents table';

        INSERT INTO silver_system_incidents
        SELECT
            incident_id,
            component,
            start_ts as satrt_time,
            end_ts as end_time,
            (1.0*DATEDIFF(SECOND, start_ts, end_ts))/60 as duration_in_minutes,
            severity,
            CASE WHEN ticket_id IS NULL THEN 'N/A' ELSE ticket_id END as ticket_id,
            getdate() as import_time
        FROM Bronze_system_incidents;

                SET @end_time = GETDATE();
                PRINT '>>> Loaded: silver_api_logs table';
                PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
                PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
                PRINT ' ';

/*
============================================================================================ 
Getting data into the "silver_company_financials_incidents" table
==============================================================================================
*/
                PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
                PRINT '>>> Truncating: silver_company_financials_incidents table';
                SET @start_time = GETDATE();

        TRUNCATE TABLE silver_company_financials;

                PRINT '>>> Loading: silver_company_financials_incidents table';

        INSERT INTO silver_company_financials
        SELECT
            CAST(Month_Year as date) as month_year,
            Gross_Revenue_USD as gross_revenue_usd,
            Rebates_Incentives_USD as rebates_incentives_usd,
            Operating_Income_USD as operating_income_usd,
            getdate() as import_time
        FROM Bronze_company_financials;

                SET @end_time = GETDATE();
                PRINT '>>> Loaded: silver_company_financials_incidents table';
                PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
                PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
                PRINT ' ';

/*
============================================================================================ 
Getting data into the "silver_country_reference" table
==============================================================================================
*/
                PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
                PRINT '>>> Truncating: silver_country_reference table';
                SET @start_time = GETDATE();

        TRUNCATE TABLE silver_country_reference;

                PRINT '>>> Loading: silver_country_reference table';

	INSERT INTO silver_country_reference
	SELECT
   		UPPER(TRIM(country_code)) as country_code,
    		CASE 
                WHEN UPPER(TRIM(country_name)) = 'UNITED STATES' THEN 'United States'
                WHEN UPPER(TRIM(Country_Name)) = 'UNITED ARAB EMIRATES' THEN 'United Arab Emirates'
                WHEN UPPER(TRIM(Country_Name)) = 'INDIA' THEN 'India'
                WHEN UPPER(TRIM(Country_Name)) = 'GERMANY' THEN 'Germany'
                WHEN UPPER(TRIM(Country_Name)) = 'CANADA' THEN 'Canada'
                WHEN UPPER(TRIM(Country_Name)) = 'AUSTRALIA' THEN 'Australia'
                WHEN UPPER(TRIM(Country_Name)) = 'MEXICO' THEN 'Mexico'
                WHEN UPPER(TRIM(Country_Name)) = 'JAPAN' THEN 'Japan'
                WHEN UPPER(TRIM(Country_Name)) = 'BRAZIL' THEN 'Brazil'
                WHEN UPPER(TRIM(Country_Name)) = 'FRANCE' THEN 'France'
                WHEN UPPER(TRIM(Country_Name)) = 'SINGAPORE' THEN 'Singapore'
                WHEN UPPER(TRIM(Country_Name)) = 'UNITED KINGDOM' THEN 'United Kingdom'
                ELSE UPPER(TRIM(Country_Name))
            END as country_name,
    		CASE UPPER(TRIM(Region))
        		WHEN 'MEA' THEN 'Middle East & Africa'
        		WHEN 'APAC' THEN 'Asia-Pacific'
        		WHEN 'LATAM' THEN 'Latin-America'
        		WHEN 'EU' THEN 'Europe'
        		ELSE Region
    		END as region,
    		Currency as currency,
    		getdate() as import_time
	FROM (SELECT *, ROW_NUMBER() OVER(PARTITION BY country_code ORDER BY Currency DESC) as flag from Bronze_country_reference)t
    WHERE flag = 1;

		SET @end_time = GETDATE();
		PRINT '>>> Loaded: silver_country_reference table';
		PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
		PRINT ' ';

/*
============================================================================================ 
Getting data into the "silver_card_master_system_A" table
==============================================================================================
*/
                PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
                PRINT '>>> Truncating: silver_card_master_system_A table';
                SET @start_time = GETDATE();

        TRUNCATE TABLE silver_card_master_system_A;

                PRINT '>>> Loading: silver_card_master_system_A table';

        INSERT INTO silver_card_master_system_A
        SELECT
            TRIM(Card_id) as card_id,
            CASE UPPER(TRIM(REPLACE(REPLACE(REPLACE(Card_Network, ' ', '<>'), '><', ''), '<>',' ')))
                WHEN 'MERIDIAN PRIMARY' THEN 'Meridian Primary'
                WHEN 'MERIDIAN DIRECT' THEN 'Meridian Direct'
                WHEN 'MERIDIAN AFFILIATE' THEN 'Meridian Affiliate'
                ELSE 'N/A'
               END as card_network,
            Card_Type as card_type,
            CASE TRIM(Segment)
                WHEN 'Consumer' THEN 'Consumer'
                WHEN 'Commercial' THEN 'Commercial'
                ELSE 'N/A'
            END as segment,
            CASE 
                WHEN UPPER(TRIM(REPLACE(REPLACE(REPLACE(Issuer_Bank, ' ', '<>'), '><', ''), '<>',' ')))  
                IN ('N/A', 'UNKNOWN','NULL', '-', 'NONE') THEN 'N/A' 
                ELSE TRIM(REPLACE(REPLACE(REPLACE(Issuer_Bank, ' ', '<>'), '><', ''), '<>',' '))
            END as issuer_bank,
            CASE Issuance_Country
                WHEN 'Australia' THEN 'AU'
                WHEN 'Brazil' THEN 'BR'
                WHEN 'Canada' THEN 'CA'
                WHEN 'France' THEN 'FR'
                WHEN 'Germany' THEN 'DE'
                WHEN 'India' THEN 'IN'
                WHEN 'Japan' THEN 'JP'
                WHEN 'Mexico' THEN 'MX'
                WHEN 'Singapore' THEN 'SG'
                WHEN 'United Arab Emirates' THEN 'AE'
                WHEN 'United Kingdom' THEN 'GB'
                WHEN 'UK' THEN 'GB'
                WHEN 'United States' THEN 'US'
                ELSE TRIM(UPPER(Issuance_Country))
            END as issuance_country,
            -- Tried multiple methods on getting the issue_date column fixed yet unable to get it done hence did use AI to understand the scenario
            -- Below if the solution it gave, except the 'TRY_CONVERT(DATE, Issue_date, 105)" part, 
            -- as ther were still issues and I figured this out from understanding the issue
            CAST(COALESCE(
                TRY_CONVERT(DATE, Issue_date, 105),
                TRY_CAST(Issue_date AS DATE), 
                TRY_CONVERT(DATE, Issue_date, 101),
                TRY_CAST(TRY_CAST(Issue_date AS INT) AS DATETIME),
                TRY_CONVERT(DATE, Issue_date, 112)) AS DATE)
            AS issue_date, -- Will use this for the expiry_date as well
            CAST(COALESCE(
                TRY_CONVERT(DATE, Expiry_Date, 105),
                TRY_CAST(Expiry_Date AS DATE), 
                TRY_CONVERT(DATE, Expiry_Date, 101),
                TRY_CAST(TRY_CAST(TRY_CAST(Expiry_Date AS INT) AS DATETIME) AS Date),
                TRY_CONVERT(DATE, Expiry_Date, 112)) AS DATE)
            AS expiry_date,
            CASE 
                WHEN UPPER(TRIM(Status)) = 'EXPIRED' THEN 'Expired'
                WHEN UPPER(TRIM(Status)) = 'BLOCKED' THEN 'Blocked'
                WHEN CAST(COALESCE(
                    TRY_CONVERT(DATE, Expiry_Date, 105),
                    TRY_CAST(Expiry_Date AS DATE), 
                    TRY_CONVERT(DATE, Expiry_Date, 101),
                    TRY_CAST(TRY_CAST(TRY_CAST(Expiry_Date AS INT) AS DATETIME) AS Date),
                    TRY_CONVERT(DATE, Expiry_Date, 112)) AS DATE) > CAST(getdate() as date) 
                THEN 'Active'
                WHEN CAST(COALESCE(
                    TRY_CONVERT(DATE, Expiry_Date, 105),
                    TRY_CAST(Expiry_Date AS DATE), 
                    TRY_CONVERT(DATE, Expiry_Date, 101),
                    TRY_CAST(TRY_CAST(TRY_CAST(Expiry_Date AS INT) AS DATETIME) AS Date),
                    TRY_CONVERT(DATE, Expiry_Date, 112)) AS DATE) < CAST(getdate() as date)
                THEN 'Inactive'
                ELSE 'N/A'
                END as card_status, 
            source_extract_date,
            getdate() as import_time
        FROM (
            SELECT *, 
            ROW_NUMBER() OVER(PARTITION BY Card_ID ORDER BY(SELECT NULL)) as flag
            FROM Bronze_card_master_system_A)t
        WHERE flag = 1;

		SET @end_time = GETDATE();
		PRINT '>>> Loaded: silver_card_master_system_A table';
		PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
		PRINT ' ';

/*
============================================================================================ 
Getting data into the "silver_card_status_feed" table
==============================================================================================
*/
                PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
                PRINT '>>> Truncating: silver_card_status_feed table';
                SET @start_time = GETDATE();

        TRUNCATE TABLE silver_card_status_feed;

                PRINT '>>> Loading: silver_card_status_feed table';

        INSERT INTO silver_card_status_feed
        SELECT TRIm(card_no) as card_number
              ,network as card_network
              ,CASE WHEN UPPER(TRIM(card_category)) = 'CR' THEN 'Credit'
                  WHEN UPPER(TRIM(card_category)) = 'DB' THEN 'Debit'
                  ELSE 'Prepaid' 
               END AS card_category
              ,CASE WHEN trim(is_active) = 'Y' THEN 'Active'
               ELSE 'Inactive' END AS card_status
              ,CAST(last_updated AS DATE) AS last_updated
              ,getdate() as import_time
        FROM dbo.Bronze_card_status_feed;
		SET @end_time = GETDATE();
		PRINT '>>> Loaded: silver_card_status_feed table';
		PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
		PRINT ' ';

/*
============================================================================================ 
Getting data into the "silver_merchant_incremental" table
==============================================================================================
*/
                PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
                PRINT '>>> Truncating: silver_merchant_incremental table';
                SET @start_time = GETDATE();

        TRUNCATE TABLE silver_merchant_incremental;

                PRINT '>>> Loading: silver_merchant_incremental table';

        INSERT INTO silver_merchant_incremental
        SELECT merchant_id
              ,merchant_name
              ,mcc_code as merchant_code
              ,Case when trim(country) = 'Canada' then 'CA'
                    when trim(country) = 'Germany' then 'DE'
                    when trim(country) = 'United Kingdom' then 'GB'
                    when trim(country) = 'United Arab Emirates' then 'AE'
                    when trim(country) = 'India' then 'IN'
                    Else trim(country)
                END as country_code
              ,channel
              ,CAST(COALESCE(
                TRY_CONVERT(DATE, onboarded_date, 105),
                TRY_CAST(onboarded_date AS DATE), 
                TRY_CONVERT(DATE, onboarded_date, 101),
                TRY_CAST(TRY_CAST(onboarded_date AS INT) AS DATETIME),
                TRY_CONVERT(DATE, onboarded_date, 112)) AS DATE) AS onboarded_date
              ,CASE UPPER(trim(status))
                when 'ACTIVE' then 'Active'
                Else 'Inactive' END as status
             ,getdate() as import_time
        FROM dbo.Bronze_merchant_incremental;

		SET @end_time = GETDATE();
		PRINT '>>> Loaded: silver_merchant_incremental table';
		PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
		PRINT ' ';

/*
============================================================================================ 
Getting data into the "silver_merchant_master" table
==============================================================================================
*/
                PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
                PRINT '>>> Truncating: silver_merchant_master table';
                SET @start_time = GETDATE();

        TRUNCATE TABLE silver_merchant_master;

                PRINT '>>> Loading: silver_merchant_master';

        INSERT INTO silver_merchant_master
        SELECT merchant_id
              ,Merchant_Name as merchant_name
              ,MCC_Code as merchant_code
              , CASE REPLACE(UPPER(TRIM(Country)), '.', '')
                    WHEN 'AUSTRALIA' THEN 'AU'
                    WHEN 'BRAZIL' THEN 'BR'
                    WHEN 'INDIA' THEN 'IN'
                    WHEN 'DEUTSCHLAND' THEN 'DE'
                    WHEN 'CANADA' THEN 'CA'
                    WHEN 'GERMANY' Then 'DE'
                    WHEN 'JAPAN' THEN 'JP'
                    WHEN 'MEXICO' THEN 'MX'
                    WHEN 'SINGAPORE' THEN 'SG'
                    WHEN 'UNITED ARAB EMIRATES' THEN 'AE'
                    WHEN 'UNITED KINGDOM' THEN 'GB'
                    WHEN 'UNITED STATES' THEN 'US'
                    ELSE REPLACE(UPPER(TRIM(Country)), '.', '')
                END as country
              ,TRIM(Channel) as channel
              ,CAST(COALESCE(
                TRY_CONVERT(DATE, onboarded_date, 105),
                TRY_CAST(onboarded_date AS DATE), 
                TRY_CONVERT(DATE, onboarded_date, 101),
                TRY_CAST(TRY_CAST(onboarded_date AS INT) AS DATETIME),
                TRY_CONVERT(DATE, onboarded_date, 112)) AS DATE) AS onboarded_date
              ,CASE UPPER(trim(status))
                when 'ACTIVE' then 'Active'
                Else 'Inactive' END as status
              ,mcc_desc as merchant_description
              ,getdate() as import_time
        FROM 
            (SELECT *, COUNT(merchant_id) OVER(PARTITION BY(merchant_id) ORDER BY(SELECT NULL)) as flag 
            FROM meridian_pay.dbo.Bronze_merchant_master)t
        WHERE flag = 1;
		SET @end_time = GETDATE();
		PRINT '>>> Loaded: silver_merchant_master table';
		PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
		PRINT ' ';


/*
============================================================================================ 
Getting data into the "silver_revenue_amer_apac" table
==============================================================================================
*/
                PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
                PRINT '>>> Truncating: silver_revenue_amer_apac table';
                SET @start_time = GETDATE();

        TRUNCATE TABLE silver_revenue_amer_apac;

                PRINT '>>> Loading: silver_revenue_amer_apac table';

        INSERT INTO silver_revenue_amer_apac
        SELECT month
              ,TRIM(country) as country
              ,CAST(Cross_Border_Fees as float) as cross_border_fees
              ,CAST(Domestic_Assessments as float) as domestic_assessments
              ,CAST(Other_Network_Fees as float) as other_network_fees
              ,CAST(VAS_Cybersecurity as float) as vas_cybersecurity
              ,CAST(VAS_Data_Analytics as float) as vas_data_analytics
              ,CAST(VAS_Fraud_n_Security_Tools as float) as vas_fraud_and_security_tools
              ,CAST(VAS_Open_Banking as float) as vas_open_banking
              ,getdate() as import_time
          FROM meridian_pay.dbo.Bronze_revenue_amer_apac;

		SET @end_time = GETDATE();
		PRINT '>>> Loaded: silver_revenue_amer_apac table';
		PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
		PRINT ' ';

/*
============================================================================================ 
Getting data into the "silver_revenue_emea" table
==============================================================================================
*/
                PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
                PRINT '>>> Truncating: silver_revenue_emea table';
                SET @start_time = GETDATE();

        TRUNCATE TABLE silver_revenue_emea;

                PRINT '>>> Loading: silver_revenue_emea table';

	INSERT INTO silver_revenue_emea
	SELECT CAST('01-' + period as DATE) as month
     		,country_code
      		,CAST(Replace(COALESCE(Cross_Border_Fees,'0.00'),',', '.') as float) as cross_border_fees
      		,CAST(Replace(COALESCE(Domestic_Assessments,'0.00'),',', '.') as float) as domestic_assessments
     		,CAST(Replace(COALESCE(Other_Network_Fees,'0.00'),',', '.') as float) as other_network_fees
     		,CAST(Replace(COALESCE(VAS_Cybersecurity,'0.00'),',', '.') as float) as vas_cybersecurity
      		,CAST(Replace(COALESCE(VAS_Data_Analytics,'0.00'),',', '.') as float) as vas_data_analytics
      		,CAST(Replace(COALESCE(VAS_Fraud_n_Security_Tools,'0.00'),',', '.') as float) as vas_fraud_and_security_tools
      		,CAST(Replace(COALESCE(VAS_Open_Banking,'0.00'),',', '.') as float) as vas_open_banking
      		,getdate() as import_time
	FROM meridian_pay.dbo.Bronze_revenue_emea;

		SET @end_time = GETDATE();
		PRINT '>>> Loaded: silver_revenue_emea table';
		PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
		PRINT ' ';

/*
============================================================================================ 
Getting data into the "silver_transactions_2024H2_2025" table
==============================================================================================
*/
                PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
                PRINT '>>> Truncating: silver_transactions_2024H2_2025 table';
                SET @start_time = GETDATE();

        TRUNCATE TABLE silver_transactions_2024H2_2025;

                PRINT '>>> Loading: silver_transactions_2024H2_2025 table';

	INSERT INTO silver_transactions_2024H2_2025
	SELECT transaction_id
      	,CAST(COALESCE(
        	TRY_CONVERT(DATETIME, txn_datetime, 105),             -- 1. European format (DD-MM-YYYY)
        	TRY_CAST(txn_datetime AS DATETIME),                   -- 2. Standard formats (YYYY-MM-DD)
        	TRY_CONVERT(DATETIME, txn_datetime, 101),             -- 3. US format (MM/DD/YYYY)
        	TRY_CAST(TRY_CAST(txn_datetime AS INT) AS DATETIME),  -- 4. Excel serial dates (days since 1900)
       		TRY_CONVERT(DATETIME, txn_datetime, 112),
        	DATEADD(second, TRY_CAST(txn_datetime AS INT), '1970-01-01 00:00:00')
       ) AS DATETIME) AS transaction_date_time
      ,card_id
      ,merchant_id
      ,card_type
      ,card_country
      ,merchant_country
      ,merchant_name
      ,REPLACE(REPLACE(REPLACE(TRIM(transaction_type), ' ','<>'), '><', ''), '<>',' ') as transaction_type
      ,TRIM(channel) as channel 
      ,CAST(REPLACE(REPLACE(TRIM(amount),'$',''), ',', '') as float) as amount
      ,TRIM(currency) as currency
      ,TRIM(status) as transaction_status
      ,REPLACE(REPLACE(
            (CASE 
                WHEN UPPER(TRIM(is_cross_border)) IN ('N', 'FALSE', 'NO') THEN 0
                WHEN UPPER(TRIM(is_cross_border)) IN ('Y', 'TRUE', 'YES') THEN 1
                ELSE TRIM(is_cross_border)
             END), 0, 'No'), 1,'Yes') as cross_border_transaction
      ,REPLACE(REPLACE(
            (CASE 
                WHEN UPPER(TRIM(is_contactless)) IN ('N', 'FALSE', 'NO') THEN 0
                WHEN UPPER(TRIM(is_contactless)) IN ('Y', 'TRUE', 'YES') THEN 1
                ELSE TRIM(is_contactless)
            END) , 0, 'No'), 1,'Yes') as contactless_transaction
      ,REPLACE(REPLACE(
            (CASE 
                WHEN UPPER(TRIM(is_tokenized)) IN ('N', 'FALSE', 'NO') THEN 0
                WHEN UPPER(TRIM(is_tokenized)) IN ('Y', 'TRUE', 'YES') THEN 1
                ELSE TRIM(is_tokenized)
            END) , 0, 'No'), 1,'Yes') as tokenized_transaction
      ,CAST(switch_msg_count as INT) as switch_message_count
      ,REPLACE(REPLACE(
            (CASE 
                WHEN UPPER(TRIM(is_fraud)) IN ('N', 'FALSE', 'NO') THEN 0
                WHEN UPPER(TRIM(is_fraud)) IN ('Y', 'TRUE', 'YES') THEN 1
                ELSE TRIM(is_fraud)
            END) , 0, 'No'), 1,'Yes') as fraudulent_transaction
      ,CAST(fraud_amt as float) as fraudulent_amount
      ,source_system
      ,CAST(ingested_at as datetime) as ingestion_date_time
      ,CAST(Unnamed as INT) as Unknown
      ,getdate() as import_time
	FROM(
    		SELECT *,
        	ROW_NUMBER() OVER(PARTITION BY transaction_id ORDER BY(SELECT NULL)) as rownum
    		FROM meridian_pay.dbo.Bronze_transactions_2024H2_2025)t
	WHERE rownum !>1;

		SET @end_time = GETDATE();
		PRINT '>>> Loaded: silver_transactions_2024H2_2025 table';
		PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
		PRINT ' ';

/*
============================================================================================ 
Getting data into the "silver_transactions_legacy_2024H1" table
==============================================================================================
*/
                PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
                PRINT '>>> Truncating: silver_transactions_legacy_2024H1 table';
                SET @start_time = GETDATE();

        TRUNCATE TABLE silver_transactions_legacy_2024H1;

                PRINT '>>> Loading: silver_transactions_legacy_2024H1 table';

        INSERT INTO silver_transactions_legacy_2024H1
        SELECT TRIM(TXN_ID) as transaction_id
              ,CAST(COALESCE(
                TRY_CONVERT(DATETIME, TXN_DATE, 105),
                TRY_CAST(TXN_DATE AS DATETIME), 
                TRY_CONVERT(DATETIME, TXN_DATE, 101),
                TRY_CAST(TRY_CAST(TXN_DATE AS INT) AS DATETIME),
                TRY_CONVERT(DATETIME, TXN_DATE, 112)) AS DATETIME)
            AS transaction_date
              ,TRIM(CARD_NO) as card_number
              ,TRIM(MERCH_ID) as merchant_id
              ,CASE REPLACE(REPLACE(REPLACE(TRIM(TYPE), ' ', '<>'), '><', ''), '<>', ' ') 
              WHEN 'PURCHASE' THEN 'Purchase'
              WHEN 'BALANCE TRANSFER' THEN 'Balance Transfer'
              WHEN 'ATM WITHDRAWAL' THEN 'ATM Withdrawal'
              ELSE 'Cash Advance' END
              as transaction_type
              ,CAST(REPLACE(REPLACE(amt,'$', ''), ',', '') as float) as transaction_amount
              ,TRIM(CCY) as currency
              ,CASE
                WHEN STATUS = 'A' THEN 'Approved'
                ELSE 'Declined'
               END as card_status
              ,CASE WHEN FLAG_INTL = 0 THEN 'No' ELSE 'Yes' END as international_transaction
              ,getdate() as import_date
        FROM (
		SELECT *,
                ROW_NUMBER() OVER(PARTITION BY TXN_ID ORDER BY(SELECT NULL)) as rownum
            	FROM meridian_pay.dbo.Bronze_transactions_legacy_2024H1)t
        WHERE rownum !>1;

		SET @end_time = GETDATE();
		PRINT '>>> Loaded: silver_transactions_legacy_2024H1 table';
		PRINT '>>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*';
		PRINT ' ';
        PRINT ' ';
        SET @batch_end_time = GETDATE();
        PRINT '===================================================';
        PRINT 'Successfully fetched silver layer, have a good day';
        PRINT '>>> SILVER Layer Load Duration ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '===================================================';
    END TRY
    BEGIN CATCH 
        PRINT 'X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-';
        PRINT 'An Error Occured During the load of silver layer';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR)
        PRINT 'X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-X-';
    END CATCH
END;
