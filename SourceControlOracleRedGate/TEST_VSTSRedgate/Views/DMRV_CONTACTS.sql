CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_contacts (contact_id,contact_ovid,contact_name,business_info_id,business_info_ovid,business_info_name,design_ovid) AS
select  Contact_ID, Contact_OVID, Contact_Name, Business_Info_ID, Business_Info_OVID, Business_Info_Name, Design_OVID from DMRS_CONTACTS;