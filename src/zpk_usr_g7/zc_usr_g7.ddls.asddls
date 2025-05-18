@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'User BO projection view'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@Search.searchable: true
@Metadata.allowExtensions: true

define view entity ZC_USR_G7
  as select from ZI_USR_G7 as User
  //    left outer join t247      as date_information on date_information.spras = $session.system_language
{
  key User.Username,
      User.ValidFrom,
      User.ValidTo,
      User.Type,
      User.NoFailedLogonAttempts,
      @Aggregation.default: #COUNT_DISTINCT
      User.LockStatus,
      User.LockReason,
      User.LockCriticality,
      User.AccountId,
      User.LastLogonDate,
      User.LastLogonTime,
      User.UserTimezone,
      User.Address,
      User.LockDate,
      User._log,
      User._lockStatusValueHelp,
      @Aggregation.default: #SUM
      @EndUserText.label: 'Active User(s)'
      User.UniqueUserCount,
      @Aggregation.default: #SUM
      @EndUserText.label: 'User(s)'
      User.UserCount,
      //      concat_with_space ( SUBSTRING (User.LastLogonDate,1,4),  date_information.ltx, 1 ) as Date_YearMonth //YearMonth(YYYYMM)
      User.DaysSinceInactive,
      @ObjectModel.text.element: ['ActStatText']
      User.ActivityStatus,
      @Semantics.calendar.yearMonth: true
      @EndUserText.label: 'Month'
      User.YearMonth,
      @Semantics.text: true
      User._actStatValueHelp.ActStatText as ActStatText,
      User.LogonSuccessRate
}
//where
//  date_information.mnr = substring(User.LastLogonDate, 5, 2);
