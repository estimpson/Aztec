SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[FormatDate]
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
		EDI_DICT.DictionaryDTFormats ddf
	where
		ddf.DictionaryVersion = coalesce
			(	(	select
						ddfR.DictionaryVersion
					from
						EDI_DICT.DictionaryDTFormats ddfR
					where
						ddfR.DictionaryVersion = @dictionaryVersion
						and ddfR.Type = 1
				)
			,	(	select
						max(ddfP.DictionaryVersion)
					from
						EDI_DICT.DictionaryDTFormats ddfP
					where
						ddfP.DictionaryVersion < @dictionaryVersion
						and ddfP.Type = 1
				)
			,	(	select
						min(ddfP.DictionaryVersion)
					from
						EDI_DICT.DictionaryDTFormats ddfP
					where
						ddfP.DictionaryVersion > @dictionaryVersion
						and ddfP.Type = 1
				)
			)
		and ddf.Type = 1

	set @dateString = EDI_XML.FormatDT(@dateFormat, @date)
--- </Body>

---	<Return>
	return
		@dateString
end
GO
