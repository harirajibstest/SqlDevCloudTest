CREATE TABLE "TEST_VSTSRedgate".trdepo005 (
  tint_company_code NUMBER(8),
  tint_counter_party NUMBER(8),
  tint_currency_code NUMBER(8),
  tint_effective_date DATE,
  tint_period_upto NUMBER(5),
  tint_period_in NUMBER(8),
  tint_from_amount NUMBER(15,2),
  tint_to_amount NUMBER(15,2),
  tint_mat_date DATE,
  tint_record_status NUMBER(8),
  tint_user_remarks VARCHAR2(200 BYTE),
  tint_entry_detail XMLTYPE,
  tint_create_date DATE,
  tint_add_date DATE,
  tint_int_rate NUMBER(8,4),
  tint_negotiated_rate NUMBER(6,2)
);