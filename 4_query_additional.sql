/*
 * Dotaz č. 4:
 * 
 * Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
 */

with total_avg_salary_CTE as(
	select
		tvrpspf.payroll_year,
		tvrpspf.prod_cat_name,
		AVG(tvrpspf.avg_salary) as avg_salary,
		AVG(tvrpspf.avg_prod_cat_price) as avg_year_price
	from t_vladimir_radek_project_sql_primary_final tvrpspf
	where tvrpspf.prod_cat_name <> 'Jakostní víno bílé'
	group by 
		tvrpspf.payroll_year,
		tvrpspf.prod_cat_name 
),
salary_and_prices_from_last_year_CTE as (
	select
		tas.payroll_year,
		tas.prod_cat_name ,
		tas.avg_salary,
		lag(tas.avg_salary) over (partition by tas.prod_cat_name order by tas.payroll_year) as salary_last_year,
		tas.avg_year_price,
		lag(tas.avg_year_price) over (partition by tas.prod_cat_name order by tas.payroll_year) as avg_prod_cat_price_last_year
	from total_avg_salary_CTE tas
),
percent_salary_and_productc_growth_CTE as (
	select
		spfly.*,
		(spfly.avg_salary - spfly.salary_last_year) * 100 / nullif(spfly.salary_last_year, 0) as perc_salary_growth,
		(spfly.avg_year_price  - spfly.avg_prod_cat_price_last_year) * 100 / nullif(spfly.avg_prod_cat_price_last_year, 0) as perc_prod_cat_price_growth
	from salary_and_prices_from_last_year_CTE spfly
	where spfly.salary_last_year is not null
)
select 
	pspg.prod_cat_name,
	pspg.payroll_year,
	round(pspg.perc_salary_growth::numeric, 2) as salary_growth,
	round(pspg.perc_prod_cat_price_growth::numeric, 2) as product_growth,
	round((pspg.perc_prod_cat_price_growth - pspg.perc_salary_growth)::numeric, 2) as diff_of_growth
from percent_salary_and_productc_growth_CTE pspg
where 
	pspg.perc_prod_cat_price_growth - pspg.perc_salary_growth > 20
order by pspg.payroll_year asc;








