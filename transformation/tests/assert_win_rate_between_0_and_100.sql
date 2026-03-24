select account_id, account_name, win_rate_pct
from {{ ref('dim_accounts') }}
where win_rate_pct is not null and (win_rate_pct < 0 or win_rate_pct > 100)
