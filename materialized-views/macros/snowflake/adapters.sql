{% macro snowflake__create_materialized_view_as(relation, sql, config) -%}
    {%- set secure = config.get('secure', default=false) -%}
    {%- set cluster_by_keys = config.get('cluster_by', default=none) -%}
    {%- set enable_automatic_clustering = config.get('automatic_clustering', default=false) -%}
    {%- set sql_header = config.get('sql_header', none) -%}

    {%- if cluster_by_keys is not none and cluster_by_keys is string -%}
        {%- set cluster_by_keys = [cluster_by_keys] -%}
    {%- endif -%}
    {%- if cluster_by_keys is not none -%}
        {%- set cluster_by_string = cluster_by_keys|join(", ")-%}
    {% else %}
        {%- set cluster_by_string = none -%}
    {%- endif -%}

    {{ sql_header if sql_header is not none }}

    create or replace 
        {% if secure -%} secure {%- endif %} 
        materialized view {{relation}}
    as (
        {{sql}}
    );
    
    {% if cluster_by_string is not none and not temporary -%}
      alter materialized view {{relation}} cluster by ({{cluster_by_string}});
    {%- endif -%}
    {% if enable_automatic_clustering and cluster_by_string is not none and not temporary  -%}
      alter materialized view {{relation}} resume recluster;
    {%- endif -%}

{% endmacro %}
