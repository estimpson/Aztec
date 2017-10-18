
/*
Create ScalarFunction.FxAztec.EDI_XML.FormatTime.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.FormatTime'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.FormatTime
end
go

create function EDI_XML.FormatTime
(	@dictionaryVersion varchar(25)
,	@time time
)
returns varchar(12)
as
begin
--- <Body>
	declare
		@timeString varchar(12)
	,	@timeFormat varchar(12)

	select
		@timeFormat = ddf.FormatString
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
						and ddfR.Type = 2
				)
			,	(	select
						max(ddfP.DictionaryVersion)
					from
						FxEDI.EDI_DICT.DictionaryDTFormat ddfP
					where
						ddfP.DictionaryVersion < @dictionaryVersion
						and ddfP.Type = 2
				)
			,	(	select
						min(ddfP.DictionaryVersion)
					from
						FxEDI.EDI_DICT.DictionaryDTFormat ddfP
					where
						ddfP.DictionaryVersion > @dictionaryVersion
						and ddfP.Type = 2
				)
			)
		and ddf.Type = 2

	set @timeString = EDI.udf_FormatDT(@timeFormat, @time)
--- </Body>

---	<Return>
	return
		@timeString
end
go

select
	EDI_XML.FormatTime('002040', getdate())
