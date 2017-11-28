DROP VIEW IF EXISTS docinfo;
DROP FUNCTION IF EXISTS _docinfo(INTEGER, TEXT);
CREATE OR REPLACE FUNCTION _docinfo(pRefId INTEGER, pRefType TEXT, pRecursive BOOLEAN = false)
  RETURNS SETOF _docinfo AS
$$
DECLARE
  _crmacct      JSON;
  _id           INTEGER;
  _column       TEXT;
  _row          _docinfo%ROWTYPE;
  _target       RECORD;
BEGIN

  -- Unify images, urls, and documents into one "view" for the given reference item
  FOR _row IN

    SELECT imageass_id            AS doc_id,
           image_id::text         AS doc_target_number,
           'IMG'                  AS doc_target_type,
           imageass_image_id      AS doc_target_id,
           imageass_source        AS doc_source_type,
           imageass_source_id     AS doc_source_id,
           image_name             AS doc_name,
           image_descrip          AS doc_descrip,
           imageass_purpose::text AS doc_purpose
      FROM imageass
      JOIN image ON image_id = imageass_image_id
     WHERE imageass_source_id = pRefId
       AND imageass_source = pRefType

    UNION
    SELECT url_id                 AS doc_id,
           url_id::text           AS doc_target_number,
           CASE WHEN url_stream IS NULL
                THEN 'URL'
                ELSE 'FILE'
           END                    AS doc_target_type,
           url_id                 AS doc_target_id,
           url_source             AS doc_source_type,
           url_source_id          AS doc_source_id,
           url_title              AS doc_name,
           url_url                AS doc_descrip,
           'S'::text              AS doc_purpose
      FROM url
     WHERE url_source_id = pRefId
       AND url_source = pRefType

  LOOP
    RETURN NEXT _row;
  END LOOP;

  FOR _target IN SELECT docass_id,        docass_purpose,
                        docass_target_id, docass_target_type,
                        source_id
                   FROM docass
                   JOIN source         ON docass_target_type = source_docass
                   JOIN pg_class c     ON source_table = relname
                   JOIN pg_namespace n ON relnamespace = n.oid
                   JOIN regexp_split_to_table(buildSearchPath(), E',\\s*') sp ON nspname = sp
                  WHERE relkind = 'r'
                    AND docass_source_id = pRefId
                    AND docass_source_type = pRefType

           UNION SELECT docass_id,        docass_purpose,
                        docass_source_id, docass_source_type,
                        source_id
                   FROM docass
                   JOIN source         ON docass_source_type = source_docass
                   JOIN pg_class c     ON source_table = relname
                   JOIN pg_namespace n ON relnamespace = n.oid
                   JOIN regexp_split_to_table(buildSearchPath(), E',\\s*') sp ON nspname = sp
                  WHERE relkind = 'r'
                    AND docass_target_id = pRefId
                    AND docass_target_type = pRefType

  LOOP

    FOR _row IN SELECT _target.docass_id,
                       target_doc_number,
                       _target.docass_target_type,
                       _target.docass_target_id,
                       pRefType,
                       pRefId,
                       target_doc_name,
                       target_doc_descrip,
                       _target.docass_purpose
                  FROM _getTargetDocument(_target.docass_id, _target.source_id, pRefId)
     LOOP
       RETURN NEXT _row;
    END LOOP;

  END LOOP;

  IF NOT pRecursive THEN
    -- get child document associations for CRM Account records
    IF pRefType = 'CRMA' THEN
      _crmacct := crmaccttypes(pRefId);

      IF _crmacct#>>'{customer}' IS NOT NULL THEN
        FOR _row IN SELECT * FROM _docinfo((_crmacct#>>'{customer}')::INTEGER, 'C', TRUE) LOOP
          RETURN NEXT _row;
        END LOOP;
      END IF;
      IF _crmacct#>>'{prospect}' IS NOT NULL THEN
        FOR _row IN SELECT * FROM _docinfo((_crmacct#>>'{prospect}')::INTEGER, 'PSPCT', TRUE) LOOP
          RETURN NEXT _row;
        END LOOP;
      END IF;
      IF _crmacct#>>'{vendor}' IS NOT NULL THEN
        FOR _row IN SELECT * FROM _docinfo((_crmacct#>>'{vendor}')::INTEGER, 'V', TRUE) LOOP
          RETURN NEXT _row;
        END LOOP;
      END IF;
      IF _crmacct#>>'{taxauth}' IS NOT NULL THEN
        FOR _row IN SELECT * FROM _docinfo((_crmacct#>>'{taxauth}')::INTEGER, 'TAXAUTH', TRUE) LOOP
          RETURN NEXT _row;
        END LOOP;
      END IF;
      IF _crmacct#>>'{employee}' IS NOT NULL THEN
        FOR _row IN SELECT * FROM _docinfo((_crmacct#>>'{employee}')::INTEGER, 'EMP', TRUE) LOOP
          RETURN NEXT _row;
        END LOOP;
      END IF;
      IF _crmacct#>>'{salesrep}' IS NOT NULL THEN
        FOR _row IN SELECT * FROM _docinfo((_crmacct_crmacct#>>'{salesrep}')::INTEGER, 'SR', TRUE) LOOP
          RETURN NEXT _row;
        END LOOP;
      END IF;
    END IF;

    -- get CRM Account document associations for child records
    _id := CASE pRefType WHEN 'C'       THEN (_crmacct#>>'{customer}')::INTEGER
                         WHEN 'PSPCT'   THEN (_crmacct#>>'{prospect}')::INTEGER
                         WHEN 'V'       THEN (_crmacct#>>'{vendor}')::INTEGER
                         WHEN 'TAXAUTH' THEN (_crmacct#>>'{taxauth}')::INTEGER
                         WHEN 'EMP'     THEN (_crmacct#>>'{employee}')::INTEGER
                         WHEN 'SR'      THEN (_crmacct#>>'{salesrep}')::INTEGER
               END;
    IF _id IS NOT NULL THEN
      FOR _row IN SELECT * FROM _docinfo(_id, 'CRMA', TRUE) LOOP
        RETURN NEXT _row;
      END LOOP;
    END IF;
  END IF;

  END;
$$ LANGUAGE plpgsql;

