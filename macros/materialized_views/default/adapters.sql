{% macro create_materialized_view_as(relation, sql, config) %}
    {{ adapter_macro('dbt_labs_experimental_features.create_materialized_view_as', relation, sql, config) }}
{% endmacro %}

{% macro default__create_materialized_view_as(relation, sql, config) -%}

    create materialized view {{relation}} as (
        {{sql}}
    )

{% endmacro %}


{% macro refresh_materialized_view(relation, config) %}
    {{ adapter_macro('dbt_labs_experimental_features.refresh_materialized_view', relation, config) }}
{% endmacro %}

{% macro default__refresh_materialized_view(relation, config) -%}

    refresh materialized view {{relation}}

{% endmacro %}


{% macro drop_materialized_view(relation) %}
    {{ adapter_macro('dbt_labs_experimental_features.drop_materialized_view', relation) }}
{% endmacro %}

{% macro default__drop_materialized_view(relation) %}

    drop materialized view if exists {{relation}} cascade

{% endmacro %}



{% macro is_materialized_view(relation) %}
    {{ return(adapter_macro('dbt_labs_experimental_features.is_materialized_view', relation)) }}
{% endmacro %}

{% macro default__is_materialized_view(relation) %}
    {% set is_matview = (relation.type == 'materialized view') %}
    {% do return(is_matview) %}
{% endmacro %}
