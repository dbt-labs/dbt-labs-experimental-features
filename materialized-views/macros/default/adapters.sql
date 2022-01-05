{% macro create_materialized_view_as(relation, sql, config) %}
    {{ return(adapter.dispatch('create_materialized_view_as', macro_namespace = 'dbt_labs_materialized_views')(relation, sql, config)) }}
{% endmacro %}

{% macro default__create_materialized_view_as(relation, sql, config) -%}

    create materialized view {{relation}} as (
        {{sql}}
    )

{% endmacro %}

{% macro refresh_materialized_view(relation, config) %}
    {{ return(adapter.dispatch('refresh_materialized_view', macro_namespace = 'dbt_labs_materialized_views')(relation, config)) }}
{% endmacro %}

{% macro default__refresh_materialized_view(relation, config) -%}

    refresh materialized view {{relation}}

{% endmacro %}

{# override builtin behavior of adapter.drop_relation #}
{% macro drop_relation(relation) -%}
  {% set relation_type = 'materialized view' if relation.type == 'materializedview' else relation.type %}
  {% call statement('drop_relation', auto_begin=False) -%}
    drop {{ relation_type }} if exists {{ relation }} cascade
  {%- endcall %}
{% endmacro %}
