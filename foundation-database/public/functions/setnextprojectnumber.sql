CREATE OR REPLACE FUNCTION setNextProjectNumber(pNumber INTEGER) RETURNS INTEGER  AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _orderseqid INTEGER;
BEGIN

    INSERT INTO orderseq (orderseq_name, orderseq_number)
    VALUES ('ProjectNumber'::TEXT, pNumber)
    ON CONFLICT (orderseq_name)
    DO UPDATE SET orderseq_number=pNumber
    RETURNING orderseq_id INTO _orderseqid;

  RETURN _orderseqid;

END;
$$ LANGUAGE plpgsql;

