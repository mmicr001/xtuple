create or replace function createUrl(text, text) returns integer as $$
declare
  pTitle ALIAS FOR $1;
  pUrl ALIAS FOR $2;
begin
  insert into urlinfo ( url_title, url_url) values ( pTitle, pUrl);
  return currval('file_file_id_seq');
end;
$$ language 'plpgsql';
