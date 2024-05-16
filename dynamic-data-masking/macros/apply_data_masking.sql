{% macro apply_data_masking(columns) %}
{% set relation_type='view' if model.config.materialized == 'view' else 'table' %}
create masking policy if not exists {{ this.database }}.{{ this.schema }}.masking_policy__text as (val text) returns text ->
    case
        when current_role() = 'TRANSFORMER' then val
        else md5(val)
    end;
{% for col in columns %}
    alter {{ relation_type }} {{ this }} modify column {{ col }} set masking policy {{ this.database }}.{{ this.schema }}.masking_policy__text;
{% endfor %}

{% endmacro %}
