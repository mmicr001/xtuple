drop function if exists createFile(TEXT, TEXT, BYTEA) cascade;

create or replace function createFile(pTitle TEXT, pDescription TEXT, pStream BYTEA, pMimeType TEXT DEFAULT NULL) returns integer as $$
declare
begin
  insert into file ( file_title, file_descrip, file_stream, file_mime_type) values ( pTitle, pDescription, pStream, COALESCE(pMimeType, 'application/octet-stream'));
  return currval('file_file_id_seq');
end;
$$ language 'plpgsql';
