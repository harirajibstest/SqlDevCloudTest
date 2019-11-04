CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCGETSPOTRATE" (
      MonthOrder IN VARCHAR,
      Srno       IN NUMBER,
      frmDate    IN DATE,
      toDate     IN DATE )
    RETURN NUMBER
  AS
    numRate NUMBER(15,2);
  BEGIN
    IF Srno = 1 THEN
      SELECT SpotRate
      INTO numRate
      FROM
        (SELECT TO_CHAR(Drat_Effective_Date,'YYYYMM'),
          MAX(Drat_Serial_Number),
          AVG(Drat_Spot_Bid) SpotRate
        FROM Trtran012
        WHERE TO_CHAR(Drat_Effective_Date,'YYYYMM') = Monthorder
        AND Drat_Currency_Code                      = 30400004
        AND Drat_For_Currency                       = 30400003
        GROUP BY TO_CHAR(Drat_Effective_Date,'YYYYMM')
        );
    ELSIF Srno = 2 THEN
      SELECT AVG(SpotRate )
      INTO numRate
      FROM
        (SELECT AVG(Drat_Spot_Bid) SpotRate,
          TO_CHAR(Drat_Effective_Date,'YYYYMM')Moonthy
        FROM Trtran012
        WHERE Drat_Effective_Date BETWEEN frmDate AND toDate
        AND Drat_Currency_Code = 30400004
        AND Drat_For_Currency  = 30400003
        GROUP BY TO_CHAR(Drat_Effective_Date,'YYYYMM')
        );
    ELSIF Srno = 3 THEN
      SELECT AVG(SpotRate )
      INTO numRate
      FROM
        (SELECT AVG(Drat_Spot_Bid) SpotRate,
          TO_CHAR(Drat_Effective_Date,'YYYYMM')Moonthy
        FROM Trtran012
        WHERE Drat_Effective_Date between '01-APR-' || to_char(to_number(to_char(frmDate,'YYYY'))-1)  and (frmDate -1)
        AND Drat_Currency_Code    = 30400004
        AND Drat_For_Currency     = 30400003
        GROUP BY TO_CHAR(Drat_Effective_Date,'YYYYMM')
        );
    END IF;
    RETURN numRate;
  END fncGetSpotRate;
 
 
 
 
 
 
 
 
/