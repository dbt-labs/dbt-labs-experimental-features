# dbt Labs: Experimental Features

This package will add dbt support for database features which are not
yet supported natively in dbt-core.

### Materialized views

This package adds support for `materialized_view` as a dbt materialization. It takes an
approach similar to that of the existing `incremental` materialization:
- In a "full refresh" run, drop and recreate the MV from scratch.
- Otherwise, "refresh" the MV as appropriate. Depending on the database, that could be DML (`refresh`) or noop.

At any point, if the database object corresponding to a MV model exists instead as a table
or standard view, dbt will attempt to drop it and recreate the model from scratch as a 
materialized view.

#### Postgres

- Supported model configs: none
- [docs](https://www.postgresql.org/docs/9.3/rules-materializedviews.html)

##### Current issues
- Materialized views are registered in `pg_matviews`. Because dbt's current caching
only checks `pg_tables` and `pg_views` for existing relations, the current approach is to work around
the cache and check `pg_matviews` from within the materialization.
- dbt only allows 'materializedview' as a `RelationType`. (See [here](https://github.com/fishtown-analytics/dbt/blob/dev/octavius-catto/core/dbt/adapters/base/relation.py#L24)). When we try to use
`adapter.rename` or `adapter.drop`, the database is expecting `drop materialized view ...` or `alter materialized view ... rename`,
not `drop materializedview ...` or `alter materializedview ... rename`.

#### Redshift

- Supported model configs: `sort`, `dist`
- [docs](https://docs.aws.amazon.com/redshift/latest/dg/materialized-view-overview.html)
- Anecdotally, `refresh materialized view ...` is _very_ slow to run

##### Current issues
- MVs do not support late binding. If the base table is cascade dropped, the materialized view seems to stick around in the cache. We need
some way to "hard refresh" the cache or check the database after running parents.
- If the column is renamed or removed + readded (e.g. varchar widening), the materialized view cannot be refreshed.
```
Database Error in model test_mv (models/test_mv.sql)
  Materialized view test_mv is unrefreshable as a column was renamed for a base table.
  compiled SQL at target/run/dbt_labs_experimental_features_integration_tests/test_mv.sql
```

#### BigQuery

- Supported model configs: `enable_refresh`, `refresh_interval_minutes`
- [docs](https://cloud.google.com/bigquery/docs/materialized-views-intro)
- Although BQ does not have `drop ... cascade`, if the base table of a materialized is dropped
and recreated, the MV also needs to be dropped and recreated
```
Materialized view dbt-dev-168022:dbt_jcohen.test_mv references table dbt-dev-168022:dbt_jcohen.base_tbl which was deleted and recreated. The view must be deleted and recreated as well.
```

#### Snowflake

- support TK
- [docs](https://docs.snowflake.com/en/user-guide/views-materialized.html) (note: you must have enterprise edition)


### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
