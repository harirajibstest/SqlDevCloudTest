CREATE TABLE "TEST_VSTSRedgate".trtran050c (
  mfmm_source_name VARCHAR2(50 BYTE) NOT NULL,
  mfmm_nav_code VARCHAR2(10 BYTE) NOT NULL,
  mfmm_reference_date DATE NOT NULL,
  mfmm_isindiv_payout VARCHAR2(50 BYTE),
  mfmm_isindiv_reinvestment VARCHAR2(50 BYTE),
  mfmm_scheme_name VARCHAR2(200 BYTE),
  mfmm_netasset_value NUMBER(15,8),
  mfmm_repurchase_price NUMBER(15,8),
  mfmm_sale_price NUMBER(15,8),
  mfmm_corpus_amount NUMBER(15,2),
  mfmm_add_date DATE,
  mfmm_create_date DATE,
  mfmm_entry_details XMLTYPE,
  mfmm_record_status NUMBER(8),
  mfmm_dividend_amount NUMBER(15,8),
  CONSTRAINT trtran050c_pk PRIMARY KEY (mfmm_nav_code,mfmm_reference_date)
);