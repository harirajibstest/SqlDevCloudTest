CREATE OR REPLACE TRIGGER "TEST_VSTSRedgate"."GENOBJECTKEYTRIG" 
					BEFORE INSERT ON "TEST_VSTSRedgate".stage_syb12_sysobjects
					FOR EACH ROW 
					BEGIN
					  IF :new.objid_gen is null THEN
					     :new.objid_gen := MD_META.get_next_id;
					  END IF;
					END GenObjectKeyTrig;
/