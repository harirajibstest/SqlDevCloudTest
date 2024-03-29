CREATE TABLE "TEST_VSTSRedgate".dmrs_indexes (
  index_name VARCHAR2(256 BYTE) NOT NULL,
  object_id VARCHAR2(70 BYTE) NOT NULL,
  ovid VARCHAR2(36 BYTE) NOT NULL,
  import_id VARCHAR2(70 BYTE),
  container_id VARCHAR2(70 BYTE) NOT NULL,
  container_ovid VARCHAR2(36 BYTE) NOT NULL,
  "STATE" VARCHAR2(20 BYTE) NOT NULL,
  functional CHAR,
  expression VARCHAR2(4000 BYTE),
  engineer CHAR NOT NULL,
  table_name VARCHAR2(256 BYTE) NOT NULL,
  spatial_index CHAR,
  spatial_layer_type VARCHAR2(15 BYTE),
  geodetic_index CHAR,
  number_of_dimensions NUMBER DEFAULT 2,
  schema_ovid VARCHAR2(36 BYTE),
  schema_name VARCHAR2(256 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);