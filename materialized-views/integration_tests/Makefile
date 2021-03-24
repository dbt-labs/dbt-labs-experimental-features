test-postgres:
	dbt deps
	dbt seed --target postgres --full-refresh
	dbt run --target postgres --full-refresh --vars 'update: false'
	dbt run --target postgres --vars 'update: true'
	dbt test --target postgres

test-redshift:
	dbt deps
	dbt seed --target redshift --full-refresh
	dbt run --target redshift --full-refresh --vars 'update: false'
	dbt run --target redshift --vars 'update: true'
	sleep 10	# wait for auto refresh
	dbt test --target redshift

test-snowflake:
	dbt deps
	dbt seed --profile garage-snowflake --full-refresh
	dbt run --profile garage-snowflake --full-refresh --vars 'update: false'
	dbt run --profile garage-snowflake --vars 'update: true'
	dbt test --profile garage-snowflake

test-bigquery:
	dbt deps
	dbt seed --target bigquery --full-refresh
	dbt run --target bigquery --full-refresh --vars 'update: false'
	dbt run --target bigquery --vars 'update: true'
	dbt test --target bigquery

test-all: test-postgres test-redshift test-snowflake test-bigquery
	echo "Completed successfully"
