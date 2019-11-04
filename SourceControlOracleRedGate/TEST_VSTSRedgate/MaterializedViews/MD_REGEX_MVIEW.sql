CREATE MATERIALIZED VIEW "TEST_VSTSRedgate".md_regex_mview (project_name,project_id,connection_id,connection_name,catalog_id,catalog_name,schema_id,schema_name,program_id,program_name,item,"VALUE")
ORGANIZATION HEAP 
AS SELECT  pr.PROJECT_NAME, pr.ID "PROJECT_ID", c.ID "CONNECTION_ID", c.NAME "CONNECTION_NAME", mc.ID "CATALOG_ID",
        mc.CATALOG_NAME,s.id "SCHEMA_ID",s.NAME "SCHEMA_NAME", p.ID "PROGRAM_ID", p.name "PROGRAM_NAME",
        rg.DESCRIPTION "ITEM", regexp_count(p.native_sql,rg.REGEX,1,'ix') "VALUE"
FROM MD_STORED_PROGRAMS p,
  md_projects pr,
  md_connections c,
  md_schemas s,
  MD_CATALOGS mc,
  MD_CODE_REGEX rg
WHERE c.TYPE          IS NULL --Shows captured
AND mc.CONNECTION_ID_FK=c.id
AND mc.id              =s.CATALOG_ID_FK
AND pr.PROJECT_NAME LIKE 'SS%'
and pr.id=c.PROJECT_ID_FK
and p.SCHEMA_ID_FK=s.ID
and regexp_count(p.native_sql,rg.REGEX,1,'ix')>0;