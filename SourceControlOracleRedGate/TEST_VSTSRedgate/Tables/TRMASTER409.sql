CREATE TABLE "TEST_VSTSRedgate".trmaster409 (
  prec_company_code NUMBER(8),
  prec_location_code NUMBER(8),
  prec_counter_party NUMBER(8),
  prec_currency_code NUMBER(8),
  prec_fd_number VARCHAR2(25 BYTE),
  prec_fd_srno NUMBER(3),
  prec_value_date DATE,
  prec_period_in NUMBER(8),
  prec_mat_date DATE,
  prec_int_rate NUMBER(8,4),
  prec_user_remarks VARCHAR2(200 BYTE),
  prec_entry_detail XMLTYPE,
  prec_create_date DATE,
  prec_add_date DATE,
  prec_record_status NUMBER(8),
  prec_period_upto NUMBER(5,2)
);