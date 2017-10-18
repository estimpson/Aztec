SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_Toyota_ASN].[LOOP_HL_OrderLines]
(	@ShipperID int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml = ''
	
	declare
		@ASNLines table
	(	ShipperID int
	,	ReturnableContainer varchar(20)
	,	SupplierCode varchar(20)
	,	CustomerPart varchar(30)
	,	ManifestNumber varchar(22)
	,	Quantity int
	)

	insert
		@ASNLines
	(	ShipperID
	,	ReturnableContainer
	,	SupplierCode
	,	CustomerPart
	,	ManifestNumber
	,	Quantity
	)
	select
		ShipperID = al.ShipperID
	,	ReturnableContainer = al.ReturnableContainer
	,	SupplierCode = al.SupplierCode
	,	CustomerPart = al.CustomerPart
	,	ManifestNumber = al.ManifestNumber
	,	Quantity = al.Quantity
	from
		EDI_XML_Toyota_ASN.ASNLines al
	where
		al.ShipperID = @ShipperID
	
	declare
		manifestHeaders cursor local for
	select distinct
		al.ReturnableContainer
	,	al.SupplierCode
	,	al.ManifestNumber
	from
		@ASNLines al

	open
		manifestHeaders

	declare
		@hl int = 1

	while
		1 =	1 begin

		declare
			@parentHL int

		declare
			@kanbanNumber varchar(20)
		,	@supplierCode varchar(20)
		,	@manifestNumber varchar(22)

		fetch
			manifestHeaders
		into
			@kanbanNumber
		,	@supplierCode
		,	@manifestNumber

		if	@@FETCH_STATUS != 0 begin
			break
		end

		set	@hl = @hl + 1

		set	@xmlOutput = convert(varchar(max), @xmlOutput)
			+ convert
			(	varchar(max)
			,	(	select
						EDI_XML.LOOP_INFO('HL')
					,	EDI_XML_V4010.SEG_HL(@hl, 1, 'O', 1)
					,	EDI_XML_V4010.SEG_PRF(@manifestNumber)
					,	EDI_XML_V4010.SEG_REF('MH', @ShipperID)
					,	(	select
					 			EDI_XML.LOOP_INFO('N1')
							,	EDI_XML_V4010.SEG_N1('SU', '92', @supplierCode)
					 		for xml raw ('LOOP-N1'), type
					 	)
					for xml raw ('LOOP-HL'), type
				)
			)

		declare
			manifestDetails cursor local for
		select
			al.CustomerPart
		,	al.Quantity
		from
			EDI_XML_Toyota_ASN.ASNLines al
		where
			al.ShipperID = @ShipperID
			and al.ManifestNumber = @manifestNumber

		open
			manifestDetails

		set	@parentHL = @hl			

		while
			1 = 1 begin

			declare
				@customerPart varchar(30)
			,	@quantity int

			fetch
				manifestDetails
			into
				@customerPart
			,	@quantity

			if	@@FETCH_STATUS != 0 begin
				break
			end

			set @hl = @hl + 1

			set	@xmlOutput = convert(varchar(max), @xmlOutput)
				+ convert
				(	varchar(max)
				,	(	select
							EDI_XML.LOOP_INFO('HL')
						,	EDI_XML_V4010.SEG_HL(@hl, @parentHL, 'I', 0)
						,	EDI_XML_V4010.SEG_LIN('001', 'BP', @customerPart, 'RC', @kanbanNumber)
						,	EDI_XML_V4010.SEG_SN1(null, @quantity, 'EA', null)
						for xml raw ('LOOP-HL'), type
					)
				)
		end
		close
			manifestDetails
		deallocate
			manifestDetails
	end
	close
		manifestHeaders
	deallocate
		manifestHeaders
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
