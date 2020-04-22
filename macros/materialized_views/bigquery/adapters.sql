{% macro bigquery_options() %}
  {%- set opts = kwargs -%}
  {%- set options -%}
    OPTIONS({% for opt_key, opt_val in kwargs.items() if opt_val is not none %}
      {{ opt_key }}={{ opt_val }}{{ "," if not loop.last }}
    {%- endfor -%})
  {%- endset %}
  {%- do return(options) -%}
{%- endmacro -%}

{% macro bigquery__create_materialized_view_as(relation, sql, config) -%}

    {%- set enable_refresh = config.get('enable_refresh', none) -%}
    {%- set refresh_interval_minutes = config.get('refresh_interval_minutes', none) -%}
    {%- set sql_header = config.get('sql_header', none) -%}

    {{ sql_header if sql_header is not none }}

    create materialized view {{relation}}
    {{ dbt_labs_experimental_features.bigquery_options(
        enable_refresh=enable_refresh, 
        refresh_interval_minutes=refresh_interval_minutes
    ) }}
    as (
        {{sql}}
    )

{% endmacro %}


{% macro bigquery__refresh_materialized_view(relation, config) -%}
    
    {%- set is_auto_refresh = config.get('enable_refresh', true) %}
    
    {%- if not is_auto_refresh -%} {# manual refresh #}
    
        call bq.refresh_materialized_view('{{relation|replace('`','')}}')
    
    {%- else -%} {# automatic refresh #}
    
        {%- do log("Skipping materialized view " ~ relation ~ " because it is set
            to refresh automatically") -%}
    
        -- noop
        select 1 as fun
    
    {%- endif -%}

{% endmacro %}
