{% macro get_rows_inserted(result) -%}
  {{ return(adapter.dispatch('get_rows_inserted', 'insert_by_period')(result)) }}
{% endmacro %}

{% macro default__get_rows_inserted(result) %}
  
  {% if 'response' in result.keys() %} {# added in v0.19.0 #}
    {% set rows_inserted = result['response']['rows_affected'] %}
  {% else %} {# older versions #}
    {% set rows_inserted = result['status'].split(" ")[2] | int %}
  {% endif %}

  {{return(rows_inserted)}}

{% endmacro %}

{% macro databricks__get_rows_inserted(result) %}
  
  {% if 'data' in result.keys() %}
    {% set rows_inserted = result['data'][0][0] | int %}
  {% endif %}

  {{return(rows_inserted)}}

{% endmacro %}