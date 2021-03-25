with 

tickets as (
    select * from {{ ref('sample_tickets') }}
),

final as (
    
    select 
        tickets.*,
        
        {{ non_business_hours_between('conversation_created_at_business', 'first_response_at_business') }}
    
    from tickets   
    
)

select * from final