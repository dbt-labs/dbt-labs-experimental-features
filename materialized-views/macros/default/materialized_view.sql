{% materialization materialized_view, default -%}

  {% set full_refresh_mode = (should_full_refresh()) %}

  {% set target_relation = this %}
  {% set existing_relation = load_relation(this) %}
  {% set tmp_relation = make_temp_relation(this) %}
  
  {{ run_hooks(pre_hooks, inside_transaction=False) }}

  -- `BEGIN` happens here:
  {{ run_hooks(pre_hooks, inside_transaction=True) }}

  {% set to_drop = [] %}
  
  {% if existing_relation is none %}
      {% set build_sql = dbt_labs_materialized_views.create_materialized_view_as(target_relation, sql, config) %}
  
  {% elif full_refresh_mode or existing_relation.type != 'materializedview' %}
      {#-- Make sure the backup doesn't exist so we don't encounter issues with the rename below #}
      {% set backup_identifier = existing_relation.identifier ~ "__dbt_backup" %}
      {% set backup_relation = existing_relation.incorporate(path={"identifier": backup_identifier}) %}
      {% do adapter.drop_relation(backup_relation) %}

      {% do adapter.rename_relation(target_relation, backup_relation) %}
      {% set build_sql = dbt_labs_materialized_views.create_materialized_view_as(target_relation, sql, config) %}
      {% do to_drop.append(backup_relation) %}
  
  {% else %}
      {% set build_sql = dbt_labs_materialized_views.refresh_materialized_view(target_relation, config) %}
  {% endif %}

  {% if build_sql %}

      {% call statement("main") %}
          {{ build_sql }}
      {% endcall %}
      
      {{ run_hooks(post_hooks, inside_transaction=True) }}
      
      {% do persist_docs(target_relation, model) %}

      -- `COMMIT` happens here
      {% do adapter.commit() %}
 
  {% else %}

    {{ store_result('main', 'SKIP') }}

  {% endif %}  

  {% for rel in to_drop %}
      {% do adapter.drop_relation(rel) %}
  {% endfor %}

  {{ run_hooks(post_hooks, inside_transaction=False) }}

  {{ return({'relations': [target_relation]}) }}

{%- endmaterialization %}
