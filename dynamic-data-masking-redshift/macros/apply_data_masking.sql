{% macro mask_column(column_name) %}
    -- logic that controls the masking
    case
        when current_user in ('claire') then {{ column_name }}
        else md5({{ column_name }})
    end
{% endmacro %}

{% macro create_data_masked_view(schema, columns_to_mask) %}
    {% if execute %}
    
    {# get all columns in the relation #}
    
        {% set model_cols = adapter.get_columns_in_relation(this) %}
        
        {# create Relation object for masked view #}
        
        {%- set masked_view = api.Relation.create(
              database=this.database,
              schema=schema,
              identifier=this.identifier) -%}
              
        {# create schema #}
        
        {% do adapter.create_schema(masked_view) %}
        
        {# create masked view in new schema for sensitive columns #}
        
        {% set view_sql %}

            drop view if exists {{ masked_view }};

            create view {{ masked_view }} as (

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
        
        {% do dbt_utils.log_info("Masked view created at: " ~  masked_view ) %}
        
    {% endif %}
    
    select 1=1
    
{% endmacro %}