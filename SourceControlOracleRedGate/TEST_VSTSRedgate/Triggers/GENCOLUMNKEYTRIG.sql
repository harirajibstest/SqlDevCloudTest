CREATE OR REPLACE TRIGGER "TEST_VSTSRedgate"."GENCOLUMNKEYTRIG" 
					BEFORE INSERT ON "TEST_VSTSRedgate".stage_syb12_syscolumns
					FOR EACH ROW 
					BEGIN
					  IF :new.colid_gen is null THEN
					     :new.colid_gen := MD_META.get_next_id;
					  END IF;
					END GenColumnKeyTrig;
/