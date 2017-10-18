
/*
Create ScalarFunction.FxAztec.EDI_XML.DE.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.DE'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.DE
end
go

create function EDI_XML.DE
(	@dictionaryVersion varchar(25)
,	@elementCode char(4)
,	@value varchar(max)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@elementCode = right('0000' + ltrim(rtrim(@elementCode)), 4)

	set	@xmlOutput =
	/*	DE */
		(	select
				Tag = 1
			,	Parent = null
			,	[DE!1!code] = rtrim(@elementCode)
			,	[DE!1!name] = coalesce(de.ElementName, '')
			,	[DE!1!type] = case when de.ElementDataType = 'ID' and devc.Description is null then 'AN' else coalesce(de.ElementDataType, '') end
			,	[DE!1!desc] = devc.Description
			,	[DE!1] = @value
			from
				(	select
						'' dummy
				) dummy
				left join fxEDI.EDI_DICT.DictionaryElements de
					on de.DictionaryVersion = coalesce
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
				left join fxEDI.EDI_DICT.DictionaryElementValueCodes devc
					on devc.DictionaryVersion = @dictionaryVersion
					and devc.ElementCode = @elementCode
					and devc.ValueCode = @value
					and de.ElementDataType = 'ID'
			for xml explicit, type
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
	de.DictionaryVersion = '002002FORD'
	and de.ElementCode = '0353'

select
	*
from
	fxEDI.EDI_DICT.DictionaryElementValueCodes devc
where
	devc.DictionaryVersion = '002002FORD'
	and devc.ElementCode = '0353'
	and devc.ValueCode = '00'

select
	EDI_XML.DE('002002FORD', '353', '00')