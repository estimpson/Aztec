SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE procedure [dbo].[ftsp_DESADV_VW_Detail] (@shipper integer )
as
begin

create table #DESADVDetailFlatFileLines (
		LineId	int identity
	,	LineData varchar(75))

declare
	-- Pallet variables
		@parentid int = 0 -- CPS segment	
	,	@parentserial int
	,	@packtype varchar(25)
	,	@mid int
	,	@stringlen int
	,	@skid varchar(25)
	,	@lid varchar(25) = ''
	-- Container variables
	,	@childid int = 0 -- CPS segment
	,	@conpacktype varchar(25)
	,	@concount int
	,	@quantity int
	,	@totalquantity int = 0
	,	@minserial int
	,	@maxserial int
	,	@serialrange varchar(50)
	,	@looseboxserial int
	,	@part varchar(25)
	,	@po varchar(25)
	-- Line number (RFF segment) and dock code (LOC segment) variables
	,	@linenumberconvert char(3)
	,	@totalloose int = 0
	,	@totalpallets int = 0
	,	@totallines int = 0
	,	@dockcode varchar(10)
	

-- Loose boxes
create table #looseboxes (
		part varchar(25)
	,	packtype varchar(25)
	,	po	varchar(25)
	,	quantity int
	,	dockcode varchar(10)
	,	serial int )
	
insert into #looseboxes (
		part
	,	packtype
	,	po
	,	quantity
	,	dockcode
	,	serial )
select	at.part, pm.name, sd.customer_po, at.quantity, oh.dock_code, at.serial
from	dbo.audit_trail at join 
		dbo.package_materials pm on at.package_type = pm.code join
		dbo.shipper_detail sd on at.shipper = sd.shipper and
		sd.part = at.part join
		dbo.order_header oh on oh.order_no = sd.order_no 
where	at.shipper = convert(varchar(10),@shipper) and
		at.object_type is null and
		at.parent_serial is null and
		pm.type = 'B'
		
			
-- Get total number of line items for RFF segment (loose boxes plus pallets)
--
select	@totalloose = count(1) 
from	#looseboxes

-- This temp table will be used in the Pallet loop as well
create table #pallets (
		parentserial int
	,	packtype varchar(25)
	,	dockcode varchar(10))

insert into #pallets (
		parentserial
	,	packtype
	,	dockcode	)
select distinct 
		at.parent_serial 
	,	pm.name
	,	(select oh.dock_code from dbo.order_header oh where oh.shipper = @shipper)
from	audit_trail at join dbo.package_materials pm on	
		at.package_type = pm.code
where	at.shipper = convert(varchar(10),@shipper) and
		at.object_type = 'S' and 
		isnull(at.parent_serial,0) > 0 and
		pm.type = 'P'		
		
select @totalpallets = count(parentserial) from #pallets		

set @totallines = @totalloose + @totalpallets + 1

		
-- Loose box loop
declare looseboxes cursor local
for
select	part, packtype
from	#looseboxes
group by part, packtype

open	looseboxes
fetch
		looseboxes	
into
		@part
	,	@conpacktype

while @@FETCH_STATUS = 0 begin

	set @parentid = @parentid + 1
	set @totallines = @totallines - 1

	-- Get loose box serial number, quantity and po number
	select	@looseboxserial = serial, 
			@quantity = quantity,
			@po = po,
			@dockcode = dockcode
	from	#looseboxes
	where	part = @part
	
	-- Convert line number to proper format
	if len(@totallines) = 1 begin
		set @linenumberconvert = '00' + convert(char(1), @totallines) 
	end
	else if len(@totallines) = 2 begin
		set @linenumberconvert = '0' + convert(char(2), @totallines) 
	end
	else begin
		set @linenumberconvert = convert(char(3), @totallines) 
	end
		
			
			
	-- CPS
	insert	#DESADVDetailFlatFileLines (LineData)
	select	('13' + left(convert(varchar(35), @parentID), 35) + '4  ')
	-- PAC
	insert	#DESADVDetailFlatFileLines (LineData)
	select	('14' + '1            ' + '12 ' + left(@conpacktype, 17) + '92 ')
	-- QTY
	insert	#DESADVDetailFlatFileLines (LineData)
	select	('15' + '52 ' + left(convert(varchar(17), @quantity), 17) + 'PCE')
	-- PCI
	insert	#DESADVDetailFlatFileLines (LineData)
	select	('16' + '17 ' + '1J ' + '5  ')
	-- GIN
	insert	#DESADVDetailFlatFileLines (LineData)
	select	('17' + 'ML ' + left(convert(varchar(35), @looseboxserial), 35))
	-- LIN
	insert	#DESADVDetailFlatFileLines (LineData)
	select	('18' + left(@part, 35))
	--PIA
	insert	#DESADVDetailFlatFileLines (LineData)
	select	('19' + left(@po, 35) + 'ON ')
	--QTY
	insert	#DESADVDetailFlatFileLines (LineData)
	select	('23' + '1  ' + left(convert(varchar(17), @quantity), 17) + 'PCE')
	--RFF
	insert	#DESADVDetailFlatFileLines (LineData)
	select	('28' + 'AAU' + left(convert(varchar(8), @shipper), 8) + @linenumberconvert)
	--DTM
	insert	#DESADVDetailFlatFileLines (LineData)
	select	('29' + '171' + left(convert(date, getdate(), 112), 35) + '102')
	--LOC
	insert	#DESADVDetailFlatFileLines (LineData)
	select	('33' + '11 ' + left(@dockcode, 25) + '92 ')
		
	
	fetch
			looseboxes	
	into
			@part
		,	@conpacktype

end
	
close looseboxes
deallocate looseboxes



-- Pallets and inner containers
--
declare pallets cursor local
for
select	parentserial
	,	packtype
	,	dockcode
from	#pallets
open	pallets

fetch
		pallets	
into
		@parentserial
	,	@packtype
	,	@dockcode

while @@FETCH_STATUS = 0 begin

	if @childid = 0 begin
		set @parentid = @parentid + 1
	end
	else begin
		set @parentid = @childid + 1
	end
	
	set @totallines = @totallines - 1
	
	-- Convert line number to proper format
	if len(@totallines) = 1 begin
		set @linenumberconvert = '00' + convert(char(1), @totallines) 
	end
	else if len(@totallines) = 2 begin
		set @linenumberconvert = '0' + convert(char(2), @totallines) 
	end
	else begin
		set @linenumberconvert = convert(char(3), @totallines) 
	end
	
	-- Separate pallet packtype into skid and lid if necessary
	set @mid = charindex('*', @packtype)
	if @mid > 0 begin
		set @skid = substring(@packtype, 1, (patindex('%*%', @packtype) - 1))
		set @lid = substring(@packtype, (patindex('%*%', @packtype) + 1), 50)
	end
	else begin
		set @skid = @packtype
	end
	
	
	
	-- CPS
	insert	#DESADVDetailFlatFileLines (LineData)
	select	('13' + left(convert(varchar(35), @parentID), 35) + '3  ')
	-- PAC
	if @lid > '' begin
		insert	#DESADVDetailFlatFileLines (LineData)
		select	('14' + '1         ' + '37 ' + '12 ' + left(@skid, 17) + '92 ')
	end
	else begin
		insert	#DESADVDetailFlatFileLines (LineData)
		select	('14' + '1         ' + '37 ' + '12 ' + left(@skid, 17) + '92 ')
		
		insert	#DESADVDetailFlatFileLines (LineData)
		select	('14' + '1         ' + '12 ' + left(@lid, 17) + '92 ')
	end
	-- PCI
	insert	#DESADVDetailFlatFileLines (LineData)
	select	('16' + '17 ' + '6J ' + '5  ')
	-- GIN
	insert	#DESADVDetailFlatFileLines (LineData)
	select	('17' + 'ML ' + left(convert(varchar(35), @parentid), 35))
	
	
	
	-- Begin container part/quantity loop
	declare containers cursor local
	for
	select	at.part, at.quantity, pm.name, count(at.part) as concount, sd.customer_po
	from	audit_trail at join dbo.package_materials pm on	
			at.package_type = pm.code join 
			dbo.shipper_detail sd on at.shipper = sd.shipper and
			sd.part = at.part
	where	at.shipper = convert(varchar(10), @shipper) and
			at.object_type is null and 
			at.parent_serial = @parentserial and
			pm.type = 'B'
	group by at.part, at.quantity, pm.name, sd.customer_po
	open	containers

	fetch
			containers	
	into
			@part
		,	@quantity 
		,	@conpacktype
		,	@concount
		,	@po

	while @@FETCH_STATUS = 0 begin

		set @childid = @parentid + 1
		set @totalquantity = @totalquantity + @quantity
		
		
		-- CPS
		insert	#DESADVDetailFlatFileLines (LineData)
		select	('13' + left(convert(varchar(35), @childID) + '' + convert(varchar(35), @parentID), 35) + '3  ')
		-- PAC
		insert	#DESADVDetailFlatFileLines (LineData)
		select	('14' + left(convert(varchar(10), @concount), 10) + '   12 ' + left(@conpacktype, 17) + '92 ')
		-- QTY
		insert	#DESADVDetailFlatFileLines (LineData)
		select	('15' + '52 ' + left(convert(varchar(17), @quantity), 17) + 'PCE')
		-- PCI
		insert	#DESADVDetailFlatFileLines (LineData)
		select	('16' + '17 ' + '1J ' + '5  ')
		
		
		-- Get list of child serial numbers for this particular parent
		create table #childserialnumbers (
				serial int )
		
		insert into #childserialnumbers (
				serial )
		select	at.serial
		from	audit_trail at
		where	at.shipper = convert(varchar(10),@shipper) and
				at.object_type is null and 
				at.parent_serial = @parentserial and
				at.part = @part
		
		
		-- Begin container serial numbers loop using ranges
		declare serials cursor local
		for
		select	csn1.serial as beginserial, 
				null as endserial
		from	#childserialnumbers csn1 
				left join #childserialnumbers csn2 on csn1.serial - 1 = csn2.serial
				left join  #childserialnumbers csn3 on csn1.serial + 1 = csn3.serial 
		where	csn2.serial is null and
				csn3.serial is null 
		union all
		select	beginserial = rangebegins.serial,
				endserial = min(rangeends.serial)
		from	
		(	select	csn1.serial
			from	#childserialnumbers csn1 
					left join #childserialnumbers csn2 on csn1.serial - 1 = csn2.serial
					left join  #childserialnumbers csn3 on csn1.serial + 1 = csn3.serial 
			where	csn2.serial is null and
					csn3.serial is not null ) rangebegins 		
			left join
			(	select	csn4.serial
				from	#childserialnumbers csn4
						left join #childserialnumbers csn5 on csn4.serial - 1 = csn5.serial
						left join  #childserialnumbers csn6 on csn4.serial + 1 = csn6.serial 
				where	csn5.serial is not null and
						csn6.serial is null ) rangeends
			on rangebegins.serial < rangeends.serial
		group by rangebegins.serial
		order by 1


		fetch
				serials	
		into
				@minserial
			,	@maxserial
			
		while @@FETCH_STATUS = 0 begin
		
			-- GIN
			if @maxserial is null begin
				set @serialrange = cast(@minserial as varchar(50))
			end
			else begin
				set @serialrange = cast(@minserial as varchar(50)) + ':' + cast(@maxserial as varchar(50))
			end
			insert	#DESADVDetailFlatFileLines (LineData)
			select	('17' + 'ML ' + left(@serialrange, 35))
			
			
			fetch
				serials	
			into
				@minserial
			,	@maxserial
			
		end
		
		close serials
		deallocate serials
		-- End container serial numbers loop



		-- LIN
		insert	#DESADVDetailFlatFileLines (LineData)
		select	('18' + left(@part, 35))
		--PIA
		insert	#DESADVDetailFlatFileLines (LineData)
		select	('19' + left(@po, 35) + 'ON ')


		fetch
				containers	
		into
				@part
			,	@quantity
			,	@conpacktype
			,	@po

	end
	
	close containers
	deallocate containers
	-- End container part/quantity loop



	--QTY
	insert	#DESADVDetailFlatFileLines (LineData)
	select	('23' + '1  ' + left(convert(varchar(17), @totalquantity), 17) + 'PCE')
	--RFF
	insert	#DESADVDetailFlatFileLines (LineData)
	select	('28' + 'AAU' + left(convert(varchar(8), @shipper), 8) + @linenumberconvert)
	--DTM
	insert	#DESADVDetailFlatFileLines (LineData)
	select	('29' + '171' + left(convert(date, getdate(), 112), 35) + '102')
	--LOC
	insert	#DESADVDetailFlatFileLines (LineData)
	select	('33' + '11 ' + left(@dockcode, 25) + '92 ')
	


	fetch
			pallets	
	into
			@parentserial
		,	@packtype
		,	@dockcode
	
end

close pallets
deallocate pallets
				
			

			
select	*
from	#DESADVDetailFlatFileLines
order by 1 asc


end
GO
