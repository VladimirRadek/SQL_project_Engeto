/*
 * Dotaz č. 5:
 * Má výška HDP vliv na změny ve mzdách a cenách potravin? 
 * Neboli, pokud HDP vzroste výrazněji v jednom roce, 
 * projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
 * 
 * Does the level of GDP affect changes in wages and food prices? 
 * Or, if GDP increases more significantly in one year, will this be reflected in 
 * a more significant increase in food prices or wages in the same or the following year?
 */

with total_avg_salary_and_prices_CTE as(
	--Average salaries and average food prices across categories for each year
	select
		vrpp.payroll_year,
		AVG(vrpp.avg_salary) as avg_salary,
		AVG(vrpp.avg_prod_cat_price) as avg_product_price
	from t_vladimir_radek_project_sql_primary_final vrpp
	where vrpp.prod_cat_name <> 'Jakostní víno bílé'
	group by vrpp.payroll_year 
),
gdp_data_CTE as (
	-- Information on the year-on-year level of GDP in a specified country
	select
		vrps."year",
		vrps.country,
		vrps.gdp 
	from t_vladimir_radek_project_sql_secondary_final vrps
	where vrps.country = 'Czech Republic'
),
lag_data_of_price_salary_gdp_CTE as (
	-- Year-on-year information on salaries, food prices, GDP, their comparison with data 
	--from the previous year and determination of year-on-year relative change
	select
		tasp.payroll_year as year,
		tasp.avg_salary,
		lag(tasp.avg_salary) over (order by tasp.payroll_year) as avg_salary_last_year,
		((tasp.avg_salary - (lag(tasp.avg_salary) over (order by tasp.payroll_year))) / (lag(tasp.avg_salary) over (order by tasp.payroll_year))) * 100 as perc_salary_growth,
		tasp.avg_product_price,
		lag(tasp.avg_product_price) over (order by tasp.payroll_year) as avg_prod_price_last_year,
		((tasp.avg_product_price - (lag(tasp.avg_product_price) over (order by tasp.payroll_year))) / (lag(tasp.avg_product_price) over (order by tasp.payroll_year))) * 100 as perc_prod_cat_price_growth,
		gd.gdp,
		lag(gd.gdp) over (order by tasp.payroll_year) as gdp_last_year,
		((gd.gdp - lag(gd.gdp) over (order by tasp.payroll_year)) / lag(gd.gdp) over (order by tasp.payroll_year)) * 100 as perc_gdp_growth
	from total_avg_salary_and_prices_CTE tasp
	join gdp_data_CTE gd
	on tasp.payroll_year = gd."year"
)
select
	-- Final selection with relative changes of wages, product prices and GDP
	ldps."year",
	round(ldps.perc_prod_cat_price_growth::numeric, 3) as product_growth,
	round(ldps.perc_salary_growth::numeric, 3) as salary_growth,
	round(ldps.perc_gdp_growth::numeric, 3) as gdp_growth,
	lag(ldps.perc_gdp_growth) over (order by year) as gdp_growth_last_year
from lag_data_of_price_salary_gdp_CTE ldps
where ldps.avg_prod_price_last_year  is not null;




