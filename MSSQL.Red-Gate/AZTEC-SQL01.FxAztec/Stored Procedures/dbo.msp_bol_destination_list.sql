SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_bol_destination_list] ( @shipper integer )
as
begin
	-- declare local variables
	declare @bol_number	integer,
		@destination	varchar(20),
		@count		integer
	
	-- get bill of lading number and destination from the passed shipper
	select	@bol_number = isnull ( bill_of_lading_number, 0 ),
		@destination = destination
	from	shipper
	where	id = @shipper
	
	-- is there already a bill of lading?
	if @bol_number > 0
	begin
		-- get the number of shippers on bol that have destinations different from passed shipper
		select	@count = count(id)
		from	shipper
		where	destination <> @destination and
			bill_of_lading_number = @bol_number

		-- if there is more that 1, return pool_code and editable flag of 0 (FALSE)
		if @count > 0
			select	edi_setups.pool_code code, 
				destination.name name,
				0 editable
			from	edi_setups,
				destination 
			where	destination.destination = edi_setups.pool_code and
				edi_setups.destination=@destination 
			order by code
		-- otherwise, return destination / pool_code and editable flag of 1 (TRUE)
		else
			select	edi_setups.pool_code code, 
				destination.name name,
				1 editable
			from	edi_setups,
				destination 
			where	destination.destination = edi_setups.pool_code and
				edi_setups.destination=@destination 
			UNION  
			select	destination code,
				name,
				1 editable
			from 	destination
			where 	destination.destination = @destination 
			order by code
	end
	else
	-- return destination / pool_code and editable flag of 1 (TRUE)
	begin
		select	edi_setups.pool_code code, 
			destination.name name,
			1 editable
		from	edi_setups,
			destination 
		where	destination.destination = edi_setups.pool_code and
			edi_setups.destination=@destination 
		UNION  
		select	destination code,
			name,
			1 editable
		from 	destination
		where 	destination.destination = @destination 
		order by code
	end
end
GO
