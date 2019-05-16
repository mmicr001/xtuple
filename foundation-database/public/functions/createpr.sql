DROP FUNCTION IF EXISTS createPr(INTEGER, INTEGER, NUMERIC, DATE, TEXT, CHARACTER(1), INTEGER);
CREATE OR REPLACE FUNCTION createPr(
  pOrderNumber INTEGER,
  pItemsiteid INTEGER,
  pQty NUMERIC,
  pDueDate DATE,
  pNotes TEXT,
  pOrderType CHARACTER(1),
  pOrderId INTEGER
) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _prid INTEGER;

BEGIN

  -- Check for existing pr for this pOrderId and pOrderType.
  SELECT pr_id INTO _prid
    FROM pr
   WHERE pr_order_id = pOrderId
     AND pr_order_type = pOrderType
     AND pOrderId != -1
     AND pOrderType != 'M';
  IF _prid IS NOT NULL THEN
    RETURN _prid;
  END IF;

  SELECT NEXTVAL('pr_pr_id_seq') INTO _prid;
  INSERT INTO pr
  ( pr_id, pr_number, pr_subnumber, pr_status,
    pr_order_type, pr_order_id,
    pr_itemsite_id, pr_qtyreq, pr_duedate, pr_releasenote )
  VALUES
  ( _prid, pOrderNumber, nextPrSubnumber(pOrderNumber), 'O',
    pOrderType, pOrderId,
    pItemsiteid, pQty, pDuedate, pNotes );

  RETURN _prid;

END;
$$ LANGUAGE 'plpgsql';

DROP FUNCTION IF EXISTS createPr(INTEGER, INTEGER, NUMERIC, DATE, TEXT);
CREATE OR REPLACE FUNCTION createPr(
  pOrderNumber INTEGER,
  pItemsiteid INTEGER,
  pQty NUMERIC,
  pDueDate DATE,
  pNotes TEXT
) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _prid INTEGER;

BEGIN

  SELECT NEXTVAL('pr_pr_id_seq') INTO _prid;
  INSERT INTO pr
  ( pr_id, pr_number, pr_subnumber, pr_status,
    pr_order_type, pr_order_id,
    pr_itemsite_id, pr_qtyreq, pr_duedate, pr_releasenote )
  VALUES
  ( _prid, pOrderNumber, nextPrSubnumber(pOrderNumber), 'O',
    'M', -1,
    pItemsiteid, pQty, pDuedate, pNotes);

  RETURN _prid;

END;
$$ LANGUAGE 'plpgsql';

DROP FUNCTION IF EXISTS createpr(CHAR, INTEGER);
CREATE OR REPLACE FUNCTION createPr(
  pParentType CHAR,
  pParentId INTEGER
) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _orderNumber INTEGER;
  _prid INTEGER;

BEGIN

  IF pParentType = 'W' THEN
    SELECT wo_number INTO _orderNumber
      FROM wo, womatl
     WHERE womatl_wo_id = wo_id
       AND womatl_id = pParentId;

  ELSIF pParentType = 'S' THEN
    SELECT CAST(cohead_number AS INTEGER) INTO _orderNumber
      FROM cohead, coitem
     WHERE coitem_cohead_id = cohead_id
       AND coitem_id = pParentId;

  ELSIF pParentType = 'F' THEN
    SELECT fetchPrNumber() INTO _orderNumber;

  ELSE
    RETURN -2;
  END IF;

  IF _orderNumber IS NULL THEN
    RETURN -1;
  END IF;

  SELECT createPr(_orderNumber, pParentType, pParentId) INTO _prid;

  RETURN _prid;

END;
$$ LANGUAGE 'plpgsql';

DROP FUNCTION IF EXISTS createpr(INTEGER, CHARACTER, INTEGER);
DROP FUNCTION IF EXISTS createpr(INTEGER, CHARACTER, INTEGER, TEXT);
CREATE OR REPLACE FUNCTION createpr(
  pOrderNumber INTEGER,
  pParentType CHARACTER,
  pParentId INTEGER,
  pParentNotes TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _parent RECORD;
  _prid INTEGER;
  _orderNumber INTEGER;

BEGIN

  IF (pOrderNumber = -1) THEN
    SELECT fetchPrNumber() INTO _orderNumber;
  ELSE
    _orderNumber := pOrderNumber;
  END IF;

  IF (pParentType = 'W') THEN
    SELECT womatl_itemsite_id AS itemsiteid,
           itemuomtouom(itemsite_item_id, womatl_uom_id, NULL, womatl_qtyreq) AS qty,
           womatl_duedate AS duedate, wo_prj_id AS prjid,
           womatl_notes AS notes INTO _parent
      FROM wo, womatl, itemsite
     WHERE womatl_wo_id = wo_id
       AND womatl_itemsite_id = itemsite_id
       AND womatl_id= pParentId;

  ELSIF (pParentType = 'S') THEN
    SELECT coitem_itemsite_id AS itemsiteid,
           (coitem_qtyord - coitem_qtyshipped + coitem_qtyreturned) AS qty,
           coitem_scheddate AS duedate, cohead_prj_id AS prjid,
           coitem_memo AS notes INTO _parent
      FROM coitem, cohead
     WHERE cohead_id = coitem_cohead_id
       AND coitem_id = pParentId;

  ELSIF (pParentType = 'F') THEN
    SELECT planord_itemsite_id AS itemsiteid,
           planord_qty AS qty,
           planord_duedate AS duedate, NULL::INTEGER AS prjid,
           planord_comments AS notes INTO _parent
      FROM planord
     WHERE planord_id = pParentId;

  ELSE
    RETURN -2;
  END IF;

  IF _parent IS NULL THEN
    RETURN -1;
  END IF;

  _prid := createPr(
    _orderNumber,
    _parent.itemsiteid,
    validateOrderQty(_parent.itemsiteid, _parent.qty, TRUE),
    _parent.duedate,
    COALESCE(pParentNotes, _parent.notes),
    pParentType,
    pParentId
  );

  RETURN _prid;

END;
$$ LANGUAGE 'plpgsql';
