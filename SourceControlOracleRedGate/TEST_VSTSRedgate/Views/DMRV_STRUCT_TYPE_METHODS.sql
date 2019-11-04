CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_struct_type_methods (method_id,method_ovid,method_name,structured_type_id,structured_type_ovid,structured_type_name,"BODY",constructor,overridden_method_id,overridden_method_ovid,overridden_method_name,design_ovid) AS
SELECT stm.Method_ID, stm.Method_OVID, stm.Method_Name, stm.Structured_Type_ID, stm.Structured_Type_OVID, stm.Structured_Type_Name, lt.Text, stm.Constructor, stm.Overridden_Method_ID, stm.Overridden_Method_OVID, stm.Overridden_Method_Name, stm.Design_OVID FROM DMRS_STRUCT_TYPE_METHODS stm, DMRS_LARGE_TEXT lt WHERE stm.Method_id  = lt.Object_id;