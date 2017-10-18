alter trigger dbo.mtr_object_u ON [dbo].[object]
FOR UPDATE
AS
set nocount on
set ansi_warnings off
BEGIN
-----------------------------------------------------------------------------------------------
--	Modifications	09/06/02, HGP	Commented out the object update st. to over come 
--					recurrsive trigger problem.
-----------------------------------------------------------------------------------------------
		      
	DECLARE	@update_shipper		int,
		@net_weight		numeric(20,6),
		@tare_weight		numeric(20,6),
		@old_shipper		int,
		@type			varchar(1),
		@part			varchar(25),
		@package_type		varchar(25),
		@std_qty		numeric(20,6),
		@serial			int,
		@shipper		int,
		@weight			numeric(20,6),
		@calc_weight		numeric(20,6),
		@unit_weight		numeric(20,6)

	DECLARE	recs CURSOR FOR
		SELECT	type,
			part,
			package_type,
			std_quantity,
			serial,
			shipper,
			weight
		FROM	inserted

	OPEN recs

	FETCH recs INTO @type,
			@part,
			@package_type,
			@std_qty,
			@serial,
			@shipper,
                	@weight
	
	WHILE @@fetch_status = 0
	BEGIN

		SELECT	@old_shipper		= shipper
		FROM	deleted
		WHERE	serial = @serial
/*
		if Update ( shipper )
		begin
			if @shipper > 0
			begin
				update	object
				set	object.destination = shipper.destination
				from	shipper
				where	serial = @serial and
					object.shipper = shipper.id
			end
			else
				update	object
				set	destination = ''
				where	serial = @serial
		end
*/		
		IF @type IS NULL -- normal object or pallet 
		BEGIN
                  -- weight is from scale or not    
			IF IsNull ( (	SELECT	part_packaging.serial_type
					FROM	part_packaging
					WHERE	part = @part AND
						code = @package_type ), '(None)' ) = '(None)'
			BEGIN
                        -- calculate the weight only when the qty or std qty differs & deleted 
                        -- weight is same as the inserted wt. or when the inserted wt. is null 
				IF ( Update ( std_quantity ) or Update ( part ) ) and ( NOT Update ( weight ) or @weight IS NULL)
				BEGIN
					SELECT	@unit_weight = IsNull ( unit_weight, 0 )
					FROM	part_inventory
					WHERE	part_inventory.part = @part

					SELECT	@calc_weight = @unit_weight * @std_qty
/*
					UPDATE	object
					SET	object.weight = isnull(@calc_weight,0)
					WHERE	object.serial = @serial
*/					
				END

				SELECT @update_shipper = 1

			END

			ELSE

				SELECT @update_shipper = 1

			IF @shipper > 0 AND @update_shipper = 1

				IF @old_shipper > 0 AND Update ( shipper )
				BEGIN

					execute msp_calc_shipper_weights @shipper

					execute msp_calc_shipper_weights @old_shipper

				END
				ELSE

					execute msp_calc_shipper_weights @shipper

			ELSE IF @old_shipper > 0 AND @update_shipper = 1

				execute msp_calc_shipper_weights @old_shipper

		END
		ELSE

			IF Update ( package_type ) AND @shipper > 0
				execute msp_calc_shipper_weights @shipper

		FETCH recs INTO @type,
				@part,
				@package_type,
				@std_qty,
				@serial,
				@shipper,
				@weight

	END

	CLOSE recs

	DEALLOCATE recs

END
GO
