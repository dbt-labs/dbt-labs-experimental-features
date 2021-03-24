{% macro redshift__create_materialized_view_as(relation, sql, config) -%}

  {%- set _dist = config.get('dist') -%}
  {%- set _sort_type = config.get(
          'sort_type',
          validator=validation.any['compound', 'interleaved']) -%}
  {%- set _sort = config.get(
          'sort',
          validator=validation.any[list, basestring]) -%}
  {%- set sql_header = config.get('sql_header', none) -%}
  {%- set auto_refresh = 'yes' if config.get('auto_refresh', false) else 'no' %}

  {{ sql_header if sql_header is not none }}

  create materialized view {{ relation }}
    {{ dist(_dist) }}
    {{ sort(_sort_type, _sort) }}
    auto refresh {{ auto_refresh }}
  as (
    {{ sql }}
  );
{%- endmacro %}


{% macro redshift__refresh_materialized_view(relation, config) -%}

    {%- set is_auto_refresh = config.get('auto_refresh', true) %}

    {%- if is_auto_refresh == false -%} {# manual refresh #}

        refresh materialized view {{relation}}
    
    {%- else -%} {# automatic refresh #}
    
        {%- do log("Skipping materialized view " ~ relation ~ " because it is set
            to refresh automatically") -%}
            
        {%- do return(none) -%}
    
    {%- endif -%}

{% endmacro %}


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


{% macro redshift_load_relation_or_mv(relation) %}
  
  {% set rel = adapter.get_relation(
    database=relation.database,
    schema=relation.schema,
    identifier=relation.identifier
  ) -%}
  
  {% if rel.type == 'materializedview' and execute %}
  
    {# materialized views are not properly registered in pg_depend,
       so the cache can miss that they've been dropped
       https://github.com/awslabs/amazon-redshift-utils/issues/499 #}

    {% set hard_check_mv_sql %}

        select count(*) from stv_mv_info
        where schema = '{{ rel.schema }}'
        and name = '{{ rel.identifier }}'

    {% endset %}

    {% set result = run_query(hard_check_mv_sql)[0][0] %}
    {% set mv_rel = rel if result > 0 else none %}
    {% do return(mv_rel) %}
  
  {% else %}
  
    {% do return(rel) %}
  
  {% endif %}

{% endmacro %}

