FUNCTION ZFM_G7_USER_STATUS .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(S_BNAME) TYPE  XUBNAME OPTIONAL
*"     REFERENCE(S_TRDAT) TYPE  XULDATE OPTIONAL
*"     REFERENCE(S_LOCK) TYPE  CHECKBOX OPTIONAL
*"  EXPORTING
*"     REFERENCE(ET_USER_DATA) TYPE  ZUSR_G7_T_ALV
*"----------------------------------------------------------------------
  DATA: lt_date  TYPE dats.

 lt_date = sy-datum + 1.


  " Select the required data
  SELECT u02~bname, u02~gltgv, u02~gltgb, u02~ustyp, u02~accnt, u02~trdat,
         u02~ltime, u02~tzone,
         CASE u02~uflag
             WHEN 0 THEN ' '
             ELSE 'Locked'
         END AS user_status,
         CASE u02~uflag
             WHEN 32 THEN 'Incorrect logins'
             WHEN 64 THEN 'Administrator'
             WHEN 128 THEN 'Inactive'
         END AS lock_reason,
          pu002~smtp_addr, u02~locnt
  INTO TABLE @ET_USER_DATA
  FROM usr02 AS u02
  LEFT JOIN puser002 AS pu002
  ON u02~bname = pu002~bname
  WHERE u02~trdat LT @lt_date
    AND u02~bname = @S_BNAME
    AND u02~uflag NE 0.




ENDFUNCTION.
