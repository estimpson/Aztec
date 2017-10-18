SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_shipping_dock_objects_list]
(	@shipper integer )
as
------------------------------------------------------------------------------------------------------------------------------------------------------------------
--	This procedure returns the list of objects available for all the parts on shipper.
--
--	Modifications:	22 SEP 1998, Chris Rogers	Original.
--			19 FEB 1999, Eric E. Stimpson	Rewrote for performance.
--			05 AUG 1999, Mamatha Bettareger	Included configurable column to the select statement.
--			02 OCT 1999, Eric E. Stimpson	Optimized query.
--			28 Dec 2000, Harish G P		Removed commit transaction statement at the end
--
--	Arguments:	@shipper	mandatory
--
--	1. Return result set.
------------------------------------------------------------------------------------------------------------------------------------------------------------------
begin
	create table #results
	(
		serial integer null,
		part varchar(25) null,
		status char(1) null,
		quantity decimal(20,6) null,
		unit_measure varchar(2) null,
		std_quantity decimal(20,6) null,
		parent_serial integer null,
		shipper integer null,
		location varchar(10) null,
		note varchar(255) null,
		suffix integer null,
		origin varchar(20) null,
		engineering_level varchar(10) null,
		configurable char(1) null
	)
	
	insert into #results
	select	box.serial,
		box.part,
		box.status,
		box.quantity,
		box.unit_measure,
		box.std_quantity,
		box.parent_serial,
		box.shipper,
		box.location,
		box.note,
		box.suffix,
		box.origin,
		box.engineering_level,
		configurable
	from	object box,
		shipper_detail sd,
		part_inventory pi
	where	box.status = 'a' and
		pi.part = box.part and 
		box.part = part_original and
		sd.shipper = @shipper and
		( isnull ( box.suffix, 0 ) = isnull ( sd.suffix, 0 ) or
		isnull ( pi.configurable, 'N' ) = 'N' )
	
	insert into #results
	select	pallet.serial,
		pallet.part,
		pallet.status,
		pallet.quantity,
		pallet.unit_measure,
		pallet.std_quantity,
		pallet.parent_serial,
		pallet.shipper,
		pallet.location,
		pallet.note,
		pallet.suffix,
		pallet.origin,
		pallet.engineering_level,
		'N'
	from	object pallet,
		#results box
	where	box.parent_serial = pallet.serial
	
	select	serial,
		part,
		status,
		quantity,
		unit_measure,
		std_quantity,
		parent_serial,
		shipper,
		location,
		note,
		suffix,
		origin,
		engineering_level,
		configurable
	from	#results
	order by 2, 1
	
	drop table #results
end
GO
