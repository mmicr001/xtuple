select xt.create_view('xt.cntctinfo', $$

-- TODO how to define contact-crm_account relationship when it is a one to many???

select cntct.*, a.crmacct_number, p.crmacct_number as crmacct_parent_number 
from cntct
  left join crmacctcntctass on cntct_id=crmacctcntctass_cntct_id
  left join crmacct a on a.crmacct_id=crmacctcntctass_crmacct_id
  left join crmacct p on a.crmacct_parent_id=p.crmacct_id;

$$);

