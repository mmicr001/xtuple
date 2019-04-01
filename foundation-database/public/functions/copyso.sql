DROP FUNCTION IF EXISTS copyso(integer, date);
CREATE OR REPLACE FUNCTION copyso(psoheadid integer, pcustomer integer, pscheddate date)
  RETURNS integer AS
$$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _soheadid INTEGER;
  _soitemid INTEGER;
  _soitem RECORD;

BEGIN

  _soheadid := copysoheader(pSoheadid, pcustomer, pSchedDate);

  FOR _soitem IN
    SELECT coitem.*, itemsite_item_id
    FROM coitem JOIN itemsite ON (itemsite_id=coitem_itemsite_id)
    WHERE ( (coitem_cohead_id=pSoheadid)
      AND   (coitem_status <> 'X')
      AND   (coitem_subnumber = 0) ) LOOP

    INSERT INTO coitem (
      coitem_cohead_id,
      coitem_linenumber,
      coitem_itemsite_id,
      coitem_status,
      coitem_scheddate,
      coitem_promdate,
      coitem_qtyord,
      coitem_unitcost,
      coitem_price,
      coitem_custprice,
      coitem_qtyshipped,
      coitem_order_id,
      coitem_memo,
      coitem_imported,
      coitem_qtyreturned,
      coitem_closedate,
      coitem_custpn,
      coitem_order_type,
      coitem_close_username,
      coitem_substitute_item_id,
      coitem_created,
      coitem_creator,
      coitem_prcost,
      coitem_qty_uom_id,
      coitem_qty_invuomratio,
      coitem_price_uom_id,
      coitem_price_invuomratio,
      coitem_warranty,
      coitem_cos_accnt_id,
      coitem_qtyreserved,
      coitem_subnumber,
      coitem_firm,
      coitem_taxtype_id, 
      coitem_dropship )
    VALUES (
      _soheadid,
      _soitem.coitem_linenumber,
      _soitem.coitem_itemsite_id,
      'O',
      COALESCE(pSchedDate, _soitem.coitem_scheddate),
      _soitem.coitem_promdate,
      _soitem.coitem_qtyord,
      CASE WHEN fetchMetricBool('WholesalePriceCosting') THEN (SELECT item_listcost FROM item
                                                               WHERE item_id=_soitem.itemsite_item_id)
           ELSE stdCost(_soitem.itemsite_item_id)
      END,
      _soitem.coitem_price,
      _soitem.coitem_custprice,
      0.0,
      -1,
      _soitem.coitem_memo,
      FALSE,
      0.0,
      NULL,
      _soitem.coitem_custpn,
      _soitem.coitem_order_type,
      NULL,
      _soitem.coitem_substitute_item_id,
      NULL,
      getEffectiveXtUser(),
      _soitem.coitem_prcost,
      _soitem.coitem_qty_uom_id,
      _soitem.coitem_qty_invuomratio,
      _soitem.coitem_price_uom_id,
      _soitem.coitem_price_invuomratio,
      _soitem.coitem_warranty,
      _soitem.coitem_cos_accnt_id,
      0.0,
      _soitem.coitem_subnumber,
      _soitem.coitem_firm,
      _soitem.coitem_taxtype_id,
      _soitem.coitem_dropship )
    RETURNING coitem_id INTO _soitemid;

    -- insert characteristics first so they can be copied to associated supply order
    INSERT INTO charass
          (charass_target_type, charass_target_id,
           charass_char_id, charass_value, charass_price)
    SELECT charass_target_type, _soitemid,
           charass_char_id, charass_value, charass_price
      FROM charass
     WHERE ((charass_target_type='SI')
       AND  (charass_target_id=_soitem.coitem_id));

  END LOOP;

  RETURN _soheadid;

END;
$$ LANGUAGE plpgsql;
