CREATE TABLE "TEST_VSTSRedgate".dmrs_domain_check_constraints (
  domain_id VARCHAR2(70 BYTE) NOT NULL,
  domain_ovid VARCHAR2(36 BYTE) NOT NULL,
  "SEQUENCE" NUMBER NOT NULL,
  "TEXT" VARCHAR2(4000 BYTE) NOT NULL,
  database_type VARCHAR2(60 BYTE) NOT NULL,
  domain_name VARCHAR2(256 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);