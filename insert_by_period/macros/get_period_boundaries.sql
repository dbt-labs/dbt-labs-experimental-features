{% macro get_period_boundaries(target_schema, target_table, timestamp_field, start_date, stop_date, period) -%}
    {{ return(adapter.dispatch('get_period_boundaries', 'insert_by_period')(target_schema, target_table, timestamp_field, start_date, stop_date, period)) }}
{% endmacro %}

{% macro default__get_period_boundaries(target_schema, target_table, timestamp_field, start_date, stop_date, period) -%}

  {% call statement('period_boundaries', fetch_result=True) -%}
    with data as (
      select
          coalesce(max("{{timestamp_field}}"), '{{start_date}}')::timestamp as start_timestamp,
          coalesce(
            {{ dateadd('millisecond',
                                -1,
                                "nullif('" ~ stop_date ~ "','')::timestamp") }},
            {{ dbt.current_timestamp() }}
          ) as stop_timestamp
      from "{{target_schema}}"."{{target_table}}"
    )

    select
      start_timestamp,
      stop_timestamp,
      {{ datediff('start_timestamp',
                           'stop_timestamp',
                           period) }}  + 1 as num_periods
    from data
  {%- endcall %}

{%- endmacro %}
