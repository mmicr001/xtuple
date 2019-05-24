CREATE or replace FUNCTION createException(pWhsId INTEGER,
                                pOpen boolean,
                                pDate DATE,
                                pLength INTEGER)
  RETURNS int AS
$$
DECLARE
_pId INTEGER := nextval('xtmfg.whsecal_whsecal_id_seq'::regclass);
BEGIN
  INSERT into xtmfg.whsecal(whsecal_id,
                      whsecal_warehous_id,
                      whsecal_effective,
                      whsecal_expires,
                      whsecal_descrip,
                      whsecal_active)
  values(_pId,
         pWhsId,
         pDate,
         pDate + pLength,
         NULL,
         pOpen);
  
  RETURN _pId;
END;
$$ LANGUAGE plpgsql;


CREATE or replace FUNCTION removeException(pId INTEGER)
  RETURNS INTEGER AS
$$
DECLARE

BEGIN
  IF pid = 0 then 
    DELETE FROM xtmfg.whsecal
    WHERE whsecal_id >0;
  ELSE 
    DELETE FROM xtmfg.whsecal
      WHERE whsecal_id = pId; 
  END IF;
  RETURN -1;
END;
$$ LANGUAGE plpgsql;

CREATE or replace FUNCTION createCalendar( eType TEXT)
  RETURNS INTEGER AS
$$
DECLARE
_whsid INTEGER;
_count INTEGER;
BEGIN
  -- create calendar where every day is a work day
  IF eType = 'open' THEN
    INSERT INTO whsinfo( warehous_code,warehous_sitetype_id) values ( eType,5);
    SELECT warehous_id into _whsid
      FROM whsinfo
    WHERE warehous_code = eType;
    
    -- create whsewk entries
    _count := 0;
    WHILE _count<7 LOOP
      INSERT INTO xtmfg.whsewk(whsewk_warehous_id, whsewk_weekday)
        VALUES(_whsid, _count);
      _count := _count + 1;
    END LOOP;

    RETURN _whsid;  
  END IF;

  -- create calendar with 2 non work days 
  IF eType = 'both' THEN
    INSERT INTO whsinfo(warehous_code,warehous_sitetype_id) values (eType,5);
    SELECT warehous_id into _whsid
      FROM whsinfo
    WHERE warehous_code = eType;

    -- create whsewk entries
    _count := 0;
    WHILE _count<5 LOOP
      INSERT INTO xtmfg.whsewk(whsewk_warehous_id, whsewk_weekday)
        VALUES(_whsid, EXTRACT(DOW FROM CURRENT_DATE+_count));
      _count := _count + 1;
    END LOOP;
    
    RETURN _whsid;  
  ELSE
    RAISE EXCEPTION 'Failed to create calendar. Elligible parameters are "open" or "both". ';
  END IF;

  

END;
$$ LANGUAGE plpgsql;

CREATE or replace FUNCTION deleteCalendars()
RETURNS INTEGER AS
$$
BEGIN
  
  DELETE FROM xtmfg.whsewk
    WHERE whsewk_warehous_id in (SELECT warehous_id
                           FROM whsinfo 
                          WHERE warehous_code = 'open' 
                             OR warehous_code='both');

  DELETE FROM xtmfg.whsecal
    WHERE whsecal_warehous_id in (SELECT warehous_id
                           FROM whsinfo 
                          WHERE warehous_code = 'open' 
                             OR warehous_code='both');

  DELETE FROM whsinfo
    WHERE warehous_code = 'open' OR warehous_code='both';

  RETURN -1;
END;
$$ LANGUAGE plpgsql;



CREATE or replace FUNCTION getWhsId()
RETURNS INTEGER AS
$$
DECLARE
_id integer;
BEGIN
  select warehous_id into _id
    from whsinfo
   where warehous_code='open';

  RETURN _id;
END;
$$ LANGUAGE plpgsql;