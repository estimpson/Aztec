SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [SPORTAL].[usp_Q_BOLNumberDestination_BySupplierAndShipperID]
	@SupplierCode varchar(10)
,	@ShipperID varchar(50)
as
begin
	set nocount on

	declare 
		@ProcName nvarchar(100) = N'SPORTAL.usp_Q_BOLNumberDestination_BySupplierAndShipperID'
	,	@CustomError as nvarchar(1000)


	begin try
		begin transaction

		-- <Validation>
		-- If ShipperID exists for the supplier, it cannot already be shipped
		if exists (
				select
					*
				from
					SPORTAL.SupplierShipmentsASN ssa
				where
					ssa.SupplierCode = @SupplierCode
					and ssa.ShipperID = @ShipperID
					and ssa.[Status] = 1 ) begin

			select @CustomError = formatmessage('ShipperID %s for supplier %s has already been shipped.  Proc %s.', @ShipperID, @SupplierCode, @ProcName);
			throw 50000, @CustomError, 0;
		end;
		--</Validation>
		

		select
			ssa.BOLNumber
		,	ssa.Destination
		from
			SPORTAL.SupplierShipmentsASN ssa
		where
			ssa.SupplierCode = @SupplierCode
			and ssa.ShipperID = @ShipperID;

		commit transaction
	end try
	begin catch

		if @@trancount > 0 rollback transaction;
		throw;
	
	end catch
end
GO
