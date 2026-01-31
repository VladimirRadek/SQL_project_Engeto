create table t_vladimir_radek_project_SQL_primary_final as
select 
	cpay.payroll_year, 
	cpay."name" as branch_name, 
	cpay.avg_salary  as avg_salary,
	cpri.name as prod_cat_name, 
	cpri.avg_prod_cat_value  as avg_prod_cat_price
from (
	select
		cpa.payroll_year,
		cpa.industry_branch_code,
		AVG(cpa.value) as AVG_salary,
		cpib."name" 
	from czechia_payroll cpa
	join czechia_payroll_industry_branch cpib 
	on cpa.industry_branch_code = cpib.code 
	where cpa.value_type_code = 5958
	group by cpa.payroll_year, cpa.industry_branch_code, cpib."name" 
)cpay
join (
	select 
		cpr.category_code,
		AVG(cpr.value) as avg_prod_cat_value,
		cpc."name",
		date_part('year', cpr.date_from) as year
		--cpc.price_value
	from czechia_price cpr
	join czechia_price_category cpc 
	on cpr.category_code = cpc.code
	group by cpr.category_code, cpc."name", "year" 
)cpri
on cpay.payroll_year = cpri."year";
