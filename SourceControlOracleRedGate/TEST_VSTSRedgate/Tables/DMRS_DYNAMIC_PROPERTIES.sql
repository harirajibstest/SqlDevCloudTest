CREATE TABLE "TEST_VSTSRedgate".dmrs_dynamic_properties (
  design_ovid VARCHAR2(36 BYTE),
  object_ovid VARCHAR2(36 BYTE) NOT NULL,
  object_id VARCHAR2(70 BYTE) NOT NULL,
  object_name VARCHAR2(100 BYTE) NOT NULL,
  object_type VARCHAR2(100 BYTE) NOT NULL,
  "NAME" VARCHAR2(256 BYTE),
  "VALUE" VARCHAR2(4000 BYTE)
);