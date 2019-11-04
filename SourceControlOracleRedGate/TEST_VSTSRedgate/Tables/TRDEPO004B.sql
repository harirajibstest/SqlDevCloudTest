CREATE TABLE "TEST_VSTSRedgate".trdepo004b (
  depo_company_code NUMBER(8),
  depo_counter_party NUMBER(8),
  depo_currency_code NUMBER(8),
  depo_tds_effectivedate DATE,
  depo_tds_plan NUMBER(8),
  depo_tds_shortdesc VARCHAR2(10 BYTE),
  depo_tds_longdesc VARCHAR2(200 BYTE),
  depo_tds_type NUMBER(8),
  depo_tds_baseamt NUMBER(15,2),
  depo_tds_rate NUMBER(15,6),
  depo_tds_excemptionamt NUMBER(15,2),
  depo_tds_surchargerate NUMBER(15,6),
  depo_tds_remark VARCHAR2(200 BYTE),
  depo_record_status NUMBER(8),
  depo_entry_detail XMLTYPE,
  depo_create_date DATE,
  depo_add_date DATE
);