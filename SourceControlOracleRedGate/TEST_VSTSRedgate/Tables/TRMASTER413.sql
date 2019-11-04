CREATE TABLE "TEST_VSTSRedgate".trmaster413 (
  norm_company_code NUMBER(8) NOT NULL,
  norm_location_code NUMBER(8) NOT NULL,
  norm_effective_date DATE NOT NULL,
  norm_investment_type NUMBER(8) NOT NULL,
  norm_column_heading VARCHAR2(50 BYTE) NOT NULL,
  norm_column_subheading VARCHAR2(50 BYTE) NOT NULL,
  norm_type_code VARCHAR2(50 BYTE),
  norm_category_code VARCHAR2(20 BYTE),
  norm_limit_minrange NUMBER(15,2),
  norm_limit_maxrange NUMBER(15,2),
  norm_rating_code NUMBER(8),
  norm_above_below NUMBER(8),
  norm_record_status NUMBER(8),
  norm_add_date DATE
);