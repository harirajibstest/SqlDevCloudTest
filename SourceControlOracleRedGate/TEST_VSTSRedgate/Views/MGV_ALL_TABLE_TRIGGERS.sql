CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".mgv_all_table_triggers (project_id,project_name,connection_id,host,port,username,catalog_id,catalog_name,dummy_flag,schema_id,schema_name,table_id,table_name,trigger_id,trigger_name) AS
SELECT md_projects.id project_id ,
    md_projects.project_name project_name,
    md_connections.id connection_id ,
    md_connections.host host ,
    md_connections.port port ,
    md_connections.username username ,
    md_catalogs.id catalog_id ,
    md_catalogs.catalog_name catalog_name,
    md_catalogs.dummy_flag dummy_flag ,
    md_schemas.id schema_id ,
    md_schemas.name schema_name ,
    md_tables.id table_id ,
    md_tables.TABLE_NAME TABLE_NAME ,
    md_triggers.id trigger_id ,
    md_triggers.trigger_name trigger_name
  FROM md_projects ,
    md_connections,
    md_catalogs ,
    md_schemas ,
    md_tables ,
    md_triggers
  WHERE md_triggers.table_or_view_id_fk = md_tables.id
  AND md_tables.schema_id_fk            = md_schemas.id
  AND md_schemas.catalog_id_fk          = md_catalogs.id
  AND md_catalogs.connection_id_fk      = md_connections.id
  AND md_connections.project_id_fk      = md_projects.id;