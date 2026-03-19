{% test assert_delivered_has_date(model, column_name) %}

select *
from {{ model }}
where is_delivered = true
  and {{ column_name }} is null

{% endtest %}