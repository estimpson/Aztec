SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[CE]

(	@dictionaryVersion varchar(25)
,	@elementCode char(4)
,	@de xml
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@elementCode = right('0000' + ltrim(rtrim(@elementCode)), 4)

	set	@xmlOutput =
	/*	CE */
		(	select
				code = de.ElementCode
			,	name = de.ElementName
			/*	DE(s)*/
			,	@de
			from
				EDI_DICT.DictionaryElements de
			where
				de.DictionaryVersion = coalesce
					(	(	select
					 			deR.DictionaryVersion
					 		from
					 			EDI_DICT.DictionaryElements deR
							where
								deR.DictionaryVersion = @dictionaryVersion
								and deR.ElementCode = @elementCode
					 	)
					,	(	select
					 			max(deP.DictionaryVersion)
					 		from
					 			EDI_DICT.DictionaryElements deP
							where
								deP.DictionaryVersion < @dictionaryVersion
								and deP.ElementCode = @elementCode
					 	)
					,	(	select
					 			min(deP.DictionaryVersion)
					 		from
					 			EDI_DICT.DictionaryElements deP
							where
								deP.DictionaryVersion > @dictionaryVersion
								and deP.ElementCode = @elementCode
					 	)
					)
				and de.ElementCode = @elementCode
			for xml raw ('CE'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
