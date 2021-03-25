with 

tickets as (
    select * from {{ ref('sample_tickets') }}
),

final as (
    
    select 
        tickets.*,
        {{ weekdays_between('conversation_created_at_business', 'first_response_at_business') }} as weekdays_to_first_response,
        {{ non_business_hours_between('conversation_created_at_business', 'first_response_at_business') }} as non_working_hours,
        {{ business_minutes_between('conversation_created_at_business', 'first_response_at_business') }} as business_minutes
        
    
    from tickets   
    
)

select * from final