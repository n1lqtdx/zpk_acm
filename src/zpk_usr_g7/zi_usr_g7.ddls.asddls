@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'User activation view'
define root view entity ZI_USR_G7
  as select from usr02 as Usr02
  association [1..1] to P_USER002         as _pu002               on $projection.Username = _pu002.bname
  association [1..1] to ztb_user          as _zu                  on $projection.Username = _zu.bname
  association [1..*] to ZC_LOG_G7         as _log                 on $projection.Username = _log.Bname
  association [0..*] to ZI_LOCKSTAT_VH_G7 as _lockStatusValueHelp on $projection.LockReason = _lockStatusValueHelp.UflagText
  association [0..*] to ZI_USRTYP_VH_G7   as _usrTypeValueHelp    on $projection.Type = _usrTypeValueHelp.UstypText
  association [1..1] to ZI_ACTSTAT_VH_G7  as _actStatValueHelp    on $projection.ActivityStatus = _actStatValueHelp.ActStat
{
      @Search.defaultSearchElement: true
  key bname                                             as Username,
      gltgv                                             as ValidFrom,
      gltgb                                             as ValidTo,
      @Consumption.valueHelp: '_usrTypeValueHelp'
      case ustyp
          when 'A' then 'A Dialog'
          when 'B' then 'B System'
          when 'C' then 'C Communication'
          when 'L' then 'L Reference'
          else 'S Service'
      end                                               as Type,
      locnt                                             as NoFailedLogonAttempts,
      uflag                                             as LockStatus,
      @Consumption.valueHelp: '_lockStatusValueHelp'
      case uflag
          when 32 then 'By Administrator'
          when 64 then 'By Administrator'
          when 128 then 'Incorrect Logins'
          when 192 then 'By Administrator'
          else 'Active'
      end                                               as LockReason,
      case uflag
          when 32 then 'com.sap.vocabularies.UI.v1.CriticalityType/Negative'
          when 64 then 'com.sap.vocabularies.UI.v1.CriticalityType/Negative'
          when 128 then 'com.sap.vocabularies.UI.v1.CriticalityType/Negative'
          when 192 then 'com.sap.vocabularies.UI.v1.CriticalityType/Negative'
      else 'com.sap.vocabularies.UI.v1.CriticalityType/Positive'
      end                                               as LockCriticality,
      accnt                                             as AccountId,
      trdat                                             as LastLogonDate,
      ltime                                             as LastLogonTime,
      tzone                                             as UserTimezone,
      _pu002.smtp_addr                                  as Address,
      case trdat
            when '00000000' then 0
            else 1
      end                                               as UniqueUserCount,
      _zu.inactive_date                                 as LockDate,
      cast (1 as abap.int4)                             as UserCount,
      //      concat(substring(trdat, 1, 4), substring(trdat, 5, 2)) as YearMonth,
      case trdat
          when '00000000' then ''
          else concat(substring(trdat, 1, 4), substring(trdat, 5, 2))
          end                                           as YearMonth,
      case
          when trdat is not null then dats_days_between(trdat, $session.system_date)
          when trdat = '00000000' then 999999
          else 0
      end                                               as DaysSinceInactive,
      @Consumption.valueHelp: '_actStatValueHelp'
      case
          when dats_days_between(trdat, $session.system_date) <= 30 then '1'
          when dats_days_between(trdat, $session.system_date) <= 90 then '2'
          when trdat = '00000000' then '0'
          else '3'
      end                                               as ActivityStatus,
      // === Added Analytical Fields ===

      // Logon Success Rate (assuming max = 5 failed attempts)
      cast ( (locnt / 5) as abap.dec(3,2)) as LogonSuccessRate,
      _log,
      _lockStatusValueHelp,
      _usrTypeValueHelp,
      _actStatValueHelp
}
