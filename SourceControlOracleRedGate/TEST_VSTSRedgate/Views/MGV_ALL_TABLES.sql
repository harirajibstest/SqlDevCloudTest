CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".mgv_all_tables (project_id,project_name,connection_id,host,port,username,dburl,catalog_id,catalog_name,schema_id,schema_name,table_id,table_name) AS
SELECT md_projects.id project_id ,
    md_projects.project_name project_name,
    md_connections.id connection_id ,
    md_connections.host host ,
    md_connections.port port ,
    md_connections.username username ,
    md_connections.dburl dburl ,
    md_catalogs.id catalog_id ,
    md_catalogs.catalog_name catalog_name,
    md_schemas.id schema_id ,
    md_schemas.name schema_name ,
    md_tables.id table_id ,
    md_tables.TABLE_NAME TABLE_NAME
  FROM md_connections,
    md_catalogs ,
    md_schemas ,
    md_tables ,
    md_projects
  WHERE md_tables.schema_id_fk     = md_schemas.id
  AND md_schemas.catalog_id_fk     = md_catalogs.id
  AND md_catalogs.connection_id_fk = md_connections.id
  AND md_connections.project_id_fk = md_projects.id
WITH READ ONLY;