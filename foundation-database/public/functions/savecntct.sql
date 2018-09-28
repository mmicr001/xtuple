-- ===================================================================
--Remove the legacy functions
-- ===================================================================
DROP FUNCTION IF EXISTS saveCntct( INTEGER,TEXT,INTEGER,INTEGER,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,BOOL,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT ) CASCADE;
DROP FUNCTION IF EXISTS saveCntct( INTEGER,TEXT,INTEGER,INTEGER,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,BOOL,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT) CASCADE;
DROP FUNCTION IF EXISTS saveCntct( INTEGER,TEXT,INTEGER,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT) CASCADE;
DROP FUNCTION IF EXISTS saveCntct( INTEGER,TEXT,INTEGER,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,BOOL,JSON,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT) CASCADE;
DROP FUNCTION IF EXISTS saveCntct( INTEGER,TEXT,INTEGER,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,BOOL,JSON,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,BOOL) CASCADE;

CREATE OR REPLACE FUNCTION public.savecntct(
    pCntctid integer,
    pContactNumber text,
    pAddrid integer,
    pHonorific text,
    pFirstname text,
    pMiddlename text,
    pLastname text,
    pSuffix text,
    pInitials text,
    pActive boolean,
    pPhone JSON,
    pEmail text,
    pWebaddr text,
    pNotes text,
    pTitle text,
    pFlag text,
    pOwnerUsername text DEFAULT NULL,
    pEmailOptIn boolean DEFAULT fetchmetricbool('DefaultEmailOptIn'),
    pCompany text DEFAULT NULL)
  RETURNS integer AS
$$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _cntctId      INTEGER;
  _cntctNumber  TEXT;
  _isNew        BOOLEAN;
  _flag         TEXT;
  _phones       JSON;
  _contactCount INTEGER := 0;
  _upd          RECORD;
BEGIN
  --Validate
  IF ((pFlag IS NULL) OR (pFlag = '') OR (pFlag = 'CHECK') OR (pFlag = 'CHANGEONE') OR (pFlag = 'CHANGEALL')) THEN
    IF (pFlag='') THEN
      _flag := 'CHECK';
    ELSE
      _flag := COALESCE(pFlag,'CHECK');
    END IF;
  ELSE
	RAISE EXCEPTION 'Invalid Flag (%). Valid flags are CHECK, CHANGEONE or CHANGEALL', pFlag;
  END IF;
  
  --If there is nothing here get out
  IF ( (pCntctId IS NULL OR pCntctId = -1)
	AND (pAddrId IS NULL)
	AND (COALESCE(pFirstName, '') = '')
	AND (COALESCE(pMiddleName, '') = '')
	AND (COALESCE(pLastName, '') = '')
	AND (COALESCE(pSuffix, '') = '')
	AND (COALESCE(pHonorific, '') = '')
	AND (COALESCE(pInitials, '') = '')
	AND (COALESCE(pEmail, '') = '')
	AND (COALESCE(pWebAddr, '') = '')
	AND (COALESCE(pNotes, '') = '')
	AND (COALESCE(pTitle, '') = '') ) THEN
	
	RETURN NULL;

  END IF;
  
  IF (pCntctId IS NULL OR pCntctId = -1) THEN 
    _isNew := true;
    _cntctId := nextval('cntct_cntct_id_seq');
    _cntctNumber := COALESCE(pContactNumber,fetchNextNumber('ContactNumber'));
  ELSE
    SELECT COUNT(cntct_id) INTO _contactCount
      FROM cntct
      WHERE ((cntct_id=pCntctId)
      AND (cntct_first_name=pFirstName)
      AND (cntct_last_name=pLastName));

    -- ask whether new or update if name changes
    -- but only if this isn't a new record with a pre-allocated id
    IF (_contactCount < 1 AND _flag = 'CHECK') THEN
      IF (EXISTS(SELECT cntct_id
                 FROM cntct
                 WHERE (cntct_id=pCntctId))) THEN
        RETURN -10;
      ELSE
        _isNew := true;
        _cntctNumber := fetchNextNumber('ContactNumber');
      END IF;
    ELSIF (_flag = 'CHANGEONE') THEN
      _isNew := true;
      _cntctId := nextval('cntct_cntct_id_seq');
      _cntctNumber := fetchNextNumber('ContactNumber');
    ELSIF (_flag = 'CHANGEALL') THEN
      _isNew := false;
    END IF;
  END IF;

  IF (pContactNumber = '') THEN
    _cntctNumber := fetchNextNumber('ContactNumber');
  ELSE
    _cntctNumber := COALESCE(_cntctNumber,pContactNumber,fetchNextNumber('ContactNumber'));
  END IF;

  _phones = json_extract_path(pphone, 'phones');

  IF (_isNew) THEN
    INSERT INTO cntct (
      cntct_number,
      cntct_addr_id,cntct_first_name, cntct_last_name,
      cntct_companyname,cntct_honorific,cntct_initials,
      cntct_active,cntct_email,cntct_email_optin,cntct_webaddr,
      cntct_notes,cntct_title,cntct_middle,cntct_suffix, cntct_owner_username ) 
    VALUES (
      COALESCE(_cntctNumber,fetchNextNumber('ContactNumber')) ,pAddrId,
      pFirstName,pLastName,pCompany,pHonorific,
      pInitials,COALESCE(pActive,true),
      pEmail,COALESCE(pEmailOptIn,fetchmetricbool('DefaultEmailOptIn'), FALSE),pWebAddr,pNotes,pTitle,pMiddleName,pSuffix,pOwnerUsername )
    RETURNING cntct_id INTO _cntctId;

    -- Now insert the Contact's phone numbers
    INSERT INTO cntctphone (cntctphone_cntct_id,cntctphone_crmrole_id, cntctphone_phone)
      SELECT _cntctId, getcrmroleid(json_array_elements(_phones)->>'role'), 
                       json_array_elements(_phones)->>'number'
    ON CONFLICT DO NOTHING;

    RETURN _cntctId;

  ELSE
    UPDATE cntct SET
      cntct_number=COALESCE(_cntctNumber,fetchNextNumber('ContactNumber')),
      cntct_addr_id=COALESCE(pAddrId,cntct_addr_id),
      cntct_first_name=COALESCE(pFirstName,cntct_first_name),
      cntct_last_name=COALESCE(pLastName,cntct_last_name),
      cntct_companyname=COALESCE(pCompany,cntct_companyname),
      cntct_honorific=COALESCE(pHonorific,cntct_honorific),
      cntct_initials=COALESCE(pInitials,cntct_initials),
      cntct_active=COALESCE(pActive,cntct_active),
      cntct_email=COALESCE(pEmail,cntct_email),
      cntct_email_optin=COALESCE(pEmailOptIn,fetchmetricbool('DefaultEmailOptIn'), FALSE),
      cntct_webaddr=COALESCE(pWebAddr,cntct_webaddr),
      cntct_notes=COALESCE(pNotes,cntct_notes),
      cntct_title=COALESCE(pTitle,cntct_title),
      cntct_middle=COALESCE(pMiddleName,cntct_middle),
      cntct_suffix=COALESCE(pSuffix,cntct_suffix),
      cntct_owner_username=COALESCE(pOwnerUsername, cntct_owner_username) 
    WHERE (cntct_id=pCntctId);

    -- Now insert the Contact's phone numbers
    -- There's no primary key available so we have to delete no longer existing numbers
    -- and insert new ones.
    DELETE FROM cntctphone 
      WHERE cntctphone_cntct_id = pCntctId
        AND cntctphone_phone NOT IN (SELECT json_array_elements(_phones)->>'number');

    INSERT INTO cntctphone (cntctphone_cntct_id,cntctphone_crmrole_id, cntctphone_phone)
      SELECT pCntctId, getcrmroleid(json_array_elements(_phones)->>'role'), 
                       json_array_elements(_phones)->>'number'
    ON CONFLICT DO NOTHING; 
    
    RETURN pCntctId;

  END IF;
END;
$$
  LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION saveCntct( pCntctId         INTEGER,
                                      pContactNumber   TEXT,
                                      pAddrId          INTEGER,
                                      pHonorific       TEXT,
                                      pFirstName       TEXT,
                                      pMiddleName      TEXT,
                                      pLastName        TEXT,
                                      pSuffix          TEXT,
                                      pPhone           JSON,
                                      pEmail           TEXT,
                                      pWebAddr         TEXT,
                                      pTitle           TEXT,
                                      pFlag            TEXT ) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _returnVal INTEGER;

BEGIN
  
  SELECT saveCntct(pCntctId,pContactNumber,pAddrId,pHonorific,pFirstName,pMiddleName,pLastName,pSuffix,NULL,
        NULL,pPhone,pEmail,pWebAddr,NULL,pTitle,pFlag, NULL) INTO _returnVal;
  
  RETURN _returnVal;

END;
$$ LANGUAGE 'plpgsql';
