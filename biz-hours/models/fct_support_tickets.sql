with

tickets as (
    select * from {{ ref('sample_tickets') }}
),

ticket_hours as (
    select * from {{ ref('ticket_hours') }}
),


aggregated_ticket_hours as (
    select
        id,
        sum(calendar_minutes_to_first_solve) as calendar_minutes_to_first_solve,
        sum(business_minutes_to_first_solve) as business_minutes_to_first_solve,
        sum(calendar_minutes_to_first_close) as calendar_minutes_to_first_close,
        sum(business_minutes_to_first_close) as business_minutes_to_first_close,
        sum(calendar_minutes_to_last_close) as calendar_minutes_to_last_close,
        sum(business_minutes_to_last_close) as business_minutes_to_last_close

    from ticket_hours
    group by 1
),

final as (

    select
        tickets.*,
        aggregated_ticket_hours.calendar_minutes_to_first_solve,
        aggregated_ticket_hours.business_minutes_to_first_solve,
        aggregated_ticket_hours.calendar_minutes_to_first_close,
        aggregated_ticket_hours.business_minutes_to_first_close,
        aggregated_ticket_hours.calendar_minutes_to_last_close,
        aggregated_ticket_hours.business_minutes_to_last_close

    from tickets
    left join aggregated_ticket_hours using (id)

)

select * from final
