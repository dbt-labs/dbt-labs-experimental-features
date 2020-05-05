{% materialization materialized_view, adapter='snowflake' -%}

  {% set full_refresh_mode = flags.FULL_REFRESH %}

  {% set target_relation = this %}
  {% set existing_relation = load_relation(this) %}
  {% set tmp_relation = make_temp_relation(this) %}

  {{ run_hooks(pre_hooks) }}

  {% if (existing_relation is none or full_refresh_mode) %}
      {% set build_sql = dbt_labs_experimental_features.create_materialized_view_as(target_relation, sql, config) %}
  {% elif existing_relation.is_view or existing_relation.is_table %}
      {#-- Can't overwrite a view with a table - we must drop --#}
      {{ log("Dropping relation " ~ target_relation ~ " because it is a " ~ existing_relation.type ~ " and this model is a materialized view.") }}
      {% do adapter.drop_relation(existing_relation) %}
      {% set build_sql = dbt_labs_experimental_features.create_materialized_view_as(target_relation, sql, config) %}
  {% else %}
      {# noop #}
  {% endif %}
  
  {% if build_sql %}
      {% call statement("main") %}
          {{ build_sql }}
      {% endcall %}
  {% else %}
    {{ store_result('main', status='SKIP') }}
  {% endif %}

  {{ run_hooks(post_hooks) }}

  {{ return({'relations': [target_relation]}) }}

{%- endmaterialization %}
