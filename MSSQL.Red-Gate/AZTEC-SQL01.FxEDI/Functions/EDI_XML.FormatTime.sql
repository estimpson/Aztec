SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[FormatTime]
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
		EDI_DICT.DictionaryDTFormats ddf
	where
		ddf.DictionaryVersion = coalesce
			(	(	select
						ddfR.DictionaryVersion
					from
						EDI_DICT.DictionaryDTFormats ddfR
					where
						ddfR.DictionaryVersion = @dictionaryVersion
						and ddfR.Type = 2
				)
			,	(	select
						max(ddfP.DictionaryVersion)
					from
						EDI_DICT.DictionaryDTFormats ddfP
					where
						ddfP.DictionaryVersion < @dictionaryVersion
						and ddfP.Type = 2
				)
			,	(	select
						min(ddfP.DictionaryVersion)
					from
						EDI_DICT.DictionaryDTFormats ddfP
					where
						ddfP.DictionaryVersion > @dictionaryVersion
						and ddfP.Type = 2
				)
			)
		and ddf.Type = 2

	set @timeString = EDI_XML.FormatDT(@timeFormat, @time)
--- </Body>

---	<Return>
	return
		@timeString
end
GO
