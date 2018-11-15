create or replace function createUrl(text, text) returns integer as $$
declare
  pTitle ALIAS FOR $1;
  pUrl ALIAS FOR $2;
  _id integer;
  pDefault text;
begin
  select column_default 
    into pDefault 
      FROM INFORMATION_SCHEMA.COLUMNS 
    where table_name = 'urlinfo' 
      and column_name='url_id';

  if pDefault like '%file_id%'
    then _id := nextval('file_file_id_seq');
  elsif(pDefault like '%url_id%') 
    then _id := nextval('urlinfo_url_id_seq');
  end if;   
  
  insert into urlinfo (url_id, url_title, url_url) values (_id, pTitle, pUrl);
  return _id;
end;
$$ language 'plpgsql';
