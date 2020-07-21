{% macro make_lamda_view(model, run_time) %}

{% set cutoff_time %}
dateadd('hour', 2, {{ run_time }})
{% endset %}

{% set create_view_sql %}
-- should we put it in a different schema?
create or replace view {{ this }}_view as ( -- the suffix will break if quoting is involved / we should create these as dbt Relations
    select * from {{ this }}
    where updated_at >= {{ cutoff_time }} -- how do we know what the column to filter is? extra arg
)
{% endmacro %}


{% set create_table_sql %}
-- should we put it in a different schema?
-- what if this should be incremental? it probably should! how do we configure that?
create or replace table {{ this }}_table as ( -- the suffix will break if quoting is involved
    select * from {{ this }}
    where updated_at < {{ cutoff_time }} -- how do we know what the column to filter is? extra arg
)
{% endmacro %}

{% set create_union_sql %}
-- _dbt_lambda_source is for debugging
create table {{ this }}_unioned as (
    select
        *,
        'table' as _dbt_lambda_source,
        '{{ run_time }}' as _dbt_loaded_at

    from {{ this }}_table

    union all

    select
        *,
        'view' as _dbt_lambda_source,
        '{{ run_time }}' as _dbt_loaded_at
    from {{ this }}_view
)

{% endset %}
