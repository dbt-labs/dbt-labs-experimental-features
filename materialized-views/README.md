## dbt_labs_materialized_views

`dbt_labs_materialized_views` is a dbt project containing materializations, helper macros, and some builtin macro overrides that enable use of materialized views in your dbt project. It takes a conceptual approach similar to that of the existing `incremental` materialization:
- In a "full refresh" run, drop and recreate the MV from scratch.
- Otherwise, "refresh" the MV as appropriate. Depending on the database, that could require DML (`refresh`) or no action.

At any point, if the database object corresponding to a MV model exists instead as a table or standard view, dbt will attempt to drop it and recreate the model from scratch as a materialized view.

Materialized views vary significantly across databases, as do their current limitations. Be sure to read the documentation for your adapter.

If you're here, you may also like the [dbt-materialize](https://github.com/MaterializeInc/materialize/tree/main/misc/dbt-materialize) plugin, which enables dbt to materialize models as materialized views in [Materialize](https://materialize.io/).

## Setup

### General installation:

You can install the materialized-view funcionality using one of the following methods.

- Install this project as a package ([package-management docs](https://docs.getdbt.com/docs/building-a-dbt-project/package-management))
  - [Local package](https://docs.getdbt.com/docs/building-a-dbt-project/package-management#local-packages): by referencing the [`materialized-views`](https://github.com/dbt-labs/dbt-labs-experimental-features/tree/master/materialized-views) folder.
  - [Git package](https://docs.getdbt.com/docs/building-a-dbt-project/package-management#git-packages) using [project subdirectories](https://docs.getdbt.com/docs/building-a-dbt-project/package-management#git-packages): again by referencing the [`materialized-views`](https://github.com/dbt-labs/dbt-labs-experimental-features/tree/master/materialized-views) folder.
- Copy-paste the files from `macros/` (specifically `default` and your adapter) into your own project.

### Extra installation steps for Postgres and Redshift

The Postgres and Redshift implementations both require overriding the builtin versions of some adapter macros. If you've installed `dbt_labs_materialized_views` as a local package, you can achieve this override by creating a file `macros/*.sql` in your project with the following contents:

```sql
{# postgres and redshift #}

{% macro drop_relation(relation) -%}
  {{ return(dbt_labs_materialized_views.drop_relation(relation)) }}
{% endmacro %}

{% macro postgres__list_relations_without_caching(schema_relation) %}
  {{ return(dbt_labs_materialized_views.postgres__list_relations_without_caching(schema_relation)) }}
{% endmacro %}

{% macro postgres_get_relations() %}
  {{ return(dbt_labs_materialized_views.postgres_get_relations()) }}
{% endmacro %}

{# redshift only #}

{% macro redshift__list_relations_without_caching(schema_relation) %}
  {{ return(dbt_labs_materialized_views.redshift__list_relations_without_caching(schema_relation)) }}
{% endmacro %}

{% macro load_relation(relation) %}
  {{ return(dbt_labs_materialized_views.redshift_load_relation_or_mv(relation)) }}
{% endmacro %}
```

## Postgres

- Supported model configs: none
- [docs](https://www.postgresql.org/docs/9.3/rules-materializedviews.html)

## Redshift

- Supported model configs: `sort`, `dist`, `auto_refresh`
- [docs](https://docs.aws.amazon.com/redshift/latest/dg/materialized-view-overview.html)
- Anecdotally, `refresh materialized view ...` is very slow to run. By contrast, `auto_refresh` runs in the background, with minimal disruption to other workloads, at the risk of some small potential latency.
- ❗ MVs do not support late binding, so if an underlying table is cascade-dropped, the MV will be dropped as well. This would be fine, except that MVs don't include their "true" dependencies in `pg_depend`. Instead, a materialized view claims to depend on a table relation called `mv_tbl__[MV_name]__0`, in place of the name of the true underlying table (https://github.com/awslabs/amazon-redshift-utils/issues/499). As such, dbt's runtime cache is unable to reliably know if a MV has been dropped when it cascade-drops the underlying table. This package requires an override of `load_relation()` to perform a "hard" check (database query of `stv_mv_info`) every time dbt's cache thinks a `materializedview` relation may already exist.
- ❗ MVs do appear in `pg_views`, but the only way we can know that they're materialized views is that the `create materialized view` DDL appear in their `definition`, instead of just the SQL without DDL (standard views). There's another Redshift system table, `stv_mv_info`, but it can't effectively be joined with `pg_views` because they're different types of system tables.
- ❗ If a column in the underlying table renamed, or removed and readded (e.g. varchar widening), the materialized view cannot be refreshed:
```
Database Error in model test_mv (models/test_mv.sql)
  Materialized view test_mv is unrefreshable as a column was renamed for a base table.
  compiled SQL at target/run/dbt_labs_experimental_features_integration_tests/test_mv.sql
```

## BigQuery

- Supported model configs: `auto_refresh`, `refresh_interval_minutes`
- [docs](https://cloud.google.com/bigquery/docs/materialized-views-intro)
- ❗ Although BQ does not have `drop ... cascade`, if the base table of a MV is dropped and recreated, the MV also needs to be dropped and recreated:
```
Materialized view dbt-dev-168022:dbt_jcohen.test_mv references table dbt-dev-168022:dbt_jcohen.base_tbl which was deleted and recreated. The view must be deleted and recreated as well.
```

## Snowflake

- Supported model configs: `secure`, `cluster_by`, `automatic_clustering`, `persist_docs` (relation only)
- [docs](https://docs.snowflake.com/en/user-guide/views-materialized.html)
- ❗ Note: Snowflake MVs are only enabled on enterprise accounts
- ❗ Although Snowflake does not have `drop ... cascade`, if the base table table of a MV is dropped and recreated, the MV also needs to be dropped and recreated, otherwise the following error will appear:
```
Failure during expansion of view 'TEST_MV': SQL compilation error: Materialized View TEST_MV is invalid.
```
