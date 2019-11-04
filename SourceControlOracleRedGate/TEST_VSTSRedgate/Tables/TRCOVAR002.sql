CREATE TABLE "TEST_VSTSRedgate".trcovar002 (
  vari_calc_date DATE NOT NULL,
  vari_currency_code1 NUMBER(8) NOT NULL,
  vari_for_currency1 NUMBER(8) NOT NULL,
  vari_currency_code2 NUMBER(8) NOT NULL,
  vari_for_currency2 NUMBER(8) NOT NULL,
  vari_maturity_month NUMBER(8),
  vari_var_covar NUMBER(30,20),
  CONSTRAINT trcovar002_pk PRIMARY KEY (vari_calc_date,vari_currency_code1,vari_for_currency1,vari_currency_code2,vari_for_currency2)
);