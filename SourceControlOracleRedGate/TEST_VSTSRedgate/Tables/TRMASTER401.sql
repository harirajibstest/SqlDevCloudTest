CREATE TABLE "TEST_VSTSRedgate".trmaster401 (
  iprm_company_code NUMBER(8) NOT NULL,
  iprm_pick_code NUMBER(8) NOT NULL,
  iprm_short_description VARCHAR2(15 BYTE) NOT NULL,
  iprm_long_description VARCHAR2(50 BYTE) NOT NULL,
  iprm_link_type NUMBER(8) NOT NULL,
  iprm_day_type NUMBER(8) NOT NULL,
  iprm_interest_type NUMBER(8) NOT NULL,
  iprm_interest_period NUMBER(8) NOT NULL,
  iprm_simple_compound NUMBER(8) NOT NULL,
  iprm_overdue_interest NUMBER(8) NOT NULL,
  iprm_create_date DATE NOT NULL,
  iprm_entry_detail XMLTYPE,
  iprm_record_status NUMBER(8) NOT NULL,
  iprm_base_type NUMBER(8) NOT NULL,
  mfsc_source_code VARCHAR2(50 BYTE)
);