{% macro mask_column(column_name) %}
    
    -- This is what we will need the macro to say, but for now we want to use a "masking" policy which helps us debug
    case
        when current_user in ('claire') then {{ column_name }}
        else md5({{ column_name }})
    end
   
    {# current_user || '-' || {{ column_name }} #}
{% endmacro %}

{% macro create_data_masked_view(schema, columns_to_mask) %}

-- what are the columns in our model?
{% set model_cols = adapter.get_columns_in_relation(this) %}

{% set schema_sql %}

create schema if not exists {{ schema }};

{% endset %}

{% do run_query(schema_sql) %}

{% set view_sql %}

create view {{ schema }}.{{ this.identifier }} as (

    select
        {% for col in model_cols %}
            {% if col.name in columns_to_mask %}
            {{ mask_column(col.name) }} as {{ col.name }}
            {% else %}
            {{ col.name }}
            {% endif %}
            {{ "," if not loop.last }}
        {% endfor %}
    from {{ this }}
)

{% endset %}
{% do run_query(view_sql) %}
select 1=1
{% endmacro %}
