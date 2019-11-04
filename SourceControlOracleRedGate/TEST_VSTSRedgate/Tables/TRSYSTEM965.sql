CREATE TABLE "TEST_VSTSRedgate".trsystem965 (
  alrt_alert_name VARCHAR2(50 BYTE) NOT NULL,
  alrt_alert_to VARCHAR2(2000 BYTE),
  alrt_alert_cc VARCHAR2(500 BYTE),
  alrt_alert_bcc VARCHAR2(500 BYTE),
  CONSTRAINT trsystem965_pk PRIMARY KEY (alrt_alert_name)
);