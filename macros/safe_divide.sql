{% macro safe_divide(numerator, denominator, precision=4) %}
    round(
        ({{ numerator }})::decimal(18, 6) / nullif({{ denominator }}, 0),
        {{ precision }}
    )
{% endmacro %}
