CREATE TABLE "TEST_VSTSRedgate".trcovar001 (
  rate_calc_date DATE NOT NULL,
  rate_currency_code NUMBER(8) NOT NULL,
  rate_for_currency NUMBER(8) NOT NULL,
  rate_maturity_month NUMBER(8) NOT NULL,
  rate_spotbid_change NUMBER(15,6),
  rate_spotask_change NUMBER(15,6),
  CONSTRAINT trcovar001_pk PRIMARY KEY (rate_calc_date,rate_currency_code,rate_for_currency,rate_maturity_month)
);