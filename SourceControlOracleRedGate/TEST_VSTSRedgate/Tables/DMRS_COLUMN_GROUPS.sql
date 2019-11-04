CREATE TABLE "TEST_VSTSRedgate".dmrs_column_groups (
  table_id VARCHAR2(70 BYTE) NOT NULL,
  table_ovid VARCHAR2(36 BYTE) NOT NULL,
  "SEQUENCE" NUMBER NOT NULL,
  columngroup_id VARCHAR2(70 BYTE) NOT NULL,
  columngroup_ovid VARCHAR2(36 BYTE) NOT NULL,
  columngroup_name VARCHAR2(256 BYTE) NOT NULL,
  "COLUMNS" VARCHAR2(4000 BYTE),
  notes VARCHAR2(4000 BYTE),
  table_name VARCHAR2(256 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);