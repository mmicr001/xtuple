select xt.create_view('xt.cntctinfo', $$

select cntct.*, a.crmacct_id AS contact_crmacct, a.crmacct_number, p.crmacct_number as crmacct_parent_number,
       getcontactphone(cntct_id, 'Office') AS contact_phone,
       getcontactphone(cntct_id, 'Mobile') AS contact_phone2,
       getcontactphone(cntct_id, 'Fax') AS contact_fax
from cntct
  left join crmacctcntctass on (cntct_id=crmacctcntctass_cntct_id AND crmacctcntctass_crmrole_id=getcrmroleid())
  left join crmacct a on a.crmacct_id=crmacctcntctass_crmacct_id
  left join crmacct p on a.crmacct_parent_id=p.crmacct_id;

$$);

