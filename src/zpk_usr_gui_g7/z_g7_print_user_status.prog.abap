*&---------------------------------------------------------------------*
*& Report Z_G7_PRINT_USER_STATUS
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z_G7_PRINT_USER_STATUS.

DATA: lt_user_status TYPE zusr_g7_t_alv,
      lv_function  TYPE rs38l_fnam.

" Fetch user status data
CALL FUNCTION 'ZFM_G7_USER_STATUS'
  IMPORTING
    ET_USER_DATA       = lt_user_status.
                         .

*cl_demo_output=>display( lt_user_status ).

CALL FUNCTION '/1BCDWB/SF00000049'
  EXPORTING
*   ARCHIVE_INDEX              =
*   ARCHIVE_INDEX_TAB          =
*   ARCHIVE_PARAMETERS         =
*   CONTROL_PARAMETERS         =
*   MAIL_APPL_OBJ              =
*   MAIL_RECIPIENT             =
*   MAIL_SENDER                =
*   OUTPUT_OPTIONS             =
*   USER_SETTINGS              = 'X'
    it_user_status             = lt_user_status
* IMPORTING
*   DOCUMENT_OUTPUT_INFO       =
*   JOB_OUTPUT_INFO            =
*   JOB_OUTPUT_OPTIONS         =
 EXCEPTIONS
   FORMATTING_ERROR           = 1
   INTERNAL_ERROR             = 2
   SEND_ERROR                 = 3
   USER_CANCELED              = 4
   OTHERS                     = 5
          .
IF sy-subrc <> 0.
* Implement suitable error handling here
ENDIF.
