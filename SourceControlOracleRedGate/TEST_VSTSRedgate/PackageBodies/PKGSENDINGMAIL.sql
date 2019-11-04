CREATE OR REPLACE PACKAGE BODY "TEST_VSTSRedgate"."PKGSENDINGMAIL" AS


PROCEDURE process_recipients (p_mail_conn IN UTL_SMTP.connection ,
                              o_mail_conn out UTL_SMTP.connection,
                              p_list      IN     VARCHAR2)
  AS
    l_tab PKGSendingMail.t_split_array;
    temp_mail_conn  UTL_SMTP.connection;
  BEGIN
  --UTL_SMTP.rcpt(l_mail_conn, p_to);
   temp_mail_conn:=p_mail_conn;
   insert into temp values (' Before Loop process_recipients Mail List ' || p_list,'Test');

    IF TRIM(p_list) IS NOT NULL THEN
      l_tab := PKGSendingMail.split_text(p_list);
      FOR i IN 1 .. l_tab.COUNT LOOP
       -- UTL_SMTP.rcpt(temp_mail_conn, TRIM(l_tab(i)))
--         insert into temp1 values (' Outside Loop process_recipients Mail List ' || TRIM(l_tab(i)));
--        commit;
        if (TRIM(l_tab(i)) is not null) then
--        insert into temp1 values (' Inside Loop process_recipients Mail List ' || TRIM(l_tab(i)));
--        commit;
            UTL_SMTP.command(temp_mail_conn,'RCPT TO: <'||TRIM(l_tab(i))||'>' );
        end if;
      END LOOP;
    END IF;
    o_mail_conn:= temp_mail_conn;
END process_recipients;


PROCEDURE send_mail_secure (p_to      IN VARCHAR2,
                     p_cc        IN VARCHAR2,
                     p_bcc       IN VARCHAR2,
                     p_subject   IN VARCHAR2,
                     p_text_msg  IN VARCHAR2 DEFAULT NULL,
                     p_html_msg  IN VARCHAR2 DEFAULT NULL,
                     p_html_msg_Clob  IN Clob DEFAULT NULL)

AS
  --l_mail_conn   UTL_SMTP.connection;
      Temp_mail_conn   UTL_SMTP.connection;
      l_boundary    VARCHAR2(50) := '----=*#abc1234321cba#*=';
       l_conn           utl_smtp.connection;
      nls_charset    varchar2(255);
        l_tab PKGSendingMail.t_split_array;
    g_smtp_host      varchar2 (256);
    g_smtp_port      pls_integer;
    g_wallet_path    varchar2(500);
    g_wallet_password varchar2(50);
    g_From_User      varchar2 (256);
    g_From_password  varchar2 (256);
    g_smtp_domain    varchar2 (256);

BEGIN
     select prmc_mail_userid,prmc_password_key, prmc_smtp_server,
            PRMC_smtp_domain,prmc_smtp_port,prmc_wallet_path,PRMC_WALLET_PSWD
         into g_From_User,g_From_password,g_smtp_host,
          g_smtp_domain,g_smtp_port,g_wallet_path,g_wallet_password
     from trsystem051;

      select value
      into   nls_charset
      from   nls_database_parameters
      where  parameter = 'NLS_CHARACTERSET';
      -- establish connection and autheticate
     -- l_conn   := utl_smtp.open_connection (g_smtp_host, g_smtp_port);

--       l_conn := UTL_SMTP.open_connection(g_smtp_host, g_smtp_port);
       l_conn := UTL_SMTP.open_connection(
                        host => g_smtp_host,
                        port => g_smtp_port,
                        wallet_path => g_wallet_path,
                        wallet_password => g_wallet_password,
                        secure_connection_before_smtp => FALSE);
--                        ,secure_host => 'gmail.com');
--                        l_conn := UTL_SMTP.open_connection(g_smtp_host,g_smtp_port,
--                        'file:C:\app\IBS_BGLR1\product\12.1.0\dbhome_1\BIN\owm1',
--                        'ibs@mumbai'
--                        );
     utl_smtp.ehlo(l_conn, g_smtp_domain);  
      utl_smtp.starttls(l_conn);





--      utl_smtp.ehlo(l_conn, g_smtp_domain);  
--commenting to test normal mail
--          utl_smtp.auth(l_conn,
--                   utl_encode.text_encode(g_From_User, nls_charset, 1),
--                   utl_encode.text_encode(g_From_password, nls_charset, 1));
      utl_smtp.command(l_conn, 'auth login');
      utl_smtp.command(l_conn,utl_encode.text_encode(g_From_User, nls_charset, 1));
      utl_smtp.command(l_conn, utl_encode.text_encode(g_From_password, nls_charset, 1));
      -- set from/recipient
    --   utl_smtp.open_data (l_conn);
      utl_smtp.command(l_conn, 'MAIL FROM: <'||g_From_User||'>');
      --utl_smtp.command(l_conn, 'RCPT TO: <'||p_to||'>');
      --  utl_smtp.command(l_conn, 'RCPT TO: <'||p_to||'>');

    IF TRIM(p_to) IS NOT NULL THEN
      l_tab := PKGSendingMail.split_text(p_to);
      FOR i IN 1 .. l_tab.COUNT LOOP
       -- UTL_SMTP.rcpt(temp_mail_conn, TRIM(l_tab(i)));
        UTL_SMTP.command(l_conn,'RCPT TO: <'||TRIM(l_tab(i))||'>' );
      END LOOP;
    END IF;

    IF TRIM(p_cc) IS NOT NULL THEN
      l_tab := PKGSendingMail.split_text(p_cc);
      FOR i IN 1 .. l_tab.COUNT LOOP
       -- UTL_SMTP.rcpt(temp_mail_conn, TRIM(l_tab(i)));
        UTL_SMTP.command(l_conn,'RCPT TO: <'||TRIM(l_tab(i))||'>' );
      END LOOP;
    END IF;

        IF TRIM(p_bcc) IS NOT NULL THEN
      l_tab := PKGSendingMail.split_text(p_bcc);
      FOR i IN 1 .. l_tab.COUNT LOOP
       -- UTL_SMTP.rcpt(temp_mail_conn, TRIM(l_tab(i)));
        UTL_SMTP.command(l_conn,'RCPT TO: <'||TRIM(l_tab(i))||'>' );
      END LOOP;
    END IF;

  --UTL_SMTP.mail(l_mail_conn, p_from);
  --UTL_SMTP.rcpt(l_mail_conn, p_to);
--  Temp_mail_conn:= l_conn;
--  process_recipients(Temp_mail_conn,l_conn, p_to);
--  Temp_mail_conn:= l_conn;
--  process_recipients(Temp_mail_conn,l_conn, p_cc);
--  Temp_mail_conn:= l_conn;
--  process_recipients(Temp_mail_conn,l_conn, p_bcc);

  UTL_SMTP.open_data(l_conn);

  UTL_SMTP.write_data(l_conn, 'Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_conn, 'To: ' || p_to || UTL_TCP.crlf);
   UTL_SMTP.write_data(l_conn, 'CC: ' || p_cc || UTL_TCP.crlf);
--    UTL_SMTP.write_data(l_conn, 'BCC: ' || p_bcc || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_conn, 'From: ' || g_From_User || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_conn, 'Subject: ' || p_subject || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_conn, 'Reply-To: ' || g_From_User || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_conn, 'MIME-Version: 1.0' || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_conn, 'Content-Type: multipart/alternative; boundary="' || l_boundary || '"' || UTL_TCP.crlf || UTL_TCP.crlf);

  IF p_text_msg IS NOT NULL THEN
    UTL_SMTP.write_data(l_conn, '--' || l_boundary || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_conn, 'Content-Type: text/plain; charset="iso-8859-1"' || UTL_TCP.crlf || UTL_TCP.crlf);

    UTL_SMTP.write_data(l_conn, p_text_msg);
    UTL_SMTP.write_data(l_conn, UTL_TCP.crlf || UTL_TCP.crlf);
  END IF;

  IF p_html_msg IS NOT NULL THEN
    UTL_SMTP.write_data(l_conn, '--' || l_boundary || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_conn, 'Content-Type: text/html; charset="iso-8859-1"' || UTL_TCP.crlf || UTL_TCP.crlf);

    UTL_SMTP.write_data(l_conn, p_html_msg);
    UTL_SMTP.write_data(l_conn, UTL_TCP.crlf || UTL_TCP.crlf);
  END IF;

  IF p_html_msg_Clob IS NOT NULL THEN
    UTL_SMTP.write_data(l_conn, '--' || l_boundary || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_conn, 'Content-Type: text/html; charset="iso-8859-1"' || UTL_TCP.crlf || UTL_TCP.crlf);

    UTL_SMTP.write_data(l_conn, p_html_msg_Clob);
    UTL_SMTP.write_data(l_conn, UTL_TCP.crlf || UTL_TCP.crlf);
  END IF;

  UTL_SMTP.write_data(l_conn, '--' || l_boundary || '--' || UTL_TCP.crlf);
  UTL_SMTP.close_data(l_conn);

  UTL_SMTP.quit(l_conn);
END send_mail_secure;

PROCEDURE send_mail (p_to        IN VARCHAR2,
                     p_cc        IN VARCHAR2,
                     p_bcc       IN VARCHAR2,
                     p_subject   IN VARCHAR2,
                     p_text_msg  IN VARCHAR2 DEFAULT NULL,
                     p_html_msg  IN VARCHAR2 DEFAULT NULL,
                     p_html_msg_Clob  IN Clob DEFAULT NULL)

AS
  l_mail_conn   UTL_SMTP.connection;
  Temp_mail_conn   UTL_SMTP.connection;
  l_boundary    VARCHAR2(50) := '----=*#abc1234321cba#*=';
  p_smtp_host      varchar2 (256);
  p_smtp_port      pls_integer;
  p_From_User      varchar2 (256) ;
  p_smtp_domain    varchar2 (256);
BEGIN

     select prmc_mail_userid, prmc_smtp_server,
             prmc_smtp_port
         into p_From_User,p_smtp_host,
               p_smtp_port
     from trsystem051;

  l_mail_conn := UTL_SMTP.open_connection(p_smtp_host, p_smtp_port);
  INSERT INTO TEMP VALUES (p_smtp_host,p_smtp_port);

  commit;
  UTL_SMTP.helo(l_mail_conn, p_smtp_host);
  UTL_SMTP.mail(l_mail_conn, p_From_User);
 -- UTL_SMTP.rcpt(l_mail_conn, 'bg@mahindra.com');
 --UTL_SMTP.rcpt(l_mail_conn,'surendrababu.v@sailife.com');
 UTL_SMTP.rcpt(l_mail_conn,'naveen.kumar@ibsfintech.com');
  insert into temp1 values('xx',p_to);commit;
  Temp_mail_conn:= l_mail_conn;
  --insert into temp1 values (p_to); commit;
  process_recipients(Temp_mail_conn,l_mail_conn, p_to);
  Temp_mail_conn:= l_mail_conn;
  process_recipients(Temp_mail_conn,l_mail_conn, p_cc);
  Temp_mail_conn:= l_mail_conn;
  process_recipients(Temp_mail_conn,l_mail_conn, p_bcc);


  UTL_SMTP.open_data(l_mail_conn);

  UTL_SMTP.write_data(l_mail_conn, 'Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'From: ' || p_From_User || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Subject: ' || p_subject || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Reply-To: ' || p_From_User || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'MIME-Version: 1.0' || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Content-Type: multipart/alternative; boundary="' || l_boundary || '"' || UTL_TCP.crlf || UTL_TCP.crlf);


  IF p_text_msg IS NOT NULL THEN
    UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Content-Type: text/plain; charset="iso-8859-1"' || UTL_TCP.crlf || UTL_TCP.crlf);

    UTL_SMTP.write_data(l_mail_conn, p_text_msg);
    UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
  END IF;

  IF p_html_msg IS NOT NULL THEN
    UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Content-Type: text/html; charset="iso-8859-1"' || UTL_TCP.crlf || UTL_TCP.crlf);

    UTL_SMTP.write_data(l_mail_conn, p_html_msg);
    UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
  END IF;
  ---Added by Naveen on 18-04-2018
   IF p_html_msg_Clob IS NOT NULL THEN
    UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Content-Type: text/html; charset="iso-8859-1"' || UTL_TCP.crlf || UTL_TCP.crlf);

    UTL_SMTP.write_data(l_mail_conn, p_html_msg_Clob);
    UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
  END IF;

  UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || '--' || UTL_TCP.crlf);
  UTL_SMTP.close_data(l_mail_conn);

  UTL_SMTP.quit(l_mail_conn);

END send_mail;


FUNCTION split_text (p_text       IN  CLOB,
                     p_delimeter  IN  VARCHAR2 DEFAULT ';')
  RETURN t_split_array IS

  l_array  t_split_array   := t_split_array();
  l_text   CLOB := p_text;
  l_idx    NUMBER;
BEGIN
  l_array.delete;

  IF l_text IS NULL THEN
    RAISE_APPLICATION_ERROR(-20000, 'P_TEXT parameter cannot be NULL');
  END IF;

  WHILE l_text IS NOT NULL LOOP
    l_idx := INSTR(l_text, p_delimeter);
    l_array.extend;
    IF l_idx > 0 THEN
      l_array(l_array.last) := SUBSTR(l_text, 1, l_idx - 1);
      l_text := SUBSTR(l_text, l_idx + 1);
    ELSE
      l_array(l_array.last) := l_text;
      l_text := NULL;
    END IF;
  END LOOP;
  RETURN l_array;
END split_text;


END PKGSendingMail;
/