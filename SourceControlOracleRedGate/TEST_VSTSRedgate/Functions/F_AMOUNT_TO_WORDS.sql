CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."F_AMOUNT_TO_WORDS" (P_AMT       IN NUMBER )
                                               RETURN VARCHAR2 IS
M_MAIN_AMT_TEXT      VARCHAR2(2000) ;
M_TOP_AMT_TEXT       VARCHAR2(2000) ;
M_BOTTOM_AMT_TEXT    VARCHAR2(2000) ;
M_DECIMAL_TEXT       VARCHAR2(2000) ;
M_TOP                NUMBER(20,5) ;
M_MAIN_AMT           NUMBER(20,5) ;
M_TOP_AMT            NUMBER(20,5) ;
M_BOTTOM_AMT         NUMBER(20,5) ;
M_DECIMAL            NUMBER(20,5) ;
M_AMT                NUMBER(20,5);
M_TEXT               VARCHAR2(2000) ;
BEGIN
   M_MAIN_AMT        := NULL ;
   M_TOP_AMT_TEXT    := NULL ;
   M_BOTTOM_AMT_TEXT := NULL ;
   M_DECIMAL_TEXT    := NULL ;

   -- To get paise part
   M_DECIMAL    := P_AMT - TRUNC(P_AMT) ;

   IF M_DECIMAL >0 THEN
   M_DECIMAL := M_DECIMAL *100;
   END IF;

   M_AMT        := TRUNC(P_AMT) ;


   M_TOP        := TRUNC(M_AMT / 100000) ;
   M_MAIN_AMT   := TRUNC(M_TOP / 100);
   M_TOP_AMT    := M_TOP - M_MAIN_AMT * 100 ;
   M_BOTTOM_AMT :=  M_AMT - (M_TOP * 100000) ;

  IF M_MAIN_AMT > 0 THEN
      M_MAIN_AMT_TEXT := TO_CHAR(TO_DATE(M_MAIN_AMT,'J'),'JSP') ;
      IF M_MAIN_AMT = 1 THEN
        M_MAIN_AMT_TEXT := M_MAIN_AMT_TEXT || ' CRORE ' ;
      ELSE
        M_MAIN_AMT_TEXT := M_MAIN_AMT_TEXT || ' CRORES ' ;
      END IF ;
   END IF ;

   IF M_TOP_AMT > 0 THEN
      M_TOP_AMT_TEXT := TO_CHAR(TO_DATE(M_TOP_AMT,'J'),'JSP') ;
      IF M_TOP_AMT = 1 THEN
        M_TOP_AMT_TEXT := M_TOP_AMT_TEXT || ' LAKH ' ;
      ELSE
        M_TOP_AMT_TEXT := M_TOP_AMT_TEXT || ' LAKHS ' ;
      END IF;
   END IF ;
   IF M_BOTTOM_AMT > 0 THEN
      M_BOTTOM_AMT_TEXT := TO_CHAR(TO_DATE(M_BOTTOM_AMT,'J'),'JSP') ;
   END IF ;
   IF M_DECIMAL > 0 THEN
      IF NVL(M_BOTTOM_AMT,0) + NVL(M_TOP_AMT,0) > 0 THEN
         M_DECIMAL_TEXT := ' AND ' || TO_CHAR(TO_DATE(M_DECIMAL,'J'),'JSP') || ' Paise ' ;
      ELSE
         M_DECIMAL_TEXT :=  TO_CHAR(TO_DATE(M_DECIMAL,'J'),'JSP') ||' Paise ';
      END IF ;
        END IF ;
   M_TEXT := LOWER(M_MAIN_AMT_TEXT || M_TOP_AMT_TEXT || M_BOTTOM_AMT_TEXT || ' Rupees' ||
M_DECIMAL_TEXT || ' ONLY') ;
   M_TEXT := UPPER(SUBSTR(M_TEXT,1,1))|| SUBSTR(M_TEXT,2);
   M_TEXT := ' '|| M_TEXT;
   RETURN(M_TEXT);

END F_AMOUNT_TO_WORDS;
 
 
 
 
 
 
 
 
 
 
 
/