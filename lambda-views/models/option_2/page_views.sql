{{
    config(
        materialized = 'view',
        unique_key = 'page_view_id'
    )
}}

{{ lambda_union(
    historical_relation = ref(this.name ~ '__lambda_historical'),
    model_sql = page_views_model_sql()
) }}
