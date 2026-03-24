select opportunity_id, amount, stagename
from {{ ref('fct_opportunities') }}
where iswon = true and (amount is null or amount <= 0)
