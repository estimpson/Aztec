
/*
Create ScalarFunction.FxAztec.EDI_XML.CE.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.CE'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.CE
end
go

create function EDI_XML.CE
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
				fxEDI.EDI_DICT.DictionaryElements de
			where
				de.DictionaryVersion = coalesce
					(	(	select
					 			deR.DictionaryVersion
					 		from
					 			fxEDI.EDI_DICT.DictionaryElements deR
							where
								deR.DictionaryVersion = @dictionaryVersion
								and deR.ElementCode = @elementCode
					 	)
					,	(	select
					 			max(deP.DictionaryVersion)
					 		from
					 			fxEDI.EDI_DICT.DictionaryElements deP
							where
								deP.DictionaryVersion < @dictionaryVersion
								and deP.ElementCode = @elementCode
					 	)
					,	(	select
					 			min(deP.DictionaryVersion)
					 		from
					 			fxEDI.EDI_DICT.DictionaryElements deP
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
go

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.DictionaryVersion = '004010'
	and de.ElementCode = 'C001'

select
	*
from
	fxEDI.EDI_DICT.DictionaryElementValueCodes devc
where
	devc.DictionaryVersion = '004010'
	and devc.ElementCode = '0355'
	and devc.ValueCode = 'LB'

select
	EDI_XML.CE('004010', 'C001', EDI_XML.DE('004010', '0355', 'LB'))

select
	EDI_XML.CE('004010', 'C001', null)

select
	EDI_XML.DE('004010', '0355', 'LB')

select
	code = de.ElementCode
,	name = de.ElementName
/*	DE(s)*/
,	null
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.DictionaryVersion = coalesce
		(	(	select
					deR.DictionaryVersion
				from
					fxEDI.EDI_DICT.DictionaryElements deR
				where
					deR.DictionaryVersion = '004010'
					and deR.ElementCode = 'C001'
			)
		,	(	select
					max(deP.DictionaryVersion)
				from
					fxEDI.EDI_DICT.DictionaryElements deP
				where
					deP.DictionaryVersion < '004010'
					and deP.ElementCode = 'C001'
			)
		,	(	select
					min(deP.DictionaryVersion)
				from
					fxEDI.EDI_DICT.DictionaryElements deP
				where
					deP.DictionaryVersion > '004010'
					and deP.ElementCode = 'C001'
			)
		)
	and de.ElementCode = 'C001'