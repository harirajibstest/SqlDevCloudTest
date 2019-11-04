CREATE TABLE "TEST_VSTSRedgate".dmrs_mappings (
  logical_model_id VARCHAR2(70 BYTE) NOT NULL,
  logical_model_ovid VARCHAR2(36 BYTE) NOT NULL,
  logical_model_name VARCHAR2(256 BYTE) NOT NULL,
  logical_object_id VARCHAR2(80 BYTE) NOT NULL,
  logical_object_ovid VARCHAR2(36 BYTE) NOT NULL,
  logical_object_name VARCHAR2(256 BYTE) NOT NULL,
  logical_object_type VARCHAR2(30 BYTE),
  relational_model_id VARCHAR2(70 BYTE) NOT NULL,
  relational_model_ovid VARCHAR2(36 BYTE) NOT NULL,
  relational_model_name VARCHAR2(256 BYTE) NOT NULL,
  relational_object_id VARCHAR2(70 BYTE) NOT NULL,
  relational_object_ovid VARCHAR2(36 BYTE) NOT NULL,
  relational_object_name VARCHAR2(256 BYTE) NOT NULL,
  relational_object_type VARCHAR2(30 BYTE),
  entity_id VARCHAR2(70 BYTE),
  entity_ovid VARCHAR2(36 BYTE),
  entity_name VARCHAR2(256 BYTE),
  table_id VARCHAR2(70 BYTE),
  table_ovid VARCHAR2(36 BYTE),
  table_name VARCHAR2(256 BYTE),
  design_id VARCHAR2(70 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL,
  design_name VARCHAR2(256 BYTE) NOT NULL
);