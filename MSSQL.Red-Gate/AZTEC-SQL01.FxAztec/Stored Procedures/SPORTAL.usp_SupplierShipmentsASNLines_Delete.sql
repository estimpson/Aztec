SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [SPORTAL].[usp_SupplierShipmentsASNLines_Delete]
	@SupplierShipmentsASNRowID int
,	@LineID int	
as
begin

	set nocount on

	begin try
		begin transaction

		delete from
			SPORTAL.SupplierShipmentsASNLines
		where
			SupplierShipmentsASNRowID = @SupplierShipmentsASNRowID
			and RowID = @LineID

		commit transaction
	end try
	begin catch

		if @@trancount > 0 rollback transaction;
		throw;

	end catch

end
GO
GRANT EXECUTE ON  [SPORTAL].[usp_SupplierShipmentsASNLines_Delete] TO [SupplierPortal]
GO
