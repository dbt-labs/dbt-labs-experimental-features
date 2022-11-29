# Custom insert by period materialization

`insert_by_period` allows dbt to insert records into a table one period (i.e. day, week) at a time.

This materialization is appropriate for event data that can be processed in discrete periods. It is similar in concept to the built-in incremental materialization, but has the added benefit of building the model in chunks even during a full-refresh so is particularly useful for models where the initial run can be problematic.

Should a run of a model using this materialization be interrupted, a subsequent run will continue building the target table from where it was interrupted (granted the `--full-refresh` flag is omitted).

Progress is logged in the command line for easy monitoring.

## Installation
This is not a package on the Package Hub. To install it via git, add this to `packages.yml`:
```yaml
packages:
  - git: https://github.com/dbt-labs/dbt-labs-experimental-features
    subdirectory: insert_by_period
    revision: XXXX #optional but highly recommended. Provide a full git sha hash, e.g. 7180db61d26836b931aa6ef8ad9d70e7fb3a69fa. If not provided, uses the current HEAD.

```

## Usage:

```sql
{{
  config(
    materialized = "insert_by_period",
    period = "day",
    timestamp_field = "created_at",
    start_date = "2018-01-01",
    stop_date = "2018-06-01")
}}
with events as (
  select *
  from {{ ref('events') }}
  where __PERIOD_FILTER__ -- This will be replaced with a filter in the materialization code
)
....complex aggregates here....
```

**Configuration values:**

- `period`: period to break the model into, must be a valid [datepart](https://docs.aws.amazon.com/redshift/latest/dg/r_Dateparts_for_datetime_functions.html) (default='Week')
- `timestamp_field`: the column name of the timestamp field that will be used to break the model into smaller queries
- `start_date`: literal date or timestamp - generally choose a date that is earlier than the start of your data
- `stop_date`: literal date or timestamp (default=current_timestamp)

**Caveats:**

- This materialization has been written for Redshift.
- This materialization can only be used for a model where records are not expected to change after they are created.
- Any model post-hooks that use `{{ this }}` will fail using this materialization. For example:

```yaml
models:
    project-name:
        post-hook: "grant select on {{ this }} to db_reader"
```

A useful workaround is to change the above post-hook to:

```yaml
        post-hook: "grant select on {{ this.schema }}.{{ this.name }} to db_reader"
```
