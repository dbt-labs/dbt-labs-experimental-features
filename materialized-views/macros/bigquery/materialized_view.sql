{% materialization materialized_view, adapter='bigquery' -%}

  {% set full_refresh_mode = (should_full_refresh()) %}

  {% set target_relation = this %}
  {% set existing_relation = load_relation(this) %}
  {% set tmp_relation = make_temp_relation(this) %}

  {{ run_hooks(pre_hooks) }}

  {% if existing_relation is none %}
      {% set build_sql = dbt_labs_materialized_views.create_materialized_view_as(target_relation, sql, config) %}
  {% elif existing_relation.is_view or existing_relation.is_table %}
      {#-- Can't overwrite a view with a table - we must drop --#}
      {{ log("Dropping relation " ~ target_relation ~ " because it is a " ~ existing_relation.type ~ " and this model is a materialized view.") }}
      {% do adapter.drop_relation(existing_relation) %}
      {% set build_sql = dbt_labs_materialized_views.create_materialized_view_as(target_relation, sql, config) %}
  {% elif full_refresh_mode %}
      {#-- create or replace not yet supported for materialized views --#}
      {{ log("Dropping relation " ~ target_relation ~ " because replacing an existing materialized view is not supported.") }}
      {% do adapter.drop_relation(existing_relation) %}
      {% set build_sql = dbt_labs_materialized_views.create_materialized_view_as(target_relation, sql, config) %}
  {% else %}
      {% set build_sql = dbt_labs_materialized_views.refresh_materialized_view(target_relation, config) %}
  {% endif %}

  {% if build_sql %}
      {% call statement("main") %}
          {{ build_sql }}
      {% endcall %}
  {% else %}
    {{ store_result('main', 'SKIP') }}
  {% endif %}

  {{ run_hooks(post_hooks) }}
  
  {% do persist_docs(target_relation, model) %}

  {{ return({'relations': [target_relation]}) }}

{%- endmaterialization %}
