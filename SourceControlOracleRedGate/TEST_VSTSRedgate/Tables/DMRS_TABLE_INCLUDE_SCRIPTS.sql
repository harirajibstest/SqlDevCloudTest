CREATE TABLE "TEST_VSTSRedgate".dmrs_table_include_scripts (
  table_id VARCHAR2(70 BYTE) NOT NULL,
  table_ovid VARCHAR2(36 BYTE) NOT NULL,
  table_name VARCHAR2(256 BYTE),
  "TYPE" VARCHAR2(15 BYTE),
  "SEQUENCE" NUMBER NOT NULL,
  "TEXT" VARCHAR2(4000 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);