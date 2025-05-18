@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value help for User type'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity ZI_USRTYP_VH_G7
  as select from ztbl_usrtyp_vh as usrtyp_vh
{
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'UstypText' ]
      @EndUserText.label: 'User type key for fixed value'
  key case ustyp
          when 'A' then 'A'
          when 'B' then 'B'
          when 'C' then 'C'
          when 'L' then 'L'
          else 'S'
      end        as Ustyp,
      @EndUserText.label: 'User type description for fixed value'
      ustyp_text as UstypText
}
