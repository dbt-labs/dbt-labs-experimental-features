{# 

### PURPOSE ###
This macro calculates the total working minutes between two timestamps,
meaning, if a ticket begins on a Friday and then carries into Monday,
we do not want to count non-working hours (e.g. Saturdays) towards the
total time to respond/close.

## MACROS + INPUTS ##
* Macro 1: working_min_between
    This macro takes the two timestamps and finds the total number
    of working hours between the timestamps and multiples it by 60
    to get the total working minutes between the two timestamps

    Example:
    ticket_id = '14025'
    first_message_at: 2021-07-09 11:29
    first_closed_at: 2021-07-12 14:46

    The total business hours between these two timestamps
    (2021-07-09 11:00:00 and 2021-07-12 14:00:00) is 14hr
    NOTE: We do not include the 11:00 and 14:00 hours in this
    because we will manually calculate the minutes from these
    hours in the next macro

* Macro 2: business_minutes_between
    This macro will do two things:
     1. If the working minutes between is 0min, then 
        just datediff the start and end timestamps to
        find the minutes between.
    2. If it's greater than 0, then we want to
    add the start_minutes and end_minutes to the
    hours between to get the total working minutes.
    See example below for a walk-through explanation
Example:
    ticket_id = '14025'
    first_message_at: 2021-07-09 11:29
    first_closed_at: 2021-07-12 14:46
The below macro will take three inputs into consideration:
    1. The total working hours/minutes between the timestmaps
        ^in this case -- 14 * 60 = 840min
    2. The minutes from the start timestamp to the next hour
        ^in this case -- 2021-07-09 11:29 --> 31min
    3. The minutes from the end timestamp
        ^in this case, 46min
    We then add these together to see the total working business minutes
    between the two timestamps which is 917min
#}
{%- macro working_min_between(start_date, end_date) -%}
     ( select
          coalesce(count_if(is_business_hour),0) * 60
      from {{ ref('all_business_hours') }}
      where date_hour > date_trunc('hour', {{ start_date }})
      and date_hour < date_trunc('hour', {{ end_date }})
     )
{%- endmacro -%}

{%- macro business_minutes_between__2(start_date, end_date) -%}
    coalesce(
        case
            -- take into account tickets opened and closed in same hour
            when (date_trunc('hour', {{ start_date }} ) = date_trunc('hour', {{ end_date }} ))  
                then datediff('minute', {{ start_date }}, {{ end_date }})
            else {{ working_min_between(start_date, end_date) }}
                + (60 - extract(minute from {{ start_date }}))
                + (extract(minute from {{ end_date }}))
        end,
        0
    )
{%- endmacro -%}