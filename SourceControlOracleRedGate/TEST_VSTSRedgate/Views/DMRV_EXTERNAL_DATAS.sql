CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_external_datas (external_data_id,external_data_ovid,external_data_name,model_id,model_ovid,model_name,logical_type_id,logical_type_ovid,logical_type_name,record_structure_type_id,record_structure_type_ovid,record_structure_type_name,starting_pos,description,design_ovid) AS
select  External_Data_ID, External_Data_OVID, External_Data_Name, Model_ID, Model_OVID, Model_Name, Logical_Type_ID, Logical_Type_OVID, Logical_Type_Name, Record_Structure_Type_ID, Record_Structure_Type_OVID, Record_Structure_Type_Name, Starting_Pos, Description, Design_OVID from DMRS_EXTERNAL_DATAS;