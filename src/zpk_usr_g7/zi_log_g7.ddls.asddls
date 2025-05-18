@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Log view'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZI_LOG_G7
  as select from ztb_log_acm
{
  key id                                                                    as Id,
  key bname                                                                 as Bname,
      action_type                                                           as ActionType,
      timestamp                                                             as Timestamp,
      admin_user                                                            as AdminUser,
      report                                                                as Report,
      sysid                                                                 as Sysid,
      spras                                                                 as Spras,
      cast (1 as abap.int4)                                                 as LogCount,
      cast(substring (cast(timestamp as abap.char(17)), 1, 7) as abap.dats) as LogDate
}
