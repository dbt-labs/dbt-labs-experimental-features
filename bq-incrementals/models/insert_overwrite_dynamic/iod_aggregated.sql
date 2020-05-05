{{config(
    materialized = 'incremental',
    unique_key = 'id',
    partition_by = {'field': 'date_hour', 'data_type': 'timestamp'},
    incremental_strategy = 'insert_overwrite'
)}}

with page_views as (
    
    select * from {{source('wikipedia', 'pageviews_2020')}}
    
    {% if is_incremental() %}
        -- always rebuild up to the current day
        where date(datehour) >= date_sub(date(_dbt_max_partition), interval ({{var('new')}}) day)
          and date(datehour) < current_date
    {% else %}
        -- this source table requires a partition filter regardless
        where date(datehour) >= date_sub(current_date, interval ({{var('old')}}) day)
          and date(datehour) < current_date
    {% endif %}
    
),

pages_of_interest as (
    
    select * from {{ref('pages_of_interest')}}
    
),

parsed as (
    
    select *,
    
        replace(split(wiki, '.')[offset(0)], '-', '_') as lang
        
    from page_views
    
),

tagged as (
    
    select * from parsed
    left join pages_of_interest using (title, lang)

),

agg as (
    
    select
    
        datehour as date_hour,
        subject,
        lang,
        sum(views) as total_views
        
    from tagged
    group by 1,2,3
    
),

final as (
    
    select
    
        {{ dbt_utils.surrogate_key('date_hour', 'subject', 'lang') }} as id,
        *
    
    from agg
    
)

select * from final
