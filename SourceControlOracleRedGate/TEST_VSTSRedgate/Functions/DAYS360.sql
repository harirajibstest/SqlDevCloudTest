CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."DAYS360" (
       p_start_date           date,
       p_end_date             date,
       p_rule_type            char default 'F'
       )
    RETURN number
IS
  v_mm1    pls_integer;
  v_dd1    pls_integer;
  v_yyyy1  pls_integer;
  v_mm2    pls_integer;
  v_dd2    pls_integer;
  v_yyyy2  pls_integer;
BEGIN
  v_yyyy1 := to_number(to_char(p_start_date,'yyyy'));
  v_mm1   := to_number(to_char(p_start_date,'mm'));
  v_dd1   := to_number(to_char(p_start_date,'dd'));
  v_yyyy2 := to_number(to_char(p_end_date,'yyyy'));
  v_mm2   := to_number(to_char(p_end_date,'mm'));
  v_dd2   := to_number(to_char(p_end_date,'dd'));
  IF p_rule_type = 'F' THEN
     IF v_dd1 = 31 THEN v_dd1 := 30; END IF;
     IF v_mm1 = 2  AND v_dd1 = to_number(to_char(last_day(p_start_date),'dd'))
          THEN v_dd1 := 30; END IF;
     IF v_dd2 = 31
          THEN IF v_dd1 < 30
                    THEN v_dd2 := 1;
                         v_mm2 := v_mm2 + 1;
                         IF v_mm2 = 13 THEN v_mm2 := 1;
                                            v_yyyy2 := v_yyyy2 +1;
                         END IF;
                    ELSE v_dd2 := 30;
               END IF;
     END IF;
     IF v_mm2 = 2  AND v_dd2 = to_number(to_char(last_day(p_end_date),'dd'))
          THEN v_dd2 := 30;
               IF  (v_dd1 < 30)
                   THEN v_dd2 := 1;
                        v_mm2 := 3;
               END IF;
     END IF;
     IF v_mm2 IN (4, 6, 9, 11) AND v_dd2 = 30
          AND v_dd1 < 30
          THEN v_dd2 := 1;
               v_mm2 := v_mm2 + 1;
     END IF;
  ELSIF p_rule_type = 'T' THEN
     IF v_dd1 = 31 THEN v_dd1 := 30; END IF;
     IF v_dd1 = 31 THEN v_dd1 := 30; END IF;
     IF v_mm1 = 2  AND v_dd1 = to_number(to_char(last_day(p_start_date),'dd'))
          THEN v_dd1 := 30; END IF;
     IF v_dd2 = 31 THEN v_dd2 := 30; END IF;
     IF v_mm2 = 2  AND v_dd2 = to_number(to_char(last_day(p_end_date),'dd'))
          THEN v_dd2 := 30; END IF;
  ELSE RAISE_APPLICATION_ERROR('-20002','3VL Not Allowed Here');
  END IF;
  RETURN (v_yyyy2 - v_yyyy1) * 360
       + (v_mm2 - v_mm1) * 30
       + (v_dd2 - v_dd1);
END;
 
 
 
 
 
 
 
/