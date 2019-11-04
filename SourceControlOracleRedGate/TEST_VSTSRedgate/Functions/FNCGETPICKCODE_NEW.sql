CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate".FNCGETPICKCODE_New (DESCRIPTION IN VARCHAR,
                         DESCRIPTIONTYPE IN  NUMBER, -- 1 for Long 2 for Short
                         KEYGROUP IN NUMBER)
                         return number
IS 
    varoperation gconst.gvaroperation%type;
    varmessage gconst.gvarmessage%type;
    VARERROR GCONST.GVARERROR%TYPE;
      NUMERROR NUMBER;
    numKeyNumber number(8);
BEGIN 
   VARMESSAGE := 'Getting Pick code for ' || DESCRIPTION || ' and Key Grouop' ||  KEYGROUP;
   
VAROPERATION := 'Getting Pick code for ' || DESCRIPTION || ' and Key Grouop' ||  KEYGROUP;

  SELECT PICK_KEY_VALUE
       into numKeyNumber
       FROM TRMASTER001
      WHERE ((DESCRIPTIONTYPE=2 AND PICK_SHORT_DESCRIPTION =DESCRIPTION)
        OR (DESCRIPTIONTYPE=1 AND PICK_LONG_DESCRIPTION =DESCRIPTION))
       AND PICK_KEY_GROUP= KEYGROUP
       AND PICK_RECORD_STATUS NOT IN (10200005,10200006);

return numKeyNumber;
EXCEPTION 
  when others then 
    numerror := sqlcode;
    VARERROR := SQLERRM || ' - ' || VARERROR;
    varError := GCONST.FNCRETURNERROR('FNCGETPICKCODE',   VARMESSAGE,   0,   NUMERROR,   VAROPERATION,   VARERROR);
    RAISE_APPLICATION_ERROR(-20101, VARERROR);
end;
/