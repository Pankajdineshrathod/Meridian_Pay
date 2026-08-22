/*
=============================================================================================
SILVER LAYER
This query creates all the tables with desired data-types for the Silver Layer of the DWH
=============================================================================================
*/

-- Creating the "api_logs" table
IF OBJECT_ID ('silver_api_logs', 'U') IS NOT NULL
    DROP TABLE silver_api_logs;
        PRINT '----****----';
        PRINT 'Handling: silver_api_logs';
        PRINT '----****----';
CREATE TABLE silver_api_logs (
       log_id INT
      ,record_date DATE
      ,bank_name NVARCHAR(100)
      ,integration_api NVARCHAR(20)
      ,total_api_calls INT
      ,successful_api_calls INT
      ,failed_api_calls INT
      ,average_response_time DECIMAL(6,2)
      ,source_system NVARCHAR(50)
      ,extraction_date DATE
      ,import_time DATETIME
);


--====================================================================================================

-- Creating the "system_incidents" table
IF OBJECT_ID ('silver_system_incidents', 'U') IS NOT NULL
    DROP TABLE silver_system_incidents;
        PRINT '----****----';
        PRINT 'Handling: silver_system_incidents';
        PRINT '----****----';
CREATE TABLE silver_system_incidents (
    incident_id NVARCHAR(20),
    component NVARCHAR(50),
    start_time DATETIME2,
    end_time DATETIME2,
    duration_in_minutes DECIMAL(6,2),
    severity NVARCHAR(20),
    ticket_id NVARCHAR(20),
    import_time DATETIME
);

--====================================================================================================

-- Creating the "company_financials" table
IF OBJECT_ID ('silver_company_financials', 'U') IS NOT NULL
    DROP TABLE silver_company_financials;
        PRINT '----****----';
        PRINT 'Handling: silver_company_financials';
        PRINT '----****----';
CREATE TABLE silver_company_financials (
    month_year DATE,
    Gross_Revenue_USD DECIMAL(10,2),
    Rebates_Incentives_USD DECIMAL(10,2),
    Operating_Income_USD DECIMAL(10,2),
    import_time DATETIME
);

--====================================================================================================

-- Creating the "country_reference" table
IF OBJECT_ID ('silver_country_reference', 'U') IS NOT NULL
    DROP TABLE silver_country_reference;
        PRINT '----****----';
        PRINT 'Handling: silver_country_reference';
        PRINT '----****----';
CREATE TABLE silver_country_reference (
    country_code VARCHAR(2),
    country_name NVARCHAR(50),
    region NVARCHAR(30),
    currency VARCHAR(10),
    import_time DATETIME
);

--====================================================================================================

-- Creating the "card_master_system_A" table
IF OBJECT_ID ('silver_card_master_system_A', 'U') IS NOT NULL
    DROP TABLE silver_card_master_system_A;
        PRINT '----****----';
        PRINT 'Handling: silver_card_master_system_A';
        PRINT '----****----';
CREATE TABLE silver_card_master_system_A (
    card_id NVARCHAR(20),
    card_network NVARCHAR(20),
    card_type NVARCHAR(20),
    segment NVARCHAR(20),
    issuer_bank NVARCHAR(100),
    issuance_country NVARCHAR(2),
    issue_date DATE,
    expiry_date DATE,
    card_status NVARCHAR(20), 
    source_extract_date DATE,
    import_time DATETIME
);

--====================================================================================================  

-- Creating the "card_status_feed" table
IF OBJECT_ID ('silver_card_status_feed', 'U') IS NOT NULL
    DROP TABLE silver_card_status_feed;
        PRINT '----****----';
        PRINT 'Handling: silver_card_status_feed';
        PRINT '----****----';
CREATE TABLE silver_card_status_feed (
    card_number NVARCHAR(30),
    card_network NVARCHAR(50),
    card_category NVARCHAR(20),
    card_status NVARCHAR(10),
    last_updated DATE,
    import_time DATETIME
);

--==================================================================================================== 

-- Creating the "merchant_incremental" table
IF OBJECT_ID ('silver_merchant_incremental', 'U') IS NOT NULL
    DROP TABLE silver_merchant_incremental;
        PRINT '----****----';
        PRINT 'Handling: silver_merchant_incremental';
        PRINT '----****----';
CREATE TABLE silver_merchant_incremental (
    merchant_id NVARCHAR(20),
    merchant_name NVARCHAR(100),
    merchant_code INT,
    country_code NVARCHAR(2),
    channel NVARCHAR(20),
    onboarded_date DATE,
    [status] NVARCHAR(20),
    import_time DATETIME
);

--==================================================================================================== 

-- Creating the "merchant_master" table
IF OBJECT_ID ('silver_merchant_master', 'U') IS NOT NULL
    DROP TABLE silver_merchant_master;
        PRINT '----****----';
        PRINT 'Handling: silver_merchant_master';
        PRINT '----****----';
CREATE TABLE silver_merchant_master (
    merchant_id NVARCHAR(20),
    Merchant_name NVARCHAR(50),
    merchant_code INT,
    country NVARCHAR(2),
    channel NVARCHAR(20),
    onboarded_date DATE,
    [status] NVARCHAR(20),
    merchant_description NVARCHAR(100),
    import_time DATETIME
);


--====================================================================================================

-- Creating the "revenue_amer_apac" table
IF OBJECT_ID ('silver_revenue_amer_apac', 'U') IS NOT NULL
    DROP TABLE silver_revenue_amer_apac;
        PRINT '----****----';
        PRINT 'Handling: silver_revenue_amer_apac';
        PRINT '----****----';
CREATE TABLE silver_revenue_amer_apac (
    [month] DATE,
    country NVARCHAR(2),
    cross_border_fees float,
    domestic_sssessments float,
    other_network_fees float,
    vas_cybersecurity float,
    vas_data_analytics float,
    vas_fraud_and_security_tools float,
    vas_open_banking float,
    import_time DATETIME
);

--====================================================================================================

-- Creating the "revenue_emea" table
IF OBJECT_ID ('silver_revenue_emea', 'U') IS NOT NULL
    DROP TABLE silver_revenue_emea;
        PRINT '----****----';
        PRINT 'Handling: silver_revenue_emea';
        PRINT '----****----';
CREATE TABLE silver_revenue_emea (
    [month] DATE,
    country NVARCHAR(2),
    cross_border_fees float,
    domestic_assessments float,
    other_network_fees float,
    vas_cybersecurity float,
    vas_data_analytics float,
    vas_fraud_and_security_tools float,
    vas_open_banking float,
    import_time DATETIME
);

--====================================================================================================

-- Creating the "transactions_2024H2_2025" table
IF OBJECT_ID ('silver_transactions_2024H2_2025', 'U') IS NOT NULL
    DROP TABLE silver_transactions_2024H2_2025;
        PRINT '----****----';
        PRINT 'Handling: silver_transactions_2024H2_2025';
        PRINT '----****----';
CREATE TABLE silver_transactions_2024H2_2025 (
    transaction_id NVARCHAR(20),
    transaction_datetime DATETIME,
    card_id NVARCHAR(20),
    merchant_id NVARCHAR(20),
    card_type NVARCHAR(20),
    card_country NVARCHAR(2),
    merchant_country NVARCHAR(2),
    merchant_name NVARCHAR(100),
    transaction_type NVARCHAR(20),
    channel NVARCHAR(20),
    amount float,
    currency varchar(3),
    transaction_status NVARCHAR(20),
    cross_border_transaction NVARCHAR(10),
    contactless_transaction NVARCHAR(10),
    tokenized_transaction NVARCHAR(10),
    switch_message_count INT,
    fraudulent_transaction NVARCHAR(10),
    fraudulent_amount float,
    source_system NVARCHAR(100),
    ingestion_date_time NVARCHAR(100),
    Unknown NVARCHAR(max),
    import_time DATETIME
);

--====================================================================================================

-- Creating the "transactions_legacy_2024H1" table
IF OBJECT_ID ('silver_transactions_legacy_2024H1', 'U') IS NOT NULL
    DROP TABLE silver_transactions_legacy_2024H1;
        PRINT '----****----';
        PRINT 'Handling: silver_transactions_legacy_2024H1';
        PRINT '----****----';
CREATE TABLE silver_transactions_legacy_2024H1(
   transaction_id NVARCHAR(20),
   transaction_date DATETIME,
   card_number NVARCHAR(20),
   merchant_id NVARCHAR(20),
   transaction_type NVARCHAR(20),
   transaction_amount float,
   currency varchar(3),
   card_status NVARCHAR(20),
   international_transaction NVARCHAR(10),
   import_time DATETIME
);

--====================================================================================================
