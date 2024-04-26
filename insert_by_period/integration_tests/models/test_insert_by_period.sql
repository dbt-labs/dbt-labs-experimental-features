{{
	config(
		materialized = 'insert_by_period',
		period = 'month',
		timestamp_field = 'created_at',
		start_date = '2018-01-01',
		stop_date = '2018-06-01',
		enabled=(project_name == 'insert_by_period_integration_tests')
	)
}}

with events as (
	select *
	from {{ ref('data_insert_by_period') }}
	where __PERIOD_FILTER__
)

select * from events
