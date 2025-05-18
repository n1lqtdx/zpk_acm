CLASS zcl_log_utils_g7 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS:
      log_message
        IMPORTING
          iv_locked_target TYPE string
          iv_action        TYPE zdt_ua_act_type.
PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_log_utils_g7 IMPLEMENTATION.

  METHOD log_message.
    DATA: ls_log_entry TYPE ztb_log_acm
        , lv_uuid TYPE zdt_ua_id
        , lv_host type string.

    TRY.
        " Generate unique log ID
        lv_uuid = cl_system_uuid=>create_uuid_x16_static(  ).

        " Assign values
        ls_log_entry-id           = lv_uuid.
        ls_log_entry-bname        = iv_locked_target.
        ls_log_entry-action_type  = iv_action.
        ls_log_entry-admin_user   = sy-uname.
        ls_log_entry-report       = sy-repid.
        ls_log_entry-sysid        = sy-sysid.
        ls_log_entry-spras        = sy-langu.
        GET TIME STAMP FIELD ls_log_entry-timestamp.

        " Insert log entry
        INSERT INTO ztb_log_acm VALUES @ls_log_entry.
        IF sy-subrc = 0.
          COMMIT WORK.
        ELSE.
          ROLLBACK WORK.
        ENDIF.

      CATCH cx_uuid_error INTO DATA(lx_uuid_error). "To implement something here?
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
