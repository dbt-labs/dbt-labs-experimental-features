{{
	config(
		materialized = 'view',
		enabled=(project_name == 'insert_by_period_integration_tests'),
	)
}}

select *
from {{ ref('data_insert_by_period') }}
where id in (2, 3, 4, 5, 6)
