/*
 * Dotaz č. 1:
 * Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
 * Are wages increasing in all sectors over the years, or are they decreasing in some?
 */


select
tvrpspf.branch_name,
tvrpspf.payroll_year,
--getting the average salary pf each branch
AVG(tvrpspf.avg_salary) as branch_avg_salary,
--getting the average salary from previous year
LAG(AVG(tvrpspf.avg_salary)) OVER (PARTITION BY tvrpspf.branch_name  ORDER BY tvrpspf.payroll_year) AS branch_avg_sal_prev_year,
--compares the current year's salary to the previous year's salary and divides into a groups
case
	when LAG(AVG(tvrpspf.avg_salary)) OVER (PARTITION BY tvrpspf.branch_name  ORDER BY tvrpspf.payroll_year) is null then 'Nothing to compare (First year)'
	when LAG(AVG(tvrpspf.avg_salary)) OVER (PARTITION BY tvrpspf.branch_name  ORDER BY tvrpspf.payroll_year) < AVG(tvrpspf.avg_salary) then 'Growth'
	when LAG(AVG(tvrpspf.avg_salary)) OVER (PARTITION BY tvrpspf.branch_name  ORDER BY tvrpspf.payroll_year) > AVG(tvrpspf.avg_salary) then 'Fall'
	else 'Stagnation'
end as salary_trend
from t_vladimir_radek_project_sql_primary_final tvrpspf 
group by 
	tvrpspf.branch_name,
	tvrpspf.payroll_year 
order by 
	tvrpspf.branch_name asc,
	tvrpspf.payroll_year asc;




