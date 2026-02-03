--Table #2 with aditional data on European countries and their economies over the years
create table if not exists t_vladimir_radek_project_SQL_secondary_final as
with selected_years as(
	--unification of years with table t_vladimir_radek_project_SQL_primary_final
	select 
		MAX(cp.payroll_year) as max_year,
		MIN(cp.payroll_year) as min_year
	from czechia_payroll cp
	where cp.payroll_year  in (
		select date_part('year', cp.date_from)
		from czechia_price cp 
	)
)
select 
	--selection of data about countries and their economies limited to selected years
	distinct e."year",
	e.country,
	e.gdp,
	e.population,
	e.gini,
	e.taxes 
from( 
	select *
	from countries co 
	where co.continent = 'Europe' 
) c
join economies e 
on c.country = e.country
where 
	e.year between (select min_year from selected_years)
	and (select max_year from selected_years)
order by 
	e.country,
	e."year";

