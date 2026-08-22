/*
==================================================================================================
SCRIPT SUMMARY: Platform Health & Security Metrics
==================================================================================================
Purpose:
Monitors the IT infrastructure reliability and risk profile of the network. This script 
isolates technical bottlenecks and identifies channels disproportionately driving fraud.

Key Analytics:
- Fraud Monitoring: Tracks overall Fraud-to-Sales ratio in basis points (bps) and isolates 
  the specific transaction types and channels driving fraud.
- System Uptime: Measures monthly overall platform uptime percentage and API success rates.
- IT Bottlenecks: Component-wise uptime tracking (API Gateway, Network Switch, Settlement Engine) 
  and partner-bank API success rates.

Core Tables Referenced:
- Facts: gold_fact_transactions, gold_fact_api_logs, gold_fact_incidents
- Dims:  gold_dim_countries
==================================================================================================*/

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
9. What's our fraud-to-sales ratio in basis points by month, and are certain transaction types or channels driving it disproportionately?
--------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

	-- Fraud-to-sales ration in basis points by month
	WITH monthly_trasactions as(
		SELECT DATETRUNC(MONTH, transaction_datetime) as Month
			,SUM(amount * usd_multiplier) as total_transaction
			,SUM(fraudulent_amount * usd_multiplier) as fraud_transaction
		FROM gold_fact_transactions t
		LEFT JOIN gold_dim_countries c
		ON t.currency = c.currency
		GROUP BY DATETRUNC(MONTH, transaction_datetime))
	SELECT FORMAT(Month, 'MMM-yyyy') as Month
		,ROUND(total_transaction,2) as Total_Transactions
		,ROUND(fraud_transaction,2) as Fraudulent_Transactions
		,ROUND(((fraud_transaction/total_transaction)*10000),2) as Fraud_to_Sales_BP
	FROM monthly_trasactions
	ORDER BY CAST(Month	as Date);


	-- Transactions type orchannels driving it disproportionately
	WITH only_fraud_purchases as(
		SELECT --DATETRUNC(MONTH, transaction_datetime) as period
			transaction_type
			,channel
			,SUM(amount * usd_multiplier) as total_transaction
			,SUM(fraudulent_amount * usd_multiplier) as fraud_transaction
		FROM gold_fact_transactions t
		LEFT JOIN gold_dim_countries c
		ON t.currency = c.currency
		GROUP BY transaction_type, channel
		HAVING SUM(fraudulent_amount * usd_multiplier) !=0
		)
	SELECT transaction_type as Transaction_Type
		,channel as Channel
		,ROUND(((fraud_transaction/total_transaction)*10000),2) as Fraud_to_Sales_BP
	FROM only_fraud_purchases
	ORDER BY ROUND(((fraud_transaction/total_transaction)*10000),2) DESC;

/*
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
10. How reliable is the platform — API success rate and network uptime by month — and are specific partner banks or system components underperforming?
--------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
	-- Monthly API success rate & Network Uptime

	WITH monthly_api as(
		SELECT DATETRUNC(MONTH,record_date) as period
			,FORMAT(SUM((1.0*successful_api_calls))/SUM(total_api_calls),'00.00%') as API_Success_Rate
		from gold_fact_api_logs
		GROUP BY DATETRUNC(MONTH,record_date)),
	monthly_uptime as(
		SELECT DATETRUNC(MOnth, start_time) as period
			,FORMAT((SUM(1.0*uptime_in_minutes)/SUM(total_time)),'00.00%') as Uptime_Percentage
		from gold_fact_incidents
		GROUP BY DATETRUNC(MOnth, start_time))
	SELECT a.period as Month_Year
		,API_Success_Rate
		,Uptime_Percentage
	FROM monthly_api a
	LEFT JOIN monthly_uptime u
	ON a.period = u.period
	ORDER BY u.period;

	-- Component-Wise monthly uptime
	WITH combined_uptime AS (
		SELECT 
			DATETRUNC(Month, start_time) AS period,
			LOWER(component) AS Component,
			FORMAT((SUM(1.0 * uptime_in_minutes) / SUM(total_time)), '00.00%') AS Uptime_Percentage
		FROM gold_fact_incidents
		GROUP BY DATETRUNC(Month, start_time), LOWER(component)
		)
	SELECT 
		FORMAT(period, 'MMM-yyyy') AS Period,
		COALESCE(MAX(CASE WHEN Component = 'api gateway' THEN Uptime_Percentage END), '100%') AS API_Gateway_Uptime,
		COALESCE(MAX(CASE WHEN Component = 'network switch' THEN Uptime_Percentage END), '100%') AS Network_Switch_Uptime,
		COALESCE(MAX(CASE WHEN Component = 'settlement engine' THEN Uptime_Percentage END), '100%') AS Settlement_Engine_Uptime
	FROM combined_uptime
	GROUP BY period
	ORDER BY CAST(period as DATE);

	-- Bank-Wise Monthly API-success rate

	SELECT
		DATETRUNC(Month, record_date) AS period,
		LOWER(bank_name) AS bank_name,
		FORMAT((SUM(1.0 * successful_api_calls) / SUM(total_api_calls)), '00.00%') AS success_rate
	FROM gold_fact_api_logs
	GROUP BY DATETRUNC(Month, record_date), LOWER(bank_name);


	-- For better visuals
	WITH combines_success_rate AS (
		SELECT 
			DATETRUNC(Month, record_date) AS period,
			LOWER(bank_name) AS bank_name,
			FORMAT((SUM(1.0 * successful_api_calls) / SUM(total_api_calls)), '00.00%') AS success_rate
		FROM gold_fact_api_logs
		GROUP BY DATETRUNC(Month, record_date), LOWER(bank_name)
		)
	SELECT 
		FORMAT(period, 'MMM-yyyy') AS Period,
		MAX(CASE WHEN bank_name = 'alta financial' THEN success_rate END) AS Alta_Financial
		,MAX(CASE WHEN bank_name = 'andes financial group' THEN success_rate END) AS Andes_Financial_Group
		,MAX(CASE WHEN bank_name = 'crestview bank' THEN success_rate END) AS Crestview_Bank
		,MAX(CASE WHEN bank_name = 'eurotrust bank' THEN success_rate END) AS Eurotrust_Bank
		,MAX(CASE WHEN bank_name = 'gulf horizon bank' THEN success_rate END) AS Guof_Horizon_Bank
		,MAX(CASE WHEN bank_name = 'harbor national bank' THEN success_rate END) AS Harbor_National_Bank
		,MAX(CASE WHEN bank_name = 'meridian community bank' THEN success_rate END) AS Meridian_Community_Bank
		,MAX(CASE WHEN bank_name = 'northbridge bank' THEN success_rate END) AS Northbridge_Bank
		,MAX(CASE WHEN bank_name = 'pacific rim bank' THEN success_rate END) AS Pacific_Rim_Bank
		,MAX(CASE WHEN bank_name = 'ridgeway bank' THEN success_rate END) AS Ridgeway_Bank
		,MAX(CASE WHEN bank_name = 'silverline bank' THEN success_rate END) AS Silverline_Bank
		,MAX(CASE WHEN bank_name = 'unity trust bank' THEN success_rate END) AS Unity_Trust_Bank
	FROM combines_success_rate
	GROUP BY period
	ORDER BY CAST(period as DATE);

/*
===============================
END
===============================
*/
