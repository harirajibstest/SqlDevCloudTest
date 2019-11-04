CREATE TABLE "TEST_VSTSRedgate".trsystem013a (
  alrt_alert_code NUMBER(8),
  alrt_noof_days NUMBER(5),
  alrt_alert_reference VARCHAR2(25 BYTE) NOT NULL,
  alrt_uer_id VARCHAR2(4000 BYTE),
  alrt_alert_to VARCHAR2(4000 BYTE),
  alrt_alert_cc VARCHAR2(4000 BYTE),
  alrt_alert_bcc VARCHAR2(4000 BYTE),
  alrt_record_status NUMBER(8),
  alrt_create_date DATE,
  alrt_add_date DATE,
  alrt_alert_description VARCHAR2(100 BYTE),
  alrt_risk_level NUMBER(8),
  CONSTRAINT trsystem13a_pk PRIMARY KEY (alrt_alert_reference)
);