{% macro fiscal_quarter(date_column, fiscal_year_start_month=1) %}
    'FY' || cast(
        case
            when month({{ date_column }}) >= {{ fiscal_year_start_month }}
            then year({{ date_column }})
            else year({{ date_column }}) - 1
        end
    as varchar)
    || '-Q' || cast(
        case
            {% for q in range(1, 5) %}
            {%- set months_in_q = [] -%}
            {%- for m in range(3) -%}
                {%- do months_in_q.append(((fiscal_year_start_month - 1 + (q-1)*3 + m) % 12) + 1) -%}
            {%- endfor -%}
            when month({{ date_column }}) in ({{ months_in_q | join(', ') }}) then {{ q }}
            {% endfor %}
        end
    as varchar)
{% endmacro %}
