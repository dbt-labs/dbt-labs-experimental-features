# Securing data at scale with Snowflake's dynamic data masking, and dbt

### 0. Create a test masking policy

To get familiar with masking policies, it might be a good idea to first manually create a policy. Here's some SQL that works for us, but you'll likely  need to adjust the database, schema, and role names to work in your Snowflake account. Check out the [Snowflake docs](https://docs.snowflake.com/en/sql-reference/sql/create-masking-policy.html) for more information on the SQL here.

```sql
create table analytics.dbt_ashley.test_masking_policy as
  select 1 as id, 'Ashley' as first_name ;

create masking policy if not exists analytics.dbt_ashley.masking_policy__text as (val text) returns text ->
    case
        when current_role() = 'TRANSFORMER' then val
        else md5(val)
    end ;

alter table analytics.dbt_ashley.test_masking_policy modify column first_name set masking policy analytics.dbt_ashley.masking_policy__text;
```

It's worth noting that the masked value uses an [md5 hashing function](https://docs.snowflake.com/en/sql-reference/functions/md5.html) to obfuscate the value.

If possible, try selecting from the table with two different roles to observe the masking policy in action!

```sql
use role transformer;
-- this should return the unmasked values
select * from analytics.dbt_ashley.test_masking_policy;

use role reporter;
-- this should return the masked values
select * from analytics.dbt_ashley.test_masking_policy;

```

Now that we know it's working, we have to find a way to dynamically apply it to any models with sensitive information. Fortunately, dbt's [post-hooks](https://docs.getdbt.com/reference/resource-configs/pre-hook-post-hook/) come in handy here!

### 1. Create a macro that applies a masking policy

Now, we can turn the above SQL into a dbt macro:

```sql
{% macro apply_data_masking(columns) %}
{% set relation_type='view' if model.config.materialized == 'view' else 'table' %}
create masking policy if not exists {{ this.database }}.{{ this.schema }}.masking_policy__text as (val text) returns text ->
    case
        when current_role() = 'TRANSFORMER' then val
        else md5(val)
    end;
{% for col in columns %}
    alter {{ relation_type }} {{ this }} modify column {{ col }} set masking policy {{ this.database }}.{{ this.schema }}.masking_policy__text;
{% endfor %}
{% endmacro %}

```

We're using the jinja variables [model](https://docs.getdbt.com/reference/dbt-jinja-functions/model/), and [this](https://docs.getdbt.com/reference/dbt-jinja-functions/this/) — these are automatically available whenever a macro is called from a model.

### 3. Call the macro as a post-hook
You'll need to apply this in every single model that contains sensitive data, and pass in the list of columns

```sql
{{
    config(
        post_hook=apply_data_masking(
            columns=['first_name', 'last_name']
        )
    )
}}

select
    id,
    first_name,
    last_name,
    favorite_bagel_flavor
from {{ ref('employees') }}

```

### 4. Adjust the masking policy to suit your organization's needs

In particular, you might want to:
- Use a different role to create the masking policy
- Create multiple masking policies — for example, a policy for `date` types
- Leverage user groups in your masking policy logic
- Maintain a  list of columns to be masked, and use that list
