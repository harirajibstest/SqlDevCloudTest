CREATE TABLE "TEST_VSTSRedgate".dmrs_process_attributes (
  process_id VARCHAR2(70 BYTE) NOT NULL,
  process_ovid VARCHAR2(36 BYTE) NOT NULL,
  entity_id VARCHAR2(70 BYTE) NOT NULL,
  entity_ovid VARCHAR2(36 BYTE) NOT NULL,
  flow_id VARCHAR2(70 BYTE) NOT NULL,
  flow_ovid VARCHAR2(36 BYTE) NOT NULL,
  dfd_id VARCHAR2(70 BYTE) NOT NULL,
  dfd_ovid VARCHAR2(36 BYTE) NOT NULL,
  process_name VARCHAR2(256 BYTE) NOT NULL,
  entity_name VARCHAR2(256 BYTE) NOT NULL,
  flow_name VARCHAR2(256 BYTE) NOT NULL,
  dfd_name VARCHAR2(256 BYTE) NOT NULL,
  op_read CHAR,
  op_create CHAR,
  op_update CHAR,
  op_delete CHAR,
  crud_code VARCHAR2(4 BYTE),
  flow_direction VARCHAR2(3 BYTE) NOT NULL,
  attribute_id VARCHAR2(70 BYTE) NOT NULL,
  attribute_ovid VARCHAR2(36 BYTE) NOT NULL,
  attribute_name VARCHAR2(256 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);