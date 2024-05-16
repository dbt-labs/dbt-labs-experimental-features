{{
    config(
        post_hook=apply_data_masking(
            columns=['first_name', 'last_name']
        )
    )
}}

select
    id,
    first_name,
    last_name,
    favorite_bagel_flavor
from {{ ref('employees') }}
