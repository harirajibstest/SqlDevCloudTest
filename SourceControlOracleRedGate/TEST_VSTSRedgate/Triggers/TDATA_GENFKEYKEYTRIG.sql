CREATE OR REPLACE TRIGGER "TEST_VSTSRedgate"."TDATA_GENFKEYKEYTRIG" 
                                BEFORE INSERT ON "TEST_VSTSRedgate".STAGE_TERADATA_FKEYS
                                FOR EACH ROW 
                                BEGIN
                                  IF :new.MDID1 IS NULL OR :new.MDID1=0 THEN
                                     :new.MDID1 := MD_META.get_next_id;
                                  END IF;
                                  IF :new.MDID2 IS NULL OR :new.MDID2=0 THEN
                                     :new.MDID2 := MD_META.get_next_id;
                                  END IF;
                                END TDATA_GENFKEYKEYTRIG;
/