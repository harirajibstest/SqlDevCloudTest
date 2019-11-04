CREATE TABLE "TEST_VSTSRedgate".dmrs_view_order_groupby (
  view_ovid VARCHAR2(36 BYTE) NOT NULL,
  view_id VARCHAR2(70 BYTE) NOT NULL,
  view_name VARCHAR2(256 BYTE) NOT NULL,
  container_id VARCHAR2(70 BYTE) NOT NULL,
  container_ovid VARCHAR2(36 BYTE) NOT NULL,
  container_name VARCHAR2(256 BYTE) NOT NULL,
  container_alias VARCHAR2(256 BYTE),
  is_expression CHAR,
  "USAGE" CHAR,
  "SEQUENCE" NUMBER(3) NOT NULL,
  column_id VARCHAR2(70 BYTE),
  column_ovid VARCHAR2(36 BYTE),
  column_name VARCHAR2(256 BYTE),
  column_alias VARCHAR2(256 BYTE),
  sort_order VARCHAR2(4 BYTE),
  expression VARCHAR2(2000 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);