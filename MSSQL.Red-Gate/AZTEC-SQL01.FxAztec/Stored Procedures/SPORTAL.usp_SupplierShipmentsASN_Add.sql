SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [SPORTAL].[usp_SupplierShipmentsASN_Add]
	@ShipperID varchar(50)
,	@Destination varchar(20)
,	@SupplierCode varchar(10)
,	@BOLNumber varchar(50)
,	@Part varchar(25)
,	@Quantity decimal(20,6)
as
begin
	set nocount on

	declare 
		@ProcName nvarchar(100) = N'SPORTAL.usp_SupplierShipmentsASN_Add'
	,	@CustomError as nvarchar(1000)


	begin try
		begin transaction

		-- Check for header record
		declare @RowID int = (
			select
				ssa.RowID 
			from 
				SPORTAL.SupplierShipmentsASN ssa 
			where 
				ssa.SupplierCode = @SupplierCode
				and ssa.ShipperID = @ShipperID );

		if (@RowID is null) begin 
		
			-- Create header
			insert into SPORTAL.SupplierShipmentsASN
				(ShipperID, SupplierCode, BOLNumber, Destination)
			values
				(@ShipperID, @SupplierCode, @BOLNumber, @Destination);

			set @RowID = scope_identity();
		end;


		-- Detail
		if exists (
				select
					*
				from
					SPORTAL.SupplierShipmentsASNLines ssal
				where
					ssal.SupplierShipmentsASNRowID = @RowID
					and ssal.Part = @Part ) begin

			-- Update
			update
				SPORTAL.SupplierShipmentsASNLines
			set
				Quantity = @Quantity
			where
				SupplierShipmentsASNRowID = @RowID
				and Part = @Part
		end
		else begin
			-- Insert
			insert into SPORTAL.SupplierShipmentsASNLines
				(SupplierShipmentsASNRowID, Part, Quantity)
			values
				(@RowID, @Part, @Quantity);
		end;

		commit transaction
	end try
	begin catch

		if @@trancount > 0 rollback transaction;
		throw;

	end catch

end
GO
