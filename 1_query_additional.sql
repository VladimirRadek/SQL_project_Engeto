/*
 * Dotaz č. 1:
 * Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
 * Are wages increasing in all sectors over the years, or are they decreasing in some?
 * 
 * This is an additional query where it is possible to find out the industries in which there was a decrease 
 * in salaries in the specified time period or industries where there was never a decrease in salaries in that period.
 * You can make a choise by commenting out the following lines in the "where" section of the "Final select".
 */


with salary_trend_CTE as (
	select
	tvrpspf.branch_name,
	tvrpspf.payroll_year,
	--getting the average salary of each industry
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
),
--CTE to find out which industries have ever seen a decline in salaries
--This section is only important for identifying industries that have never experienced a decline in salaries
branches_falling_salaries_CTE as (
	select *
	from salary_trend_CTE st2
	where st2.salary_trend = 'Fall'
)
--Final select
select
	distinct st.branch_name
from salary_trend_CTE st
where
	--if you want to get the industries whose salaries declined in the past use this condition
	st.salary_trend = 'Fall'
	-- or use this if you want to know which industries have never declined in salaries
	/*st.branch_name not in (
		select
			bfs.branch_name
		from branches_falling_salaries_CTE bfs
	)*/
;