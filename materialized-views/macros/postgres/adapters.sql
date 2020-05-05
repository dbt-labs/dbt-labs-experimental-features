{% macro postgres__is_materialized_view(relation) %}

    {% set existing_relation = load_relation(this) %}
    
    {# materialized views don't appear in pg_tables or pg_views #}
    {% if existing_relation is none %}

        {% set find_matview %}
        
            select count(*) from pg_matviews
            where schemaname = '{{relation.schema}}'
            and matviewname = '{{relation.identifier}}'
        
        {% endset %}
        
        {% if execute %}
            {% set result = run_query(find_matview)[0][0] %}
        {% else %}
            {% set result = 0 %}
        {% endif %}

        {% set is_matview = (result > 0) %}
        {% do return(is_matview) %}
        
    {% else %}
    
        {% do return(false) %}
        
    {% endif %}

{% endmacro %}
