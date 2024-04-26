{% macro get_period_sql(target_cols_csv, sql, timestamp_field, period, start_timestamp, stop_timestamp, offset) -%}
    {{ return(adapter.dispatch('get_period_sql', 'insert_by_period')(target_cols_csv, sql, timestamp_field, period, start_timestamp, stop_timestamp, offset)) }}
{% endmacro %}

{% macro default__get_period_sql(target_cols_csv, sql, timestamp_field, period, start_timestamp, stop_timestamp, offset) -%}

  {%- set period_filter -%}
    ({{timestamp_field}} >  '{{start_timestamp}}'::timestamp + interval '{{offset}} {{period}}' and
     {{timestamp_field}} <= '{{start_timestamp}}'::timestamp + interval '{{offset}} {{period}}' + interval '1 {{period}}' and
     {{timestamp_field}} <  '{{stop_timestamp}}'::timestamp)
  {%- endset -%}

  {%- set filtered_sql = sql | replace("__PERIOD_FILTER__", period_filter) -%}

  select
    {{target_cols_csv}}
  from (
    {{filtered_sql}}
  ) target_cols

{%- endmacro %}


{% macro bigquery__get_period_sql(target_cols_csv, sql, timestamp_field, period, start_timestamp, stop_timestamp, offset) -%}

  {%- set period_filter -%}
    ({{timestamp_field}} >  cast(cast(timestamp('{{start_timestamp}}') as datetime) + interval {{offset}} {{period}} as timestamp) and
     {{timestamp_field}} <= cast(cast(timestamp('{{start_timestamp}}') as datetime) + interval {{offset}} {{period}} + interval 1 {{period}} as timestamp) and
     {{timestamp_field}} <  cast('{{stop_timestamp}}' as timestamp))
  {%- endset -%}

  {%- set filtered_sql = sql | replace("__PERIOD_FILTER__", period_filter) -%}

  select
    {{target_cols_csv}}
  from (
    {{filtered_sql}}
  ) target_cols

{%- endmacro %}