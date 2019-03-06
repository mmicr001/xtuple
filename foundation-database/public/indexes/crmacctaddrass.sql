SELECT xt.add_index('crmacctaddrass', 'crmacctaddrass_addr_id', 'crmacctaddrass_addr_id_idx', 'btree', 'public'),
       xt.add_index('crmacctaddrass', 'crmacctaddrass_crmacct_id', 'crmacctaddrass_crmacct_id_idx', 'btree', 'public');
