SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [SPORTAL].[usp_SupplierShipmentsASNLines_Add]
	@SupplierShipmentsASNRowID int
,	@Part varchar(25)
,	@Quantity decimal(20,6)
as
begin

	exec FxAztec_Temp.SPORTAL.usp_SupplierShipmentsASNLines_Add
		@SupplierShipmentsASNRowID = @SupplierShipmentsASNRowID
	,	@Part = @Part
	,	@Quantity = @Quantity

	return

	set nocount on

	declare 
		@ProcName nvarchar(100) = N'SPORTAL.usp_SupplierShipmentsASNLines_Add'
	,	@CustomError as nvarchar(1000)


	begin try
		begin transaction

		-- Update the line if it already exists, else insert
		if exists (
				select
					*
				from
					SPORTAL.SupplierShipmentsASNLines ssal
				where
					ssal.SupplierShipmentsASNRowID = @SupplierShipmentsASNRowID
					and ssal.Part = @Part ) begin

			-- Update line
			update
				SPORTAL.SupplierShipmentsASNLines
			set
				Quantity = @Quantity
			where
				SupplierShipmentsASNRowID = @SupplierShipmentsASNRowID
				and Part = @Part;

		end
		else begin

			-- Insert new line
			insert into SPORTAL.SupplierShipmentsASNLines
				(SupplierShipmentsASNRowID, Part, Quantity)
			values
				(@SupplierShipmentsASNRowID, @Part, @Quantity);

		end

		commit transaction
	end try
	begin catch

		if @@trancount > 0 rollback transaction;
		throw;

	end catch

end
GO
GRANT EXECUTE ON  [SPORTAL].[usp_SupplierShipmentsASNLines_Add] TO [SupplierPortal]
GO
