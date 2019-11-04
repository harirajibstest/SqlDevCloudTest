CREATE TABLE "TEST_VSTSRedgate".trsystem060 (
  stre_reference_number VARCHAR2(25 BYTE),
  stre_company_code VARCHAR2(1000 BYTE) NOT NULL,
  stre_location_code VARCHAR2(1000 BYTE),
  stre_reference_date DATE,
  stre_product_category VARCHAR2(1000 BYTE),
  stre_subproduct_code VARCHAR2(1000 BYTE),
  stre_stress_type NUMBER(8) NOT NULL,
  stre_change_type NUMBER(8) NOT NULL,
  stre_price_type NUMBER(8) NOT NULL,
  stre_start_date DATE,
  stre_end_date DATE,
  stre_created_date DATE,
  stre_add_date DATE,
  stre_entry_details XMLTYPE,
  stre_record_status NUMBER(8) NOT NULL,
  stre_deal_type NUMBER(8),
  stre_user_reference VARCHAR2(50 BYTE)
);