{{
    config(
        materialized = 'incremental',
        unique_key = 'session_id',
        schema = 'lambda_historical',
        alias = 'sessions'
    )
}}

{{ sessions_model_sql() }}
