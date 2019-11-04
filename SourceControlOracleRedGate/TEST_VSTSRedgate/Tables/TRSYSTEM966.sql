CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".trsystem966 (
  opmt_serial_number NUMBER(5),
  opmt_subserial_number NUMBER(5),
  opmt_maturity_date DATE,
  opmt_settlement_date DATE,
  opmt_amount_fcy NUMBER(15,2),
  opmt_buy_sell NUMBER(8),
  opmt_option_type NUMBER(8)
)
ON COMMIT PRESERVE ROWS;