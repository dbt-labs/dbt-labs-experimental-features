{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'delete+insert',
        unique_key = 'page_view_id',
        schema = 'lambda_historical',
        alias = 'page_views'
    )
}}

{{ page_views_model_sql() }}
