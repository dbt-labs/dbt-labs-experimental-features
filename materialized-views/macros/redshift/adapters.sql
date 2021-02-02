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


{% macro redshift__list_relations_without_caching(schema_relation) %}
  {#
    pretty silly, but this is the best Redshift has given us.
    we effectively can't join stv_mv_info here,
    because they're different types of sytem tables (pg_ vs. stv_)
  #}

  {% call statement('list_relations_without_caching', fetch_result=True) -%}
    select
      '{{ schema_relation.database }}' as database,
      tablename as name,
      schemaname as schema,
      'table' as type
    from pg_tables
    where schemaname ilike '{{ schema_relation.schema }}'
    union all
    select
      '{{ schema_relation.database }}' as database,
      viewname as name,
      schemaname as schema,
      case when definition ilike '%create materialized view%'
        then 'materializedview'
        else 'view'
        end as type
    from pg_views
    where schemaname ilike '{{ schema_relation.schema }}'
  {% endcall %}
  
  {{ return(load_result('list_relations_without_caching').table) }}
{% endmacro %}

