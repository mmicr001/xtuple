SELECT xt.create_table('crmacctrole', 'public');

ALTER TABLE public.crmacctrole DISABLE TRIGGER ALL;

SELECT
  xt.add_column('crmacctrole', 'crmacctrole_id',             'SERIAL', 'NOT NULL',     'public'),
  xt.add_column('crmacctrole', 'crmacctrole_crmacct_id',    'INTEGER', 'NOT NULL',     'public'),
  xt.add_column('crmacctrole', 'crmacctrole_crmrole_id',    'INTEGER', 'NOT NULL',     'public');

SELECT
  xt.add_constraint('crmacctrole', 'crmacctrole_pkey', 'PRIMARY KEY (crmacctrole_id)', 'public'),
  xt.add_constraint('crmacctrole', 'crmacctrole_crmacct_id_fkey',
                    'FOREIGN KEY (crmacctrole_crmacct_id) REFERENCES crmacct(crmacct_id)', 'public'),
  xt.add_constraint('crmacctrole', 'crmacctrole_crmrole_id_fkey',
                    'FOREIGN KEY (crmacctrole_crmrole_id) REFERENCES crmrole(crmrole_id)', 'public');

ALTER TABLE public.crmacctrole ENABLE TRIGGER ALL;

COMMENT ON TABLE crmacctrole IS 'CRM Account Additional Roles.';
