SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_INFO]
(	@dictionaryVersion varchar(25)
,	@segmentCode varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
	/*	CE */
		(	select
				code = dsc.Code
			,	name = dsc.Description
			from
				EDI_DICT.DictionarySegmentCodes dsc
			where
				dsc.DictionaryVersion = coalesce
					(	(	select
						 		dscR.DictionaryVersion
						 	from
						 		EDI_DICT.DictionarySegmentCodes dscR
							where
								dscR.DictionaryVersion = @dictionaryVersion
								and dscR.Code = @segmentCode
						)
					,	(	select
						 		max(dscP.DictionaryVersion)
						 	from
						 		EDI_DICT.DictionarySegmentCodes dscP
							where
								dscP.DictionaryVersion < @dictionaryVersion
								and dscP.Code = @segmentCode
						)
					,	(	select
						 		min(dscP.DictionaryVersion)
						 	from
						 		EDI_DICT.DictionarySegmentCodes dscP
							where
								dscP.DictionaryVersion > @dictionaryVersion
								and dscP.Code = @segmentCode
						)
					)
				and dsc.Code = @segmentCode
			for xml raw ('SEG-INFO'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
