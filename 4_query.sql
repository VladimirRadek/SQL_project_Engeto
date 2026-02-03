/*
 * Dotaz č. 4:
 * 
 * Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
 * Is there a year in which the year-on-year increase in food prices was significantly higher than wage growth (greater than 10%)?
 */

with total_avg_salary_and_prices_CTE as(
	--Average salaries and average food prices across categories for each year
	select
		tvrpspf.payroll_year,
		AVG(tvrpspf.avg_salary) as avg_salary,
		AVG(tvrpspf.avg_prod_cat_price) as avg_year_price
	from t_vladimir_radek_project_sql_primary_final tvrpspf
	where tvrpspf.prod_cat_name <> 'Jakostní víno bílé'
	group by 
		tvrpspf.payroll_year
),
salary_and_prices_from_last_year_CTE as (
	--Adding columns with average salaries and average food prices in the previous year
	select
		tasp.payroll_year,
		tasp.avg_salary,
		lag(tasp.avg_salary) over (order by tasp.payroll_year) as salary_last_year,
		tasp.avg_year_price,
		lag(tasp.avg_year_price) over (order by tasp.payroll_year) as avg_prod_cat_price_last_year
	from total_avg_salary_and_prices_CTE tasp
),
percent_salary_and_productc_growth_CTE as (
	--Determining the year-on-year relative change in wages and food prices
	select
		spfly.*,
		(spfly.avg_salary - spfly.salary_last_year) * 100 / nullif(spfly.salary_last_year, 0) as perc_salary_growth,
		(spfly.avg_year_price  - spfly.avg_prod_cat_price_last_year) * 100 / nullif(spfly.avg_prod_cat_price_last_year, 0) as perc_prod_cat_price_growth
	from salary_and_prices_from_last_year_CTE spfly
	where spfly.salary_last_year is not null
)
-- A final selection that will determine whether some food prices rose significantly faster (>10%) than wages
select 
	pspg.payroll_year,
	round(pspg.perc_salary_growth::numeric, 2) as salary_growth,
	round(pspg.perc_prod_cat_price_growth::numeric, 2) as product_growth,
	round((pspg.perc_prod_cat_price_growth - pspg.perc_salary_growth)::numeric, 2) as diff_of_growth
from percent_salary_and_productc_growth_CTE pspg
where 
	pspg.perc_prod_cat_price_growth - pspg.perc_salary_growth > 0
order by pspg.payroll_year asc;








