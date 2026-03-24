select f.opportunity_id, f.accountid
from {{ ref('fct_opportunities') }} f
left join {{ ref('dim_accounts') }} d on f.account_key = d.account_key
where d.account_key is null
