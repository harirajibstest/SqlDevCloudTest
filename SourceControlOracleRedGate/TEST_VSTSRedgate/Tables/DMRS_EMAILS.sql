CREATE TABLE "TEST_VSTSRedgate".dmrs_emails (
  email_id VARCHAR2(70 BYTE) NOT NULL,
  email_ovid VARCHAR2(36 BYTE) NOT NULL,
  email_name VARCHAR2(256 BYTE) NOT NULL,
  business_info_id VARCHAR2(70 BYTE) NOT NULL,
  business_info_ovid VARCHAR2(36 BYTE) NOT NULL,
  business_info_name VARCHAR2(256 BYTE) NOT NULL,
  email_address VARCHAR2(2000 BYTE),
  email_type VARCHAR2(1000 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);