CREATE TABLE "TEST_VSTSRedgate".dmrs_key_attributes (
  key_id VARCHAR2(70 BYTE) NOT NULL,
  key_ovid VARCHAR2(36 BYTE) NOT NULL,
  attribute_id VARCHAR2(70 BYTE) NOT NULL,
  attribute_ovid VARCHAR2(36 BYTE) NOT NULL,
  entity_id VARCHAR2(70 BYTE) NOT NULL,
  entity_ovid VARCHAR2(36 BYTE) NOT NULL,
  key_name VARCHAR2(256 BYTE) NOT NULL,
  entity_name VARCHAR2(256 BYTE) NOT NULL,
  attribute_name VARCHAR2(256 BYTE) NOT NULL,
  "SEQUENCE" NUMBER,
  relationship_id VARCHAR2(100 BYTE),
  relationship_ovid VARCHAR2(36 BYTE),
  relationship_name VARCHAR2(256 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);