{% macro partition_by(partition_config) -%}
    {%- if partition_config is none -%}
      {% do return('') %}
    {%- elif partition_config.data_type | lower in ('date','timestamp','datetime') -%}
        partition by {{ partition_config.render() }}
    {%- elif partition_config.data_type | lower in ('int64') -%}
        {%- set range = partition_config.range -%}
        partition by range_bucket(
            {{ partition_config.field }},
            generate_array({{ range.start}}, {{ range.end }}, {{ range.interval }})
        )
    {%- endif -%}
{%- endmacro -%}

{% macro cluster_by(raw_cluster_by) %}
  {%- if raw_cluster_by is not none -%}
  cluster by {% if raw_cluster_by is string -%}
    {% set raw_cluster_by = [raw_cluster_by] %}
  {%- endif -%}
  {%- for cluster in raw_cluster_by -%}
    {{ cluster }}
    {%- if not loop.last -%}, {% endif -%}
  {%- endfor -%}

  {% endif %}

{%- endmacro -%}

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
    {%- set raw_partition_by = config.get('partition_by', none) -%}
    {%- set partition_config = adapter.parse_partition_by(raw_partition_by) -%}
    {%- set raw_cluster_by = config.get('cluster_by', none) -%}


    {{ sql_header if sql_header is not none }}

    create materialized view {{relation}}
    {{ partition_by(partition_config) }}
    {{ cluster_by(raw_cluster_by) }}
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
