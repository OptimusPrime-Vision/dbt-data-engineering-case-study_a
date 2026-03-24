{% macro safe_divide(numerator, denominator, default=0) %}
    case
        when coalesce({{ denominator }}, 0) = 0 then {{ default }}
        else {{ numerator }} / {{ denominator }}
    end
{% endmacro %}
