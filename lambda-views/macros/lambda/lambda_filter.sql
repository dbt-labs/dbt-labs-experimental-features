{% macro lambda_filter(column_name) %}

    {% set materialized = config.require('materialized') %}
    {% set filter_time = var('lambda_split', run_started_at) %}

    {% if materialized == 'view' %}

        where {{ column_name }} >= '{{ filter_time }}'

    {% elif is_incremental() %}

        where {{ column_name }} >= (select max({{ column_name }}) from {{ this }})
          and {{ column_name }} < '{{ filter_time }}'

    {% else %}

        where {{ column_name }} < '{{ filter_time }}'

    {% endif %}

{% endmacro %}
