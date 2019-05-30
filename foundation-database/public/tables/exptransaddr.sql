SELECT xt.create_table('exptransaddr', 'public');

ALTER TABLE public.exptransaddr DISABLE TRIGGER ALL;

SELECT xt.add_column('exptransaddr', 'exptransaddr_id', 'SERIAL', 'PRIMARY KEY', 'public'),
       xt.add_column('exptransaddr', 'exptransaddr_invhist_id', 'INTEGER', 'NOT NULL', 'public'),
       xt.add_column('exptransaddr', 'exptransaddr_line1', 'TEXT', 'NOT NULL DEFAULT ''''', 'public'),
       xt.add_column('exptransaddr', 'exptransaddr_line2', 'TEXT', 'NOT NULL DEFAULT ''''', 'public'),
       xt.add_column('exptransaddr', 'exptransaddr_line3', 'TEXT', 'NOT NULL DEFAULT ''''', 'public'),
       xt.add_column('exptransaddr', 'exptransaddr_city', 'TEXT', 'NOT NULL DEFAULT ''''', 'public'),
       xt.add_column('exptransaddr', 'exptransaddr_state', 'TEXT', 'NOT NULL DEFAULT ''''', 'public'),
       xt.add_column('exptransaddr', 'exptransaddr_postalcode', 'TEXT', 'NOT NULL DEFAULT ''''', 'public'),
       xt.add_column('exptransaddr', 'exptransaddr_country', 'TEXT', 'NOT NULL DEFAULT ''''', 'public');

SELECT xt.add_constraint('exptransaddr', 'exptransaddr_invhist_id_fkey', 'FOREIGN KEY (exptransaddr_invhist_id) REFERENCES invhist (invhist_id) ON DELETE CASCADE', 'public'),
       xt.add_constraint('exptransaddr', 'exptransaddr_invhist_id_key', 'UNIQUE (exptransaddr_invhist_id)', 'public');

ALTER TABLE public.exptransaddr ENABLE TRIGGER ALL;
