with unioned as (
    
    {{ dbt_utils.union_relations([
        ref('seed_oss'),
        ref('seed_defs_op'),
        ref('seed_cov_bond')
    ]) }}
    
),

by_subject as (
    
    select *,
    
        max(case when lang = 'en' then
            lower(replace(title, '-', '_'))
            end) over (partition by _dbt_source_relation) as subject
        
    from unioned
    
)

select * from by_subject
