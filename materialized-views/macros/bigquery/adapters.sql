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

    {%- set enable_refresh = config.get('auto_refresh', none) -%}
    {%- set refresh_interval_minutes = config.get('refresh_interval_minutes', none) -%}
    {%- set sql_header = config.get('sql_header', none) -%}

    {{ sql_header if sql_header is not none }}

    create materialized view {{relation}}
    {{ dbt_labs_materialized_views.bigquery_options(
        enable_refresh=enable_refresh, 
        refresh_interval_minutes=refresh_interval_minutes
    ) }}
    as (
        {{sql}}
    )

{% endmacro %}


{% macro bigquery__refresh_materialized_view(relation, config) -%}
    
    {%- set is_auto_refresh = config.get('auto_refresh', true) %}
    
    {%- if is_auto_refresh == false -%} {# manual refresh #}
    
        {% set refresh_command %}
        call bq.refresh_materialized_view('{{relation|replace("`","")}}')
        {% endset %}
        
        {%- do return(refresh_command) -%}
    
    {%- else -%} {# automatic refresh #}
    
        {%- do log("Skipping materialized view " ~ relation ~ " because it is set
            to refresh automatically") -%}
            
        {%- do return(none) -%}
    
    {%- endif -%}

{% endmacro %}
