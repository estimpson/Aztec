SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [SPORTAL].[usp_SupplierShipmentsASN_Add]
	@ShipperID varchar(50)
,	@Destination varchar(20)
,	@SupplierCode varchar(10)
,	@BOLNumber varchar(50)
,	@DateShipped datetime2
,	@RowID int = null out
as
begin

	set nocount on

	declare 
		@ProcName nvarchar(100) = N'SPORTAL.usp_SupplierShipmentsASN_Add'
	,	@CustomError as nvarchar(1000)


	begin try
		begin transaction

		-- Check for header record
		select
			@RowID = ssa.RowID 
		from 
			SPORTAL.SupplierShipmentsASN ssa 
		where 
			ssa.SupplierCode = @SupplierCode
			and ssa.ShipperID = @ShipperID;


		if (@RowID is null) begin 
		
			-- Create header
			insert into SPORTAL.SupplierShipmentsASN
				(ShipperID, SupplierCode, BOLNumber, Destination)
			values
				(@ShipperID, @SupplierCode, @BOLNumber, @Destination);

			set @RowID = scope_identity();

		end
		else begin

			-- <Validation>
			-- Make sure the ASN has not already been sent
			if exists (
					select
						*
					from
						SPORTAL.SupplierShipmentsASN ssa
					where
						ssa.RowID = @RowID
						and ssa.[Status] = 1 ) begin

				select @CustomError = formatmessage('The ASN for Shipper ID %s has already been sent.  Proc %s.', @ShipperID, @ProcName);
				throw 50000, @CustomError, 0;
			end;
			-- </Validation>


			-- If the destination is changing, delete any lines
			if not exists ( 
					select
						*
					from
						SPORTAL.SupplierShipmentsASN ssa 
					where
						ssa.RowID = @RowID
						and ssa.Destination = @Destination ) begin

				-- Delete lines
				delete from
					SPORTAL.SupplierShipmentsASNLines
				where
					SupplierShipmentsASNRowID = @RowID;

			end
	
			-- Update header
			update
				SPORTAL.SupplierShipmentsASN
			set
				BOLNumber = @BOLNumber
			,	ShippedDate = @DateShipped
			,	Destination = @Destination
			where
				RowID = @RowID;

		end

		commit transaction
	end try
	begin catch

		if @@trancount > 0 rollback transaction;
		throw;

	end catch

end
GO
GRANT EXECUTE ON  [SPORTAL].[usp_SupplierShipmentsASN_Add] TO [SupplierPortal]
GO
