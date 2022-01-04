with 

tickets as (
    select * from {{ ref('sample_tickets') }}
),

final as (
    
    select 
        tickets.*,

        -- macros for attempt 1 -- nested macros

        -- measure weekdays between dates
        {{ weekdays_between('conversation_created_at_business', 'first_response_at_business') }} as weekdays_to_first_response,
        -- add up overnights + weekends
        {{ non_business_hours_between('conversation_created_at_business', 'first_response_at_business') }} as non_working_hours,
        -- final calculation
        {{ business_minutes_between__1('conversation_created_at_business', 'first_response_at_business') }} as business_minutes__1,
        
        -- macros for attempt 2 -- subquery
        
        -- subquery to get working hours
        {{ working_min_between('conversation_created_at_business', 'first_response_at_business') }} as working_min_subquery,
        
        -- adjustments + final calculation
        {{ business_minutes_between__2('conversation_created_at_business', 'first_response_at_business') }} as business_minutes__2


    
    from tickets   
    
)

select * from final