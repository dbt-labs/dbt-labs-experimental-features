# Using snapshots to detect dbt model regressions
This dbt project is a worked example to demonstrate how to use snapshots to detect dbt model regressions. **Check out the full write-up [on Discourse](to-do).**

The SQL in this project is compatible with Snowflake¹.

If you want to run this project yourself to play with it (assuming you have
dbt installed):
1. Clone this repo.
2. `cd` into this directory
2. Create a profile named `acme`, or update the `profile:` key in the `dbt_project.yml` file to point to an existing profile ([docs](https://docs.getdbt.com/docs/configure-your-profile)).
3. Run `dbt seed`.
4. Run `dbt snapshot`.
4. Run `dbt test` — no test failures should occur.
5. Run `dbt snapshot` a second time — on this run, a regression should be introduced.
6. Run `dbt test` to see the failure.
7. Run `dbt run-operation historic_revenue_snapshot_cleanup` to move the rogue record into an audit table.
8. Run `dbt test` again to see the healed failure.

-----
1. We decided to _not_ check that the SQL in this project is multi-warehouse compatible — it _might_ work on other warehouses!
