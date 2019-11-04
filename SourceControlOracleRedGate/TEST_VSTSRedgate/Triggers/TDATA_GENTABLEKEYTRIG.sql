CREATE OR REPLACE TRIGGER "TEST_VSTSRedgate"."TDATA_GENTABLEKEYTRIG" 
                                BEFORE INSERT ON "TEST_VSTSRedgate".STAGE_TERADATA_TABLES
                                FOR EACH ROW 
                                BEGIN
                                  IF :new.MDID IS NULL OR :new.MDID=0 THEN
                                     :new.MDID := MD_META.get_next_id;
                                  END IF;
                                END TDATA_GENTABLEKEYTRIG;
/