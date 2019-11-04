CREATE TABLE "TEST_VSTSRedgate".dmrs_rdbms_sites (
  site_name VARCHAR2(256 BYTE) NOT NULL,
  site_id VARCHAR2(70 BYTE),
  site_ovid VARCHAR2(36 BYTE),
  rdbms_type NUMBER NOT NULL,
  design_ovid VARCHAR2(36 BYTE)
);