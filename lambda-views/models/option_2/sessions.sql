{{
    config(
        materialized = 'view',
        unique_key = 'session_id'
    )
}}

{{ lambda_union(
    historical_relation = ref(this.name ~ '__lambda_historical'),
    model_sql = sessions_model_sql()
) }}
