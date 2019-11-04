CREATE TABLE "TEST_VSTSRedgate".trtran064c (
  cfmm_effective_date DATE NOT NULL,
  cfmm_exchange_code NUMBER(8),
  cfmm_instrument_type NUMBER(8) NOT NULL,
  cfmm_base_currency NUMBER(8) NOT NULL,
  cfmm_other_currency NUMBER(8) NOT NULL,
  cfmm_expiry_month DATE NOT NULL,
  cfmm_serial_number NUMBER(5) NOT NULL,
  cfmm_opening_rate VARCHAR2(20 BYTE),
  cfmm_high_rate NUMBER(15,2),
  cfmm_low_rate NUMBER(15,2),
  cfmm_closing_rate NUMBER(15,4),
  cfmm_rate_time VARCHAR2(20 BYTE),
  cfmm_bid_rate NUMBER(15,6),
  cfmm_ask_rate NUMBER(15,6),
  cfmm_open_interest NUMBER(15,6),
  cfmm_volume NUMBER(15,6)
);