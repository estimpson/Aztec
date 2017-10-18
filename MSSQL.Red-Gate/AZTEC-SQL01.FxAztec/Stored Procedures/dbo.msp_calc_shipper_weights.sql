SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[msp_calc_shipper_weights] @shipper int
AS
BEGIN

	DECLARE	@tare_weight	numeric(20,6),
		@net_weight		numeric(20,6),
		@gross_weight	numeric(20,6),
		@part			varchar(35),
		@part_original	varchar(25),
		@suffix			integer,
		@pallet_tare	numeric(20,6),
		
		--Andre S. Boulanger - Added for Aztec 2013-06-13 .Destination AF52MP025A should not calc weights
		@destination varchar(25)

		Select	@destination = 'AF52MP025A'
	

	select	@part = min(part)
	from	shipper_detail
	where	shipper = @shipper

	select	@part = isnull(@part,'')

	while ( @part > '' )
	begin

		select	@part_original = part_original,
			@suffix = suffix
		from	shipper_detail
		where	shipper = @shipper and
			part = @part

		if isnull(@suffix,0) > 0
		begin
			SELECT	@net_weight = sum ( isnull(object.weight,0) )
			FROM	object
			WHERE	object.shipper = @shipper AND
				object.part = @part_original AND
				object.suffix = @suffix

			SELECT	@tare_weight = sum ( isnull ( pm.weight, 0 ) )
			FROM	object as o,
				package_materials as pm
			WHERE 	o.package_type = pm.code AND
				o.shipper = @shipper AND
				o.part = @part_original AND
				o.suffix = @suffix
		end
		else
		begin
			SELECT	@net_weight = sum ( IsNull ( object.weight, 0 ) )
			FROM	object
			WHERE	object.shipper = @shipper AND
				object.part = @part

			SELECT	@tare_weight = sum ( isnull ( pm.weight, 0 ) )
			FROM	object o,
				package_materials pm
			WHERE 	o.package_type = pm.code AND
				o.shipper = @shipper AND
				o.part = @part
		end

		select 	@tare_weight = isnull(@tare_weight,0),
			@net_weight = isnull(@net_weight,0),
			@gross_weight = isnull(@tare_weight,0) + isnull(@net_weight,0)

		update 	shipper_detail set
			net_weight = @net_weight,
			tare_weight = @tare_weight,
			gross_weight = @gross_weight
		where 	shipper = @shipper and
			part = @part

		select	@part = min(part)
		from	shipper_detail
		where	shipper = @shipper and
			part > @part
	
		select	@part = isnull(@part,'')
	end

	SELECT	@pallet_tare = isnull ( sum ( o.tare_weight ), 0 )
	FROM	object as o
	WHERE 	o.shipper = @shipper and
		type = 'S'
		
	select	@tare_weight = sum (sd.tare_weight) + @pallet_tare,
		@net_weight = sum (sd.net_weight),
		@gross_weight = sum (sd.gross_weight) + @pallet_tare
	from	shipper_detail sd
	where	sd.shipper = @shipper

	select	@tare_weight = isnull(@tare_weight,0),
		@net_weight = isnull(@net_weight,0),
		@gross_weight = isnull(@gross_weight,0)

	UPDATE	shipper
	SET	shipper.tare_weight = @tare_weight,
		shipper.net_weight = @net_weight,
		shipper.gross_weight = @gross_weight
	WHERE	shipper.id = @shipper and
				shipper.destination != @destination --Andre S. Boulanger - Added for Aztec 2013-06-13 .Destination AF52MP025A should not calc weights

END

GO
