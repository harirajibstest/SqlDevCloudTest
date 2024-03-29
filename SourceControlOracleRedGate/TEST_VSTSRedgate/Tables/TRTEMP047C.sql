CREATE TABLE "TEST_VSTSRedgate".trtemp047c (
  tdst_company_code NUMBER(8),
  tdst_location_code NUMBER(8),
  tdst_counter_party NUMBER(8),
  tdst_currency_code NUMBER(8),
  tdst_scheme_code NUMBER(8),
  tdst_fd_number VARCHAR2(25 BYTE),
  tdst_fd_srnumber NUMBER(4),
  tdst_deducted_date DATE,
  tdst_fdopen_date DATE,
  tdst_principal_amt NUMBER(15,2),
  tdst_int_amount NUMBER(15,2),
  tdst_tds_amount NUMBER(15,2),
  tdst_sercharge_amount NUMBER(15,2),
  tdst_transaction_type NUMBER(8),
  tdst_financial_year VARCHAR2(9 BYTE),
  tdst_add_date DATE,
  tdst_entry_detail XMLTYPE,
  tdst_record_status NUMBER(8),
  tdst_tds_adjustment NUMBER(15,2),
  tdst_create_date DATE
);