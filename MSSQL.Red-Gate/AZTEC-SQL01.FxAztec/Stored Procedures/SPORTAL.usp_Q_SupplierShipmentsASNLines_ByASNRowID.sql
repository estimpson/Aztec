SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [SPORTAL].[usp_Q_SupplierShipmentsASNLines_ByASNRowID]
	@SupplierShipmentsASNRowID int
as
begin

	exec FxAztec_Temp.SPORTAL.usp_Q_SupplierShipmentsASNLines_ByASNRowID
		@SupplierShipmentsASNRowID = @SupplierShipmentsASNRowID
	
	return

	set nocount on

	declare 
		@ProcName nvarchar(100) = N'SPORTAL.usp_Q_ShipmentLinesASN_ByASNRowID'
	,	@CustomError as nvarchar(1000)

	begin try
		begin transaction

		-- <Validation>
		-- If ASN shipper exists for the supplier, it cannot already be shipped
		declare
			@ShipperID varchar(50)
		,	@SupplierCode varchar(10)

		select
			@ShipperID = ssa.ShipperID
		,	@Suppliercode = ssa.SupplierCode
		from
			SPORTAL.SupplierShipmentsASN ssa
		where
			ssa.RowID = @SupplierShipmentsASNRowID
			and ssa.[Status] = 1 
			
		if (@shipperID is not null) begin
			select @CustomError = formatmessage('ShipperID %s for supplier %s has already been shipped.  Proc %s.', @ShipperID, @SupplierCode, @ProcName);
			throw 50000, @CustomError, 0;
		end;
		--</Validation>


		select
			ssal.Part as Part
		,	ssal.Quantity as Quantity
		,	ssal.RowID as LineID
		from
			SPORTAL.SupplierShipmentsASNLines ssal
			join SPORTAL.SupplierShipmentsASN ssa
				on ssa.RowID = ssal.SupplierShipmentsASNRowID
		where
			ssal.SupplierShipmentsASNRowID = @SupplierShipmentsASNRowID
		order by
			Part;

		commit transaction
	end try
	begin catch

		if @@trancount > 0 rollback transaction;
		throw;
	
	end catch
end
GO
GRANT EXECUTE ON  [SPORTAL].[usp_Q_SupplierShipmentsASNLines_ByASNRowID] TO [SupplierPortal]
GO
