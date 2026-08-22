/*
==================================================================================================
SCRIPT SUMMARY: Operational Network KPIs
==================================================================================================
Purpose:
Analyzes the core transactional throughput and user base footprint of the global payment network. 
This script tracks total volume processed and identifies regional or product-level shifts 
in consumer payment behavior.

Key Analytics:
- Gross Dollar Volume (GDV): Monthly YoY growth tracking.
- Cross-Border Volume (CBV): Identifying fastest-growing countries for international volume.
- Product Mix: Tracks shifting consumer preference between Credit, Debit, and Prepaid.
- Network Footprint: Outstanding active card base by network (Primary/Direct/Affiliate) and country.

Core Tables Referenced:
- Facts: gold_fact_transactions
- Dims:  gold_dim_countries, gold_dim_cards
==================================================================================================

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
1. What's our Gross Dollar Volume by month, and how does it compare year-over-year?
--------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

	WITH GDV as(
			SELECT DATETRUNC(MONTH, t.transaction_datetime) as Date_Sort
				,SUM(t.amount*c.usd_multiplier) as Gross_Domestic_value_USD
			FROM gold_fact_transactions as t
			LEFT JOIN gold_dim_countries as c
			On t.currency = c.currency
			GROUP BY DATETRUNC(MONTH, t.transaction_datetime)
			),
		Previous_Year_GDV as (
			SELECT Date_Sort
				,Gross_Domestic_value_USD
				,LAG(Gross_Domestic_Value_USD,1,0.0) OVER(PARTITION BY FORMAT(Date_sort,'MMMM') ORDER BY Date_sort) as Previous_Year_GDV
			FROM GDV)
	SELECT FORMAT(date_sort, 'MMMM-yyyy') as Period
		,ROUND(Gross_Domestic_value_USD,2) as Gross_Domestic_value_USD
		,ROUND(Previous_Year_GDV,2) as Previous_Year_GDV_USD
		,FORMAT(((Gross_Domestic_value_USD-Previous_Year_GDV)/Previous_Year_GDV), '00.00%') as Growth_in_GDV
	FROM Previous_Year_GDV
	WHERE Previous_Year_GDV!=0
	ORDER BY YEAR(date_sort), Month(date_sort);

/*
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
2. Which countries are driving the most cross-border volume(CBV) growth, and how fast?
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
	Countries with highest CBV Overall
	=====================================*/
	SELECT issuance_country as Country
		,year(t.transaction_datetime) as Year
		,ROUND(SUM(t.amount * usd_multiplier),2) as Total_Cross_Border_Volume_USD
	FROM gold_fact_transactions as t
	LEFT JOIN gold_dim_cards as c
		ON t.card_id = c.card_id
		LEFT JOIN gold_dim_countries as m
		ON c.issuance_country = m.country_code
		WHERE cross_border_transaction = 'Yes'
		GROUP BY c.issuance_country, year(t.transaction_datetime)
		ORDER BY ROUND(SUM(amount * usd_multiplier),2) DESC, year(t.transaction_datetime);
	/*
	What's the rate of growth?
	==========================*/
	WITH Monthly_Cross_Border_Volume AS(
			SELECT m.country_name as Country
				,DATETRUNC(MONTH, transaction_datetime) as Month_Sort		-- To keep the scope of formatting in order of month rather thanalphabetically
				,ROUND(SUM(t.amount * m.usd_multiplier),2) as Cross_Border_Volume
			FROM gold_fact_transactions as t
			LEFT JOIN gold_dim_cards as c				-- To get card country reference
			ON t.card_id = c.card_id				
			LEFT JOIN gold_dim_countries as m			-- To get usd_multiplier and country's full name
			ON c.issuance_country = m.country_code
			WHERE cross_border_transaction = 'Yes'		-- To only consider "Cross Border Transactions"
			GROUP BY m.country_name, DATETRUNC(MONTH, transaction_datetime)
			),
		Previou_Year_CBT as(	
			SELECT Country 
				,Month_Sort
				,Cross_Border_Volume
				,LAG(Cross_Border_Volume, 1, 0.0) OVER(PARTITION BY Country, FORMAT(Month_Sort, 'MMMM') ORDER BY Month_Sort ASC) as Previous_Year_Cross_Border_Volume
			FROM Monthly_Cross_Border_Volume)
	SELECT Country
		,Format(Month_Sort, 'MMMM-yyyy') as Year_Month
		,Cross_Border_Volume
		,Previous_Year_Cross_Border_Volume
		,FORMAT(((Cross_Border_Volume - Previous_Year_Cross_Border_Volume) / Previous_Year_Cross_Border_Volume),'00.00%') as Rate_of_Change
	
	FROM Previou_Year_CBT
	WHERE Previous_Year_Cross_Border_Volume!=0			-- Adding thisto remove first year which cannot be compared with anything
	ORDER BY Country, Month(Month_Sort) DESC;


/*
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
3. What's the card mix (Credit vs Debit vs Prepaid) by purchase volume, and has it shifted over the last 12 months?
--------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

	WITH Monthly_mix as(
		SELECT DATETRUNC(MONTH,t.transaction_datetime) as Period
			,COALESCE(c.card_type, 'Unknown') as Card_Type
			,SUM(t.amount * cnt.usd_multiplier) as Purchase_Volume
		from gold_fact_transactions t
		LEFT JOIN gold_dim_cards c
		ON t.card_id = c.card_id
		LEFT JOIN gold_dim_countries cnt
		ON t.currency = cnt.currency
		WHERE transaction_type = 'Purchase' AND 
		t.transaction_datetime >= (SELECT DATEADD(MONTH, -13, DATETRUNC(MONTH, MAX(transaction_datetime))) FROM gold_fact_transactions)
		-- Initially kept this -12 but was getting a null or removing it wasleaving the comparison to only 11 months thus changed it to -13
		GROUP BY DATETRUNC(MONTH,t.transaction_datetime), c.card_type
		),
	Monthly_share as (
		SELECT Period
			, Card_Type
			,Purchase_Volume as Monthly_Purchase_Volume
			,SUM(Purchase_Volume) OVER(PARTITION BY Period) as Total_Purchase_Volume
		FROM Monthly_mix),
	Card_Mix_with_Prev as(
	SELECT Card_Type
		,Period
		,ROUND(monthly_Purchase_Volume,2) as Purchase_Volume_USD
		,((monthly_Purchase_Volume*100.0)/Total_Purchase_Volume) as Mix_Share
		,LAG(((monthly_Purchase_Volume*100.0)/Total_Purchase_Volume)) OVER(PARTITION BY card_type ORDER BY Period) as Prev_Month_Mix_Share
	FROM Monthly_Share)
	SELECT Card_Type
		,FORMAT(Period, 'MMMM-yyyy') as Period_MY
		,Purchase_Volume_USD
		,ROUND(Mix_Share,2) as Mix_Share
		,ROUND(Prev_Month_Mix_Share,2) as Prev_Month_Mix_Share
		,ROUND((Mix_Share - Prev_Month_Mix_Share),2) as Mix_Shift_PP
	FROM Card_Mix_with_Prev
	WHERE Prev_Month_Mix_Share IS NOT NULL
	ORDER BY Card_Type, DATETRUNC(MONTH, Period);


/*
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
4. How many active cards do we have outstanding, broken down by network (Primary/Direct/Affiliate) and country?
--------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

	SELECT p.card_network as Network
		,COALESCE(s.country_name, 'Unknown') as Country
		,COUNT(card_network) as Outstaanding_Active_Cards
	FROM gold_dim_cards p
	LEFT JOIN gold_dim_countries s
	ON p.issuance_country = s.country_code
	WHERE card_status = 'Active'
	GROUP BY card_network,country_name
	ORDER BY card_network, COUNT(card_network) DESC;

/*
========================================================
END
========================================================
*/
