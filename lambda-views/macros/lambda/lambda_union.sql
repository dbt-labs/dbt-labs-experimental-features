{% macro lambda_union(historical_relation, model_sql) %}

{% set unique_key = config.get('unique_key', none) %}

with historical as (

    select *,
        'historical' as _dbt_lambda_view_source,
        '{{ run_started_at }}' as _dbt_last_run_at

    from {{ historical_relation }}

),

new_raw as (

    {{ model_sql }}

),

new as (

    select *,
        'new' as _dbt_lambda_view_source,
        '{{ run_started_at }}' as _dbt_last_run_at

    from new_raw

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
