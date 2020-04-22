{% macro redshift__create_table_as(relation, sql, config) -%}

  {%- set _dist = config.get('dist') -%}
  {%- set _sort_type = config.get(
          'sort_type',
          validator=validation.any['compound', 'interleaved']) -%}
  {%- set _sort = config.get(
          'sort',
          validator=validation.any[list, basestring]) -%}
  {%- set sql_header = config.get('sql_header', none) -%}

  {{ sql_header if sql_header is not none }}

  create materialized view {{ relation }}
    {{ dist(_dist) }}
    {{ sort(_sort_type, _sort) }}
  as (
    {{ sql }}
  );
{%- endmacro %}


{% macro redshift__is_materialized_view(relation) %}

    {% set existing_relation = load_relation(this) %}

    {# materialized views do appear in pg_views #}
    {% if existing_relation.is_view %}

        {% set find_matview %}
        
            select count(*) from pg_views
            where schemaname = 'dbt_jcohen'
            and viewname = 'test_mv'
            and definition ilike '%create materialized view%'
        
        {% endset %}
        
        {% if execute %}
            {% set result = run_query(find_matview)[0][0] %}
        {% else %}
            {% set result = 0 %}
        {% endif %}

        {% set is_matview = (result > 0) %}
        {% do return(is_matview) %}
        
    {% else %}
    
        {% do return(false) %}
        
    {% endif %}

{% endmacro %}
