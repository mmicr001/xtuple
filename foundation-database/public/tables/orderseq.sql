select xt.create_table('orderseq', 'public');

ALTER TABLE public.orderseq DISABLE TRIGGER ALL;

SELECT xt.add_column('orderseq','orderseq_id',     'SERIAL', 'PRIMARY KEY', 'public'),
       xt.add_column('orderseq','orderseq_name',   'TEXT',      'NOT NULL', 'public'),
       xt.add_column('orderseq','orderseq_number', 'INTEGER',        null , 'public'),
       xt.add_column('orderseq','orderseq_table',  'TEXT',            null, 'public'),
       xt.add_column('orderseq','orderseq_numcol', 'TEXT',            null, 'public'),
       xt.add_column('orderseq','orderseq_seqiss', 'seqiss[]',        null, 'public');

SELECT
  xt.add_constraint('orderseq', 'orderseq_pkey', 'PRIMARY KEY (orderseq_id)', 'public'),
  xt.add_constraint('orderseq', 'orderseq_orderseq_name_key', 'UNIQUE (orderseq_name)', 'public'),
  xt.add_constraint('orderseq', 'orderseq_orderseq_name_check', $$CHECK (orderseq_name <> ''::TEXT$$, 'public');

ALTER TABLE public.orderseq ENABLE TRIGGER ALL;

COMMENT ON TABLE public.orderseq IS 'Order Number Sequence table for maintaining document numbering.';


ALTER TABLE orderseq DISABLE TRIGGER ALL;
-- Populate the sequence table [will not override existing entries or Order Number values]
INSERT INTO orderseq (orderseq_name, orderseq_number, orderseq_table, orderseq_numcol, orderseq_seqiss)
  VALUES ('ACHBatch',         100000, 'checkhead', 'checkhead_ach_batch', NULL),
         ('APMemoNumber',      70000, 'apmemo',    'apopen_docnumber',    NULL),
         ('ARMemoNumber',      20000, 'armemo',    'aropen_docnumber',    NULL),
         ('AddressNumber',         1, 'addr',      'addr_number',         '{}'),
         ('AlarmNumber',           1, 'alarm',     'alarm_number',        NULL),
         ('CRMAccountNumber',  33000, 'crmacct',   'crmacct_number',      NULL),
         ('CashRcptNumber',    10000, 'cashrcpt',  'cashrcpt_number',     NULL),
         ('CmNumber',          60000, 'armemo',    'aropen_docnumber',    NULL),
         ('ContactNumber',         1, 'cntct',     'cntct_number',        NULL),
         ('IncidentNumber',    10000, 'incdt',     'incdt_number',        NULL),
         ('InvcNumber',        70000, 'invchead',  'invchead_invcnumber', NULL),
         ('LsRegNumber',           1, 'lsreg',     'lsreg_number',        NULL),
         ('OpportunityNumber',     1, 'ophead',    'ophead_number',       NULL),
         ('PlanNumber',        90000, 'planord',   'planord_number',      NULL),
         ('PoNumber',          20000, 'pohead',    'pohead_number',       NULL),
         ('PrNumber',          10000, 'pr',        'pr_number',           NULL),
         ('ProjectNumber',      1000, 'prj',       'prj_number',          NULL),
         ('QuNumber',          40000, 'quhead',    'quhead_number',       NULL),
         ('RaNumber',            100, 'rahead',    'rahead_id',           NULL),
         ('SoNumber',          50000, 'cohead',    'cohead_number',       NULL),
         ('TaskNumber',        22000, 'task',      'task_number',         NULL),
         ('ToNumber',            100, 'tohead',    'tohead_number',       NULL),
         ('VcNumber',          30000, 'vohead',    'vohead_number',       NULL),
         ('WoNumber',          20000, 'wo',        'wo_number',           NULL)
  ON CONFLICT (orderseq_name) DO NOTHING;
ALTER TABLE orderseq ENABLE TRIGGER ALL;


-- Set the default Auto/Manual numbering metric for newly created Order Number types
DO $$
BEGIN
  IF (fetchmetrictext('ProjectNumberGeneration') IS NULL) THEN
    PERFORM setmetric('ProjectNumberGeneration', 'M');
  END IF;
  IF (fetchmetrictext('TaskNumberGeneration') IS NULL) THEN
    PERFORM setmetric('TaskNumberGeneration', 'A');
  END IF;
END; $$;
