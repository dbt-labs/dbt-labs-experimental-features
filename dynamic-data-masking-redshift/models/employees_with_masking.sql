{{
    config(
        post_hook=after_commit(create_data_masked_view(
            schema='my_secret_schema',
            columns_to_mask=['first_name', 'last_name']
        ))
    )
}}

select
    -- this is the model sql
    id,
    first_name,
    last_name,
    favorite_bagel_flavor
from {{ ref('employees') }}
