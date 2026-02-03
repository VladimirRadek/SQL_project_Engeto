/*
 * Dotaz č. 3:
 * Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? 
 * Which food category is increasing in price the slowest (has the lowest percentage year-on-year increase)?
 */

with product_prices_over_years_CTE as(
	-- CTE to add a column "avg_prod_cat_price_last_year" that adds the product value for the previous year to each record
	select 
		tvrpspf.prod_cat_name,
		AVG(tvrpspf.avg_prod_cat_price) as avg_prod_cat_price,
		tvrpspf.payroll_year,
		lag(AVG(tvrpspf.avg_prod_cat_price)) over (partition by tvrpspf.prod_cat_name order by tvrpspf.payroll_year) as avg_prod_cat_price_last_year
	from t_vladimir_radek_project_sql_primary_final tvrpspf
	group by tvrpspf.prod_cat_name, tvrpspf.payroll_year
),
percent_raise_CTE as (
	-- CTE for percentile calculation
	select
		ppoy.prod_cat_name,
		ppoy.payroll_year,
		(ppoy.avg_prod_cat_price - ppoy.avg_prod_cat_price_last_year) * 100 / nullif(ppoy.avg_prod_cat_price_last_year, 0) as year_percent_raise
	from product_prices_over_years_CTE ppoy
)
,
percentil_trend_CTE as (
	--CTE for distinguishing whether food prices are increasing or decreasing year-on-year
	select 
		pr.prod_cat_name,
		round(AVG(pr.year_percent_raise)::numeric, 4) as percent_raise,
		case 
			when AVG(pr.year_percent_raise) > 0 then 'Increase'
			when AVG(pr.year_percent_raise) < 0 then 'Decrease'
			else 'Stagnation'
		end as price_development
	from percent_raise_CTE pr
	group by pr.prod_cat_name
)
-- Final select to find the slowest growing category
select *
from percentil_trend_CTE pt
where pt.price_development in ('Increase')
order by percent_raise asc
limit 1;


