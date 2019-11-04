CREATE TABLE "TEST_VSTSRedgate".dmrs_resource_locators (
  resource_locator_id VARCHAR2(70 BYTE) NOT NULL,
  resource_locator_ovid VARCHAR2(36 BYTE) NOT NULL,
  resource_locator_name VARCHAR2(256 BYTE) NOT NULL,
  business_info_id VARCHAR2(70 BYTE) NOT NULL,
  business_info_ovid VARCHAR2(36 BYTE) NOT NULL,
  business_info_name VARCHAR2(256 BYTE) NOT NULL,
  url VARCHAR2(2000 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);