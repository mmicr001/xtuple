DROP FUNCTION IF EXISTS lowercost(integer, text);

CREATE OR REPLACE FUNCTION lowerCost(pItemid   INTEGER,
                                     pCosttype TEXT,
                                     pActual   BOOLEAN DEFAULT TRUE)
  RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  _type CHAR(1);
  _actCost	NUMERIC;
  _actCost1	NUMERIC;
  _actCost2	NUMERIC;
  _stdCost	NUMERIC;
  _stdCost1	NUMERIC;
  _stdCost2	NUMERIC;
  _cost		NUMERIC;
  _cost1	NUMERIC;
  _cost2	NUMERIC;
  _batchsize	NUMERIC;

BEGIN

  SELECT item_type INTO _type
  FROM item
  WHERE (item_id=pItemid);

  _batchsize := COALESCE( (
    SELECT bomhead_batchsize
    FROM bomhead
    WHERE ((bomhead_item_id=pItemId)
     AND  (bomhead_rev_id=getActiveRevId('BOM',pItemId))) LIMIT 1), 1);

  -- find the lowercost in the base currency at the current conversion rate
  IF (_type IN ('M', 'F', 'B', 'T')) THEN

    IF (pActual) THEN
      SELECT SUM(subsum) INTO _cost
      FROM
      (SELECT CASE WHEN (EXISTS(SELECT 1 FROM bomitemcost WHERE bomitemcost_bomitem_id=bomitem_id)) THEN
                  SUM(round(currToBase(bomitemcost_curr_id, bomitemcost_actcost, CURRENT_DATE),6) *
                    itemuomtouom(bomitem_item_id, bomitem_uom_id, NULL, (bomitem_qtyfxd/_batchsize + bomitem_qtyper) * (1 + bomitem_scrap), 'qtyper'))
                  ELSE
                  SUM(round(currToBase(itemcost_curr_id, itemcost_actcost, CURRENT_DATE),6) * qty *
                    itemuomtouom(bomitem_item_id, bomitem_uom_id, NULL, (bomitem_qtyfxd/_batchsize + bomitem_qtyper) * (1 + bomitem_scrap), 'qtyper'))
                  END AS subsum
      FROM (
            WITH RECURSIVE _bomitem AS
            (
             SELECT bomitem_id AS id, bomitem_item_id, item_type,
                    bomitem_uom_id, bomitem_qtyfxd, bomitem_qtyper, bomitem_scrap,
                    1.0 AS qty
               FROM bomitem(pItemid)
               JOIN item ON bomitem_item_id = item_id
             UNION ALL
             SELECT bomitem.bomitem_id, bomitem.bomitem_item_id, item.item_type,
                    bomitem.bomitem_uom_id, bomitem.bomitem_qtyfxd, bomitem.bomitem_qtyper, bomitem.bomitem_scrap,
                    _bomitem.qty * itemuomtouom(_bomitem.bomitem_item_id, _bomitem.bomitem_uom_id, NULL, (_bomitem.bomitem_qtyfxd/_batchsize + _bomitem.bomitem_qtyper) * (1 + _bomitem.bomitem_scrap), 'qtyper')
               FROM _bomitem, bomitem(bomitem_item_id)
               JOIN item ON bomitem.bomitem_item_id = item_id
              WHERE _bomitem.item_type = 'F'
             )
             SELECT id, qty
               FROM _bomitem
              WHERE item_type != 'F'
           ) bomitems
      JOIN bomitem ON bomitems.id = bomitem_id
        JOIN item ON (item_id=bomitem_item_id AND item_type <> 'T')
        LEFT OUTER JOIN itemcost ON (itemcost_item_id=bomitem_item_id)
        LEFT OUTER JOIN costelem ic ON (ic.costelem_id=itemcost_costelem_id)
        LEFT OUTER JOIN bomitemcost ON (bomitemcost_bomitem_id=bomitem_id)
        LEFT OUTER JOIN costelem bc ON (bc.costelem_id=bomitemcost_costelem_id)
      WHERE ( CURRENT_DATE BETWEEN bomitem_effective AND (bomitem_expires - 1) )
      AND COALESCE(bc.costelem_type, ic.costelem_type)=pCosttype
      GROUP BY bomitem_id) sub;
    ELSE
      SELECT SUM(subsum) INTO _cost
      FROM
      (SELECT CASE WHEN (EXISTS(SELECT 1 FROM bomitemcost WHERE bomitemcost_bomitem_id=bomitem_id)) THEN
                  SUM(bomitemcost_stdcost *
                    itemuomtouom(bomitem_item_id, bomitem_uom_id, NULL, (bomitem_qtyfxd/_batchsize + bomitem_qtyper) * (1 + bomitem_scrap), 'qtyper'))
                  ELSE
                  SUM(itemcost_stdcost * qty *
                    itemuomtouom(bomitem_item_id, bomitem_uom_id, NULL, (bomitem_qtyfxd/_batchsize + bomitem_qtyper) * (1 + bomitem_scrap), 'qtyper'))
                  END AS subsum
      FROM (
            WITH RECURSIVE _bomitem AS
            (
             SELECT bomitem_id AS id, bomitem_item_id, item_type,
                    bomitem_uom_id, bomitem_qtyfxd, bomitem_qtyper, bomitem_scrap,
                    1.0 AS qty
               FROM bomitem(pItemid)
               JOIN item ON bomitem_item_id = item_id
             UNION ALL
             SELECT bomitem.bomitem_id, bomitem.bomitem_item_id, item.item_type,
                    bomitem.bomitem_uom_id, bomitem.bomitem_qtyfxd, bomitem.bomitem_qtyper, bomitem.
bomitem_scrap,
                    _bomitem.qty * itemuomtouom(_bomitem.bomitem_item_id, _bomitem.bomitem_uom_id, NULL, (_bomitem.bomitem_qtyfxd/_batchsize + _bomitem.bomitem_qtyper) * (1 + _bomitem.bomitem_scrap), 'qtyper')
               FROM _bomitem, bomitem(bomitem_item_id)
               JOIN item ON bomitem.bomitem_item_id = item_id
              WHERE _bomitem.item_type = 'F'
             )
             SELECT id, qty
               FROM _bomitem
              WHERE item_type != 'F'
           ) bomitems
      JOIN bomitem ON bomitems.id = bomitem_id
        JOIN item ON (item_id=bomitem_item_id AND item_type <> 'T')
        LEFT OUTER JOIN itemcost ON (itemcost_item_id=bomitem_item_id)
        LEFT OUTER JOIN costelem ic ON (ic.costelem_id=itemcost_costelem_id)
        LEFT OUTER JOIN bomitemcost ON (bomitemcost_bomitem_id=bomitem_id)
        LEFT OUTER JOIN costelem bc ON (bc.costelem_id=bomitemcost_costelem_id)
      WHERE ( CURRENT_DATE BETWEEN bomitem_effective AND (bomitem_expires - 1) )
      AND COALESCE(bc.costelem_type, ic.costelem_type)=pCosttype
      GROUP BY bomitem_id) sub; 
    END IF;
    
    IF (NOT FOUND) THEN
      _cost := NULL;
    END IF;

  ELSIF _type IN ('C') AND packageIsEnabled('xtmfg') THEN
    SELECT SUM(CASE WHEN (bbomitem_qtyper = 0) THEN 0
                    ELSE currToBase(itemcost_curr_id, itemcost_actcost, CURRENT_DATE) / bbomitem_qtyper * bbomitem_costabsorb
               END),
           SUM(CASE WHEN (bbomitem_qtyper = 0) THEN 0
                    ELSE itemcost_stdcost / bbomitem_qtyper * bbomitem_costabsorb
               END)
        INTO _actCost1, _stdCost1
    FROM itemcost
         JOIN costelem       ON (itemcost_costelem_id=costelem_id)
         JOIN xtmfg.bbomitem ON (bbomitem_parent_item_id=itemcost_item_id)
    WHERE ( (bbomitem_item_id=pItemid)
     AND (CURRENT_DATE BETWEEN bbomitem_effective AND (bbomitem_expires - 1))
     AND (costelem_type=pCosttype) );

    SELECT SUM(CASE WHEN (t.bbomitem_qtyper = 0) THEN 0
                    ELSE currToBase(itemcost_curr_id, itemcost_actcost, CURRENT_DATE) * s.bbomitem_qtyper / t.bbomitem_qtyper * t.bbomitem_costabsorb
               END),
           SUM(CASE WHEN (t.bbomitem_qtyper = 0) THEN 0
                    ELSE itemcost_stdcost * s.bbomitem_qtyper / t.bbomitem_qtyper * t.bbomitem_costabsorb
               END)
        INTO _actCost2, _stdCost2
    FROM costelem
         JOIN itemcost            ON (costelem_id=itemcost_costelem_id)
         JOIN xtmfg.bbomitem AS s ON (itemcost_item_id=s.bbomitem_item_id)
         JOIN xtmfg.bbomitem AS t ON (s.bbomitem_parent_item_id=t.bbomitem_parent_item_id)
         JOIN  item               ON (s.bbomitem_item_id=item_id)
    WHERE ( (t.bbomitem_item_id=pItemid)
     AND ( CURRENT_DATE BETWEEN s.bbomitem_effective
                        AND (s.bbomitem_expires - 1) )
     AND ( CURRENT_DATE BETWEEN t.bbomitem_effective
                        AND (t.bbomitem_expires - 1) )
     AND (item_type='Y')
     AND (costelem_type=pCosttype) );

    IF (pActual) THEN
        _cost  = _actCost;
        _cost1 = _actCost1;
        _cost2 = _actCost2;
    ELSE
        _cost  = _stdCost;
        _cost1 = _stdCost1;
        _cost2 = _stdCost2;	-- should this be std or act?
    END IF;

    IF (_cost1 IS NULL AND _cost2 IS NULL) THEN
        _cost = NULL;
    ELSE
        _cost = COALESCE(_cost1, 0) + COALESCE(_cost2, 0);
    END IF;
  ELSE
    RETURN NULL;
  END IF;

  RETURN round(_cost,6);

END;
$$ LANGUAGE plpgsql;
