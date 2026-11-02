{% macro title_case(column_name) %}
    {#- DuckDB has no initcap(); this keeps the same result for single words. -#}
    upper(substr(trim({{ column_name }}), 1, 1)) || lower(substr(trim({{ column_name }}), 2))
{% endmacro %}
