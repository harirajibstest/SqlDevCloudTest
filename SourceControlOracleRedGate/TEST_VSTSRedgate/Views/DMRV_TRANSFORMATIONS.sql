CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_transformations (transformation_id,transformation_ovid,transformation_name,transformation_task_id,transformation_task_ovid,transformation_task_name,filter_condition,join_condition,"PRIMARY",design_ovid) AS
select  Transformation_ID, Transformation_OVID, Transformation_Name, Transformation_Task_ID, Transformation_Task_OVID, Transformation_Task_Name, Filter_Condition, Join_Condition, Primary, Design_OVID from DMRS_TRANSFORMATIONS;