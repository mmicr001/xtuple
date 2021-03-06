CREATE OR REPLACE FUNCTION summarizedBOM(INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  pItemid ALIAS FOR $1;
  _revid INTEGER;

BEGIN

  SELECT getActiveRevId('BOM',pItemid) INTO _revid;

  RETURN summarizedBOM(pItemid, _revid, NULL, NULL);

END;
$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION summarizedBOM(INTEGER, INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  pItemid ALIAS FOR $1;
  pRevisionid ALIAS FOR $2;
BEGIN

  RETURN summarizedBOM(pItemid, _revid, NULL, NULL);

END;
$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION summarizedBOM(INTEGER, INTEGER, INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  pItemid ALIAS FOR $1;
  pExpired ALIAS FOR $2;
  pFuture ALIAS FOR $3;
  _revid INTEGER;

BEGIN

  SELECT getActiveRevId('BOM',pItemid) INTO _revid;

  RETURN summarizedBOM(pItemid, _revid, pExpired, pFuture);

END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION summarizedBOM(INTEGER, INTEGER, INTEGER, INTEGER) RETURNS SETOF bomdata AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  pItemid ALIAS FOR $1;
  pRevisionid ALIAS FOR $2;
  pExpiredDays  INTEGER := COALESCE($3, 0);
  pFutureDays   INTEGER := COALESCE($4, 0);
  _row bomdata%ROWTYPE;
  _bomworksetid INTEGER;
  _x RECORD;
  _check CHAR(1);
  _inactive BOOLEAN := FALSE;
  _batchsize NUMERIC;

BEGIN

  IF (pRevisionid != -1) THEN
    --Is this a deactivated revision?
    SELECT rev_status INTO _check
    FROM rev
    WHERE ((rev_id=pRevisionid)
    AND (rev_status='I'));
    IF (FOUND) THEN
      _inactive := TRUE;
    END IF;
  END IF;

  -- Get the batch quantity
  SELECT COALESCE( (
    SELECT bomhead_batchsize
    FROM bomhead
    WHERE ((bomhead_item_id=pItemId)
    AND (bomhead_rev_id=pRevisionid))),1) INTO _batchsize;

  IF NOT (_inactive) THEN

    --We can explode this out based on current data
    SELECT indentedBOM(pItemid, pRevisionid) INTO _bomworksetid;

    FOR _x IN
       SELECT item_number, uom_name,
               item_descrip1, item_descrip2,
               (item_descrip1 || ' ' || item_descrip2) AS itemdescription,
               SUM(bomwork_qtyreq) AS qtyreq,
               SUM(bomwork_qtyfxd * (1 + bomwork_scrap)) AS qtyfxd,
               SUM(bomwork_qtyper * (1 + bomwork_scrap)) AS qtyper,
       MAX(bomwork_actunitcost) AS actunitcost,
       MAX(bomwork_stdunitcost) AS stdunitcost,
       CASE WHEN item_type NOT IN ('R','T') THEN
         SUM(bomwork_actunitcost * bomwork_qtyreq)
       ELSE 0 END AS actextendedcost,
       CASE WHEN item_type NOT IN ('R','T') THEN
         SUM(bomwork_stdunitcost * bomwork_qtyreq)
       ELSE 0 END AS stdextendedcost,
       bomwork_effective,
       bomwork_expires,
       bomwork_effective > CURRENT_DATE AS future,
       bomwork_expires  <= CURRENT_DATE AS expired
       FROM ( SELECT item_number, item_type, uom_name,
                     item_descrip1, item_descrip2,
                     bomwork_qtyreq, bomwork_qtyfxd,
                     bomwork_qtyper, bomwork_scrap,
                     bomwork_actunitcost, bomwork_stdunitcost,
                     CASE WHEN (bomwork_effective > CURRENT_DATE) THEN (CURRENT_DATE + 1)
                          ELSE CURRENT_DATE END AS bomwork_effective,
                     CASE WHEN (bomwork_expires <= CURRENT_DATE) THEN (CURRENT_DATE - 1)
                          ELSE (CURRENT_DATE + 1) END AS bomwork_expires
                     FROM bomwork, item, uom
                     WHERE ( (bomwork_item_id=item_id)
                       AND (item_inv_uom_id=uom_id)
                       AND (bomwork_set_id=_bomworksetid) )
                       AND (bomwork_expires > (CURRENT_DATE - pExpiredDays))
                       AND (bomwork_effective <= (CURRENT_DATE + pFutureDays)) ) AS data
       GROUP BY item_number, uom_name, item_type,
                item_descrip1, item_descrip2,
                bomwork_effective, bomwork_expires
       ORDER BY item_number
    LOOP
        _row.bomdata_item_number := _x.item_number;
        _row.bomdata_uom_name := _x.uom_name;
        _row.bomdata_item_descrip1 := _x.item_descrip1;
        _row.bomdata_item_descrip2 := _x.item_descrip2;
        _row.bomdata_itemdescription := _x.itemdescription;
        _row.bomdata_qtyreq := _x.qtyreq;
        _row.bomdata_qtyfxd := _x.qtyfxd;
        _row.bomdata_qtyper := _x.qtyper;
        _row.bomdata_actunitcost := _x.actunitcost;
        _row.bomdata_stdunitcost := _x.stdunitcost;
        _row.bomdata_actextendedcost := _x.actextendedcost;
        _row.bomdata_stdextendedcost := _x.stdextendedcost;
        _row.bomdata_effective := _x.bomwork_effective;
        _row.bomdata_expires := _x.bomwork_expires;
        _row.bomdata_future := _x.future;
        _row.bomdata_expired := _x.expired;
        RETURN NEXT _row;
    END LOOP;

    PERFORM deleteBOMWorkset(_bomworksetid);

  ELSE

-- Use historical snapshot for inactive revisions
    FOR _x IN
       SELECT item_number, uom_name,
               item_descrip1, item_descrip2,
               (item_descrip1 || ' ' || item_descrip2) AS itemdescription,
               SUM(bomhist_qtyreq * (1 + bomhist_scrap)) AS qtyreq,
               SUM(bomhist_qtyfxd * (1 + bomhist_scrap)) AS qtyfxd,
               SUM(bomhist_qtyper * (1 + bomhist_scrap)) AS qtyper,
       MAX(bomhist_actunitcost) AS actunitcost,
       MAX(bomhist_stdunitcost) AS stdunitcost,
       CASE WHEN item_type NOT IN ('R','T') THEN
         MAX(bomhist_actunitcost) * SUM((bomhist_qtyfxd/_batchsize + bomhist_qtyper) * (1 + bomhist_scrap))
       ELSE 0 END AS actextendedcost,
       CASE WHEN item_type NOT IN ('R','T') THEN
         MAX(bomhist_stdunitcost) * SUM((bomhist_qtyfxd/_batchsize + bomhist_qtyper) * (1 + bomhist_scrap))
       ELSE 0 END AS stdextendedcost
       FROM bomhist, item, uom
       WHERE ( (bomhist_item_id=item_id)
       AND (item_inv_uom_id=uom_id)
       AND (bomhist_rev_id=pRevisionid) )
       AND (bomhist_expires > (CURRENT_DATE - pExpiredDays))
       AND (bomhist_effective <= (CURRENT_DATE + pFutureDays))
       GROUP BY item_number, uom_name, item_type,
                item_descrip1, item_descrip2
       ORDER BY item_number
    LOOP
        _row.bomdata_item_number := _x.item_number;
        _row.bomdata_uom_name := _x.uom_name;
        _row.bomdata_item_descrip1 := _x.item_descrip1;
        _row.bomdata_item_descrip2 := _x.item_descrip2;
        _row.bomdata_itemdescription := _x.itemdescription;
        _row.bomdata_qtyreq := _x.qtyreq;
        _row.bomdata_qtyfxd := _x.qtyfxd;
        _row.bomdata_qtyper := _x.qtyper;
        _row.bomdata_actunitcost := _x.actunitcost;
        _row.bomdata_stdunitcost := _x.stdunitcost;
        _row.bomdata_actextendedcost := _x.actextendedcost;
        _row.bomdata_stdextendedcost := _x.stdextendedcost;
        RETURN NEXT _row;
    END LOOP;

  END IF;

  RETURN;

END;
$$ LANGUAGE 'plpgsql';

