select
    id,
    first_name,
    last_name,
    favorite_bagel_flavor
from {{ ref('employees') }}
