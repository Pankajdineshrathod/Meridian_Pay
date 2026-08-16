/* =====================================================================================
   Layer: Gold (Presentation / Consumption Layer)
   Description:
     This script creates the business-ready Gold layer views based on the cleansed 
     and conformed Silver layer tables. These views serve as the final dimensional 
     models (Star Schema) for BI reporting, dashboards, and downstream analytics.

   Key Transformations & Business Logic:
     - DIM_CARDS: Merges System A master data with the status feed using a FULL JOIN, 
                  applying COALESCE for data survivorship. Calculates expiry dates.
     - DIM_MERCHANTS: Direct projection of curated silver merchant master data.
     - DIM_COUNTRIES: Introduces derived business logic mapping regions to EMEA/APAC zones.
     - FACT_API_LOGS: Cleans and standardizes log metrics.
     - FACT_INCIDENTS: Derives new calculated metrics (uptime_in_minutes, downtime_in_minutes) 
                       based on a standard 1440-minute day.
     - FACT_FINANCIAL_TOTAL: Standardizes column naming conventions.
     - FACT_REVENUE: Unified global view created by UNIONing AMER/APAC and EMEA regional tables.
     - FACT_TRANSACTIONS: Integrates historical (legacy 2024H1) and current (2024H2-2025) 
                          transactions via UNION ALL, padding missing legacy fields with defaults.
   ===================================================================================== */

-- Cards_view(DIM)

    CREATE VIEW gold_dim_cards AS
    WITH card_merge AS(
        SELECT a.card_id as card_id_a
              ,b.card_number as card_id_b
              ,NULLIF(a.card_network, 'N/A') as card_network_a
              ,b.card_network as card_network_b
              ,a.card_type as card_type_a
              ,b.card_category as card_type_b
              ,a.segment
              ,a.issuer_bank
              ,a.issuance_country
              ,a.issue_date
              ,a.expiry_date
              ,a.card_status as card_status_a
              ,b.card_status as card_status_b
              ,a.source_extract_date as last_updated_date_a
              ,b.last_updated as last_updated_date_b
        FROM dbo.silver_card_master_system_A as a
        FULL JOIN dbo.silver_card_status_feed as b
        ON a.card_id = b.card_number)
    SELECT      -- We are going to prioritize table_a as it has latest data(source_extract_date is newer than last_update_date in table_b)
         COALESCE(card_id_a, card_id_b) as card_id
        ,COALESCE(segment, 'N/A') as user_segment
        ,COALESCE(card_type_a, card_type_b) as card_type
        ,COALESCE(card_network_a, card_network_b, 'N/A') as card_network
        ,COALESCE(issuance_country, 'N/A') as issuance_country
        ,COALESCE(issuer_bank, 'N/A') as issuer_bank
        ,COALESCE(card_status_a, card_status_b, 'Closed') as card_status
        ,COALESCE(issue_date, '2023-01-01') as issue_date                -- Upon clarifying the stakeholders(me) it came out that these cards were issued on 1st january 2023 and are valid for 4 years
        ,COALESCE(expiry_date, CAST(DATEADD(year, 4, '2023-01-01') as date)) as expiry_date   
    FROM card_merge;


-- Merchants_view(DIM)

    CREATE VIEW gold_dim_merchants AS
    SELECT merchant_id
          ,merchant_code
          ,Merchant_name as merchant_name
          ,merchant_description
          ,country as country_code
          ,channel
          ,onboarded_date
          ,status
    FROM dbo.silver_merchant_master;

-- Country_View(DIM)

    CREATE VIEW gold_dim_countries AS
    SELECT country_code
          ,country_name
          ,currency
          ,region
          ,CASE WHEN region IN ('Middle East & Africa','Europe') THEN 'EMEA' ELSE 'APAC' END as zone
    FROM dbo.silver_country_reference;

-- API_Logs_View(FACT)

    CREATE VIEW gold_fact_api_logs AS
    SELECT log_id
          ,record_date
          ,bank_name
          ,integration_api
          ,total_api_calls
          ,successful_api_calls
          ,failed_api_calls
          ,average_response_time
    FROM dbo.silver_api_logs;

-- System_incidents_view(FACT)

    CREATE VIEW gold_fact_incidents AS
    SELECT incident_id
          ,ticket_id
          ,severity
          ,component
          ,start_time
          ,end_time
          ,1440 as total_time
          ,(1440 - duration_in_minutes) as uptime_in_minutes
          ,duration_in_minutes as downtime_in_minutes
      FROM dbo.silver_system_incidents;

-- financial_total_view(FACT)

    CREATE VIEW gold_fact_financial_total AS
    SELECT month_year as period
          ,Gross_Revenue_USD as gross_revenue_USD
          ,Rebates_Incentives_USD as rebates_and_incentives_USD
          ,Operating_Income_USD as operating_income_USD
    FROM dbo.silver_company_financials;

-- Revenue_view(FACT)

    CREATE VIEW gold_fact_revenue AS
    SELECT month as period
          ,country
          ,cross_border_fees
          ,domestic_sssessments
          ,other_network_fees
          ,vas_cybersecurity
          ,vas_data_analytics
          ,vas_fraud_and_security_tools
          ,vas_open_banking
    FROM dbo.silver_revenue_amer_apac
    UNION ALL 
    SELECT month
          ,country
          ,cross_border_fees
          ,domestic_assessments
          ,other_network_fees
          ,vas_cybersecurity
          ,vas_data_analytics
          ,vas_fraud_and_security_tools
          ,vas_open_banking
    FROM dbo.silver_revenue_emea;

-- Transactions_View(FACT)

    CREATE VIEW gold_fact_transactions AS    
    SELECT transaction_id
          ,transaction_datetime
          ,card_id
          ,merchant_id
          ,channel
          ,transaction_type
          ,amount
          ,currency
          ,transaction_status
          ,cross_border_transaction
          ,contactless_transaction
          ,tokenized_transaction
          ,switch_message_count
          ,fraudulent_transaction
          ,fraudulent_amount
    FROM dbo.silver_transactions_2024H2_2025
    UNION ALL
    SELECT transaction_id
          ,transaction_date
          ,card_number
          ,merchant_id
          ,'N/A' as channel
          ,transaction_type
          ,transaction_amount
          ,currency
          ,card_status
          ,international_transaction
          ,'N/A' as contactless
          ,'N/A' as tokenized
          ,0 as switch
          ,'N/A' as fraud_flag
          ,0 as fraud_amt
    FROM dbo.silver_transactions_legacy_2024H1;
