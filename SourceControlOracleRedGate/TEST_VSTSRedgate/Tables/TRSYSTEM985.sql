CREATE TABLE "TEST_VSTSRedgate".trsystem985 (
  trpt_group_no NUMBER(4),
  trpt_row_no NUMBER(4),
  trpt_ord_company NUMBER(8),
  trpt_ord_date DATE,
  trpt_ord_reference VARCHAR2(25 BYTE),
  trpt_ord_supplier NUMBER(8),
  trpt_ord_notional NUMBER(15,4),
  trpt_ord_uncovered NUMBER(15,4),
  trpt_ord_matfrom DATE,
  trpt_ord_matdate DATE,
  trpt_ord_payterm DATE,
  trpt_ord_product NUMBER(8),
  trpt_ord_number VARCHAR2(25 BYTE),
  trpt_deal_date DATE,
  trpt_deal_company NUMBER(8),
  trpt_deal_bank NUMBER(8),
  trpt_deal_amount NUMBER(15,4),
  trpt_deal_matdate DATE,
  trpt_deal_setl_date DATE,
  trpt_deal_bp NUMBER,
  trpt_deal_sp NUMBER,
  trpt_deal_bc NUMBER,
  trpt_deal_sc NUMBER,
  trpt_deal_premcross NUMBER,
  trpt_deal_preminr NUMBER,
  trpt_deal_bankref VARCHAR2(200 BYTE),
  trpt_deal_number VARCHAR2(25 BYTE),
  trpt_cancel_date DATE,
  trpt_cancel_amount NUMBER(15,4),
  trpt_rbi_refrate NUMBER(15,4),
  trpt_gain_loss NUMBER(15,4),
  trpt_inv_date DATE,
  trpt_inv_no VARCHAR2(25 BYTE),
  trpt_inv_supplier NUMBER(8),
  trpt_inv_duedate DATE,
  trpt_inv_spotdate DATE,
  trpt_inv_bank NUMBER(8),
  trpt_inv_amount NUMBER(15,4),
  trpt_inv_product NUMBER(8),
  trpt_import_export NUMBER(8),
  trpt_profit_loss NUMBER(15,4),
  trpt_hedge_no VARCHAR2(25 BYTE),
  trpt_deal_type NUMBER(8)
);