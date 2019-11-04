CREATE TABLE "TEST_VSTSRedgate".dmrs_spatial_column_definition (
  table_id VARCHAR2(70 BYTE) NOT NULL,
  table_ovid VARCHAR2(36 BYTE) NOT NULL,
  definition_id VARCHAR2(70 BYTE) NOT NULL,
  definition_ovid VARCHAR2(36 BYTE) NOT NULL,
  definition_name VARCHAR2(256 BYTE) NOT NULL,
  table_name VARCHAR2(256 BYTE) NOT NULL,
  column_id VARCHAR2(70 BYTE),
  column_ovid VARCHAR2(36 BYTE),
  column_name VARCHAR2(256 BYTE),
  use_function CHAR NOT NULL,
  function_expression VARCHAR2(4000 BYTE),
  coordinate_system_id VARCHAR2(70 BYTE),
  has_spatial_index CHAR NOT NULL,
  spatial_index_id VARCHAR2(70 BYTE),
  spatial_index_ovid VARCHAR2(36 BYTE),
  spatial_index_name VARCHAR2(256 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);