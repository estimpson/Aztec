
/*
Create ScalarFunction.FxAztec.EDI_XML.FormatDate.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.FormatDate'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.FormatDate
end
go

create function EDI_XML.FormatDate
(	@dictionaryVersion varchar(25)
,	@date date
)
returns varchar(12)
as
begin
--- <Body>
	declare
		@dateString varchar(12)
	,	@dateFormat varchar(12)

	select
		@dateFormat = ddf.FormatString
	from
		FxEDI.EDI_DICT.DictionaryDTFormat ddf
	where
		ddf.DictionaryVersion = coalesce
			(	(	select
						ddfR.DictionaryVersion
					from
						FxEDI.EDI_DICT.DictionaryDTFormat ddfR
					where
						ddfR.DictionaryVersion = @dictionaryVersion
						and ddfR.Type = 1
				)
			,	(	select
						max(ddfP.DictionaryVersion)
					from
						FxEDI.EDI_DICT.DictionaryDTFormat ddfP
					where
						ddfP.DictionaryVersion < @dictionaryVersion
						and ddfP.Type = 1
				)
			,	(	select
						min(ddfP.DictionaryVersion)
					from
						FxEDI.EDI_DICT.DictionaryDTFormat ddfP
					where
						ddfP.DictionaryVersion > @dictionaryVersion
						and ddfP.Type = 1
				)
			)
		and ddf.Type = 1

	set @dateString = EDI.udf_FormatDT(@dateFormat, @date)
--- </Body>

---	<Return>
	return
		@dateString
end
go

select
	EDI_XML.FormatDate('002040', getdate())
