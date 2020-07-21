{% macro lambda_union(historical_relation, model_sql) %}

{% set unique_key = config.get('unique_key', none) %}

with historical as (
    
    select * from {{ historical_relation }}
    
),

new as (
    
    {{ model_sql }}
    
),

unioned as (

    select * from historical

    {% if unique_key %}

        where {{ unique_key }} not in (
            select {{ unique_key }} from new
        )

    {% endif %}

    union all

    select * from new
    
)

select * from unioned

{% endmacro %}
