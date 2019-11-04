CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_foreignkeys (fk_name,model_id,model_ovid,object_id,ovid,import_id,child_table_name,referred_table_name,engineer,delete_rule,child_table_id,child_table_ovid,referred_table_id,referred_table_ovid,referred_key_id,referred_key_ovid,number_of_columns,mandatory,transferable,in_arc,arc_id,model_name,referred_key_name,design_ovid) AS
select  FK_Name, Model_ID, Model_OVID, Object_ID, OVID, Import_ID, Child_Table_Name, Referred_Table_Name, Engineer, Delete_Rule, Child_Table_ID, Child_Table_OVID, Referred_Table_ID, Referred_Table_OVID, Referred_Key_ID, Referred_Key_OVID, Number_Of_Columns, Mandatory, Transferable, In_Arc, Arc_ID, Model_Name, Referred_Key_Name, Design_OVID from DMRS_FOREIGNKEYS;