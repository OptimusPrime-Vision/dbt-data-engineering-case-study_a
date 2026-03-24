{% macro classify_deal_size(amount_column) %}
    case
        when {{ amount_column }} >= 100000 then 'Enterprise'
        when {{ amount_column }} >= 25000  then 'Mid-Market'
        when {{ amount_column }} >= 5000   then 'SMB'
        else                                    'Micro'
    end
{% endmacro %}
