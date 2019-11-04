CREATE TABLE "TEST_VSTSRedgate".dmrs_source_info (
  source_info_ovid VARCHAR2(36 BYTE) NOT NULL,
  source_info_type CHAR NOT NULL,
  ddl_file_name VARCHAR2(256 BYTE),
  ddl_path_name VARCHAR2(2000 BYTE),
  ddl_db_type VARCHAR2(30 BYTE),
  datadict_connection_name VARCHAR2(256 BYTE),
  datadict_connection_url VARCHAR2(2000 BYTE),
  datadict_db_type VARCHAR2(30 BYTE),
  model_id VARCHAR2(70 BYTE) NOT NULL,
  model_ovid VARCHAR2(36 BYTE) NOT NULL,
  model_name VARCHAR2(256 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);