CREATE TABLE "TEST_VSTSRedgate".trmaster901 (
  dcif_dashboard_name VARCHAR2(50 BYTE) NOT NULL,
  dcif_trans_type VARCHAR2(50 BYTE) NOT NULL,
  dcif_inflow_outflow NUMBER(8) NOT NULL,
  dicf_serial_number NUMBER(5) NOT NULL,
  dcif_account_code NUMBER(8) NOT NULL,
  dcif_record_status NUMBER(8),
  CONSTRAINT trmaster901_pk PRIMARY KEY (dcif_dashboard_name,dcif_trans_type,dicf_serial_number,dcif_inflow_outflow,dcif_account_code)
);