test-databricks:
	dbt deps
	dbt seed --target databricks --full-refresh
	dbt run -s test_insert_by_period --target databricks --full-refresh
	dbt test
	dbt run -s test_insert_by_period --target databricks --vars 'test_backfill: True'
	dbt test --target databricks

test-all: test-databricks
	echo "Completed successfully"