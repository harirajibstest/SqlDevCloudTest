CREATE OR REPLACE TRIGGER "TEST_VSTSRedgate"."GENDBKEYTRIG" 
					BEFORE INSERT ON "TEST_VSTSRedgate".stage_syb12_sysdatabases 
					FOR EACH ROW 
					BEGIN
					  IF :new.dbid_gen is null THEN
					     :new.dbid_gen := MD_META.get_next_id;
					  END IF;
					END GenDbKeyTrig;
/