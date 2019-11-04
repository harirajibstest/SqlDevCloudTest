CREATE TABLE "TEST_VSTSRedgate".dmrs_locations (
  location_id VARCHAR2(70 BYTE) NOT NULL,
  location_ovid VARCHAR2(36 BYTE) NOT NULL,
  location_name VARCHAR2(256 BYTE) NOT NULL,
  business_info_id VARCHAR2(70 BYTE) NOT NULL,
  business_info_ovid VARCHAR2(36 BYTE) NOT NULL,
  business_info_name VARCHAR2(256 BYTE) NOT NULL,
  loc_address VARCHAR2(1000 BYTE),
  loc_city VARCHAR2(1000 BYTE),
  loc_post_code VARCHAR2(1000 BYTE),
  loc_area VARCHAR2(1000 BYTE),
  loc_country VARCHAR2(1000 BYTE),
  loc_type VARCHAR2(1000 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);