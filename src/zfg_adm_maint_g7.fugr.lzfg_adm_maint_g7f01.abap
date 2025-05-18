*----------------------------------------------------------------------*
***INCLUDE LZFG_ADM_MAINT_G7F01.
*----------------------------------------------------------------------*
MODULE check_attr_bname INPUT.
  IF *ztb_admin-bname IS INITIAL AND ztb_admin-bname IS INITIAL.
    MESSAGE 'bname cannot be null' TYPE 'E'.
    sy-subrc = 4.
    RETURN.
  ENDIF.
ENDMODULE.

FORM create.

  IF ztb_admin-bname IS INITIAL.
    MESSAGE 'bname cannot be null' TYPE 'E'.
  ENDIF.

ENDFORM.

form AUTHORIZE_CHECK.
  IF sy-uname NE 'LEARN-286'.
*    MESSAGE 'You are not authorized to maintain this table' TYPE 'E'.
    VIM_AUTH_RC = 8.
    VIM_AUTH_MSGID = 'ZMSG_ZTB_ADMIN'.      " Custom or standard message class
    VIM_AUTH_MSGNO = '000'.       " Message number in that class
    VIM_AUTH_MSGV1 = sy-uname.    " Optional message variables
    VIM_AUTH_MSGV2 = 'ZTB_ADMIN'.
  endif.
ENDFORM.
