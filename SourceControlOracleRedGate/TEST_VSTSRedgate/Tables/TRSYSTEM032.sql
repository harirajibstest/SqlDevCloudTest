CREATE TABLE "TEST_VSTSRedgate".trsystem032 (
  dpos_company_code NUMBER(8) NOT NULL,
  dpos_position_date DATE NOT NULL,
  dpos_currency_code NUMBER(8) NOT NULL,
  dpos_position_type NUMBER(8) NOT NULL,
  dpos_purchase_number NUMBER(5),
  dpos_purchase_amount NUMBER(15,6),
  dpos_purchase_inr NUMBER(15,2),
  dpos_sale_number NUMBER(5),
  dpos_sale_amount NUMBER(15,6),
  dpos_sale_inr NUMBER(15,2),
  dpos_position_code NUMBER(8),
  dpos_day_position NUMBER(20,6),
  dpos_position_inr NUMBER(20,2),
  dpos_holding_rate NUMBER(15,6),
  dpos_user_id VARCHAR2(50 BYTE) NOT NULL,
  CONSTRAINT pk_trsystem032 PRIMARY KEY (dpos_company_code,dpos_position_date,dpos_currency_code,dpos_position_type,dpos_user_id)
);
COMMENT ON COLUMN "TEST_VSTSRedgate".trsystem032.dpos_position_code IS '12400001 for over bought 12400002 for over solded';