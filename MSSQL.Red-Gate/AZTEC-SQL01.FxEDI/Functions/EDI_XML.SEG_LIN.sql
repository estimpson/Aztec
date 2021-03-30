SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_LIN]
(	@DictionaryVersion varchar(25)
,	@AssignedId varchar(20)
,	@IdQualifierCodeList varchar(max)
,	@IdCodeList varchar(max)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	declare
		@idCodes table
	(	idQualifierCode char(2)
	,	idCode varchar(80)
	)
	insert
		@idCodes
	(	idQualifierCode
	,	idCode
	)
	select
		idQualifierCode = idQC.Value
	,	idCode = idc.Value
	from
		FXSYS.fn_SplitStringToRows(@IdQualifierCodeList, ',') idQC
		join FXSYS.fn_SplitStringToRows(@IdCodeList, ',') idC
			on idC.ID = idqc.ID

	declare
		@DE varchar(max) = ''

	select
		@DE += convert(varchar(max), EDI_XML.DE(@dictionaryVersion, '0235', ic.idQualifierCode))
			+ convert(varchar(max), EDI_XML.DE(@DictionaryVersion, '0234', ic.idCode))
	from
		@idCodes ic

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'LIN')
			,	EDI_XML.DE(@dictionaryVersion, '0350', @AssignedId)
			,	convert(xml, @DE)
			for xml raw ('SEG-LIN'), type
		)

--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
