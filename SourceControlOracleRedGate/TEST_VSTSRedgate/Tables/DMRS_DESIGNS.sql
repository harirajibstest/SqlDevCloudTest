CREATE TABLE "TEST_VSTSRedgate".dmrs_designs (
  design_id VARCHAR2(70 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL,
  design_name VARCHAR2(256 BYTE) NOT NULL,
  date_published TIMESTAMP,
  published_by VARCHAR2(80 BYTE),
  persistence_version NUMBER(5,2) NOT NULL,
  version_comments VARCHAR2(4000 BYTE)
);