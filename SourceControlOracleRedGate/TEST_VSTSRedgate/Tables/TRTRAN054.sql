CREATE TABLE "TEST_VSTSRedgate".trtran054 (
  cm2m_effective_date DATE NOT NULL,
  cm2m_exchange_code NUMBER(8),
  cm2m_commodity_code NUMBER(8) NOT NULL,
  cm2m_expiry_month DATE NOT NULL,
  cm2m_serial_number NUMBER(5) NOT NULL,
  cm2m_opening_rate VARCHAR2(20 BYTE),
  cm2m_high_rate NUMBER(15,2),
  cm2m_low_rate NUMBER(15,2),
  cm2m_closing_rate NUMBER(15,4),
  cm2m_record_status NUMBER(8),
  cm2m_create_date DATE
);