select lead_id, isconverted, convertedopportunityid
from {{ ref('fct_leads') }}
where isconverted = true and convertedopportunityid is null
