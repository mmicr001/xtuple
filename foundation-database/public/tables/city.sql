SELECT xt.create_table('city', 'public');

ALTER TABLE public.city DISABLE TRIGGER ALL;

SELECT
  xt.add_column('city', 'city_id',         'SERIAL',  'NOT NULL',        'public'),
  xt.add_column('city', 'city_name',       'TEXT',    'NOT NULL',        'public'),
  xt.add_column('city', 'city_abbr',       'TEXT',    'NOT NULL',        'public'),
  xt.add_column('city', 'city_region_id',  'INTEGER', 'NOT NULL',        'public'),
  xt.add_column('city', 'city_country_id', 'INTEGER', 'NOT NULL',        'public'),
  xt.add_column('city', 'city_lat',        'NUMERIC(9,6)',    NULL,              'public'),
  xt.add_column('city', 'city_lon',        'NUMERIC(9,6)',    NULL,              'public'),
  xt.add_column('city', 'city_createdby',  'TEXT',    'NOT NULL DEFAULT geteffectivextuser()', 'public'),
  xt.add_column('city', 'city_created',      'TIMESTAMP WITH TIME ZONE', 'NOT NULL DEFAULT now()', 'public'),
  xt.add_column('city', 'city_lastupdated',  'TIMESTAMP WITH TIME ZONE', NULL, 'public');

SELECT
  xt.add_constraint('city', 'city_pkey', 'PRIMARY KEY (city_id)', 'public'),
  xt.add_constraint('city', 'city_region_id_fkey',
                    'FOREIGN KEY (city_region_id) REFERENCES state(state_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('city', 'city_country_id_fkey',
                    'FOREIGN KEY (city_country_id) REFERENCES country(country_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');

ALTER TABLE public.city ENABLE TRIGGER ALL;

COMMENT ON TABLE public.city
  IS 'International Cities of the World';


