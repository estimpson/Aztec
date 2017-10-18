
/*
Create ScalarFunction.FxAztec.EDI_XML_Chrysler_ASN.LOOP_HL_OrderLines.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Chrysler_ASN.LOOP_HL_OrderLines'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_Chrysler_ASN.LOOP_HL_OrderLines
end
go

create function EDI_XML_Chrysler_ASN.LOOP_HL_OrderLines
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
	(	PackingSlip varchar(25)
	,	CustomerPart varchar(35)
	,	ECL varchar(25)
	,	BoxType varchar(25)
	,	BoxCount int
	,	PalletType varchar(25)
	,	PalletCount int
	,	QtyPacked int
	,	AccumShipped int
	,	PONumber varchar(20)
	,	DockCode varchar(10)
	,	ShipTo varchar(20)
	,	ACIndicator char(1)
	,	ACHandler char(2)
	,	ACClause char(3)
	,	ACCharge numeric(20,6)
	)

	insert
		@ASNLines
	(	PackingSlip
	,	CustomerPart
	,	ECL
	,	BoxType
	,	BoxCount
	,	PalletType
	,	PalletCount
	,	QtyPacked
	,	AccumShipped
	,	PONumber
	,	DockCode
	,	ShipTo
	,	ACIndicator
	,	ACHandler
	,	ACClause
	,	ACCharge
	)
	select
		al.PackingSlip
	,	al.CustomerPart
	,	al.ECL
	,	al.BoxType
	,	al.BoxCount
	,	al.PalletType
	,	al.PalletCount
	,	al.QtyPacked
	,	al.AccumShipped
	,	al.PONumber
	,	al.DockCode
	,	al.ShipTo
	,	al.ACIndicator
	,	al.ACHandler
	,	al.ACClause
	,	al.ACCharge
	from
		EDI_XML_Chrysler_ASN.ASNLines(@ShipperID) al
	
	declare
		orderLines cursor local for
	select
		al.PackingSlip
	,	al.CustomerPart
	,	al.ECL
	,	al.BoxType
	,	al.BoxCount
	,	al.PalletType
	,	al.PalletCount
	,	al.QtyPacked
	,	al.AccumShipped
	,	al.PONumber
	,	al.DockCode
	,	al.ShipTo
	,	al.ACIndicator
	,	al.ACHandler
	,	al.ACClause
	,	al.ACCharge
	from
		@ASNLines al

	open
		orderLines

	declare
		@hl int = 1

	while
		1 =	1 begin

		declare
			@packingSlip varchar(25)
		,	@customerPart varchar(35)
		,	@ecl varchar(25)
		,	@boxType varchar(25)
		,	@boxCount int
		,	@palletType varchar(25)
		,	@palletCount int
		,	@qtyPacked int
		,	@accumShipped int
		,	@poNumber varchar(20)
		,	@dockCode varchar(10)
		,	@shipTo varchar(20)
		,	@acIndicator char(1)
		,	@acHandler char(2)
		,	@acClause char(3)
		,	@acCharge numeric(20,6)

		fetch
			orderLines
		into
			@packingSlip
		,	@customerPart
		,	@ecl
		,	@boxType
		,	@boxCount
		,	@palletType
		,	@palletCount
		,	@qtyPacked
		,	@accumShipped
		,	@poNumber
		,	@dockCode
		,	@shipTo
		,	@acIndicator
		,	@acHandler
		,	@acClause
		,	@acCharge

		if	@@FETCH_STATUS != 0 begin
			break
		end

		set	@hl = @hl + 1

		set	@xmlOutput = convert(varchar(max), @xmlOutput)
			+ convert
			(	varchar(max)
			,	(	select
						EDI_XML.LOOP_INFO('HL')
					,	EDI_XML_V2040.SEG_HL(@hl, 1, 'O', 0)
					,	EDI_XML_Chrysler_ASN.SEG_LIN('BP', @customerPart, 'EC', @ecl, 'RC', @boxType)
					,	EDI_XML_V2040.SEG_SN1(null, @qtyPacked, 'EA', @accumShipped)
					,	EDI_XML_V2040.SEG_PRF(@poNumber)
					,	EDI_XML_V2040.SEG_REF('BM', @ShipperID)
					,	EDI_XML_V2040.SEG_REF('PK', @packingSlip)
					,	case when @acClause = '092' and @acCharge > 0 then EDI_XML_Chrysler_ASN.SEG_ITA092(@acCharge) end
					for xml raw ('LOOP-HL'), type
				)
			)

		set	@hl = @hl + 1

		set	@xmlOutput = convert(varchar(max), @xmlOutput)
			+ convert
			(	varchar(max)
			,	(	select
						EDI_XML.LOOP_INFO('HL')
					,	EDI_XML_V2040.SEG_HL(@hl, 1, 'O', 0)
					,	EDI_XML_V2040.SEG_LIN('RC', dbo.fn_SplitStringToArray(@boxType, '~', 1))
					,	EDI_XML_V2040.SEG_SN1(null, @boxCount, 'EA', @boxCount)
					,	EDI_XML_V2040.SEG_PRF(1)
					,	EDI_XML_V2040.SEG_REF('PK', @packingSlip)
					for xml raw ('LOOP-HL'), type
				)
			)

		if	@palletCount > 0 begin
			if	(	select
			  			count(*)
			  		from
			  			dbo.fn_SplitStringToRows(@palletType, '~')
			  	) > 1 begin

				set	@hl = @hl + 1

				set	@xmlOutput = convert(varchar(max), @xmlOutput)
					+ convert
					(	varchar(max)
					,	(	select
								EDI_XML.LOOP_INFO('HL')
							,	EDI_XML_V2040.SEG_HL(@hl, 1, 'O', 0)
							,	EDI_XML_V2040.SEG_LIN('RC', dbo.fn_SplitStringToArray(@palletType, '~', 1))
							,	EDI_XML_V2040.SEG_SN1(null, @palletCount, 'EA', @palletCount)
							,	EDI_XML_V2040.SEG_PRF(1)
							,	EDI_XML_V2040.SEG_REF('PK', @packingSlip)
							for xml raw ('LOOP-HL'), type
						)
					)

				set	@hl = @hl + 1

				set	@xmlOutput = convert(varchar(max), @xmlOutput)
					+ convert
					(	varchar(max)
					,	(	select
								EDI_XML.LOOP_INFO('HL')
							,	EDI_XML_V2040.SEG_HL(@hl, 1, 'O', 0)
							,	EDI_XML_V2040.SEG_LIN('RC', dbo.fn_SplitStringToArray(@palletType, '~', 2))
							,	EDI_XML_V2040.SEG_SN1(null, @palletCount, 'EA', @palletCount)
							,	EDI_XML_V2040.SEG_PRF(1)
							,	EDI_XML_V2040.SEG_REF('PK', @packingSlip)
							for xml raw ('LOOP-HL'), type
						)
					)
			end
			else begin

				set	@hl = @hl + 1

				set	@xmlOutput = convert(varchar(max), @xmlOutput)
					+ convert
					(	varchar(max)
					,	(	select
								EDI_XML.LOOP_INFO('HL')
							,	EDI_XML_V2040.SEG_HL(@hl, 1, 'O', 0)
							,	EDI_XML_V2040.SEG_LIN('RC', @palletType)
							,	EDI_XML_V2040.SEG_SN1(null, @palletCount, 'EA', @palletCount)
							,	EDI_XML_V2040.SEG_PRF(1)
							,	EDI_XML_V2040.SEG_REF('PK', @packingSlip)
							for xml raw ('LOOP-HL'), type
						)
					)

			end
		end
	end
	close
		orderLines
	deallocate
		orderLines
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_Chrysler_ASN.LOOP_HL_OrderLines(76031)
return
go

