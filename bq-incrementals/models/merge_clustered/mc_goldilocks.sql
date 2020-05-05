{{config(
    materialized = 'incremental',
    unique_key = 'id',
    partition_by = {'field': 'date_day', 'data_type': 'date'},
    cluster_by = ['id']
)}}

with page_views as (
    
    select * from {{source('wikipedia', 'pageviews_2020')}}
    
    {% if is_incremental() %}
        -- always rebuild up to the current day
        where date(datehour) >= date_sub(current_date, interval ({{var('new')}}) day)
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
    
        date(datehour) as date_day,
        replace(split(wiki, '.')[offset(0)], '-', '_') as lang
        
    from page_views
    
),

tagged as (
    
    select * from parsed
    left join pages_of_interest using (title, lang)

),

agg as (
    
    select
    
        date_day,
        lang,
        title,
        subject,
        sum(views) as views
        
    from tagged
    group by 1,2,3,4
    
),

final as (
    
    select
    
        {{ dbt_utils.surrogate_key('date_day', 'lang', 'title') }} as id,
        *
    
    from agg
    
)

select * from final
