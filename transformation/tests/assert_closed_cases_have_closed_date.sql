select case_id, status, isclosed, closeddate
from {{ ref('fct_cases') }}
where isclosed = true and closeddate is null
