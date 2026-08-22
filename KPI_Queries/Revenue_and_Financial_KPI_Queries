/*
==================================================================================================
SCRIPT SUMMARY: Revenue Yield & Financial Performance
==================================================================================================
Purpose:
Evaluates the monetary health and operational efficiency of the business. This script breaks 
down where revenue is generated and tracks if the network is operating efficiently compared 
to the cost of incentives.

Key Analytics:
- Revenue Attribution: Contribution share and YoY growth across Cross-Border Fees, 
  Domestic Assessments, and Value-Added Services (VAS).
- Business Efficiency: 24-month trend comparison of Operating Margins versus 
  Rebates and Incentives ratios to determine operational efficiency states.

Core Tables Referenced:
- Facts: gold_fact_revenue, gold_fact_financial_total
- Dims:  gold_dim_countries
================================================================================================== */

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
5. Which revenue category — domestic assessments, cross-border fees, or value-added services — is growing fastest, and which contributes the most to total revenue?
--------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

-- Total Revenue per Revenue Category
	With Total_Revenue_Generated as (
		SELECT 'Cross Border Revenue' as Revenue_Category
			,ROUND(SUM(cross_border_fees*c.usd_multiplier),2) as Revenue_Contributed
		FROM gold_fact_revenue r
		LEFT JOIN gold_dim_countries c
		ON r.country = c.country_code
		UNION ALL
		SELECT 'Domestic Assessment Fees' as Revenue_Category
			,ROUND(SUM(domestic_sssessments*c.usd_multiplier),2) as Revenue_Contributed
		FROM gold_fact_revenue r
		LEFT JOIN gold_dim_countries c
		ON r.country = c.country_code
		UNION ALL
		SELECT 'Value Added Services' as Revenue_Contributed
			,ROUND(SUM(
				(other_network_fees
				+ vas_cybersecurity
				+ vas_data_analytics
				+ vas_fraud_and_security_tools
				+ vas_open_banking)*c.usd_multiplier
				),2) as Revenue_Contributed
		FROM gold_fact_revenue r
		LEFT JOIN gold_dim_countries c
		ON r.country = c.country_code)
	SELECT Revenue_Category
		,Revenue_Contributed
		--,SUM(Revenue_Contributed) OVER() as Total_Revenue
		,FORMAT((Revenue_Contributed/SUM(Revenue_Contributed) OVER()),'00.00%') as Contribution_to_total
	FROM Total_Revenue_Generated
	ORDER BY Revenue_Contributed DESC;

-- Fastest growing revenue category

	WITH categories as(
		SELECT r.period
			,ROUND(SUM(cross_border_fees*usd_multiplier),2) as Cross_Border_Revenue
			,ROUND(SUM(domestic_sssessments*usd_multiplier),2) as Domestic_Assessment_Revenue
			,ROUND(SUM((other_network_fees
			+ vas_cybersecurity 
			+ vas_data_analytics
			+ vas_fraud_and_security_tools
			+ vas_open_banking)*c.usd_multiplier),2) as Value_Added_Services_Revenue
		FROM gold_fact_revenue r
		LEFT JOIN gold_dim_countries c
		ON r.country = c.country_code
		GROUP BY period),
	PYSM as(
		SELECT period as Period
			,Cross_Border_Revenue
			,LAG(Cross_Border_Revenue,12,0.00) OVER(ORDER BY period ASC) as PYSM_CB_Revenue
			,Domestic_Assessment_Revenue
			,LAG(Domestic_Assessment_Revenue,12,0.00) OVER(ORDER BY period ASC) as PYSM_DM_Revenue
			,Value_Added_Services_Revenue
			,LAG(Value_Added_Services_Revenue,12,0.00) OVER(ORDER BY period ASC) as PYSM_VAS_Revenue
		From categories)
	SELECT FORMAT(period, 'MMM-yyyy') as Period
		,FORMAT(((Cross_Border_Revenue-PYSM_CB_Revenue)/PYSM_CB_Revenue),'00.00%') as Cross_Border_Growth_Rate
		,FORMAT(((Domestic_Assessment_Revenue-PYSM_DM_Revenue)/PYSM_DM_Revenue),'00.00%') as Domestic_Assessment_Growth_Rate
		,FORMAT(((Value_Added_Services_Revenue-PYSM_VAS_Revenue)/PYSM_VAS_Revenue),'00.00%') as Value_Added_Services_Growth_Rate
	FROM PYSM
	WHERE PYSM_CB_Revenue !=0;

/*
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
6. How have operating margin and the rebates/incentives ratio trended over the last 24 months — is the business getting more or less efficient?
--------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
	
	WITH Ratios as(
		SELECT period
			,operating_income_USD/gross_revenue_USD as OM
			,rebates_and_incentives_USD/gross_revenue_USD as RR
		From gold_fact_financial_total)
	SELECT FORMAT(period,'MMM-yyyy') as Period
		,FORMAT(OM, '00.00%') Operating_Margin
		,FORMAT(RR, '00.00%') Rebates_Ratio
		,FORMAT((OM - RR),'00.00%') as Difference_in_ratios
		,CASE WHEN OM > RR THEN 'Efficient'
		ELSE 'In-efficient' END as State_of_Business
	FROM Ratios;

/*
================================================
END
================================================
*/
