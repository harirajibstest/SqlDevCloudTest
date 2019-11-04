CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewxmlsynonyms (synonym_name,table_name,column_id,column_name,data_type,xml_field) AS
select a.synonym_name, a.table_name, b.column_id, b.column_name, b.data_type,
replace(initcap(replace(replace(substr(b.column_name,5),''),'_', ' ')), ' ','') XML_FIELD
from all_synonyms a, all_tab_columns b
where a.table_name = b.table_name
and a.owner=b.owner
and b.owner = (select user from global_name)
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 ;