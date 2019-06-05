SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [SPORTAL].[usp_Q_SupplierShipmentsASNLines_ByASNRowID]
	@SupplierShipmentsASNRowID int
as
begin
	set nocount on

	declare 
		@ProcName nvarchar(100) = N'SPORTAL.usp_Q_ShipmentLinesASN_ByASNRowID'
	,	@CustomError as nvarchar(1000)

	begin try
		begin transaction

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
