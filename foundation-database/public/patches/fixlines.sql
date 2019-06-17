DO $$
DECLARE
  _fixcm      BOOLEAN;
  _badinvc    BOOLEAN;
  _badcm      BOOLEAN;
  _badtext    TEXT;
  _salescatid INTEGER;

BEGIN

  _fixcm :=  EXISTS(SELECT 1
                      FROM pg_attribute
                      JOIN pg_class ON attrelid = pg_class.oid
                      JOIN pg_namespace ON relnamespace = pg_namespace.oid
                     WHERE nspname = 'public'
                       AND relname = 'cmitem'
                       AND attname = 'cmitem_expcat_id'
                       AND relkind = 'r'
                       AND attnum > 0);


  _badinvc := EXISTS(SELECT 1
                       FROM invcitem
                      WHERE COALESCE(invcitem_item_id, -1) < 0 AND COALESCE(invcitem_salescat_id, -1) < 0);

  IF _fixcm THEN
    _badcm := EXISTS(SELECT 1
                       FROM cmitem
                      WHERE cmitem_itemsite_id IS NULL AND cmitem_salescat_id IS NULL);
  ELSE
    _badcm := FALSE;
  END IF;

  IF _badinvc AND _badcm THEN
    _badtext := 'invoice/sales credit';
  ELSIF _badinvc THEN
    _badtext := 'invoice';
  ELSIF _badcm THEN
    _badtext := 'sales credit';
  END IF;

  IF _badinvc OR _badcm THEN
    INSERT INTO salescat (salescat_name,
                          salescat_descrip,
                          salescat_active,
                          salescat_sales_accnt_id, salescat_prepaid_accnt_id, salescat_ar_accnt_id)
    SELECT 'BAD DATA',
           'This Sales Category is a placeholder used to patch bad ' || _badtext || ' line data',
           FALSE,
           accnt_id, accnt_id, accnt_id
      FROM accnt
     LIMIT 1
    RETURNING salescat_id INTO _salescatid;
  END IF;

  ALTER TABLE public.invcitem DISABLE TRIGGER ALL;

  UPDATE invcitem
     SET invcitem_number = COALESCE(NULLIF(COALESCE(invcitem_number, invcitem_descrip, ''), ''), 'BAD DATA'),
         invcitem_descrip = COALESCE(NULLIF(COALESCE(invcitem_descrip, invcitem_number, ''), ''),
                                     'This is an invalid invoice item with no item or ' ||
                                     CASE WHEN COALESCE(invcitem_salescat_id, -1) < 0
                                          THEN 'sales category'
                                          ELSE 'misc number'
                                      END),
         invcitem_salescat_id = CASE WHEN COALESCE(invcitem_salescat_id, -1) > 0
                                     THEN invcitem_salescat_id
                                     ELSE _salescatid
                                 END
   WHERE COALESCE(invcitem_item_id, -1) < 0
     AND (COALESCE(invcitem_salescat_id, -1) < 0 OR COALESCE(invcitem_number, '') = '' OR COALESCE(invcitem_descrip, '') = '');

  ALTER TABLE public.invcitem ENABLE TRIGGER ALL;

  IF _fixcm THEN
    UPDATE cmitem
       SET cmitem_number = COALESCE(NULLIF(COALESCE(cmitem_number, cmitem_descrip, ''), ''), 'BAD DATA'),
           cmitem_descrip = COALESCE(NULLIF(COALESCE(cmitem_descrip, cmitem_number, ''), ''),
                                     'This is an invalid sales credit item with no item or ' || 
                                     CASE WHEN cmitem_salescat_id IS NULL 
                                          THEN 'sales category'
                                          ELSE 'misc number'
                                      END),
           cmitem_salescat_id = COALESCE(cmitem_salescat_id, _salescatid)
     WHERE cmitem_itemsite_id IS NULL 
       AND (cmitem_salescat_id IS NULL OR COALESCE(cmitem_number, '') = '' OR COALESCE(cmitem_descrip, '') = '');
  END IF;

END
$$ language plpgsql;
