SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [SPORTAL].[usp_SupplierShipmentsASNLines_Delete]
	@SupplierShipmentsASNRowID int	
,	@Part varchar(25)
,	@Quantity decimal(20,6)
as
begin
	set nocount on

	begin try
		begin transaction

		delete from
			SPORTAL.SupplierShipmentsASNLines
		where
			SupplierShipmentsASNRowID = @SupplierShipmentsASNRowID
			and Part = @Part
			and @Quantity = @Quantity;

		commit transaction
	end try
	begin catch

		if @@trancount > 0 rollback transaction;
		throw;

	end catch

end
GO
