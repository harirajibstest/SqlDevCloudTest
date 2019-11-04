CREATE TABLE "TEST_VSTSRedgate".tralert001 (
  alrt_user_ids VARCHAR2(4000 BYTE),
  alrt_reference_number VARCHAR2(25 BYTE) NOT NULL,
  alrt_title VARCHAR2(100 BYTE),
  alrt_message VARCHAR2(200 BYTE),
  alrt_record_status NUMBER(8),
  alrt_noof_transaction NUMBER(10),
  alrt_create_date DATE,
  alrt_alert_type NUMBER(8),
  alrt_risk_level NUMBER(8)
);