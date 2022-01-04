--use macro to create one row per hour per day
with hours as (

    {{ dbt_utils.date_spine(
        datepart="hour",
        start_date="to_date('01/01/2017', 'mm/dd/yyyy')",
        end_date="dateadd(month, 1, current_date)"
       )
    }}

),

/* -- if we had a seed for holidays, include it here

holidays as (

    select * from  ref('stg_company_holidays') 

),

*/

--convert hour to EST
converted_hours as (

    select distinct

        convert_timezone(
            'UTC',
            date_hour
        )::timestamp_ntz as date_hour

    from hours
),


--the output of this CTE is two columns: the first is one row for every hour of
--the day date spine (from above). the second returns the same result if it falls
--within our support hours. in the future, as support potentially changes,
--this is where we will alter biz hours

business_hours as (

    select
        date_hour,

        case
--before we hired a rep in MST (M-F, 8am - 8pm EST)
            when date_hour::date < '2021-09-14'
                and dayofweek(date_hour) not in (0,6)
                and hour(date_hour) between 8 and 19
                -- and holidays.date is null
                    then converted_hours.date_hour

-- after we hired international reps (covering Sunday 7pm to Friday 5pm)
            when date_hour::date >=  '2021-09-14'
                and dayofweek(date_hour) = 0 --sundays after 7pm is fair game
                and hour(date_hour) between 19 and 23
                -- and holidays.date is null
                    then converted_hours.date_hour

            when date_hour::date >=  '2021-09-01'
                and dayofweek(date_hour) between 1 and 4 --24/hr coverage M-Thurs
                -- and holidays.date is null
                    then converted_hours.date_hour

            when date_hour::date >=  '2021-09-01'
                and dayofweek(date_hour) = 5 --fridays, we rest after 8pm ET
                and hour(date_hour) between 0 and 19
                -- and holidays.date is null
                    then converted_hours.date_hour

        end as business_hour

    from converted_hours
    -- left join holidays
    --     on date_trunc(day, date_hour)::date = holidays.date

),

--the output of this CTE adds an additional column to fill in missing values
--the purpose is to show 8am for times outside of business hours
--ex. 10:36pm at night will show 8:00am the next day
corrections as (

    select

        *,
        business_hour is not null as is_business_hour,
        lead(business_hour) ignore nulls over (
            partition by 1
            order by date_hour
        ) as adjusted_business_hour

     from business_hours

),

--this cleans up the extra columns to properly calculate business hours.
--the result is one row for every hour of every day with a mapped business hour.
final as (

    select

        date_hour,
        coalesce(business_hour, adjusted_business_hour) as business_hour,
        is_business_hour

    from corrections

)

select * from final