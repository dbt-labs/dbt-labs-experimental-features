{% macro get_last_3d() %}

    {% set partitions = [] %}

    {% set max_d_ago = var('new') + 1 %}

    {% for i in range(1, max_d_ago) %}
        {% set this_partition %} date_sub(current_date, interval -{{i}} day) {% endset %}
        {% do partitions.append(this_partition) %}
    {% endfor %}

    {% do return(partitions) %}

{% endmacro %}
