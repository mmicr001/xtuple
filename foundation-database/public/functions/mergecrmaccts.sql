CREATE OR REPLACE FUNCTION mergecrmaccts(INTEGER, BOOLEAN) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  pTargetId     ALIAS FOR $1;
  _purge        BOOLEAN := COALESCE($2, FALSE); -- deprecated

  _retval       INTEGER;
BEGIN

  -- merge the data from the various source records
  SELECT SUM(merge2crmaccts(crmacctsel_src_crmacct_id, pTargetId))
         INTO _retval
    FROM crmacctsel
   WHERE ((crmacctsel_dest_crmacct_id=pTargetId)
      AND (crmacctsel_dest_crmacct_id!=crmacctsel_src_crmacct_id));

  DELETE FROM crmacctsel WHERE crmacctsel_dest_crmacct_id=pTargetId;

  RETURN COALESCE(_retval, 0);

END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION mergecrmaccts(INTEGER, BOOLEAN) IS
'This function uses the crmacctsel table to merge multiple crmacct records together. Only the merges into the specified target account are performed. Most of the work is done by repeated calls to the merge2crmaccts function.';
