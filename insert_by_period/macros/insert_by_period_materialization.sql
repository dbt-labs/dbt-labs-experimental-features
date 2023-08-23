{% materialization insert_by_period, default -%}
  {%- set timestamp_field = config.require('timestamp_field') -%}
  {%- set start_date = config.require('start_date') -%}
  {%- set stop_date = config.get('stop_date') or '' -%}
  {%- set period = config.get('period') or 'week' -%}

  {%- if sql.find('__PERIOD_FILTER__') == -1 -%}
    {%- set error_message -%}
      Model '{{ model.unique_id }}' does not include the required string '__PERIOD_FILTER__' in its sql
    {%- endset -%}
    {{ exceptions.raise_compiler_error(error_message) }}
  {%- endif -%}

  {%- set identifier = model['name'] -%}

  {%- set old_relation = adapter.get_relation(database=database, schema=schema, identifier=identifier) -%}
  {%- set target_relation = api.Relation.create(identifier=identifier, schema=schema, type='table') -%}

  {%- set non_destructive_mode = (flags.NON_DESTRUCTIVE == True) -%}
  {%- set full_refresh_mode = (flags.FULL_REFRESH == True) -%}

  {%- set exists_as_table = (old_relation is not none and old_relation.is_table) -%}
  {%- set exists_not_as_table = (old_relation is not none and not old_relation.is_table) -%}

  {%- set should_truncate = (non_destructive_mode and full_refresh_mode and exists_as_table) -%}
  {%- set should_drop = (not should_truncate and (full_refresh_mode or exists_not_as_table)) -%}
  {%- set force_create = (flags.FULL_REFRESH and not flags.NON_DESTRUCTIVE) -%}

  -- setup
  {% if old_relation is none -%}
    -- noop
  {%- elif should_truncate -%}
    {{adapter.truncate_relation(old_relation)}}
  {%- elif should_drop -%}
    {{adapter.drop_relation(old_relation)}}
    {%- set old_relation = none -%}
  {%- endif %}

  {{run_hooks(pre_hooks, inside_transaction=False)}}

  -- `begin` happens here, so `commit` after it to finish the transaction
  {{run_hooks(pre_hooks, inside_transaction=True)}}
  {% call statement() -%}
    begin; -- make extra sure we've closed out the transaction
    commit;
  {%- endcall %}

  -- build model
  {% if force_create or old_relation is none -%}
    {# Create an empty target table -#}
    {% call statement('main') -%}
      {%- set empty_sql = sql | replace("__PERIOD_FILTER__", 'false') -%}
      {{create_table_as(False, target_relation, empty_sql)}}
    {%- endcall %}
  {%- endif %}

  {% set period_boundaries = insert_by_period.get_period_boundaries(
    schema,
    identifier,
    timestamp_field,
    start_date,
    stop_date,
    period
  ) %}
  {% set period_boundaries_results = load_result('period_boundaries')['data'][0] %}
  {%- set start_timestamp = period_boundaries_results[0] | string -%}
  {%- set stop_timestamp = period_boundaries_results[1] | string -%}
  {%- set num_periods = period_boundaries_results[2] | int -%}

  {% set target_columns = adapter.get_columns_in_relation(target_relation) %}
  {%- set target_cols_csv = target_columns | map(attribute='quoted') | join(', ') -%}
  {%- set loop_vars = {'sum_rows_inserted': 0} -%}

  -- commit each period as a separate transaction
  {% for i in range(num_periods) -%}
    {%- set msg = "Running for " ~ period ~ " " ~ (i + 1) ~ " of " ~ (num_periods) -%}
    {{ print(msg) }}

    {%- set tmp_identifier = model['name'] ~ '__dbt_incremental_period' ~ i ~ '_tmp' -%}
    {%- set tmp_relation = insert_by_period.create_relation_for_insert_by_period(tmp_identifier, schema, 'table') -%}
    {% call statement() -%}
      {% set tmp_table_sql = insert_by_period.get_period_sql(target_cols_csv,
                                                       sql,
                                                       timestamp_field,
                                                       period,
                                                       start_timestamp,
                                                       stop_timestamp,
                                                       i) %}
      {{dbt.create_table_as(True, tmp_relation, tmp_table_sql)}}
    {%- endcall %}

    {{adapter.expand_target_column_types(from_relation=tmp_relation,
                                         to_relation=target_relation)}}
    {%- set name = 'main-' ~ i -%}
    {% call statement(name, fetch_result=True) -%}
      insert into {{target_relation}} ({{target_cols_csv}})
      (
          select
              {{target_cols_csv}}
          from {{tmp_relation.include(schema=False)}}
      );
    {%- endcall %}
    {% set result = load_result('main-' ~ i) %}
    {% if 'response' in result.keys() %} {# added in v0.19.0 #}
        {% set rows_inserted = result['response']['rows_affected'] %}
    {% else %} {# older versions #}
        {% set rows_inserted = result['status'].split(" ")[2] | int %}
    {% endif %}

    {%- set sum_rows_inserted = loop_vars['sum_rows_inserted'] + rows_inserted -%}
    {%- if loop_vars.update({'sum_rows_inserted': sum_rows_inserted}) %} {% endif -%}

    {%- set msg = "Ran for " ~ period ~ " " ~ (i + 1) ~ " of " ~ (num_periods) ~ "; " ~ rows_inserted ~ " records inserted" -%}
    {{ print(msg) }}

  {%- endfor %}

  {% call statement() -%}
    begin;
  {%- endcall %}

  {{run_hooks(post_hooks, inside_transaction=True)}}

  {% call statement() -%}
    commit;
  {%- endcall %}

  {{run_hooks(post_hooks, inside_transaction=False)}}

  {%- set status_string = "INSERT " ~ loop_vars['sum_rows_inserted'] -%}

  {% call noop_statement('main', status_string) -%}
    -- no-op
  {%- endcall %}

  -- Return the relations created in this materialization
  {{ return({'relations': [target_relation]}) }}

{%- endmaterialization %}
