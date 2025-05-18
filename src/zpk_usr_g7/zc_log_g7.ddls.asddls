@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Analytics.dataCategory: #CUBE
@EndUserText.label: 'Log BO projection view'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZC_LOG_G7
  as select from ZI_LOG_G7
{
  key Id,
  key Bname,
      ActionType,
      Timestamp,
      AdminUser,
      Report,
      Sysid,
      Spras,
      @Aggregation.default: #SUM
      LogCount,
      LogDate
}
