{% macro get_period_boundaries(target_schema, target_table, timestamp_field, start_date, stop_date, period, backfill, full_refresh_mode) -%}
    {{ return(adapter.dispatch('get_period_boundaries', 'insert_by_period')(target_schema, target_table, timestamp_field, start_date, stop_date, period, backfill, full_refresh_mode)) }}
{% endmacro %}

{% macro default__get_period_boundaries(target_schema, target_table, timestamp_field, start_date, stop_date, period, backfill, full_refresh_mode) -%}

  {% call statement('period_boundaries', fetch_result=True) -%}
    with data as (
      select
          {% if backfill and not full_refresh_mode -%}
            cast('{{start_date}}' as timestamp) as start_timestamp,
          {%- else -%}
            coalesce(max({{timestamp_field}}), cast('{{start_date}}' as timestamp)) as start_timestamp,
          {%- endif %}
          coalesce(
            {{ dateadd('millisecond',
                                -1,
                                "cast(nullif('" ~ stop_date ~ "','') as timestamp)") }},
            {{ dbt.current_timestamp() }}
          ) as stop_timestamp
      from {{adapter.quote(target_schema)}}.{{adapter.quote(target_table)}}
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


{% macro bigquery__get_period_boundaries(target_schema, target_table, timestamp_field, start_date, stop_date, period, backfill, full_refresh_mode) -%}

  {% call statement('period_boundaries', fetch_result=True) -%}
    with data as (
      select
          {% if backfill and not full_refresh_mode -%}
          cast('{{start_date}}' as timestamp) as start_timestamp,
          {%- else -%}
          coalesce(max({{timestamp_field}}), cast('{{start_date}}' as timestamp)) as start_timestamp,
          {%- endif %}
          coalesce(datetime_add(cast(nullif('{{stop_date}}','') as timestamp), interval -1 millisecond), {{dbt.current_timestamp()}}) as stop_timestamp
      from {{adapter.quote(target_schema)}}.{{adapter.quote(target_table)}}
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