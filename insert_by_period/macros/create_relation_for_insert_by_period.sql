{% macro create_relation_for_insert_by_period(tmp_identifier, schema, type) -%}
    {{ return(adapter.dispatch('create_relation_for_insert_by_period', 'insert_by_period')(tmp_identifier, schema, type)) }}
{% endmacro %}

{% macro default__create_relation_for_insert_by_period(tmp_identifier, schema, type) -%}
    {% do return (api.Relation.create(identifier=tmp_identifier,
                                               schema=schema, type=type)) %}
{%- endmacro %}

{% macro postgres__create_relation_for_insert_by_period(tmp_identifier, schema, type) -%}
    {% do return (api.Relation.create(identifier=tmp_identifier,
                                               schema=None, type=type)) %}
{%- endmacro %}
