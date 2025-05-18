@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value help for Lock Status'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity ZI_ACTSTAT_VH_G7
  as select from ztb_actstat_vh as actstat_vh
{
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'ActStatText' ]
      @EndUserText.label: 'Status key for fixed value'
  key act_key as ActStat,
      @EndUserText.label: 'Status description for fixed value'
      activity_text as ActStatText
}
