CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".mgv_all_views (project_id,project_name,connection_id,host,port,username,catalog_id,catalog_name,dummy_flag,schema_id,schema_name,view_id,view_name) AS
SELECT md_projects.id project_id ,
    md_projects.project_name project_name,
    md_connections.id connection_id ,
    md_connections.host host ,
    md_connections.port port ,
    username username ,
    md_catalogs.id catalog_id ,
    md_catalogs.catalog_name catalog_name,
    md_catalogs.dummy_flag dummy_flag ,
    md_schemas.id schema_id ,
    md_schemas.name schema_name ,
    md_views.id view_id ,
    md_views.view_name view_name
  FROM md_projects ,
    md_connections,
    md_catalogs ,
    md_schemas ,
    md_views
  WHERE md_views.schema_id_fk      = md_schemas.id
  AND md_schemas.catalog_id_fk     = md_catalogs.id
  AND md_catalogs.connection_id_fk = md_connections.id
  AND md_connections.project_id_fk = md_projects.id
WITH READ ONLY;
COMMENT ON TABLE "TEST_VSTSRedgate".mgv_all_views IS 'View to iterate over all views in the system';