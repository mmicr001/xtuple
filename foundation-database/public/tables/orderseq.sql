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


-- Populate the sequence table [will not override existing entries or Order Number values]
INSERT INTO public.orderseq VALUES 
 (1, 'WoNumber', 20000, 'wo', 'wo_number', NULL),
 (2, 'SoNumber', 50000, 'cohead', 'cohead_number', NULL),
 (3, 'QuNumber', 40000, 'quhead', 'quhead_number', NULL),
 (4, 'CmNumber', 60000, 'armemo', 'aropen_docnumber', NULL),
 (5, 'InvcNumber', 70000, 'invchead', 'invchead_invcnumber', NULL),
 (6, 'PoNumber', 20000, 'pohead', 'pohead_number', NULL),
 (7, 'VcNumber', 30000, 'vohead', 'vohead_number', NULL),
 (8, 'PrNumber', 10000, 'pr', 'pr_number', NULL),
 (10, 'PlanNumber', 90000, 'planord', 'planord_number', NULL),
 (11, 'ARMemoNumber', 20000, 'armemo', 'aropen_docnumber', NULL),
 (12, 'APMemoNumber', 70000, 'apmemo', 'apopen_docnumber', NULL),
 (13, 'IncidentNumber', 10000, 'incdt', 'incdt_number', NULL),
 (15, 'ToNumber', 100, 'tohead', 'tohead_number', NULL),
 (16, 'RaNumber', 100, 'rahead', 'rahead_id', NULL),
 (17, 'AddressNumber', 1, 'addr', 'addr_number', '{}'),
 (18, 'ContactNumber', 1, 'cntct', 'cntct_number', NULL),
 (19, 'LsRegNumber', 1, 'lsreg', 'lsreg_number', NULL),
 (20, 'AlarmNumber', 1, 'alarm', 'alarm_number', NULL),
 (21, 'ACHBatch', 100000, 'checkhead', 'checkhead_ach_batch', NULL),
 (22, 'CashRcptNumber', 10000, 'cashrcpt', 'cashrcpt_number', NULL),
 (23, 'CRMAccountNumber', 33000, 'crmacct', 'crmacct_number', NULL),
 (24, 'OpportunityNumber', 1, 'ophead', 'ophead_number', NULL),
 (26, 'TaskNumber', 22000, 'task', 'task_number', NULL),
 (27, 'ProjectNumber', 1000, 'prj', 'prj_number', NULL)
 ON CONFLICT (orderseq_name) DO NOTHING;
