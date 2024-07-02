{# postgres + redshift #}

{% macro postgres_get_relations() %}
  {{ return(dbt_labs_materialized_views.postgres_get_relations()) }}
{% endmacro %}

{# redshift only #}

{% macro load_relation(relation) %}
  {% if adapter.type() == 'redshift' %}
    {{ return(dbt_labs_materialized_views.redshift_load_relation_or_mv(relation)) }}
  {% else %}
    {{ return(dbt.load_relation(relation)) }}
  {% endif %}
{% endmacro %}
