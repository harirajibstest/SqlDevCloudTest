CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_measure_folder_measures (measure_folder_id,measure_folder_name,measure_folder_ovid,measure_id,measure_name,measure_ovid,parent_object_id,parent_object_name,parent_object_ovid,parent_object_type,design_ovid) AS
select  Measure_Folder_ID, Measure_Folder_Name, Measure_Folder_OVID, Measure_ID, Measure_Name, Measure_OVID, Parent_Object_ID, Parent_Object_Name, Parent_Object_OVID, Parent_Object_Type, Design_OVID from DMRS_MEASURE_FOLDER_MEASURES;