CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".mgv_all_index_details (objtype,objname,objid,mainobjtype,mainobjname,mainobjid,schemaname,schemaid,catalogname,catalogid,connname,connid,projectname,projectid,capturedorconverted,qualifiedname) AS
SELECT 'MD_INDEXES' objtype,i.index_name objname, i.Id objid,  'MD_TABLES' MainObjType,t.table_name MAINOBJNAME,t.id MAINOBJID, s.name SchemaName, s.id schemaid, cat.catalog_name catalogname,cat.id catalogid, conn.name connname,conn.id  connid, proj.project_name projectname,proj.id projectid,
NVL(conn.type,'CAPTURED') CapturedOrConverted, 
CASE WHEN conn.type IS NULL THEN cat.catalog_name||'.' ELSE '' END || s.name||'.'||i.index_name  QualifiedName
FROM MD_INDEXES i, MD_TABLES t,MD_SCHEMAS s, MD_CATALOGS cat,MD_CONNECTIONS conn,MD_PROJECTS proj
WHERE i.table_id_fk = t.id
AND t.schema_id_fk = s.id
AND s.catalog_id_fk = cat.id
AND cat.connection_id_fk = conn.id
AND conn.PROJECT_ID_FK = proj.id;