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

        datediff(
            'minutes',
            greatest(business_hours.date_hour_start, tickets.conversation_created_at),
            least(business_hours.date_hour_end, tickets.first_response_at)
        ) as calendar_minutes_to_first_solve,

        case
            when business_hours.is_business_hour
                then calendar_minutes_to_first_solve
            else 0
        end as business_minutes_to_first_solve,

        datediff(
            'minutes',
            greatest(business_hours.date_hour_start, tickets.conversation_created_at),
            least(business_hours.date_hour_end, tickets.first_closed_at)
        ) as calendar_minutes_to_first_close,

        case
            when business_hours.is_business_hour
                then calendar_minutes_to_first_close
            else 0
        end as business_minutes_to_first_close,

        datediff(
            'minutes',
            greatest(business_hours.date_hour_start, tickets.conversation_created_at),
            least(business_hours.date_hour_end, tickets.last_closed_at)
        ) as calendar_minutes_to_last_close,

        case
            when business_hours.is_business_hour
                then calendar_minutes_to_last_close
            else 0
        end as business_minutes_to_last_close


    from tickets

    left join business_hours
        on date_trunc('hour', tickets.conversation_created_at) <= business_hours.date_hour_start
        and date_trunc('hour', tickets.last_closed_at) >= business_hours.date_hour_start
)

select * from ticket_hours

