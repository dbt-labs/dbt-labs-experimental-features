## dbt_labs_materialized_views

`dbt_labs_materialized_views` is a dbt project containing materializations, helper macros, and some builtin macro overrides that enable use of materialized views in your dbt project. It takes a conceptual approach similar to that of the existing `incremental` materialization:
- In a "full refresh" run, drop and recreate the MV from scratch.
- Otherwise, "refresh" the MV as appropriate. Depending on the database, that could require DML (`refresh`) or no action.

At any point, if the database object corresponding to a MV model exists instead as a table or standard view, dbt will attempt to drop it and recreate the model from scratch as a materialized view.

Materialized views vary significantly across databases, as do their current limitations. Be sure to read the documentation for your adapter.

If you're here, you may also like the [dbt-materialize](https://github.com/MaterializeInc/materialize/tree/main/misc/dbt-materialize) plugin, which enables dbt to materialize models as materialized views in [Materialize](https://materialize.io/).

## Setup

### General installation:

You can install the materialized-view project as a package, to get access to it in your own project, either as a `local` package (by cloning this repository to your machine) or as a `git` package referencing the `materialized-views` subdirectory:
```yml
# packages.yml
packages:
  - git: https://github.com/dbt-labs/dbt-labs-experimental-features.git
    subdirectory: materialized-views
```

If you do this, you'll need to set the `dispatch` project config ([docs](https://docs.getdbt.com/reference/dbt-jinja-functions/dispatch)), since some functionality in this package requires overriding built-in dbt macros:
```yml
# dbt_project.yml
dispatch:
  - macro_namespace: dbt
    search_order: ['dbt_labs_materialized_views', 'dbt']
```

You're also welcome to copy, paste, and edit the files from `macros/` (specifically `default` and your adapter) in your own project's `macros/` directory. If you find spots for improvement, we welcome PRs back to this repository.

### Extra installation steps for Postgres and Redshift

The Postgres and Redshift implementations both require overriding the builtin versions of some adapter macros. If you've installed `dbt_labs_materialized_views` as a local package, you can achieve this override by creating a file `macros/*.sql` in your project with the following contents:

```sql
{# postgres + redshift #}

{% macro postgres_get_relations() %}
  {{ return(dbt_labs_materialized_views.postgres_get_relations()) }}
{% endmacro %}

{# redshift only #}

{% macro load_relation(relation) %}
  {% if adapter.type() == 'redshift' %}
    {{ return(dbt_labs_materialized_views.redshift_load_relation_or_mv(relation)) }}
  {% else %}
    {{ return(dbt.load_relation(relation)) }}
  {% endif %}
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
