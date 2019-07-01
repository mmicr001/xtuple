
CREATE OR REPLACE FUNCTION _soheadTrigger() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  _p RECORD;
  _a RECORD;
  _w RECORD;
  _shiptoId INTEGER;
  _addrId INTEGER;
  _prjId INTEGER;
  _check BOOLEAN;
  _numGen CHAR(1);

BEGIN

  -- Checks
  -- Start with privileges
  IF (TG_OP = 'INSERT') THEN
    IF ( (NOT checkPrivilege('MaintainSalesOrders')) AND
       (NOT checkPrivilege('EnterReceipts')) ) THEN
      RAISE EXCEPTION 'You do not have privileges to create a Sales Order.';
    END IF;
  ELSIF (TG_OP = 'UPDATE') THEN
    IF ( (NOT checkPrivilege('MaintainSalesOrders')) AND
         (NOT checkPrivilege('IssueStockToShipping')) AND
         (NEW.cohead_holdtype = OLD.cohead_holdtype) ) THEN
      RAISE EXCEPTION 'You do not have privileges to alter a Sales Order.';
    END IF;
  END IF;

  -- If this is imported, check the order number
  IF (TG_OP = 'INSERT') THEN
    IF (NEW.cohead_imported) THEN
      SELECT fetchMetricText('CONumberGeneration') INTO _numGen;
      IF ((NEW.cohead_number IS NULL) AND (_numGen='M')) THEN
        RAISE EXCEPTION 'You must supply an Order Number.';
      ELSE
        IF (NEW.cohead_number IS NULL) THEN
          SELECT fetchsonumber() INTO NEW.cohead_number;
        END IF;
      END IF;
    END IF;

    IF (fetchMetricText('CONumberGeneration') IN ('A','O')) THEN
      --- clear the number from the issue cache
      PERFORM clearNumberIssue('SoNumber', NEW.cohead_number);
    END IF;
  ELSE
    IF (TG_OP = 'UPDATE') THEN
      IF (NEW.cohead_number <> OLD.cohead_number) THEN
        RAISE EXCEPTION 'The order number may not be changed.';
      END IF;
    END IF;
  END IF;

  IF (TG_OP IN ('INSERT','UPDATE')) THEN

    -- Get Customer data
    IF (NEW.cohead_shipto_id IS NULL) THEN
      SELECT cust_creditstatus,cust_number,cust_usespos,cust_blanketpos,cust_ffbillto,
	     cust_ffshipto,cust_name,cust_salesrep_id,cust_terms_id,cust_shipvia,
	     cust_shipchrg_id,cust_shipform_id,cust_commprcnt,cust_curr_id,cust_taxzone_id,
  	     cntct.*,
             getcontactphone(cntct_id, 'Office') AS contact_phone, 
             getcontactphone(cntct_id, 'Fax') AS contact_fax,
             addr.addr_line1, addr.addr_line2, addr.addr_line3, addr.addr_city,
             addr.addr_state, addr.addr_postalcode, addr.addr_country,
	     shipto_id,shipto_addr_id,shipto_name,shipto_salesrep_id,shipto_shipvia,
	     shipto_shipchrg_id,shipto_shipform_id,shipto_commission,shipto_taxzone_id,
             shiptoaddr.addr_line1 AS shiptoaddr_line1, shiptoaddr.addr_line2 AS shiptoaddr_line2,
             shiptoaddr.addr_line3 AS shiptoaddr_line3, shiptoaddr.addr_city AS shiptoaddr_city,
             shiptoaddr.addr_state AS shiptoaddr_state,
             shiptoaddr.addr_postalcode AS shiptoaddr_postalcode,
             shiptoaddr.addr_country AS shiptoaddr_country INTO _p
      FROM custinfo
        LEFT OUTER JOIN cntct ON (cust_cntct_id=cntct_id)
        LEFT OUTER JOIN addr ON (cntct_addr_id=addr_id)
        LEFT OUTER JOIN shiptoinfo ON ((cust_id=shipto_cust_id) AND shipto_default)
        LEFT OUTER JOIN addr shiptoaddr ON shipto_addr_id=shiptoaddr.addr_id
      WHERE (cust_id=NEW.cohead_cust_id);
    ELSE
      SELECT cust_creditstatus,cust_number,cust_usespos,cust_blanketpos,cust_ffbillto,
	     cust_ffshipto,cust_name,cust_salesrep_id,cust_terms_id,cust_shipvia,
	     cust_shipchrg_id,cust_shipform_id,cust_commprcnt,cust_curr_id,cust_taxzone_id,
  	     cntct.*,
             getcontactphone(cntct_id, 'Office') AS contact_phone, 
             getcontactphone(cntct_id, 'Fax') AS contact_fax,
             addr.addr_line1, addr.addr_line2, addr.addr_line3, addr.addr_city,
             addr.addr_state, addr.addr_postalcode, addr.addr_country,
	     shipto_id,shipto_addr_id,shipto_name,shipto_salesrep_id,shipto_shipvia,
	     shipto_shipchrg_id,shipto_shipform_id,shipto_commission,shipto_taxzone_id,
             shiptoaddr.addr_line1 AS shiptoaddr_line1, shiptoaddr.addr_line2 AS shiptoaddr_line2,
             shiptoaddr.addr_line3 AS shiptoaddr_line3, shiptoaddr.addr_city AS shiptoaddr_city,
             shiptoaddr.addr_state AS shiptoaddr_state,
             shiptoaddr.addr_postalcode AS shiptoaddr_postalcode,
             shiptoaddr.addr_country AS shiptoaddr_country INTO _p
      FROM custinfo
        CROSS JOIN shiptoinfo
        LEFT OUTER JOIN cntct ON (cust_cntct_id=cntct_id)
        LEFT OUTER JOIN addr ON (cntct_addr_id=addr_id)
        LEFT OUTER JOIN addr shiptoaddr ON shipto_addr_id=shiptoaddr.addr_id
      WHERE ((cust_id=NEW.cohead_cust_id)
        AND  (shipto_id=NEW.cohead_shipto_id));
    END IF;

    -- If there is customer data, then we can get to work
    IF (FOUND) THEN

      -- Check Credit
      IF (TG_OP = 'INSERT') THEN
          IF (_p.cust_creditstatus = 'H') THEN
            SELECT checkPrivilege('CreateSOForHoldCustomer') INTO _check;
            IF NOT (_check) THEN
              RAISE EXCEPTION 'Customer % has been placed
                               on a Credit Hold and you do not have
                               privilege to create Sales Orders for
                               Customers on Credit Hold.  The selected
                               Customer must be taken off of Credit Hold
                               before you may create a new Sales Order
                               for the Customer.',_p.cust_number;
            ELSE
              NEW.cohead_holdtype='C';
            END IF;
          END IF;
          IF (_p.cust_creditstatus = 'W') THEN
            SELECT checkPrivilege('CreateSOForWarnCustomer') INTO _check;
            IF NOT (_check) THEN
              RAISE EXCEPTION 'Customer % has been placed on
                              a Credit Warning and you do not have
                              privilege to create Sales Orders for
                              Customers on Credit Warning.  The
                              selected Customer must be taken off of
                              Credit Warning before you may create a
                              new Sales Order for the Customer.',_p.cust_number;
            ELSE
              NEW.cohead_holdtype='C';
            END IF;
          END IF;

          -- Set to defaults if values not provided
          IF (NEW.cohead_shipto_id IS NULL) THEN
            NEW.cohead_shipto_id := _p.shipto_id;
            NEW.cohead_shiptoname := _p.shipto_name;
            NEW.cohead_shiptoaddress1 := _p.shiptoaddr_line1;
            NEW.cohead_shiptoaddress2 := _p.shiptoaddr_line2;
            NEW.cohead_shiptoaddress3 := _p.shiptoaddr_line3;
            NEW.cohead_shiptocity := _p.shiptoaddr_city;
            NEW.cohead_shiptostate := _p.shiptoaddr_state;
            NEW.cohead_shiptozipcode := _p.shiptoaddr_postalcode;
            NEW.cohead_shiptocountry := _p.shiptoaddr_country;
          END IF;

          NEW.cohead_terms_id		:= COALESCE(NEW.cohead_terms_id,_p.cust_terms_id);
          NEW.cohead_orderdate		:= COALESCE(NEW.cohead_orderdate,current_date);
          NEW.cohead_packdate		:= COALESCE(NEW.cohead_packdate,NEW.cohead_orderdate);
          NEW.cohead_curr_id		:= COALESCE(NEW.cohead_curr_id,_p.cust_curr_id,basecurrid());
          NEW.cohead_freight		:= COALESCE(NEW.cohead_freight,0);
          NEW.cohead_custponumber	:= COALESCE(NEW.cohead_custponumber,'');
          NEW.cohead_ordercomments	:= COALESCE(NEW.cohead_ordercomments,'');
          NEW.cohead_shipcomments	:= COALESCE(NEW.cohead_shipcomments,'');
          NEW.cohead_shiptophone	:= COALESCE(NEW.cohead_shiptophone,'');
          NEW.cohead_misc		:= COALESCE(NEW.cohead_misc,0);
          NEW.cohead_misc_descrip	:= COALESCE(NEW.cohead_misc_descrip,'');
          NEW.cohead_shipcomplete	:= COALESCE(NEW.cohead_shipcomplete,false);

          IF (_p.shipto_id IS NOT NULL) THEN -- Pull in over ride values
	    NEW.cohead_salesrep_id 	:= COALESCE(NEW.cohead_salesrep_id,_p.shipto_salesrep_id);
	    NEW.cohead_shipvia		:= COALESCE(NEW.cohead_shipvia,_p.shipto_shipvia);
	    NEW.cohead_shipchrg_id	:= COALESCE(NEW.cohead_shipchrg_id,_p.shipto_shipchrg_id);
	    NEW.cohead_shipform_id	:= COALESCE(NEW.cohead_shipform_id,_p.shipto_shipform_id);
	    NEW.cohead_commission	:= COALESCE(NEW.cohead_commission,_p.shipto_commission);
	    IF (NEW.cohead_taxzone_id=-1) THEN
	      NEW.cohead_taxzone_id 	:= NULL;
	    ELSE
	      NEW.cohead_taxzone_id	:= COALESCE(NEW.cohead_taxzone_id,_p.shipto_taxzone_id);
	    END IF;
	  ELSE
	    NEW.cohead_salesrep_id 	:= COALESCE(NEW.cohead_salesrep_id,_p.cust_salesrep_id);
	    NEW.cohead_shipvia		:= COALESCE(NEW.cohead_shipvia,_p.cust_shipvia);
	    NEW.cohead_shipchrg_id	:= COALESCE(NEW.cohead_shipchrg_id,_p.cust_shipchrg_id);
	    NEW.cohead_shipform_id	:= COALESCE(NEW.cohead_shipform_id,_p.cust_shipform_id);
	    NEW.cohead_commission	:= COALESCE(NEW.cohead_commission,_p.cust_commprcnt);
	    IF (NEW.cohead_taxzone_id=-1) THEN
	      NEW.cohead_taxzone_id 	:= NULL;
	    ELSE
	      NEW.cohead_taxzone_id	:= COALESCE(NEW.cohead_taxzone_id,_p.cust_taxzone_id);
	    END IF;
          END IF;

          IF ((NEW.cohead_warehous_id IS NULL) OR (NEW.cohead_fob IS NULL)) THEN
            IF (NEW.cohead_warehous_id IS NULL) THEN
              SELECT warehous_id,warehous_fob INTO _w
              FROM usrpref, whsinfo
              WHERE ((warehous_id=CAST(usrpref_value AS INTEGER))
                AND (warehous_shipping)
                AND (warehous_active)
                AND (usrpref_username=getEffectiveXtUser())
                AND (usrpref_name='PreferredWarehouse'));
            ELSE
              SELECT warehous_id,warehous_fob INTO _w
              FROM whsinfo
              WHERE (warehous_id=NEW.cohead_warehous_id);
            END IF;

            IF (FOUND) THEN
              NEW.cohead_warehous_id 	:= COALESCE(NEW.cohead_warehous_id,_w.warehous_id);
              NEW.cohead_fob		:= COALESCE(NEW.cohead_fob,_w.warehous_fob);
            END IF;
          END IF;

      END IF;

      -- Only Check P/O logic for imports, because UI checks when entire order is saved
      IF (NEW.cohead_imported) THEN

        -- Check for required Purchase Order
        IF (_p.cust_usespos AND ((NEW.cohead_custponumber IS NULL) OR (TRIM(BOTH FROM NEW.cohead_custponumber)=''))) THEN
            RAISE EXCEPTION 'You must enter a Customer P/O for this Sales Order.';
        END IF;

        -- Check for duplicate Purchase Orders if not allowed
        IF (_p.cust_usespos AND NOT (_p.cust_blanketpos)) THEN
          SELECT cohead_id INTO _a
          FROM cohead
          WHERE ((cohead_cust_id=NEW.cohead_cust_id)
          AND  (cohead_id<>NEW.cohead_id)
          AND  (UPPER(cohead_custponumber) = UPPER(NEW.cohead_custponumber)) )
          UNION
          SELECT quhead_id
          FROM quhead
          WHERE ((quhead_cust_id=NEW.cohead_cust_id)
          AND  (quhead_id<>NEW.cohead_id)
          AND  (UPPER(quhead_custponumber) = UPPER(NEW.cohead_custponumber)) );
          IF (FOUND) THEN
	    RAISE EXCEPTION 'This Customer does not use Blanket P/O
                            Numbers and the P/O Number you entered has
                            already been used for another Sales Order.
                            Please verify the P/O Number and either
                            enter a new P/O Number or add to the
                            existing Sales Order.';
         END IF;
        END IF;
      END IF;

      --Auto create project if applicable
      IF ((TG_OP = 'INSERT') AND (COALESCE(NEW.cohead_prj_id,-1)=-1)) THEN
        SELECT fetchMetricBool('AutoCreateProjectsForOrders') INTO _check;
        IF (_check) THEN
          SELECT NEXTVAL('prj_prj_id_seq') INTO _prjId;
          NEW.cohead_prj_id := _prjId;
          INSERT INTO prj (prj_id, prj_number, prj_name, prj_descrip,
                           prj_status, prj_so, prj_wo, prj_po,
                           prj_owner_username, prj_start_date, prj_due_date,
                           prj_assigned_date, prj_completed_date, prj_username,
                           prj_recurring_prj_id, prj_crmacct_id,
                           prj_cntct_id, prj_prjtype_id)
          SELECT _prjId, NEW.cohead_number, NEW.cohead_number, 'Auto Generated Project from Sales Order.',
                 'O', TRUE, TRUE, TRUE,
                 getEffectiveXTUser(), NEW.cohead_orderdate, NEW.cohead_packdate,
                 NEW.cohead_orderdate, NULL, getEffectiveXTUser(),
                 NULL, crmacct_id,
                 NEW.cohead_billto_cntct_id, NULL
          FROM crmacct
          JOIN custinfo ON (crmacct_id=cust_crmacct_id)
          WHERE (cust_id=NEW.cohead_cust_id);
        END IF;
      END IF;

      IF (TG_OP = 'UPDATE') THEN
        --Update project references on supply
        UPDATE pr SET pr_prj_id=NEW.cohead_prj_id
                   FROM coitem
                   WHERE ((coitem_cohead_id=NEW.cohead_id)
                     AND  (coitem_status != 'C')
                     AND  (coitem_order_type='R')
                     AND  (coitem_order_id=pr_id));

        PERFORM changeWoProject(coitem_order_id, NEW.cohead_prj_id, TRUE)
                    FROM coitem
                    WHERE ((coitem_cohead_id=NEW.cohead_id)
                      AND  (coitem_status != 'C')
                      AND  (coitem_order_type='W'));

        SELECT true INTO _check
        FROM coitem
        WHERE ( (coitem_status='C')
        AND (coitem_cohead_id=NEW.cohead_id) )
        LIMIT 1;

        IF (FOUND) THEN
          IF NEW.cohead_prj_id <> COALESCE(OLD.cohead_prj_id,-1) THEN
            RAISE EXCEPTION 'You can not change the project ID on orders with closed lines.';
          END IF;
        END IF;
      END IF;

      -- Deal with Billing Address
      IF (TG_OP = 'INSERT') THEN
        IF (_p.cust_ffbillto) THEN
          -- If they didn't supply data, we'll put in the bill to contact and address
          NEW.cohead_billto_cntct_id=COALESCE(NEW.cohead_billto_cntct_id,_p.cntct_id);
          NEW.cohead_billto_cntct_honorific=COALESCE(NEW.cohead_billto_cntct_honorific,_p.cntct_honorific,'');
          NEW.cohead_billto_cntct_first_name=COALESCE(NEW.cohead_billto_cntct_first_name,_p.cntct_first_name,'');
          NEW.cohead_billto_cntct_middle=COALESCE(NEW.cohead_billto_cntct_middle,_p.cntct_middle,'');
          NEW.cohead_billto_cntct_last_name=COALESCE(NEW.cohead_billto_cntct_last_name,_p.cntct_last_name,'');
          NEW.cohead_billto_cntct_phone=COALESCE(NEW.cohead_billto_cntct_phone,_p.contact_phone,'');
          NEW.cohead_billto_cntct_title=COALESCE(NEW.cohead_billto_cntct_title,_p.cntct_title,'');
          NEW.cohead_billto_cntct_fax=COALESCE(NEW.cohead_billto_cntct_fax,_p.contact_fax,'');
          NEW.cohead_billto_cntct_email=COALESCE(NEW.cohead_billto_cntct_email,_p.cntct_email,'');
          NEW.cohead_billtoname=COALESCE(NEW.cohead_billtoname,_p.cust_name,'');
          NEW.cohead_billtoaddress1=COALESCE(NEW.cohead_billtoaddress1,_p.addr_line1,'');
          NEW.cohead_billtoaddress2=COALESCE(NEW.cohead_billtoaddress2,_p.addr_line2,'');
          NEW.cohead_billtoaddress3=COALESCE(NEW.cohead_billtoaddress3,_p.addr_line3,'');
          NEW.cohead_billtocity=COALESCE(NEW.cohead_billtocity,_p.addr_city,'');
          NEW.cohead_billtostate=COALESCE(NEW.cohead_billtostate,_p.addr_state,'');
          NEW.cohead_billtozipcode=COALESCE(NEW.cohead_billtozipcode,_p.addr_postalcode,'');
          NEW.cohead_billtocountry=COALESCE(NEW.cohead_billtocountry,_p.addr_country,'');
        ELSE
          -- Free form not allowed, we're going to put in the address regardless
          NEW.cohead_billto_cntct_id=_p.cntct_id;
          NEW.cohead_billto_cntct_honorific=COALESCE(_p.cntct_honorific,'');
          NEW.cohead_billto_cntct_first_name=COALESCE(_p.cntct_first_name,'');
          NEW.cohead_billto_cntct_middle=COALESCE(_p.cntct_middle,'');
          NEW.cohead_billto_cntct_last_name=COALESCE(_p.cntct_last_name,'');
          NEW.cohead_billto_cntct_phone=COALESCE(_p.contact_phone,'');
          NEW.cohead_billto_cntct_title=COALESCE(_p.cntct_title,'');
          NEW.cohead_billto_cntct_fax=COALESCE(_p.contact_fax,'');
          NEW.cohead_billto_cntct_email=COALESCE(_p.cntct_email,'');
          NEW.cohead_billtoname=COALESCE(_p.cust_name,'');
          NEW.cohead_billtoaddress1=COALESCE(_p.addr_line1,'');
          NEW.cohead_billtoaddress2=COALESCE(_p.addr_line2,'');
          NEW.cohead_billtoaddress3=COALESCE(_p.addr_line3,'');
          NEW.cohead_billtocity=COALESCE(_p.addr_city,'');
          NEW.cohead_billtostate=COALESCE(_p.addr_state,'');
          NEW.cohead_billtozipcode=COALESCE(_p.addr_postalcode,'');
          NEW.cohead_billtocountry=COALESCE(_p.addr_country,'');
        END IF;
      END IF;

      -- Now let's look at Shipto Address
      -- If there's nothing in the address fields and there is a shipto id
      -- or there is a default address available, let's put in some shipto address data
      IF ((TG_OP = 'INSERT')
        AND NOT ((NEW.cohead_shipto_id IS NULL) AND NOT _p.cust_ffshipto)
        AND (NEW.cohead_shipto_cntct_id IS NULL)
        AND (NEW.cohead_shipto_cntct_honorific IS NULL)
        AND (NEW.cohead_shipto_cntct_first_name IS NULL)
        AND (NEW.cohead_shipto_cntct_middle IS NULL)
        AND (NEW.cohead_shipto_cntct_last_name IS NULL)
        AND (NEW.cohead_shipto_cntct_suffix IS NULL)
        AND (NEW.cohead_shipto_cntct_phone IS NULL)
        AND (NEW.cohead_shipto_cntct_title IS NULL)
        AND (NEW.cohead_shipto_cntct_fax IS NULL)
        AND (NEW.cohead_shipto_cntct_email IS NULL)
        AND (NEW.cohead_shiptoname IS NULL)
        AND (NEW.cohead_shiptoaddress1 IS NULL)
        AND (NEW.cohead_shiptoaddress2 IS NULL)
        AND (NEW.cohead_shiptoaddress3 IS NULL)
        AND (NEW.cohead_shiptocity IS NULL)
        AND (NEW.cohead_shiptostate IS NULL)
        AND (NEW.cohead_shiptocountry IS NULL)) THEN
        IF ((NEW.cohead_shipto_id IS NULL) AND (_p.shipto_id IS NOT NULL)) THEN
          _shiptoId := _p.shipto_addr_id;
        ELSE
          _shiptoId := NEW.cohead_shipto_id;
        END IF;

        SELECT cntct.*, 
               getcontactphone(cntct_id, 'Office') AS contact_phone, 
               getcontactphone(cntct_id, 'Fax') AS contact_fax,
               shipto_name,
               addr.addr_line1, addr.addr_line2, addr.addr_line3, addr.addr_city,
               addr.addr_state, addr.addr_postalcode, addr.addr_country
        INTO _a
        FROM shiptoinfo
          LEFT OUTER JOIN addr ON (addr_id=shipto_addr_id)
          LEFT OUTER JOIN cntct ON (cntct_id=shipto_cntct_id)
        WHERE (shipto_id=_shiptoId);

        NEW.cohead_shipto_cntct_id := _a.cntct_id;
        NEW.cohead_shipto_cntct_honorific := COALESCE(_a.cntct_honorific,'');
        NEW.cohead_shipto_cntct_first_name := COALESCE(_a.cntct_first_name,'');
        NEW.cohead_shipto_cntct_middle := COALESCE(_a.cntct_middle,'');
        NEW.cohead_shipto_cntct_last_name := COALESCE(_a.cntct_last_name,'');
	NEW.cohead_shipto_cntct_suffix := COALESCE(_a.cntct_suffix,'');
	NEW.cohead_shipto_cntct_phone := COALESCE(_a.contact_phone,'');
	NEW.cohead_shipto_cntct_title := COALESCE(_a.cntct_title,'');
	NEW.cohead_shipto_cntct_fax := COALESCE(_a.contact_fax,'');
	NEW.cohead_shipto_cntct_email := COALESCE(_a.cntct_email,'');
        NEW.cohead_shiptoname := COALESCE(_p.shipto_name,'');
        NEW.cohead_shiptoaddress1 := COALESCE(_a.addr_line1,'');
        NEW.cohead_shiptoaddress2 := COALESCE(_a.addr_line2,'');
        NEW.cohead_shiptoaddress3 := COALESCE(_a.addr_line3,'');
        NEW.cohead_shiptocity := COALESCE(_a.addr_city,'');
        NEW.cohead_shiptostate := COALESCE(_a.addr_state,'');
        NEW.cohead_shiptozipcode := COALESCE(_a.addr_postalcode,'');
        NEW.cohead_shiptocountry := COALESCE(_a.addr_country,'');
      ELSE
        IF (_p.cust_ffshipto) THEN
          -- Use Address Save function to see if the new address entered matches
          -- data for the shipto number.  If not that will insert new address for CRM
          SELECT SaveAddr(
            NULL,
            NULL,
            NEW.cohead_shiptoaddress1,
            NEW.cohead_shiptoaddress2,
            NEW.cohead_shiptoaddress3,
            NEW.cohead_shiptocity,
            NEW.cohead_shiptostate,
            NEW.cohead_shiptozipcode,
            NEW.cohead_shiptocountry,
            'CHANGEONE') INTO _addrId;
          SELECT shipto_addr_id INTO _shiptoid FROM shiptoinfo WHERE (shipto_id=NEW.cohead_shipto_id);
          -- If the address passed doesn't match shipto address, then something is wrong
          IF (SELECT NOT
                     (UPPER(addr1.addr_line1)      = UPPER(COALESCE(addr2.addr_line1, ''))      AND
                      UPPER(addr1.addr_line2)      = UPPER(COALESCE(addr2.addr_line2, ''))      AND
                      UPPER(addr1.addr_line3)      = UPPER(COALESCE(addr2.addr_line3, ''))      AND
                      UPPER(addr1.addr_city)       = UPPER(COALESCE(addr2.addr_city, ''))       AND
                      UPPER(addr1.addr_state)      = UPPER(COALESCE(addr2.addr_state, ''))      AND
                      UPPER(addr1.addr_postalcode) = UPPER(COALESCE(addr2.addr_postalcode, '')) AND
                      UPPER(addr1.addr_country)    = UPPER(COALESCE(addr2.addr_country, '')))
                FROM addr addr1, addr addr2
               WHERE addr1.addr_id=_addrId
                 AND addr2.addr_id=_shiptoid) THEN
            RAISE WARNING 'Shipto does not match Shipto address information';
          END IF;
        ELSE
          SELECT cohead_shipto_id INTO _shiptoid FROM cohead WHERE (cohead_id=NEW.cohead_id);
          -- Get the shipto address
          IF (COALESCE(NEW.cohead_shipto_id,-1) <> COALESCE(_shiptoid,-1)) THEN
            SELECT cntct.*, shipto_name,
               getcontactphone(cntct_id, 'Office') AS contact_phone,
               getcontactphone(cntct_id, 'Fax') AS contact_fax,
               addr.addr_line1, addr.addr_line2, addr.addr_line3, addr.addr_city,
               addr.addr_state, addr.addr_postalcode, addr.addr_country
            INTO _a
            FROM shiptoinfo
              LEFT OUTER JOIN cntct ON (shipto_cntct_id=cntct_id)
              LEFT OUTER JOIN addr ON (shipto_addr_id=addr_id)
            WHERE (shipto_id=NEW.cohead_shipto_id);
            IF (FOUND) THEN
              -- Free form not allowed so we're going to make sure address matches Shipto data
              NEW.cohead_shipto_cntct_id=_a.cntct_id;
              NEW.cohead_shipto_cntct_honorific=COALESCE(_a.cntct_honorific,'');
              NEW.cohead_shipto_cntct_first_name=COALESCE(_a.cntct_first_name,'');
              NEW.cohead_shipto_cntct_middle=COALESCE(_a.cntct_middle,'');
              NEW.cohead_shipto_cntct_last_name=COALESCE(_a.cntct_last_name,'');
              NEW.cohead_shipto_cntct_phone=COALESCE(_a.contact_phone,'');
              NEW.cohead_shipto_cntct_title=COALESCE(_a.cntct_title,'');
              NEW.cohead_shipto_cntct_fax=COALESCE(_a.contact_fax,'');
              NEW.cohead_shipto_cntct_email=COALESCE(_a.cntct_email,'');
              NEW.cohead_shiptoname := COALESCE(_a.shipto_name,'');
              NEW.cohead_shiptophone := COALESCE(_a.contact_phone,'');
              NEW.cohead_shiptoaddress1 := COALESCE(_a.addr_line1,'');
              NEW.cohead_shiptoaddress2 := COALESCE(_a.addr_line2,'');
              NEW.cohead_shiptoaddress3 := COALESCE(_a.addr_line3,'');
              NEW.cohead_shiptocity := COALESCE(_a.addr_city,'');
              NEW.cohead_shiptostate := COALESCE(_a.addr_state,'');
              NEW.cohead_shiptozipcode := COALESCE(_a.addr_postalcode,'');
              NEW.cohead_shiptocountry := COALESCE(_a.addr_country,'');
            ELSE
              -- If no shipto data and free form not allowed, this won't work
              RAISE EXCEPTION 'Free form Shipto is not allowed on this Customer. You must supply a valid Shipto ID.';
            END IF;
          END IF;
        END IF;
      END IF;
    END IF;

    NEW.cohead_billtoaddress1   := COALESCE(NEW.cohead_billtoaddress1, '');
    NEW.cohead_billtoaddress2   := COALESCE(NEW.cohead_billtoaddress2, '');
    NEW.cohead_billtoaddress3   := COALESCE(NEW.cohead_billtoaddress3, '');
    NEW.cohead_billtocity       := COALESCE(NEW.cohead_billtocity, '');
    NEW.cohead_billtostate      := COALESCE(NEW.cohead_billtostate, '');
    NEW.cohead_billtozipcode    := COALESCE(NEW.cohead_billtozipcode, '');
    NEW.cohead_billtocountry    := COALESCE(NEW.cohead_billtocountry, '');
    NEW.cohead_shiptoaddress1   := COALESCE(NEW.cohead_shiptoaddress1, '');
    NEW.cohead_shiptoaddress2   := COALESCE(NEW.cohead_shiptoaddress2, '');
    NEW.cohead_shiptoaddress3   := COALESCE(NEW.cohead_shiptoaddress3, '');
    NEW.cohead_shiptoaddress4   := COALESCE(NEW.cohead_shiptoaddress4, '');
    NEW.cohead_shiptoaddress5   := COALESCE(NEW.cohead_shiptoaddress5, '');
    NEW.cohead_shiptocity       := COALESCE(NEW.cohead_shiptocity, '');
    NEW.cohead_shiptostate      := COALESCE(NEW.cohead_shiptostate, '');
    NEW.cohead_shiptozipcode    := COALESCE(NEW.cohead_shiptozipcode, '');
    NEW.cohead_shiptocountry    := COALESCE(NEW.cohead_shiptocountry, '');

  END IF;

  IF (TG_OP = 'UPDATE' AND
      (NEW.cohead_orderdate != OLD.cohead_orderdate OR
       NEW.cohead_curr_id != OLD.cohead_curr_id OR
       NEW.cohead_freight != OLD.cohead_freight OR
       NEW.cohead_freight_taxtype_id != OLD.cohead_freight_taxtype_id OR
       NEW.cohead_misc != OLD.cohead_misc OR
       NEW.cohead_misc_taxtype_id != OLD.cohead_misc_taxtype_id OR
       NEW.cohead_misc_discount != OLD.cohead_misc_discount OR
       (fetchMetricText('TaxService') = 'N' AND
        NEW.cohead_taxzone_id != OLD.cohead_taxzone_id) OR
       (fetchMetricText('TaxService') != 'N' AND
        (NEW.cohead_cust_id != OLD.cohead_cust_id OR
         NEW.cohead_warehous_id != OLD.cohead_warehous_id OR
         NEW.cohead_shiptoaddress1 != OLD.cohead_shiptoaddress1 OR
         NEW.cohead_shiptoaddress2 != OLD.cohead_shiptoaddress2 OR
         NEW.cohead_shiptoaddress3 != OLD.cohead_shiptoaddress3 OR
         NEW.cohead_shiptocity != OLD.cohead_shiptocity OR
         NEW.cohead_shiptostate != OLD.cohead_shiptostate OR
         NEW.cohead_shiptozipcode != OLD.cohead_shiptozipcode OR
         NEW.cohead_shiptocountry != OLD.cohead_shiptocountry OR
         NEW.cohead_tax_exemption != OLD.cohead_tax_exemption)))) THEN
    UPDATE taxhead
       SET taxhead_valid = FALSE
     WHERE taxhead_doc_type = 'S'
       AND taxhead_doc_id = NEW.cohead_id;
  END IF;

  IF (fetchMetricBool('SalesOrderChangeLog')) THEN

    IF (TG_OP = 'INSERT') THEN
      PERFORM postComment('ChangeLog', 'S', NEW.cohead_id, 'Created');

    ELSIF (TG_OP = 'UPDATE') THEN

      IF ( (OLD.cohead_terms_id <> NEW.cohead_terms_id) AND
           (OLD.cohead_cust_id = NEW.cohead_cust_id) ) THEN
        PERFORM postComment( 'ChangeLog', 'S', NEW.cohead_id, 'Terms',
                             (SELECT terms_code FROM terms WHERE terms_id=OLD.cohead_terms_id),
                             (SELECT terms_code FROM terms WHERE terms_id=NEW.cohead_terms_id));
      END IF;

      IF ( (OLD.cohead_shipvia <> NEW.cohead_shipvia) AND
           (OLD.cohead_cust_id = NEW.cohead_cust_id) ) THEN
        PERFORM postComment ('ChangeLog', 'S', NEW.cohead_id, 'Shipvia',
                             OLD.cohead_shipvia, NEW.cohead_shipvia);
      END IF;

      IF (OLD.cohead_holdtype <> NEW.cohead_holdtype) THEN
        PERFORM postComment( 'ChangeLog', 'S', NEW.cohead_id, 'Hold Type',
                             (CASE OLD.cohead_holdtype WHEN('N') THEN 'No Hold'
                                                       WHEN('C') THEN 'Credit Hold'
                                                       WHEN('P') THEN 'Packing Hold'
                                                       WHEN('R') THEN 'Return Hold'
                                                       WHEN('S') THEN 'Shipping Hold'
                                                       WHEN('T') THEN 'Tax Hold'
                                                       ELSE 'Unknown/Error' END),
                             (CASE NEW.cohead_holdtype WHEN('N') THEN 'No Hold'
                                                       WHEN('C') THEN 'Credit Hold'
                                                       WHEN('P') THEN 'Packing Hold'
                                                       WHEN('R') THEN 'Return Hold'
                                                       WHEN('S') THEN 'Shipping Hold'
                                                       WHEN('T') THEN 'Tax Hold'
                                                       ELSE 'Unknown/Error' END) );
      END IF;
    END IF;
  END IF;

  IF (TG_OP = 'UPDATE') THEN
    IF ( (NOT (OLD.cohead_holdtype = 'N')) AND
         (NEW.cohead_holdtype='N') ) THEN
      PERFORM postEvent('SoReleased', 'S', NEW.cohead_id,
                        NEW.cohead_warehous_id, NEW.cohead_number,
                        NULL, NULL, NULL, NULL);
    END IF;

    IF (OLD.cohead_ordercomments <> NEW.cohead_ordercomments) THEN
      PERFORM postEvent('SoNotesChanged', 'S', NEW.cohead_id,
                        NEW.cohead_warehous_id, NEW.cohead_number,
                        NULL, NULL, NULL, NULL);
    END IF;

    IF ((OLD.cohead_shipchrg_id != NEW.cohead_shipchrg_id)
        OR (OLD.cohead_shipvia != NEW.cohead_shipvia)) THEN
      UPDATE shiphead SET
        shiphead_shipchrg_id=
	     CASE WHEN (NEW.cohead_shipchrg_id <= 0) THEN NULL
	          ELSE NEW.cohead_shipchrg_id
	     END,
        shiphead_shipvia=NEW.cohead_shipvia
      WHERE ((shiphead_order_type='SO')
      AND  (shiphead_order_id=NEW.cohead_id)
      AND  (NOT shiphead_shipped));
    END IF;
  END IF;

  -- Timestamps
  IF (TG_OP = 'INSERT') THEN
    NEW.cohead_created := now();
    NEW.cohead_lastupdated := now();
  ELSIF (TG_OP = 'UPDATE') THEN
    NEW.cohead_lastupdated := now();
  END IF;

  RETURN NEW;

END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS soheadTrigger ON cohead;
CREATE TRIGGER soheadTrigger
  BEFORE INSERT OR UPDATE
  ON cohead
  FOR EACH ROW
  EXECUTE PROCEDURE _soheadTrigger();

CREATE OR REPLACE FUNCTION _soheadTriggerAfter() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
BEGIN
  IF (fetchMetricText('TaxService') = 'N' AND COALESCE(NEW.cohead_taxzone_id,-1) <> COALESCE(OLD.cohead_taxzone_id,-1)) THEN
    UPDATE coitem SET coitem_taxtype_id=getItemTaxType(itemsite_item_id,NEW.cohead_taxzone_id)
    FROM itemsite
    WHERE ((itemsite_id=coitem_itemsite_id)
     AND (coitem_cohead_id=NEW.cohead_id));
  END IF;

  -- update comments on any associated drop ship POs
  IF (fetchmetricbool('CopySOShippingNotestoPO') 
      AND COALESCE(NEW.cohead_shipcomments, TEXT('')) <> COALESCE(OLD.cohead_shipcomments, TEXT(''))) THEN
    UPDATE pohead SET pohead_comments=NEW.cohead_shipcomments
    FROM poitem JOIN coitem ON (coitem_cohead_id=NEW.cohead_id AND coitem_order_type='P' AND coitem_order_id=poitem_id)
    WHERE (pohead_id=poitem_pohead_id);
  END IF;

  -- update shipto address on any associated drop ship POs
  IF (COALESCE(NEW.cohead_shiptoname, TEXT('')) <> COALESCE(OLD.cohead_shiptoname, TEXT('')) OR
      COALESCE(NEW.cohead_shiptoaddress1, TEXT('')) <> COALESCE(OLD.cohead_shiptoaddress1, TEXT('')) OR
      COALESCE(NEW.cohead_shiptoaddress2, TEXT('')) <> COALESCE(OLD.cohead_shiptoaddress2, TEXT('')) OR
      COALESCE(NEW.cohead_shiptoaddress3, TEXT('')) <> COALESCE(OLD.cohead_shiptoaddress3, TEXT('')) OR
      COALESCE(NEW.cohead_shiptocity, TEXT('')) <> COALESCE(OLD.cohead_shiptocity, TEXT('')) OR
      COALESCE(NEW.cohead_shiptostate, TEXT('')) <> COALESCE(OLD.cohead_shiptostate, TEXT('')) OR
      COALESCE(NEW.cohead_shiptozipcode, TEXT('')) <> COALESCE(OLD.cohead_shiptozipcode, TEXT('')) OR
      COALESCE(NEW.cohead_shiptocountry, TEXT('')) <> COALESCE(OLD.cohead_shiptocountry, TEXT('')) ) THEN
    UPDATE pohead
      SET pohead_shiptoname=NEW.cohead_shiptoname,
          pohead_shiptoaddress1=NEW.cohead_shiptoaddress1,
          pohead_shiptoaddress2=NEW.cohead_shiptoaddress2,
          pohead_shiptoaddress3=NEW.cohead_shiptoaddress3,
          pohead_shiptocity=NEW.cohead_shiptocity,
          pohead_shiptostate=NEW.cohead_shiptostate,
          pohead_shiptozipcode=NEW.cohead_shiptozipcode,
          pohead_shiptocountry=NEW.cohead_shiptocountry
    FROM poitem JOIN coitem ON (coitem_cohead_id=NEW.cohead_id AND coitem_order_type='P' AND coitem_order_id=poitem_id)
    WHERE (pohead_id=poitem_pohead_id)
      AND (pohead_dropship);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT dropifexists('TRIGGER','soheadTriggerAfter');
CREATE TRIGGER soheadTriggerAfter
  AFTER UPDATE
  ON cohead
  FOR EACH ROW
  EXECUTE PROCEDURE _soheadTriggerAfter();

CREATE OR REPLACE FUNCTION _coheadBeforeDeleteTrigger() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE

BEGIN

  IF ( (NOT checkPrivilege('MaintainSalesOrders')) AND
       (NOT checkPrivilege('IssueStockToShipping')) ) THEN
    RAISE EXCEPTION 'You do not have privileges to alter a Sales Order.';
  END IF;

  DELETE FROM docass WHERE docass_source_id = OLD.cohead_id AND docass_source_type = 'S';
  DELETE FROM docass WHERE docass_target_id = OLD.cohead_id AND docass_target_type = 'S';

  DELETE FROM comment
  WHERE ( (comment_source='S')
   AND (comment_source_id=OLD.cohead_id) );

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'coheadBeforeDeleteTrigger');
CREATE TRIGGER coheadBeforeDeleteTrigger
  BEFORE DELETE
  ON cohead
  FOR EACH ROW
  EXECUTE PROCEDURE _coheadBeforeDeleteTrigger();

CREATE OR REPLACE FUNCTION _coheadAfterDeleteTrigger() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
_recurid     INTEGER;
_newparentid INTEGER;

BEGIN

  DELETE FROM charass
  WHERE charass_target_type = 'SO'
    AND charass_target_id = OLD.cohead_id;

  DELETE FROM taxhead
   WHERE taxhead_doc_type = 'S'
     AND taxhead_doc_id = OLD.cohead_id;

  --recurrence cleanup
  SELECT recur_id INTO _recurid
    FROM recur
   WHERE recur_parent_id = OLD.cohead_id
     AND recur_parent_type = 'S';
  IF (_recurid IS NOT NULL) THEN -- The deleted SO is the parent of a recurrence series
    SELECT cohead_id INTO _newparentid
      FROM cohead
     WHERE cohead_recurring_cohead_id = OLD.cohead_id
       AND cohead_id != OLD.cohead_id 
     ORDER BY cohead_packdate
     LIMIT 1; -- Find the next recurring SO whose parent is the deleted SO
    IF (_newparentid IS NULL) THEN -- The deleted SO is the only SO in the series
      DELETE FROM recur WHERE recur_id = _recurid;
    ELSE
      UPDATE recur SET recur_parent_id = _newparentid
       WHERE recur_id = _recurid;

      UPDATE cohead SET cohead_recurring_cohead_id = _newparentid
       WHERE cohead_recurring_cohead_id = OLD.cohead_id
         AND cohead_id != OLD.cohead_id;
    END IF;
  END IF;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'coheadAfterDeleteTrigger');
CREATE TRIGGER coheadAfterDeleteTrigger
  AFTER DELETE
  ON cohead
  FOR EACH ROW
  EXECUTE PROCEDURE _coheadAfterDeleteTrigger();
