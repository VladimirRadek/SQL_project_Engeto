/*
 * Dotaz č. 2:
 * Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
 * How many liters of milk and kilograms of bread can be purchased for the first and last comparable periods in the available price and wage data?
 */

with min_max_year_CTE as(
	select
	--selecting the year boundaries
		MAX(tvrpspf.payroll_year) as max_year,
		MIN(tvrpspf.payroll_year) as min_year
	from t_vladimir_radek_project_sql_primary_final tvrpspf
)
select
	tvrpspf.prod_cat_name,
	tvrpspf.payroll_year,
	--calculating how many units of goods from a given category I can buy
	ROUND((AVG(tvrpspf.avg_salary)::numeric * tvrpspf.price_value::numeric / nullif(AVG(tvrpspf.avg_prod_cat_price)::numeric, 0)), 2) as amount,
	tvrpspf.price_unit 
from t_vladimir_radek_project_sql_primary_final tvrpspf
join min_max_year_CTE mmy
on tvrpspf.payroll_year in (mmy.max_year, mmy.min_year)
where 
	-- filtering product categories
	LOWER(tvrpspf.prod_cat_name) in ('mléko polotučné pasterované', 'chléb konzumní kmínový')
group by
	tvrpspf.payroll_year,
	tvrpspf.prod_cat_name,
	tvrpspf.price_value,
	tvrpspf.price_unit
order by 
	tvrpspf.prod_cat_name,
	tvrpspf.payroll_year;




