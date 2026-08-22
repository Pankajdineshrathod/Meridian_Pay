/* This query creates all the tables in the bronze layer of the DWH*/

-- Creating the "api_logs" table
IF OBJECT_ID ('bronze_api_logs', 'U') IS NOT NULL
    DROP TABLE Bronze_api_logs;
        PRINT '----****----';
        PRINT 'Handling: Bronze_api_logs';
        PRINT '----****----';
CREATE TABLE Bronze_api_logs (
    log_id INT,
    period DATETIME2,
    bank_name VARCHAR(255),
    integration_type VARCHAR(100),
    total_calls INT,
    successful_calls INT,
    failed_calls INT,
    avg_response_time_ms DECIMAL(6, 2),
    source_system VARCHAR(100),
    extracted_at DATETIME2
);


--====================================================================================================

-- Creating the "system_incidents" table
IF OBJECT_ID ('bronze_system_incidents', 'U') IS NOT NULL
    DROP TABLE Bronze_system_incidents;
        PRINT '----****----';
        PRINT 'Handling: Bronze_system_incidents';
        PRINT '----****----';
CREATE TABLE Bronze_system_incidents (
    incident_id NVARCHAR(20),
    component NVARCHAR(50),
    start_ts DATETIME2,
    end_ts DATETIME2,
    duration_minutes DECIMAL(6,1),
    severity VARCHAR(20),
    ticket_id NVARCHAR(20)
);

--====================================================================================================

-- Creating the "company_financials" table
IF OBJECT_ID ('bronze_company_financials', 'U') IS NOT NULL
    DROP TABLE Bronze_company_financials;
        PRINT '----****----';
        PRINT 'Handling: Bronze_company_financials';
        PRINT '----****----';
CREATE TABLE Bronze_company_financials (
    Month_Year NVARCHAR(20),
    Gross_Revenue_USD DECIMAL(10,2),
    Rebates_Incentives_USD DECIMAL(10,2),
    Operating_Income_USD DECIMAL(10,2)
);

--====================================================================================================

-- Creating the "country_reference" table
IF OBJECT_ID ('bronze_country_reference', 'U') IS NOT NULL
    DROP TABLE Bronze_country_reference;
        PRINT '----****----';
        PRINT 'Handling: Bronze_country_reference';
        PRINT '----****----';
CREATE TABLE Bronze_country_reference (
    country_code VARCHAR(4),
    Country_Name NVARCHAR(50),
    Region NVARCHAR(30),
    Currency VARCHAR(10)
);

--====================================================================================================

-- Creating the "card_master_system_A" table
IF OBJECT_ID ('bronze_card_master_system_A', 'U') IS NOT NULL
    DROP TABLE Bronze_card_master_system_A;
        PRINT '----****----';
        PRINT 'Handling: Bronze_card_master_system_A';
        PRINT '----****----';
CREATE TABLE Bronze_card_master_system_A (
    Card_ID NVARCHAR(20),
    Card_Network NVARCHAR(20),
    Card_Type NVARCHAR(20),
    Segment NVARCHAR(20),
    Issuer_Bank NVARCHAR(255),
    Issuance_Country NVARCHAR(20),
    Issue_Date NVARCHAR(20),
    [Expiry_Date] NVARCHAR(20),
    [Status] NVARCHAR(20), 
    source_extract_date DATE
);

--====================================================================================================  

-- Creating the "card_status_feed" table
IF OBJECT_ID ('bronze_card_status_feed', 'U') IS NOT NULL
    DROP TABLE Bronze_card_status_feed;
        PRINT '----****----';
        PRINT 'Handling: Bronze_card_status_feed';
        PRINT '----****----';
CREATE TABLE Bronze_card_status_feed (
    card_no NVARCHAR(30),
    is_active NVARCHAR(10),
    card_category NVARCHAR(10),
    network NVARCHAR(50),
    last_updated DATETIME2
);

--==================================================================================================== 

-- Creating the "merchant_incremental" table
IF OBJECT_ID ('bronze_merchant_incremental', 'U') IS NOT NULL
    DROP TABLE Bronze_merchant_incremental;
        PRINT '----****----';
        PRINT 'Handling: Bronze_merchant_incremental';
        PRINT '----****----';
CREATE TABLE Bronze_merchant_incremental (
    merchant_id NVARCHAR(20),
    merchant_name NVARCHAR(100),
    mcc_code INT,
    country NVARCHAR(20),
    channel NVARCHAR(20),
    onboarded_date NVARCHAR(20),
    [status] NVARCHAR(20)
);

--==================================================================================================== 

-- Creating the "merchant_master" table
IF OBJECT_ID ('bronze_merchant_master', 'U') IS NOT NULL
    DROP TABLE Bronze_merchant_master;
        PRINT '----****----';
        PRINT 'Handling: Bronze_merchant_master';
        PRINT '----****----';
CREATE TABLE Bronze_merchant_master (
    merchant_id NVARCHAR(20),
    Merchant_Name NVARCHAR(50),
    MCC_Code INT,
    mcc_desc NVARCHAR(100),
    Country NVARCHAR(20),
    Channel NVARCHAR(20),
    Onboarded_Date NVARCHAR(20),
    [Status] NVARCHAR(20)
);

--====================================================================================================

-- Creating the "revenue_amer_apac" table
IF OBJECT_ID ('bronze_revenue_amer_apac', 'U') IS NOT NULL
    DROP TABLE Bronze_revenue_amer_apac;
        PRINT '----****----';
        PRINT 'Handling: Bronze_revenue_amer_apac';
        PRINT '----****----';
CREATE TABLE Bronze_revenue_amer_apac (
    [month] DATE,
    country NVARCHAR(20),
    Cross_Border_Fees DECIMAL(6,2),
    Domestic_Assessments DECIMAL(6,2),
    Other_Network_Fees DECIMAL(6,2),
    VAS_Cybersecurity DECIMAL(6,2),
    VAS_Data_Analytics DECIMAL(6,2),
    VAS_Fraud_n_Security_Tools DECIMAL(6,2),
    VAS_Open_Banking DECIMAL(6,2)
);

--====================================================================================================

-- Creating the "revenue_emea" table
IF OBJECT_ID ('bronze_revenue_emea', 'U') IS NOT NULL
    DROP TABLE Bronze_revenue_emea;
        PRINT '----****----';
        PRINT 'Handling: Bronze_revenue_emea';
        PRINT '----****----';
CREATE TABLE Bronze_revenue_emea (
    [period] NVARCHAR(20),
    country_code NVARCHAR(20),
    Cross_Border_Fees NVARCHAR(6),
    Domestic_Assessments NVARCHAR(6),
    Other_Network_Fees NVARCHAR(6),
    VAS_Cybersecurity NVARCHAR(6),
    VAS_Data_Analytics NVARCHAR(6),
    VAS_Fraud_n_Security_Tools NVARCHAR(6),
    VAS_Open_Banking NVARCHAR(6)
);

--====================================================================================================

-- Creating the "transactions_2024H2_2025" table
IF OBJECT_ID ('bronze_transactions_2024H2_2025', 'U') IS NOT NULL
    DROP TABLE Bronze_transactions_2024H2_2025;
        PRINT '----****----';
        PRINT 'Handling: Bronze_transactions_2024H2_2025';
        PRINT '----****----';
CREATE TABLE Bronze_transactions_2024H2_2025 (
    transaction_id NVARCHAR(20),
    txn_datetime VARCHAR(30),
    card_id NVARCHAR(20),
    merchant_id NVARCHAR(20),
    card_type NVARCHAR(20),
    card_country NVARCHAR(20),
    merchant_country NVARCHAR(20),
    merchant_name NVARCHAR(100),
    transaction_type NVARCHAR(20),
    channel NVARCHAR(20),
    amount NVARCHAR(10),
    currency NVARCHAR(20),
    [status] NVARCHAR(20),
    is_cross_border NVARCHAR(10),
    is_contactless NVARCHAR(10),
    is_tokenized NVARCHAR(10),
    switch_msg_count NVARCHAR(10),
    is_fraud NVARCHAR(10),
    fraud_amt NVARCHAR(10),
    source_system NVARCHAR(100),
    ingested_at NVARCHAR(100),
    Unnamed NVARCHAR(max)
);

--====================================================================================================

-- Creating the "transactions_legacy_2024H1" table
IF OBJECT_ID ('bronze_transactions_legacy_2024H1', 'U') IS NOT NULL
    DROP TABLE Bronze_transactions_legacy_2024H1;
        PRINT '----****----';
        PRINT 'Handling: Bronze_transactions_legacy_2024H1';
        PRINT '----****----';
CREATE TABLE Bronze_transactions_legacy_2024H1(
   TXN_ID NVARCHAR(20),
   TXN_DATE NVARCHAR(20),
   CARD_NO NVARCHAR(20),
   MERCH_ID NVARCHAR(20),
   [TYPE] NVARCHAR(20),
   AMT NVARCHAR(20),
   CCY NVARCHAR(20),
   [STATUS] NVARCHAR(20),
   FLAG_INTL NVARCHAR(10)
);

--====================================================================================================
