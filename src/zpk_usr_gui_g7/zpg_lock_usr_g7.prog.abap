*&---------------------------------------------------------------------*
*& Report zpg_lock_usr_g7
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpg_lock_usr_g7.

CONSTANTS:
  lc_priority    TYPE bcs_docimp VALUE '1'.

* Get inactive user
DATA: lt_date           TYPE          dats
    , lv_output         TYPE          string
    , gv_xstring        TYPE          xstring
    , gc_logger         TYPE REF TO   zcl_log_utils_g7
    , ls_status         TYPE          string.

gc_logger = NEW zcl_log_utils_g7(  ).

* Conditions: User who not logged in for 7 days and up.
lt_date = sy-datum - 7.

* Check if user authorized for this app.
SELECT * FROM ztb_admin
WHERE bname = @sy-uname
INTO @DATA(lt_admin).
ENDSELECT.

IF lt_admin IS INITIAL.
  WRITE: 'Not authorized.'.
  EXIT.
ENDIF.

* Getting user to check conditions.
SELECT u02~bname, u02~gltgv, u02~gltgb, u02~ustyp, u02~accnt, u02~trdat, u02~ltime, u02~tzone,
    CASE u02~uflag
        WHEN 0 THEN ' '
        ELSE 'Locked'
        END AS user_status,
    CASE u02~uflag
        WHEN 32  THEN 'Administrator'
        WHEN 64  THEN 'Administrator'
        WHEN 128 THEN 'Incorrect logins'
        WHEN 192 THEN 'Administrator'
        END AS lock_reason,
    u02~locnt, pu002~smtp_addr, zu~inactive_date
    FROM usr02 AS u02
    LEFT JOIN p_user002 AS pu002
    ON u02~bname = pu002~bname
    LEFT JOIN ztb_user AS zu
    ON u02~bname = zu~bname
    WHERE
    ( u02~trdat LT @lt_date
      AND u02~uflag EQ 0
      AND u02~ustyp = 'A'
      AND u02~trdat IS NOT INITIAL
* Anh BinhDVG recommend chỉ nên lock tất cả tài khoản LEARN
      AND u02~bname LIKE 'LEARN%' )
      OR
      zu~inactive_date >= @sy-datum
      AND NOT EXISTS (
          SELECT 1
            FROM agr_users AS roles
            WHERE roles~uname EQ u02~bname
                AND roles~agr_name EQ 'SAP_ALL'
       )
*      AND u02~bname EQ 'LEARN-287'
    INTO TABLE @DATA(lt_users).


IF lt_users IS NOT INITIAL.
* Convert table to Excel format.
  PERFORM table_to_xlsx
    USING
        lt_users
    CHANGING
        gv_xstring.

  LOOP AT lt_users INTO DATA(ls_user).
    IF NOT sy-subrc EQ 0.
      EXIT.
    ENDIF.
* If user not logged in for 30 days, lock them.
    IF ( sy-datum - ls_user-trdat ) > 30
       OR ls_user-inactive_date EQ sy-datum.
      PERFORM process_user
          USING    'L'
                   ls_user
                   gv_xstring.
    ELSE.
* If not, send warning email.
      CLEAR ls_status.
      ls_status = ls_user-user_status.
      "Send warning mail.
      PERFORM send_email
          USING ls_user-bname
                ls_user-smtp_addr
                ls_user-trdat
                ls_user-ltime
                ls_user-inactive_date
                ls_status
                gv_xstring
                'ZTEMPLATE_EMAIL_LOCK_WARNING'.
    ENDIF.
  ENDLOOP.
ENDIF.


FORM process_user
    USING    iv_action     TYPE char01
             iv_user       TYPE any
             iv_xstring    TYPE xstring.

  "Get selected rows data.
  DATA: lt_return   TYPE TABLE OF bapiret2,
        ls_status   TYPE string,
        lv_username TYPE string.

  CLEAR ls_status.

  ls_status = 'LOCKED'.

  IF iv_action = 'L'.

    "Lock user
    CALL FUNCTION 'BAPI_USER_LOCK'
      EXPORTING
        username = ls_user-bname
      TABLES
        return   = lt_return.

    LOOP AT lt_return INTO DATA(lv_return).
      IF lv_return-type = 'S'.
        CLEAR lv_username.
        lv_username = ls_user-bname.

        " Log
        gc_logger->log_message(
          iv_locked_target = lv_username
          iv_action        = 'LOCK'
        ).

        " Send email
        PERFORM send_email
            USING ls_user-bname
                  ls_user-smtp_addr
                  ls_user-trdat
                  ls_user-ltime
                  ls_user-inactive_date
                  ls_status
                  iv_xstring
                  'ZTEMPLATE_EMAIL_LOCK_NOTIF'.

        " Output to screen
        WRITE:/ lv_return-message.
      ENDIF.
    ENDLOOP.

  ELSEIF iv_action = 'U'.
    CALL FUNCTION 'BAPI_USER_UNLOCK'
      EXPORTING
        username = ls_user-bname
      TABLES
        return   = lt_return.
  ENDIF.

ENDFORM.

FORM send_email
    USING iv_user          TYPE xubname
          iv_email         TYPE adr6-smtp_addr
          iv_last_log_date TYPE xuldate
          iv_last_log_time TYPE xultime
          iv_lock_date     TYPE xuldate
          iv_status        TYPE string
          iv_xstring       TYPE xstring
          iv_template_name TYPE smtg_tmpl_id.

* Send email
  DATA: lo_send_request     TYPE REF TO    cl_bcs
      , lo_document         TYPE REF TO    cl_document_bcs
      , lo_recipient_sap    TYPE REF TO    if_recipient_bcs
      , lo_recipient_ext    TYPE REF TO    if_recipient_bcs
      , lt_text             TYPE TABLE OF  solisti1
      , lt_attachment       TYPE TABLE OF  solisti1
      , lv_date_lock        TYPE           sy-datum
      , lv_logon_timestamp  TYPE           timestamp
      , lv_timestamp_str    TYPE           string.

  lv_date_lock = sy-datum + ( 30 - ( sy-datum - iv_last_log_date ) ).
  DATA(lv_date_lock_str) = |{ lv_date_lock DATE = ISO }|.
  DATA(lv_ztb_user_lock_date_str) = |{ iv_lock_date DATE = ISO }|.


  TRY.
      lo_send_request = cl_bcs=>create_persistent( ).

      lo_send_request->set_sender( cl_sapuser_bcs=>create( sy-uname ) ).

* Determine recipient
      lo_recipient_sap = cl_sapuser_bcs=>create( iv_user ).
      CALL METHOD lo_send_request->add_recipient
        EXPORTING
          i_recipient = lo_recipient_sap
          i_express   = 'X'.

      IF iv_email IS NOT INITIAL.
        lo_recipient_ext = cl_cam_address_bcs=>create_internet_address( iv_email ).
        CALL METHOD lo_send_request->add_recipient
          EXPORTING
            i_recipient = lo_recipient_ext
            i_express   = 'X'.
      ENDIF.

      DATA(lo_email_api_ref) = cl_smtg_email_api=>get_instance( iv_template_id = iv_template_name ).
      DATA(i_cds_key) = VALUE if_smtg_email_template=>ty_gt_data_key(  ).
      CONVERT DATE iv_last_log_date
              TIME iv_last_log_time
              INTO TIME STAMP lv_logon_timestamp TIME ZONE 'UTC'.
      CALL FUNCTION 'RRBA_CONVERT_TIMESTAMP_TO_STR'
        EXPORTING
          i_timestamp = lv_logon_timestamp
        IMPORTING
          e_output    = lv_timestamp_str.
      .

      " Body
      lo_email_api_ref->render(
          EXPORTING
              iv_language = sy-langu
              it_data_key = i_cds_key
          IMPORTING
              ev_subject = DATA(lv_subject)
              ev_body_html = DATA(lv_body_html) ).
      CASE iv_template_name.
        WHEN 'ZTEMPLATE_EMAIL_LOCK_NOTIF'.
          CONDENSE iv_user.
          REPLACE ALL OCCURRENCES OF '{{ ID }}' IN lv_body_html WITH iv_user.
          REPLACE ALL OCCURRENCES OF '{{ inactiveDate }}' IN lv_body_html WITH lv_date_lock_str.
          IF ( iv_lock_date = sy-datum ).
            REPLACE ALL OCCURRENCES OF '{{ longReason }}' IN lv_body_html WITH 'account expired'.
            REPLACE ALL OCCURRENCES OF '{{ shortReason }}' IN lv_body_html WITH 'AE'.
          ELSE.
            REPLACE ALL OCCURRENCES OF '{{ longReason }}' IN lv_body_html WITH 'inactive for 30 days'.
            REPLACE ALL OCCURRENCES OF '{{ shortReason }}' IN lv_body_html WITH 'I30Ds'.
          ENDIF.
          REPLACE ALL OCCURRENCES OF '{{ lastLogonTime }}' IN lv_body_html WITH lv_timestamp_str.
          REPLACE ALL OCCURRENCES OF '{{ session }}' IN lv_body_html WITH sy-mandt.
          REPLACE ALL OCCURRENCES OF '{{ status }}' IN lv_body_html WITH iv_status.
        WHEN 'ZTEMPLATE_EMAIL_LOCK_WARNING'.
          CONDENSE iv_user.
          REPLACE ALL OCCURRENCES OF '{{ ID }}' IN lv_body_html WITH iv_user.
          IF iv_lock_date IS NOT INITIAL AND ( iv_lock_date - sy-datum ) <= 7.
            REPLACE ALL OCCURRENCES OF '{{ inactiveDate }}' IN lv_body_html WITH lv_ztb_user_lock_date_str.
            REPLACE ALL OCCURRENCES OF '{{ longReason }}' IN lv_body_html WITH 'account expiring soon'.
            REPLACE ALL OCCURRENCES OF '{{ shortReason }}' IN lv_body_html WITH 'AE'.
          ELSE.
            REPLACE ALL OCCURRENCES OF '{{ inactiveDate }}' IN lv_body_html WITH lv_date_lock_str.
            REPLACE ALL OCCURRENCES OF '{{ longReason }}' IN lv_body_html WITH 'inactive for 30 days'.
            REPLACE ALL OCCURRENCES OF '{{ shortReason }}' IN lv_body_html WITH 'I30Ds'.
          ENDIF.
          REPLACE ALL OCCURRENCES OF '{{ lastLogonTime }}' IN lv_body_html WITH lv_timestamp_str.
          REPLACE ALL OCCURRENCES OF '{{ session }}' IN lv_body_html WITH sy-mandt.
          REPLACE ALL OCCURRENCES OF '{{ status }}' IN lv_body_html WITH iv_status.
      ENDCASE.

      DATA(lv_body_html_soli) = cl_bcs_convert=>string_to_soli( lv_body_html ). " Build HTML for Sending
      DATA(lo_multipart_ref) = NEW cl_gbt_multirelated_service( ).

      lo_multipart_ref->set_main_html(
          EXPORTING
              content      = lv_body_html_soli
              description  = 'GIs Not Posted' ).

* Create & Set the Email Document
      lo_document = cl_document_bcs=>create_document(
          EXPORTING
              i_subject        = CONV so_obj_des( lv_subject )  " Set the Email Subject
              i_text           = lv_body_html_soli
              i_importance     = lc_priority
              i_type = 'HTM' ).

* Add attachment
      DATA:
          lt_binary             TYPE solix_tab
        , lv_size               TYPE i
        , lv_filename           TYPE string
        , main_text             TYPE bcsy_text
        , lo_attachment_subject TYPE sood-objdes
        , lt_att_head           TYPE soli_tab
        , lv_text_line          TYPE soli.
      CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
        EXPORTING
          buffer        = iv_xstring
        IMPORTING
          output_length = lv_size
        TABLES
          binary_tab    = lt_binary.

      CONCATENATE 'UserReport_' iv_user '_' sy-datum '.xlsx' INTO lv_filename.
      lo_attachment_subject = lv_filename.
      CONCATENATE '&SO_FILENAME=' lv_filename INTO lv_text_line.
      APPEND lv_text_line TO lt_att_head.

      lo_document->add_attachment(
        i_attachment_type    = 'xls'
        i_attachment_subject = lo_attachment_subject
        i_attachment_size    = CONV so_obj_len( lv_size )
        i_attachment_header  = lt_att_head
        i_att_content_hex    = lt_binary ).
      lo_send_request->set_document( lo_document ).

* Send mail
      lo_send_request->send( i_with_error_screen = 'X' ).
    CATCH cx_send_req_bcs INTO DATA(lx_send_req_bcs).
      WRITE: 'Email sending failed: ', lx_send_req_bcs->get_text( ).

    CATCH cx_document_bcs INTO DATA(lx_document_bcs).
      WRITE: 'Creating document failed: ', lx_document_bcs->get_text( ).

    CATCH cx_address_bcs INTO DATA(lx_address_bcs).
      WRITE: 'Assigning address failed: ',  lx_address_bcs->get_text( ).

    CATCH cx_smtg_email_common INTO DATA(lx_smth_email_common).
      WRITE: 'Email template failed: ', lx_smth_email_common->get_text(  ).

    CATCH cx_bcom_mime INTO DATA(lx_bcom_mime).
      WRITE: 'MIME failed: ', lx_bcom_mime->get_text(  ).

    CATCH cx_gbt_mime INTO DATA(lx_gbt_mime).
      WRITE: 'GBT framework failed: ', lx_gbt_mime->get_text(  ).

  ENDTRY.

  COMMIT WORK.
  WRITE:/ |{ iv_user } ': Email with attachment sent!'| .
ENDFORM.

FORM table_to_xlsx
    USING
        it_variant TYPE ANY TABLE
    CHANGING
        ev_xstring TYPE xstring.

  DATA:
    lo_excel        TYPE REF TO zcl_excel
    , lo_xl_converter TYPE REF TO zcl_excel_converter.

  TRY.
      lo_xl_converter = NEW zcl_excel_converter(  ).
      lo_xl_converter->convert( EXPORTING
                                    it_table = it_variant
                                CHANGING
                                    co_excel = lo_excel ).

      DATA(lo_worksheet) = lo_excel->get_active_worksheet(  ).
      lo_worksheet->freeze_panes( ip_num_rows = 1 ).

      PERFORM t2x_auto_size
        USING
          lo_worksheet
        .
*      CATCH zcx_excel.

      DATA(lo_excel_writer) = CAST zif_excel_writer( NEW zcl_excel_writer_2007(  ) ).
      ev_xstring = lo_excel_writer->write_file( lo_excel ).

    CATCH zcx_excel INTO DATA(zlx_excel).
      WRITE:/ 'Abap2Xlsx failed: ', zlx_excel->get_text(  ).
  ENDTRY.

ENDFORM.

FORM t2x_auto_size
    USING io_worksheet TYPE REF TO zcl_excel_worksheet
    RAISING zcx_excel.

  DATA(o_col_iterator) = io_worksheet->get_columns_iterator( ).
  IF o_col_iterator IS BOUND.
    WHILE o_col_iterator->has_next( ).
      DATA(o_col) = CAST zcl_excel_column( o_col_iterator->get_next( ) ).
      o_col->set_auto_size( abap_true ).
    ENDWHILE.
  ENDIF.

  io_worksheet->calculate_column_widths(  ).

ENDFORM.
