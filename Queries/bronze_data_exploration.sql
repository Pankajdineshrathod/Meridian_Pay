/*
===============================================================================
BRONZE LAYER DATA QUALITY CHECKS
===============================================================================

This file lists out all the issues with the tables in the "Bronze Layer" where 
we imported the data as-is from the source. Incorrect data types may not be 
listed everywhere but all have been taken care of. At some places, the tests 
listed might not be exhaustive, but all known tests related to data types were 
performed. Any relevant test in one table for one column was also performed 
for all others with the same data type.

Common Issues:
-------------
* Incorrect data types (imported as-is; attached whatever data-type could handle the import)
* Incorrect separators due to "quoted fields"
* Duplicate entries
* Multiple values depicting the same thing ('Yes', 'Y', 1, etc.)
* Unnecessary/unwanted spaces - before, after, and in-between words
* Non-uniform and incorrect naming conventions

I WILL BE LISTING THE ISSUES TABLE-BY-TABLE HERE.

***********************
Queries used for issues
***********************

1. Duplicates in PKs:
    SELECT column_name, COUNT(column_name) as flag 
    FROM table_name 
    GROUP BY column_name 
    HAVING COUNT(column_name) > 1;

*/

/*============================================
  1. bronze_api_logs table
============================================*/
    -- Loading the table to understand the content
    SELECT * FROM Bronze_api_logs;

    -- Checking "log_id" (INT) -- *The data type in brackets is the current data type
    --------------------------------------------------
        -- Nulls
        SELECT COUNT(*) as total_count, 
               COUNT(log_id) as id_count 
        FROM Bronze_api_logs;                            -- No nulls (both 1152)

        -- Duplicate values        
        SELECT log_id, COUNT(log_id) as flag 
        FROM Bronze_api_logs 
        GROUP BY log_id 
        HAVING COUNT(log_id) > 1;                        -- No duplicates

    -- Checking "period" (datetime2) 
    --------------------------------------------------
        -- Time values 
        SELECT period
        FROM Bronze_api_logs
        WHERE period != DATETRUNC(day, period);          -- No time values

    -- Checking "bank_name" (VARCHAR(255)) 
    --------------------------------------------------
        -- Extra leading/trailing Spaces
        SELECT bank_name
        FROM Bronze_api_logs
        WHERE LEN(bank_name) != LEN(TRIM(bank_name));    -- No leading/trailing extra spaces found 

        -- Max length as of now
        SELECT MAX(LEN(bank_name)) 
        FROM bronze_api_logs;                            -- 23, the maxlength can be changed to "50"

    -- Checking "integration_type" (varchar(100)) 
    --------------------------------------------------
        -- Distinct values, seems low cardinality
        SELECT DISTINCT integration_type 
        FROM Bronze_api_logs;                            -- Same type, different values

    -- Checking "total_calls" (INT) 
    --------------------------------------------------
        -- NULLS
        SELECT COUNT(*) as total_rows,
               COUNT(total_calls) as call_count
        FROM Bronze_api_logs;                            -- No nulls (both 1152)

        -- Correct totals
        SELECT total_calls, 
               (successful_calls + failed_calls) as sum_total
        FROM Bronze_api_logs;                            -- There are incorrect totals

    -- Checking "successful_calls" (INT) 
    --------------------------------------------------
        -- NULLS
        SELECT COUNT(*) as total_rows,
               COUNT(successful_calls) as success_call_count
        FROM Bronze_api_logs;                            -- No nulls (both 1152)

    -- Checking "failed_calls" (INT) 
    --------------------------------------------------
        -- NULLS
        SELECT COUNT(*) as total_rows,
               COUNT(failed_calls) as call_count
        FROM Bronze_api_logs;                            -- No nulls (both 1152)

    -- Checking "source_system" (VARCHAR(100)) 
    --------------------------------------------------
        -- NULLS: It has nulls in first few rows only. Cannot be fixed, leaving as-is.
        -- Leading/trailing spaces
        SELECT source_system
        FROM Bronze_api_logs
        WHERE LEN(source_system) != LEN(TRIM(source_system)); -- No leading/trailing spaces

    -- Checking "extracted_at" (datetime2) 
    --------------------------------------------------
        -- No need to check this, date and time are both visible in the first rows 
        -- and there are nulls parallel to source_system (cannot be fixed).


/*============================================
  2. bronze_system_incidents table
============================================*/
    -- Loading the table to understand the content
    SELECT * FROM Bronze_system_incidents;

    -- Checking "incident_id" (NVARCHAR(20)) 
    --------------------------------------------------
        -- Nulls
        SELECT COUNT(*) as total_count, 
               COUNT(incident_id) as id_count 
        FROM Bronze_system_incidents;                    -- No nulls (both 1152)

        -- Duplicate values        
        SELECT incident_id, COUNT(incident_id) as flag 
        FROM Bronze_system_incidents
        GROUP BY incident_id 
        HAVING COUNT(incident_id) > 1;                   -- No duplicates

    -- Checking "component" (nvarchar(50)) 
    --------------------------------------------------
        -- Distinct values, seems low cardinality
        SELECT DISTINCT component 
        FROM Bronze_system_incidents;                    -- Same type, different values

        -- Leading/trailing spaces
        SELECT component
        FROM Bronze_system_incidents
        WHERE LEN(component) != LEN(TRIM(component));    -- No leading/trailing spaces

    -- Checking "start_ts" (datetime2) and "end_ts" (datetime2)
    --------------------------------------------------
        -- No issues as the values have both date and time
        -- NULLS 
        SELECT COUNT(*) as total_rows,
               COUNT(start_ts) as total_ts_count
        FROM Bronze_system_incidents;                    -- No nulls (both 84)

        SELECT COUNT(*) as total_rows,
               COUNT(end_ts) as total_ts_count
        FROM Bronze_system_incidents;                    -- No nulls (both 84)

    -- Checking "duration_minutes" (decimal(6,2)) 
    --------------------------------------------------
        -- NULLS
        SELECT COUNT(*) as total_rows,
               COUNT(duration_minutes) as total_ts_count
        FROM Bronze_system_incidents;                    -- No nulls (both 84)

        -- Incorrect calculations
        SELECT duration_minutes,
               (1.0 * (DATEDIFF(SECOND, start_ts, end_ts))) / 60 as calculated_duration
        FROM Bronze_system_incidents
        WHERE duration_minutes != (1.0 * (DATEDIFF(SECOND, start_ts, end_ts))) / 60;  -- There are some incorrect entries

    -- Checking "severity" (varchar(20)) 
    --------------------------------------------------
        -- Distinct value, low cardinality
        SELECT DISTINCT severity 
        FROM Bronze_system_incidents;                    -- No overlapping values

    -- Checking "ticket_id" (NVARCHAR(20)) 
    --------------------------------------------------
        -- NULLS
        SELECT COUNT(*) as total_count,
               COUNT(ticket_id) as ticket_id_count
        FROM Bronze_system_incidents;                    -- There are nulls, maybe tickets were not filed for these incidents (N/A)
        
        -- Duplicates
        SELECT ticket_id, COUNT(ticket_id) as flag
        FROM Bronze_system_incidents
        GROUP BY ticket_id
        HAVING COUNT(ticket_id) > 1;                     -- No duplicates


/*============================================
  3. bronze_company_financials table
============================================*/
    -- Loading the table to understand the content
    SELECT * FROM Bronze_company_financials;

    -- Checking "Month_Year" (NVARCHAR(20)) 
    --------------------------------------------------
        -- Distinct values
        SELECT DISTINCT Month_Year 
        FROM Bronze_company_financials;                  -- The data type needs to be changed

        -- Rest of the columns seem correct in all senses


/*============================================
  4. bronze_country_reference table
============================================*/
    -- Loading the table to understand the content
    SELECT * FROM Bronze_country_reference;

    -- Checking "country_code" (varchar(4)) 
    --------------------------------------------------
        -- DISTINCT
        SELECT DISTINCT(country_code) as CCC 
        FROM Bronze_country_reference;                   -- Needs trimming and upper function

    -- Checking "Country_Name" (NVARCHAR(50)) 
    --------------------------------------------------
        -- DISTINCT
        SELECT DISTINCT(Country_Name) as CCC 
        FROM Bronze_country_reference;                   -- All seems fine

    -- Checking "region" (NVARCHAR(50)) 
    --------------------------------------------------
        -- Distinct
        SELECT DISTINCT(Region) as CCC 
        FROM Bronze_country_reference;                   -- Short and long forms both used, needs to be standardized

    -- Checking "currency" (varchar(10)) 
    --------------------------------------------------
        -- Nulls
        SELECT COUNT(*) as total_rows, 
               COUNT(currency) as total_entries
        FROM Bronze_country_reference;                   -- There is a Null value
        
        -- Distinct
        SELECT DISTINCT currency 
        FROM Bronze_country_reference;                   -- Everything looks good except a null value


/*============================================
  5. bronze_card_master_system_A table
============================================*/
    -- Loading the table to understand the content
    SELECT * FROM Bronze_card_master_system_A;

    -- Checking "card_id" (nvarchar(20)) 
    --------------------------------------------------
        -- Nulls
        SELECT COUNT(*) as total_count, 
               COUNT(Card_ID) as id_count 
        FROM Bronze_card_master_system_A;                -- No nulls (both 815)

        -- Duplicate values        
        SELECT * FROM (
            SELECT *, COUNT(card_id) OVER(PARTITION BY (card_id) ORDER BY (SELECT NULL)) as flag 
            FROM Bronze_card_master_system_A
        ) t
        WHERE flag != 1
        ORDER BY Card_ID;                                -- There are few duplicates that need to be taken care of (exact entries, can remove any row)

    -- Checking "card_network" (nvarchar(20)) 
    --------------------------------------------------
        -- Leading/trailing spaces
        SELECT Card_Network
        FROM Bronze_card_master_system_A
        WHERE LEN(card_network) != LEN(TRIM(card_network)); -- No leading/trailing spaces

        -- Distinct values, low cardinality
        SELECT DISTINCT Card_Network 
        FROM Bronze_card_master_system_A;                -- Inconsistent formats, extra spaces in between words

    -- Checking "card_type" (nvarchar(20)) 
    --------------------------------------------------
        -- Distinct values, low cardinality
        SELECT DISTINCT Card_Type 
        FROM Bronze_card_master_system_A;                -- Consistent format and standardized

    -- Checking "Segment" (nvarchar(20)) 
    --------------------------------------------------
        -- Distinct values, low cardinality
        SELECT DISTINCT Segment 
        FROM Bronze_card_master_system_A;

        -- Leading/trailing spaces
        SELECT Segment
        FROM Bronze_card_master_system_A
        WHERE LEN(Segment) != LEN(TRIM(Segment));        -- There are some leading & trailing spaces

    -- Checking "issuer_bank" (nvarchar(255)) 
    --------------------------------------------------
        -- Distinct values, low cardinality
        SELECT DISTINCT issuer_bank 
        FROM Bronze_card_master_system_A;                -- Inconsistent values (2 denotations for one name)

        -- Leading/trailing spaces
        SELECT issuer_bank
        FROM Bronze_card_master_system_A
        WHERE LEN(issuer_bank) != LEN(TRIM(issuer_bank));-- There are some leading & trailing spaces        

    -- Checking "issuance_country" (varchar(20)) 
    --------------------------------------------------
        -- Distinct values, low cardinality
        SELECT DISTINCT issuance_country 
        FROM Bronze_card_master_system_A;                -- Inconsistent values (both short and long forms used)

    -- Checking "issue_date" (nvarchar(20)) 
    --------------------------------------------------
        -- Needs to be casted/converted to date
        SELECT Issue_Date 
        FROM Bronze_card_master_system_A;                -- Will check for formats present

    -- Checking "expiry_date" (nvarchar(20)) 
    --------------------------------------------------
        SELECT Expiry_Date 
        FROM Bronze_card_master_system_A;

    -- Checking "status" (nvarchar(20)) 
    --------------------------------------------------
        -- Distinct values, low cardinality
        SELECT DISTINCT status 
        FROM Bronze_card_master_system_A;                -- Inconsistent values for same status, leading & trailing spaces present

        /***** THIS ALSO NEEDS TO BE CHECKED FOR INCORRECT TAGGINGS ONCE THE EXPIRY DATE IS FIXED *****/

        SELECT card_id, expiry_date, card_status 
        FROM silver_card_master_system_A
        WHERE expiry_date > GETDATE() AND card_status = 'Expired';  -- Few cards show status as expired even though expiry date is in future

        SELECT card_id, expiry_date, card_status 
        FROM silver_card_master_system_A
        WHERE expiry_date < GETDATE() AND card_status = 'Active';   -- Few cards show active but expiry date has passed
        -- This has been fixed in the final checks of silver layer

    -- Checking "source_extract_date" (date) 
    --------------------------------------------------
        -- Nulls
        SELECT COUNT(*) as total_count,
               COUNT(source_extract_date) as date_count 
        FROM Bronze_card_master_system_A;                -- No nulls (both gave 815)


/*============================================
  6. bronze_card_status_feed table
============================================*/
    -- Loading the table to understand the content
    SELECT * FROM Bronze_card_status_feed;
            
    -- Checking "card_no" (nvarchar(20)) 
    --------------------------------------------------
        -- Duplicates
        SELECT card_no, COUNT(card_no) as flag
        FROM Bronze_card_status_feed
        GROUP BY card_no
        HAVING COUNT(card_no) > 1;                       -- No duplicates

        -- Leading/trailing spaces
        SELECT card_no
        FROM Bronze_card_status_feed
        WHERE LEN(card_no) != LEN(TRIM(card_no));        -- There are leading and trailing spaces

    -- Checking "is_active" (nvarchar(10)) 
    --------------------------------------------------
        -- Distinct values, low cardinality
        SELECT DISTINCT is_active 
        FROM Bronze_card_status_feed;                    -- Will replace these with "Yes" and "No"

    -- Checking "card_category" (varchar) 
    --------------------------------------------------
        -- Distinct values, low cardinality
        SELECT DISTINCT card_category 
        FROM Bronze_card_status_feed;                    -- Will replace with full forms (no extra spaces)

    -- Checking "network" (nvarchar) 
    --------------------------------------------------
        -- Distinct values, low cardinality
        SELECT DISTINCT network 
        FROM Bronze_card_status_feed;

    -- Checking "last_updated" (datetime2) 
    --------------------------------------------------
        SELECT last_updated 
        FROM Bronze_card_status_feed
        WHERE DATETRUNC(day, last_updated) != last_updated; -- No value has time value, can be changed to date format


/*============================================
  7. bronze_merchant_incremental table
============================================*/
    -- Loading the table to understand the content
    SELECT * FROM Bronze_merchant_incremental;
            
    -- Checking "merchant_id" (nvarchar(20)) 
    --------------------------------------------------
        -- Duplicates
        SELECT merchant_id, COUNT(merchant_id) 
        FROM Bronze_merchant_incremental
        GROUP BY merchant_id 
        HAVING COUNT(merchant_id) > 1;                   -- No duplicates

        -- Leading/trailing spaces
        SELECT merchant_id 
        FROM Bronze_merchant_incremental
        WHERE LEN(merchant_id) != LEN(TRIM(merchant_id));-- No leading/trailing spaces

    -- Checking "merchant_name" (nvarchar) 
    --------------------------------------------------
        -- Leading/trailing spaces
        SELECT merchant_name 
        FROM Bronze_merchant_incremental
        WHERE LEN(merchant_name) != LEN(TRIM(merchant_name)); -- No leading/trailing spaces

    -- Checking "mcc_code" (INT) 
    --------------------------------------------------
        -- Nulls
        SELECT COUNT(*) as total_count, 
               COUNT(mcc_code) as code_count
        FROM Bronze_merchant_incremental;                -- No nulls (both give 20)

    -- Checking "country" (nvarchar(20)) 
    --------------------------------------------------
        -- Distinct values, low cardinality
        SELECT DISTINCT country 
        FROM Bronze_merchant_incremental;                -- Inconsistent values, full and short forms

    -- Checking "channel" (varchar(20)) 
    --------------------------------------------------
        -- Distinct values, low cardinality
        SELECT DISTINCT channel 
        FROM Bronze_merchant_incremental;                -- Standardized already, no extra spaces

    -- Checking "Onboarded_date" (nvarchar(20)) 
    --------------------------------------------------
        -- Data type needs to be fixed by casting and converting
        -- Nulls
        SELECT COUNT(*) as total_count, 
               COUNT(onboarded_date) as date_count 
        FROM Bronze_merchant_incremental;                -- No nulls (both gave 20)

    -- Checking "status" (varchar) 
    --------------------------------------------------
        -- Distinct values, low cardinality
        SELECT DISTINCT status 
        FROM Bronze_merchant_incremental;                -- Few values have multiple denotations, standardization needed


/*============================================
  8. bronze_merchant_master table
============================================*/
    -- Loading the table to understand the content
    SELECT * FROM Bronze_merchant_master;

    -- Checking "merchant_id" (nvarchar(20))
    --------------------------------------------------
        -- Duplicates
        SELECT merchant_id, COUNT(merchant_id) 
        FROM Bronze_merchant_master
        GROUP BY merchant_id 
        HAVING COUNT(merchant_id) > 1;                   -- No duplicates
            
        SELECT * FROM (
            SELECT *, COUNT(merchant_id) OVER(PARTITION BY(merchant_id) ORDER BY(SELECT NULL)) as flag 
            FROM meridian_pay.dbo.Bronze_merchant_master
        ) t 
        WHERE flag = 1;

        -- EXEC silver_load_silver
        SELECT COUNT(*) FROM silver_merchant_master;

        -- Leading/trailing spaces
        SELECT merchant_id 
        FROM Bronze_merchant_master
        WHERE LEN(merchant_id) != LEN(TRIM(merchant_id));-- No leading/trailing spaces
            
    -- Checking "merchant_name" (nvarchar) 
    --------------------------------------------------
        -- Leading & trailing spaces
        SELECT Merchant_Name 
        FROM Bronze_merchant_master
        WHERE LEN(merchant_name) != LEN(TRIM(merchant_name)); -- Leading & trailing spaces present

    -- Checking "mcc_code" (INT) 
    --------------------------------------------------
        -- Nulls
        SELECT COUNT(*) as total_count, 
               COUNT(mcc_code) as code_count
        FROM Bronze_merchant_master;                     -- No nulls (both gives 410)

    -- Checking "mcc_desc" (nvarchar(100)) 
    --------------------------------------------------
        -- Leading & trailing spaces
        SELECT mcc_desc 
        FROM Bronze_merchant_master
        WHERE LEN(mcc_desc) != LEN(TRIM(mcc_desc));      -- No leading & trailing spaces present

    -- Checking "country" (nvarchar(20)) 
    --------------------------------------------------
        -- Distinct values, low cardinality
        SELECT DISTINCT country 
        FROM Bronze_merchant_master;                     -- Multiple denotations for same countries

    -- Checking "Channel" (varchar(10)) 
    --------------------------------------------------
        -- Distinct values, low cardinality
        SELECT DISTINCT Channel 
        FROM Bronze_merchant_master;

        -- Leading & trailing spaces
        SELECT Channel 
        FROM Bronze_merchant_master
        WHERE LEN(Channel) != LEN(TRIM(Channel));        -- Leading & trailing spaces present

    -- Checking "onboarded_date" (datetime2) 
    --------------------------------------------------
        -- Nulls
        SELECT COUNT(*) as total_count,
               COUNT(onboarded_date) as date_count
        FROM Bronze_merchant_master;                     -- No nulls (both gives 410)

    -- Checking "status" (NVARCHAR(20)) 
    --------------------------------------------------
        -- Distinct values, low cardinality
        SELECT DISTINCT status 
        FROM Bronze_merchant_master;                     -- Multiple values, need standardization


/*============================================
  9. bronze_revenue_amer_apac table
============================================*/
    -- Loading the table to understand the content
    SELECT * FROM Bronze_revenue_amer_apac;

    -- Checking "month" (date) 
    --------------------------------------------------
        -- Nulls
        SELECT COUNT(*) as total_rows,
               COUNT(month) as total_dates
        FROM Bronze_revenue_amer_apac;                   -- No nulls

    -- Checking "country" (nvarchar(20)) 
    --------------------------------------------------
        -- Distinct values, low cardinality
        SELECT DISTINCT country 
        FROM Bronze_revenue_amer_apac;                   -- Already standardized

    -- Checking "ALL_OTHER_COLUMNS" (DECIMAL(6,2))
    --------------------------------------------------
        -- Going to convert to float and replace nulls with 0.00
        SELECT * FROM Bronze_revenue_amer_apac;


/*============================================
  10. bronze_revenue_emea table
============================================*/
    -- Loading the table to understand the content
    SELECT * FROM Bronze_revenue_emea;

    -- Checking "period" (nvarchar(20)) 
    --------------------------------------------------
        -- Needs to be converted to date type
        -- Nulls
        SELECT COUNT(*) as total_rows,
               COUNT(period) as period_count
        FROM Bronze_revenue_emea;                        -- No nulls (both gives 96)

    -- Checking "country_code" (nvarchar(20)) 
    --------------------------------------------------
        -- Distinct values, low cardinality
        SELECT DISTINCT country_code 
        FROM Bronze_revenue_emea;                        -- All standardized already

        -- Leading/trailing spaces
        SELECT country_code 
        FROM Bronze_revenue_emea
        WHERE LEN(country_code) != LEN(TRIM(country_code)); -- No leading/trailing spaces

    -- Checking "ALL_OTHER_COLUMNS" (DECIMAL(6,2)) 
    --------------------------------------------------
        -- Going to replace nulls with 0.00 and convert to float
        SELECT COUNT(*) as total_count,
               COUNT(cross_border_fees) as count_fee 
        FROM Bronze_revenue_emea;                        -- There are nulls, commas and extra spaces


/*============================================
  11. bronze_transactions_2024H2_2025 table
============================================*/
    -- Loading the table to understand the content
    SELECT * FROM Bronze_transactions_2024H2_2025;

    -- GONNA REPEAT ALL RELEVANT STEPS FOR THIS TABLE AS WELL


/*============================================
  12. bronze_transactions_legacy_2024H1 table
============================================*/
    -- Loading the table to understand the content
    SELECT * FROM Bronze_transactions_legacy_2024H1;

    -- GONNA REPEAT ALL RELEVANT STEPS FOR THIS TABLE AS WELL

/*
===============================================================================
*******************************************************************************
===============================================================================
*******************************************************************************
===============================================================================

Let's Fix these issues, one table at a time
*/