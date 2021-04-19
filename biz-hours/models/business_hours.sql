with hours as (
    {{ dbt_utils.date_spine(
        datepart="hour",
        start_date="to_date('01/01/2021', 'mm/dd/yyyy')",
        end_date="dateadd(month, 1, current_date)"
       )
    }}
),

converted_hours as (

    select distinct

        convert_timezone(
            'UTC',
            date_hour
        )::timestamp_ntz as date_hour

    from hours
),

business_hours as (

    select

        converted_hours.date_hour as date_hour_start,
        dateadd('hour', 1, converted_hours.date_hour) as date_hour_end,

        -- this logic might change over time to take into account whether the
        -- schedule has changed over time
        (
            dayofweek(converted_hours.date_hour) not in (0,6)
            and hour(converted_hours.date_hour) between 8 and 19
        ) as is_business_hour

    from converted_hours

)

select * from business_hours

