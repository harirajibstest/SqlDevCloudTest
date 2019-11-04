CREATE TABLE "TEST_VSTSRedgate".trsystem034 (
  gopm_structure_type NUMBER(8) NOT NULL,
  gopm_strike_rates VARCHAR2(1000 BYTE),
  gopm_notional_type VARCHAR2(100 BYTE),
  gopm_knockout_events VARCHAR2(100 BYTE),
  gopm_payout_events VARCHAR2(100 BYTE),
  gopm_payin_events VARCHAR2(100 BYTE),
  gopm_payment_types VARCHAR2(100 BYTE),
  gopm_dormancy_code NUMBER(8),
  gopm_premium_code NUMBER(8),
  gopm_help_field VARCHAR2(3000 BYTE),
  gopm_create_date DATE,
  gopm_record_status NUMBER(8),
  CONSTRAINT pk_trsystem034 PRIMARY KEY (gopm_structure_type)
);