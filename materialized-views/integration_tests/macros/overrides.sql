{# postgres + redshift #}

{% macro drop_relation(relation) -%}
  {{ return(dbt_labs_materialized_views.drop_relation(relation)) }}
{% endmacro %}

{% macro postgres__list_relations_without_caching(schema_relation) %}
  {{ return(dbt_labs_materialized_views.postgres__list_relations_without_caching(schema_relation)) }}
{% endmacro %}

{% macro postgres_get_relations() %}
  {{ return(dbt_labs_materialized_views.postgres_get_relations()) }}
{% endmacro %}

{# redshift only #}

{% macro redshift__list_relations_without_caching(schema_relation) %}
  {{ return(dbt_labs_materialized_views.redshift__list_relations_without_caching(schema_relation)) }}
{% endmacro %}

{% macro load_relation(relation) %}
  {% if adapter.type() == 'redshift' %}
    {{ return(dbt_labs_materialized_views.redshift_load_relation_or_mv(relation)) }}
  {% else %}
    {{ return(dbt.load_relation(relation)) }}
  {% endif %}
{% endmacro %}
