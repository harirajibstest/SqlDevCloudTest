CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_transformation_task_infos (transformation_task_id,transformation_task_ovid,transformation_task_name,info_store_id,info_store_ovid,info_store_name,source_target_flag,design_ovid) AS
select  Transformation_Task_ID, Transformation_Task_OVID, Transformation_Task_Name, Info_Store_ID, Info_Store_OVID, Info_Store_Name, Source_Target_Flag, Design_OVID from DMRS_TRANSFORMATION_TASK_INFOS;