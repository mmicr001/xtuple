drop function if exists createFile(TEXT, TEXT, BYTEA) cascade;

create or replace function createFile(pTitle TEXT, pDescription TEXT, pStream BYTEA, pMimeType TEXT DEFAULT NULL) returns integer as $$
declare
  _id integer;
  pDefault text;
begin
  select column_default 
    into pDefault 
      FROM INFORMATION_SCHEMA.COLUMNS 
    where table_name = 'file' 
      and column_name='file_id';

  if pDefault like '%file_id%'
    then _id := nextval('file_file_id_seq');
  elsif(pDefault like '%url_id%') 
    then _id := nextval('urlinfo_url_id_seq');
  end if;   
  
  insert into file (file_id, file_title, file_descrip, file_stream, file_mime_type) values (_id, pTitle, pDescription, pStream, COALESCE(pMimeType, 'application/octet-stream'));
  return _id;
end;
$$ language 'plpgsql';
