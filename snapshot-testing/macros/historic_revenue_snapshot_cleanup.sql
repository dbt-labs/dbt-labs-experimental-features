{% macro historic_revenue_snapshot_cleanup() %}
    {% set create_sql %}
        create table if not exists dbt_snapshots.historic_revenue_snapshot_invalidated as (
            select
                *,
                current_timestamp as _inserted_at
            from {{ ref('historic_revenue_snapshot') }}
            limit 0
        )
    {% endset %}
    {% set insert_sql %}
        insert into dbt_snapshots.historic_revenue_snapshot_invalidated (
            select
                *,
                current_timestamp as _inserted_at
            from {{ ref('historic_revenue_snapshot') }}
            where dbt_valid_to is not null
        );
    {% endset %}

  {% set delete_sql %}
  delete from {{ ref('historic_revenue_snapshot') }} where dbt_valid_to is not null
  {% endset %}

  {% do run_query('begin') %}
  {% do run_query(create_sql) %}
  {% do run_query(insert_sql) %}
  {% do run_query(delete_sql) %}
  {% do run_query('commit') %}

{% endmacro %}
