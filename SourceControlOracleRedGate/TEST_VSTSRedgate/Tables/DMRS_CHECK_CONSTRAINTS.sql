CREATE TABLE "TEST_VSTSRedgate".dmrs_check_constraints (
  dataelement_id VARCHAR2(70 BYTE) NOT NULL,
  dataelement_ovid VARCHAR2(36 BYTE) NOT NULL,
  "TYPE" VARCHAR2(10 BYTE),
  "SEQUENCE" NUMBER NOT NULL,
  constraint_name VARCHAR2(256 BYTE),
  "TEXT" VARCHAR2(4000 BYTE) NOT NULL,
  database_type VARCHAR2(60 BYTE) NOT NULL,
  container_id VARCHAR2(70 BYTE) NOT NULL,
  container_ovid VARCHAR2(36 BYTE) NOT NULL,
  container_name VARCHAR2(256 BYTE) NOT NULL,
  dataelement_name VARCHAR2(256 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);