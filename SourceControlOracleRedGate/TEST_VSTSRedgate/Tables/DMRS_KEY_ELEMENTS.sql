CREATE TABLE "TEST_VSTSRedgate".dmrs_key_elements (
  key_id VARCHAR2(80 BYTE) NOT NULL,
  key_ovid VARCHAR2(36 BYTE) NOT NULL,
  "TYPE" CHAR,
  element_id VARCHAR2(80 BYTE) NOT NULL,
  element_ovid VARCHAR2(36 BYTE) NOT NULL,
  element_name VARCHAR2(256 BYTE) NOT NULL,
  "SEQUENCE" NUMBER,
  source_label VARCHAR2(100 BYTE),
  target_label VARCHAR2(100 BYTE),
  entity_id VARCHAR2(70 BYTE) NOT NULL,
  key_name VARCHAR2(256 BYTE) NOT NULL,
  entity_ovid VARCHAR2(36 BYTE) NOT NULL,
  entity_name VARCHAR2(256 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);