with

tickets as (
    select * from {{ ref('sample_tickets') }}
),

business_hours as (
    select * from {{ ref('business_hours') }}
),

-- one record per ticket per hour that it is "active"
ticket_hours as (

    select
        *,

        case
            when business_hours.is_business_hour
                then datediff(
                    'minutes',
                    greatest(business_hours.date_hour_start, tickets.conversation_created_at_business),
                    least(business_hours.date_hour_end, tickets.first_response_at_business)
                )
            else 0
        end as business_minutes_to_first_solve,


        case
            when business_hours.is_business_hour
                then datediff(
                    'minutes',
                    greatest(business_hours.date_hour_start, tickets.conversation_created_at_business),
                    least(business_hours.date_hour_end, tickets.first_closed_at_business)
                )
            else 0
        end as business_minutes_to_first_close,

        case
            when business_hours.is_business_hour
                then datediff(
                    'minutes',
                    greatest(business_hours.date_hour_start, tickets.conversation_created_at_business),
                    least(business_hours.date_hour_end, tickets.last_closed_at_business)
                )
            else 0
        end as business_minutes_to_last_close


    from tickets

    left join business_hours
        on date_trunc('hour', tickets.conversation_created_at_business) <= business_hours.date_hour_start
        -- in reality don't need to do this pre-processing
        and date_trunc('hour', tickets.last_closed_at_business) >= business_hours.date_hour_start

)

select * from ticket_hours

