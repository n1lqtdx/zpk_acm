@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value help for Lock Status'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity ZI_LOCKSTAT_VH_G7
  as select from ztbl_lockstat_vh as lockstat_vh
{
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'UflagText' ]
      @EndUserText.label: 'Status key for fixed value'
  key uflag      as Uflag,
      @EndUserText.label: 'Status description for fixed value'
      uflag_text as UflagText
}
