{% snapshot historic_revenue_snapshot %}

    {{
        config(
          target_schema='dbt_snapshots',
          strategy='check',
          unique_key='date_day',
          check_cols=['total_revenue']
        )
    }}

    select
        order_date as date_day,
        sum(amount) as total_revenue
    from {{ ref('fct_orders') }}

    {# we're going to use this hack to make a record disappear on the second run of this #}
    {% if adapter.get_relation(this.database, this.schema, this.table) is not none %}
    where order_id != 4
    {% endif %}

    group by 1


{% endsnapshot %}
