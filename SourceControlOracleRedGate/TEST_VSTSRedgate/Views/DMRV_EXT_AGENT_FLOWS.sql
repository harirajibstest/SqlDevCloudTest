CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_ext_agent_flows (external_agent_id,external_agent_ovid,external_agent_name,flow_id,flow_ovid,flow_name,incoming_outgoing_flag,design_ovid) AS
select  External_Agent_ID, External_Agent_OVID, External_Agent_Name, Flow_ID, Flow_OVID, Flow_Name, Incoming_Outgoing_Flag, Design_OVID from DMRS_EXT_AGENT_FLOWS;