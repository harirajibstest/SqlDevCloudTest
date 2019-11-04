CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."PKGSENDINGMAIL" AS
TYPE t_split_array IS TABLE OF VARCHAR2(4000);

   g_smtp_host      varchar2 (256)     := '10.45.40.4';
   g_smtp_port      pls_integer        := 25;
   g_From_User      varchar2 (256)     := 'Treasury.Alerts@himatsingka.local';
   g_smtp_domain    varchar2 (256)     := 'himatsingka.local';
   g_mailer_id constant varchar2 (256) := 'Mailer by Oracle UTL_SMTP';

FUNCTION split_text (p_text       IN  CLOB,
                     p_delimeter  IN  VARCHAR2 DEFAULT ';')
  RETURN t_split_array;

PROCEDURE send_mail_secure (p_to      IN VARCHAR2,
                     p_cc        IN VARCHAR2,
                     p_bcc       IN VARCHAR2,
                     p_subject   IN VARCHAR2,
                     p_text_msg  IN VARCHAR2 DEFAULT NULL,
                     p_html_msg  IN VARCHAR2 DEFAULT NULL,
                     p_html_msg_Clob  IN Clob DEFAULT NULL);

PROCEDURE send_mail (p_to        IN VARCHAR2,
                     p_cc        IN VARCHAR2,
                     p_bcc       IN VARCHAR2,
                     p_subject   IN VARCHAR2,
                     p_text_msg  IN VARCHAR2 DEFAULT NULL,
                     p_html_msg  IN VARCHAR2 DEFAULT NULL,
                     p_html_msg_Clob  IN Clob DEFAULT NULL);

PROCEDURE process_recipients (p_mail_conn IN UTL_SMTP.connection ,
                              o_mail_conn out UTL_SMTP.connection,
                              p_list      IN     VARCHAR2);
END PKGSendingMail;

/