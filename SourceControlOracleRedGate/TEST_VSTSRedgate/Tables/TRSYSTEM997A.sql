CREATE TABLE "TEST_VSTSRedgate".trsystem997a (
  posn_company_code NUMBER(8) NOT NULL,
  posn_base_currency NUMBER(8) NOT NULL,
  posn_other_currency NUMBER(8) NOT NULL,
  posn_account_code NUMBER(8) NOT NULL,
  posn_user_id VARCHAR2(50 BYTE),
  posn_reference_number VARCHAR2(25 BYTE) NOT NULL,
  posn_reference_serial NUMBER(5),
  posn_reference_date DATE,
  posn_dealer_id VARCHAR2(50 BYTE),
  posn_counter_party NUMBER(8),
  posn_transaction_amount NUMBER(15,2),
  posn_fcy_rate NUMBER(15,6),
  posn_usd_rate NUMBER(15,6),
  posn_inr_value NUMBER(15,2),
  posn_usd_value NUMBER(15,2),
  posn_mtm_fcyrate NUMBER(15,6),
  posn_mtm_localrate NUMBER(15,6),
  posn_revalue_usd NUMBER(15,2),
  posn_revalue_inr NUMBER(15,2),
  posn_position_usd NUMBER(15,2),
  posn_position_inr NUMBER(15,2),
  posn_due_date DATE,
  posn_maturity_month NUMBER(2),
  posn_product_code NUMBER(8),
  posn_hedge_trade VARCHAR2(1 BYTE),
  posn_asset_liability VARCHAR2(1 BYTE),
  posn_for_currency NUMBER(8),
  posn_subproduct_code NUMBER(8),
  posn_stress_fcyrate NUMBER(15,6),
  posn_stress_localrate NUMBER(15,6),
  posn_mtm_pnl NUMBER(15,2),
  posn_mtm_pnllocal NUMBER(15,2),
  posn_stress_pnl NUMBER(15,2),
  posn_stress_pnllocal NUMBER(15,2)
);