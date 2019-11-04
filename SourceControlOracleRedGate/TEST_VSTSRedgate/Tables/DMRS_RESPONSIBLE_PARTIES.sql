CREATE TABLE "TEST_VSTSRedgate".dmrs_responsible_parties (
  responsible_party_id VARCHAR2(70 BYTE) NOT NULL,
  responsible_party_ovid VARCHAR2(36 BYTE) NOT NULL,
  responsible_party_name VARCHAR2(256 BYTE) NOT NULL,
  business_info_id VARCHAR2(70 BYTE) NOT NULL,
  business_info_ovid VARCHAR2(36 BYTE) NOT NULL,
  business_info_name VARCHAR2(256 BYTE) NOT NULL,
  parent_id VARCHAR2(70 BYTE),
  parent_ovid VARCHAR2(36 BYTE),
  parent_name VARCHAR2(256 BYTE),
  responsibility VARCHAR2(2000 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);