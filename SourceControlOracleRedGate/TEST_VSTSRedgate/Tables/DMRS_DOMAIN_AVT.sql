CREATE TABLE "TEST_VSTSRedgate".dmrs_domain_avt (
  domain_id VARCHAR2(70 BYTE) NOT NULL,
  domain_ovid VARCHAR2(36 BYTE) NOT NULL,
  "SEQUENCE" NUMBER NOT NULL,
  "VALUE" VARCHAR2(256 BYTE) NOT NULL,
  short_description VARCHAR2(256 BYTE),
  domain_name VARCHAR2(256 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);