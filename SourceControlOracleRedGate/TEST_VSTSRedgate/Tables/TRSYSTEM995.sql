CREATE TABLE "TEST_VSTSRedgate".trsystem995 (
  einf_entity_name VARCHAR2(30 BYTE) NOT NULL,
  einf_entity_prefix VARCHAR2(4 BYTE) NOT NULL,
  einf_company_field VARCHAR2(30 BYTE),
  einf_location_field VARCHAR2(30 BYTE),
  einf_status_field VARCHAR2(30 BYTE),
  einf_entity_list VARCHAR2(256 BYTE),
  einf_sql_condition VARCHAR2(4000 BYTE),
  einf_viewsql_condition VARCHAR2(1000 BYTE),
  einf_editsql_condition VARCHAR2(1000 BYTE),
  einf_confirmsql_condition VARCHAR2(1000 BYTE),
  einf_deletesql_condition VARCHAR2(1000 BYTE),
  einf_user_group NUMBER(8) NOT NULL,
  einf_document_storage NUMBER(8),
  einf_user_id VARCHAR2(50 BYTE) NOT NULL,
  CONSTRAINT trsystem995_pk PRIMARY KEY (einf_entity_name,einf_user_group,einf_user_id)
);