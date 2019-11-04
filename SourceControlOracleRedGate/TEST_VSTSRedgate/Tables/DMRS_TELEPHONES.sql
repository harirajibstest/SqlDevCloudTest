CREATE TABLE "TEST_VSTSRedgate".dmrs_telephones (
  telephone_id VARCHAR2(70 BYTE) NOT NULL,
  telephone_ovid VARCHAR2(36 BYTE) NOT NULL,
  telephone_name VARCHAR2(256 BYTE) NOT NULL,
  business_info_id VARCHAR2(70 BYTE) NOT NULL,
  business_info_ovid VARCHAR2(36 BYTE) NOT NULL,
  business_info_name VARCHAR2(256 BYTE) NOT NULL,
  phone_number VARCHAR2(1000 BYTE),
  phone_type VARCHAR2(1000 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);