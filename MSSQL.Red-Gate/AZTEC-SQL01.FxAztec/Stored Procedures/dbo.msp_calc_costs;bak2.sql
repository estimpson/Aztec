SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[msp_calc_costs;bak2] (@part VARCHAR(25), @cost_bucket CHAR(1)) AS  
BEGIN -- (1b)
--------------------------------------------------------------------------------------------------------------------------
--
--	Procedure 	msp_calc_costs
--	Arguments	part varchar(25)
--			cost bucket char(1) ie S/P/Q/F
--	Purpose		To rollup the cost from it's components for the specified part
--
--	Logic		
--		Declare variables
--		Create Temp tables
--		Initialize
--		Process data in temp table #bom_parts starting from the top part
--			process all component parts
--		processing the costing rollup from the deepest level 
--		process all the rows in the temp table in the reverse order (cost rolls up from inner most to top part)
--			calculate labor & burden
--			update part_standard table with the new values for the current part
--
--	Development	GPH
--------------------------------------------------------------------------------------------------------------------------
--	Declare variables
DECLARE @rowno  INT, 
	@rowno_prev INT,   
	@parent_part VARCHAR(25),
	@parent_part_prev VARCHAR(25),
	@bom_level INTEGER,                    
	@partno VARCHAR(25),
	@parentpartno VARCHAR(25),
	@part_tmp VARCHAR(25),
	@bom_qty NUMERIC(20,6),
	@bom_type CHAR(1),
	@bomlevel INTEGER,
	@extended_qty NUMERIC(20,6),
	@cost              NUMERIC(20,6),
	@material          NUMERIC(20,6),
	@labor             NUMERIC(20,6),
	@burden            NUMERIC(20,6),
	@other             NUMERIC(20,6),
	@cost_cum          NUMERIC(20,6),
	@material_cum      NUMERIC(20,6),
	@labor_cum         NUMERIC(20,6),
	@burden_cum        NUMERIC(20,6),
	@other_cum         NUMERIC(20,6),
	@mfg_lot_size      NUMERIC(20,6),
	@standard_rate     NUMERIC(20,6),
	@standard_rate_mc  NUMERIC(20,6),  
	@parts_per_hour    NUMERIC(20,6),
	@setup_time        NUMERIC(5,2),
	@machine_no        VARCHAR(10),
	@include_setuptime VARCHAR(1),
	@varying           NUMERIC(20,6),
	@indirect          NUMERIC(20,6),
	@sga               NUMERIC(20,6), 
	@varying_mc        NUMERIC(20,6),
	@indirect_mc       NUMERIC(20,6),
	@sga_mc            NUMERIC(20,6), 
	@crew_size         NUMERIC(20,6), 
	@parttype          VARCHAR(1),
	@calc_mtl_cost     VARCHAR(1),
	@default_vendor    VARCHAR(10),
	@vendor_price      NUMERIC(15,7),
	@qty               NUMERIC(20,6),
	@vendor_uom        VARCHAR(2),
	@std_uom           VARCHAR(2),
	@conversion        NUMERIC(15,7),
	@bom_uom           VARCHAR(2),
	@count             INTEGER

--	Create Temp tables
CREATE TABLE #bom_parts ( 
	rowno INTEGER NOT NULL,
	parent_part VARCHAR(25) NULL,
	part VARCHAR(25) NOT NULL,
	bom_qty  NUMERIC(20,6) NOT NULL,
	bom_level INTEGER NOT NULL,
	bom_uom VARCHAR(2) NULL)

CREATE TABLE #bom_parts_adnl ( 
	rowno integer not null,
	parent_part varchar(25) null,
	part varchar(25) not null,
	bom_qty  numeric(20,6) not null,
	bom_level integer not null,
	bom_uom varchar(2) null)

create table #duplicate_parts ( 
	parentpart 	varchar(25),
	part		varchar(25))

create table #bom_comp (part varchar(25) not null, 
	bom_qty numeric(20,6) not null,
	bom_uom varchar(2) null) 

begin transaction

	set rowcount 0
	--	Initialize
	select	@rowno=1, @bom_level = isnull(@bom_level,0) + 1

	select	@include_setuptime=include_setuptime,
		@calc_mtl_cost    =calc_mtl_cost
	from	parameters

	insert into #bom_parts values (@rowno, @parent_part, @part, 1, @bom_level, @bom_uom) 
	
	--	Process data in temp table #bom_parts starting from the top part
	set rowcount 1
	select	@partno=part,
		@rowno_prev = rowno,
		@bomlevel = bom_level 
	from	#bom_parts
	where	rowno > 0

	while @@rowcount > 0
	begin -- (2b)
		set rowcount 0  
		if @cost_bucket='S'
			update	part_standard
			set	cost_cum=0, material_cum=0, labor_cum=0, burden_cum=0, other_cum=0, cost=0 
			where	part = @partno
		else if @cost_bucket='Q'
			update	part_standard
			set	qtd_cost_cum=0, qtd_material_cum=0, qtd_labor_cum=0, 
				qtd_burden_cum=0, qtd_other_cum=0, qtd_cost=0 
			where	part = @partno
		else if @cost_bucket='P'
			update	part_standard
			set	planned_cost_cum=0, planned_material_cum=0, planned_labor_cum=0, 
				planned_burden_cum=0, planned_other_cum=0, planned_cost=0 
			where	part = @partno
		else if	@cost_bucket='F' 
			update	part_standard
			set	frozen_cost_cum=0, frozen_material_cum=0, frozen_labor_cum=0, 
				frozen_burden_cum=0, frozen_other_cum=0, frozen_cost=0 
			where	part = @partno

		set rowcount 0 
		--	insert into components temp table for the considered part
		insert into #bom_comp 
		select part, quantity, unit_measure from bill_of_material where parent_part = @partno and substitute_part <> 'Y'
		
		if @@rowcount > 0
		begin -- (3b)
			--	process all component parts		
			set rowcount 0 
			select @bomlevel = isnull(@bomlevel,0) + 1

			set rowcount 1
			select @part_tmp = part, @bom_qty = bom_qty, @bom_uom = bom_uom from #bom_comp

			while @@rowcount > 0
			begin -- (4b)
				set rowcount 0 
				select @rowno = @rowno + 1
				insert #bom_parts values (@rowno, @partno, @part_tmp, @bom_qty, @bomlevel, @bom_uom) 

				set rowcount 0              
				delete from #bom_comp where (part = @part_tmp)   

				set rowcount 1 
				select @part_tmp = part, @bom_qty = bom_qty, @bom_uom = bom_uom from #bom_comp
			end  -- (4e)
			set rowcount 0 
			delete from #bom_comp
			
		end -- (3e)
		
		set rowcount 1
		select	@partno=part,
			@rowno_prev = rowno,
			@bomlevel = bom_level
		from	#bom_parts
		where rowno > @rowno_prev
	end -- (2e)
	
	--	processing the costing rollup from the deepest level 
	set rowcount 0 
	insert	into #bom_parts_adnl
	select	rowno, parent_part, part, bom_qty, bom_level, bom_uom 
	from	#bom_parts
	order by rowno desc
	
	--	process all the rows in the temp table in the reverse order (cost rolls up from inner most to top part)
	set rowcount 1  
	select	@rowno = rowno,
		@parent_part=parent_part,
		@part = part,
		@bom_qty = isnull(bom_qty,1),
		@bom_level = bom_level,
		@bom_uom = bom_uom
	from	#bom_parts_adnl

	while @@rowcount > 0
	begin -- (3b)
		set rowcount 0 
		select	@material=0, @burden=0, @labor=0, @other=0, @cost=0, 
			@material_cum=0, @burden_cum=0, @labor_cum=0, @other_cum=0, @cost_cum=0,
			@standard_rate=0, @varying=0, @indirect=0, @sga=0,
			@standard_rate_mc=0, @varying_mc=0, @indirect_mc=0, @sga_mc=0,
			@conversion=1
			
		if @cost_bucket='S' -- Standard 
		begin 
			select	@material=isnull(ps.material,0.0),
				@labor   =isnull(ps.labor,0.0),
				@burden  =isnull(ps.burden,0.0),
				@other   =isnull(ps.other,0.0),
				@material_cum=isnull(ps.material_cum,0.0),
				@labor_cum   =isnull(ps.labor_cum,0.0),
				@burden_cum  =isnull(ps.burden_cum,0.0),
				@other_cum   =isnull(ps.other_cum,0.0),
				@parttype=(select p.class from part as p where p.part = ps.part),
				@std_uom=(select pi.standard_unit from part_inventory as pi where pi.part = ps.part),
				@default_vendor=(select isnull(pol.default_vendor,'') from part_online as pol where pol.part = ps.part),
				@machine_no=(select pm.machine from part_machine as pm where pm.part = ps.part  and pm.sequence = 1)
			from	part_standard as ps
			where	ps.part=@part

			set rowcount 1 
			select	@parts_per_hour=pmg.parts_per_hour,
				@mfg_lot_size  =pmg.mfg_lot_size,
				@setup_time    =pmg.setup_time,   
				@standard_rate =isnull(l.standard_rate,0),
				@varying       =isnull(l.varying_rate_1,0),
				@indirect      =isnull(l.indirect,0),
				@sga           =0
			from	part_mfg as pmg
				join labor as l on l.id = pmg.labor_code
			where	part=@part
			
			select	@standard_rate_mc=isnull(standard_rate,0),
				@varying_mc      =isnull(varying_rate_1,0),
				@indirect_mc     =isnull(indirect,0),
				@sga_mc          =0
			from	machine
			where	machine_no=@machine_no
		end
		else if @cost_bucket='Q' -- Quoted
		begin
			select	@material=isnull(ps.qtd_material,0.0),
				@labor   =isnull(ps.qtd_labor,0.0),
				@burden  =isnull(ps.qtd_burden,0.0),
				@other   =isnull(ps.qtd_other,0.0),
				@material_cum=isnull(ps.qtd_material_cum,0.0),
				@labor_cum   =isnull(ps.qtd_labor_cum,0.0),
				@burden_cum  =isnull(ps.qtd_burden_cum,0.0),
				@other_cum   =isnull(ps.qtd_other_cum,0.0),
				@parttype=(select p.class from part as p where p.part = ps.part),
				@std_uom=(select pi.standard_unit from part_inventory as pi where pi.part = ps.part),
				@default_vendor=(select isnull(pol.default_vendor,'') from part_online as pol where pol.part = ps.part),
				@machine_no=(select pm.machine from part_machine as pm where pm.part = ps.part  and pm.sequence = 1)
			from	part_standard as ps
			where	ps.part=@part
			
			set rowcount 1 
			select	@parts_per_hour=pmg.parts_per_hour,
				@mfg_lot_size  =pmg.mfg_lot_size,
				@setup_time    =pmg.setup_time,   
				@standard_rate =isnull(l.qted_rate,0),
				@varying       =isnull(l.qted_variable,0),
				@indirect      =isnull(l.qted_indirect,0),
				@sga           =isnull(l.qted_sga,0)
			from	part_mfg as pmg
				join labor as l on l.id = pmg.labor_code
			where	part=@part
			
			select	@standard_rate_mc=isnull(qted_rate,0),
				@varying_mc      =isnull(qted_variable,0),
				@indirect_mc     =isnull(qted_indirect,0),
				@sga_mc          =isnull(qted_sga,0)
			from	machine
			where	machine_no=@machine_no
		end
		else if @cost_bucket='P' -- Planned
		begin  
			select	@material=isnull(ps.planned_material,0.0),
				@labor   =isnull(ps.planned_labor,0.0),
				@burden  =isnull(ps.planned_burden,0.0),
				@other   =isnull(ps.planned_other,0.0),
				@material_cum=isnull(ps.planned_material_cum,0.0),
				@labor_cum   =isnull(ps.planned_labor_cum,0.0),
				@burden_cum  =isnull(ps.planned_burden_cum,0.0),
				@other_cum   =isnull(ps.planned_other_cum,0.0),
				@parttype=(select p.class from part as p where p.part = ps.part),
				@std_uom=(select pi.standard_unit from part_inventory as pi where pi.part = ps.part),
				@default_vendor=(select isnull(pol.default_vendor,'') from part_online as pol where pol.part = ps.part),
				@machine_no=(select pm.machine from part_machine as pm where pm.part = ps.part  and pm.sequence = 1)
			from	part_standard as ps
			where	ps.part=@part

			set rowcount 1 
			select	@parts_per_hour=pmg.parts_per_hour,
				@mfg_lot_size  =pmg.mfg_lot_size,
				@setup_time    =pmg.setup_time,   
				@standard_rate =isnull(l.plnd_rate,0),
				@varying       =isnull(l.plnd_variable,0),
				@indirect      =isnull(l.plnd_indirect,0),
				@sga           =isnull(l.plnd_sga,0)
			from	part_mfg as pmg
				join labor as l on l.id = pmg.labor_code
			where	part=@part
			
			select	@standard_rate=isnull(plnd_rate,0),
				@varying      =isnull(plnd_variable,0),
				@indirect     =isnull(plnd_indirect,0),
				@sga          =isnull(plnd_sga,0)
			from	machine
			where	machine_no=@machine_no
		end 
		else if @cost_bucket='F' -- Frozen
		begin 
			select	@material=isnull(ps.frozen_material,0.0),
				@labor   =isnull(ps.frozen_labor,0.0),
				@burden  =isnull(ps.frozen_burden,0.0),
				@other   =isnull(ps.frozen_other,0.0),
				@material_cum=isnull(ps.frozen_material_cum,0.0),
				@labor_cum   =isnull(ps.frozen_labor_cum,0.0),
				@burden_cum  =isnull(ps.frozen_burden_cum,0.0),
				@other_cum   =isnull(ps.frozen_other_cum,0.0),
				@parttype=(select p.class from part as p where p.part = ps.part),
				@std_uom=(select pi.standard_unit from part_inventory as pi where pi.part = ps.part),
				@default_vendor=(select isnull(pol.default_vendor,'') from part_online as pol where pol.part = ps.part),
				@machine_no=(select pm.machine from part_machine as pm where pm.part = ps.part  and pm.sequence = 1)
			from	part_standard as ps
			where	ps.part=@part
			
			set rowcount 1 
			select	@parts_per_hour=pmg.parts_per_hour,
				@mfg_lot_size  =pmg.mfg_lot_size,
				@setup_time    =pmg.setup_time,   
				@standard_rate =isnull(l.frzn_rate,0),
				@varying       =isnull(l.frzn_variable,0),
				@indirect      =isnull(l.frzn_indirect,0),
				@sga           =isnull(l.frzn_sga,0)
			from	part_mfg as pmg
				join labor as l on l.id = pmg.labor_code
			where	part=@part
			
			select	@standard_rate=isnull(frzn_rate,0),
				@varying      =isnull(frzn_variable,0),
				@indirect     =isnull(frzn_indirect,0),
				@sga          =isnull(frzn_sga,0)
			from	machine
			where	machine_no=@machine_no
		end
		
		if	@calc_mtl_cost='Y' and @parttype='P'
		begin
			set rowcount 1 
			select	@vendor_uom=receiving_um
			from	part_vendor
			where	part=@part and vendor=@default_vendor
			
			if @std_uom <> @vendor_uom
			begin
				set rowcount 1 
				select	@conversion=isnull(uc.conversion,1)
				from	part_unit_conversion as puc
					join unit_conversion as uc on uc.code=puc.code and
					uc.unit1=@std_uom and uc.unit2=@vendor_uom
				where	puc.part = @part
			end

			set rowcount 1
			select	@vendor_price=isnull(price,0)
			from	part_vendor_price_matrix
			where	vendor=@default_vendor and part=@part and break_qty=1
			
			if @cost_bucket='S'
				select @material= isnull(@vendor_price,0) * isnull(@conversion,1)
		end

		if @std_uom <> @bom_uom
		begin 
			set rowcount 1 
			select	@conversion=isnull(conversion,1)
			from	part_unit_conversion as a,unit_conversion as b
			where	a.part = @part and b.code=a.code and unit1=@bom_uom and unit2=@std_uom
			if @conversion is null
				select @conversion=1 
		end
		
		if @mfg_lot_size = 0
			select @mfg_lot_size=null
			
		if @parts_per_hour=0
			select @parts_per_hour=null 
			
		set rowcount 1
		select	@crew_size=isnull(crew_size,1)
		from	part_machine
		where	part=@part and machine=@machine_no and sequence=1

		if @crew_size is null or @crew_size=0
			select @crew_size=1  

		--	calculate labor & burden
		if @cost_bucket='S'
			if @include_setuptime='Y'
			begin
				--	calculate the labor with setuptime
				select @labor=(((1.0/isnull(@parts_per_hour,1.0))+(isnull(@setup_time,0.0)/isnull(@mfg_lot_size,1)))* (isnull(@standard_rate,0) * isnull(@crew_size,1)))
				if @varying>0
					select @labor= @labor + (((1.0/isnull(@parts_per_hour,1.0))+(isnull(@setup_time,0.0)/isnull(@mfg_lot_size,1))) * isnull(@varying,0)  * isnull(@crew_size,1))  
				if @indirect>0
					select @labor= @labor + (((1.0/isnull(@parts_per_hour,1.0))+(isnull(@setup_time,0.0)/isnull(@mfg_lot_size,1))) * isnull(@indirect,0) * isnull(@crew_size,1)) 
				if @sga>0
					select @labor= @labor + (((1.0/isnull(@parts_per_hour,1.0))+(isnull(@setup_time,0.0)/isnull(@mfg_lot_size,1))) * isnull(@sga,0)      * isnull(@crew_size,1)) 
					
				--	calculate the burden with setuptime
				select @burden = (((1.0/isnull(@parts_per_hour,1.0)) + (isnull(@setup_time,0.0)/isnull(@mfg_lot_size,1))) * isnull(@standard_rate_mc,0)) 
				if @varying_mc>0
					select @burden = isnull(@burden,0) + (((1.0/isnull(@parts_per_hour,1.0)) + (isnull(@setup_time,0.0)/isnull(@mfg_lot_size,1))) * isnull(@varying_mc,0))
				if @indirect_mc>0
					select @burden = isnull(@burden,0) + (((1.0/isnull(@parts_per_hour,1.0)) + (isnull(@setup_time,0.0)/isnull(@mfg_lot_size,1))) * isnull(@indirect_mc,0))
				if @sga_mc>0
					select @burden = isnull(@burden,0) + (((1.0/isnull(@parts_per_hour,1.0)) + (isnull(@setup_time,0.0)/isnull(@mfg_lot_size,1))) * isnull(@sga_mc,0))
			end -- ()
			else
			begin
				--	calculate labor without setup time
				select @labor=((1.0/isnull(@parts_per_hour,1.0))* (isnull(@standard_rate,0) * isnull(@crew_size,1)))
				if @varying>0
					select @labor= @labor + ((1.0/isnull(@parts_per_hour,1.0)) * isnull(@varying,0)  * isnull(@crew_size,1))  
				if @indirect>0
					select @labor= @labor + ((1.0/isnull(@parts_per_hour,1.0)) * isnull(@indirect,0) * isnull(@crew_size,1)) 
				if @sga>0
					select @labor= @labor + ((1.0/isnull(@parts_per_hour,1.0)) * isnull(@sga,0)      * isnull(@crew_size,1)) 
					
				--	calculate the burden without setuptime
				select @burden=((1.0/isnull(@parts_per_hour,1.0))* isnull(@standard_rate_mc,0))
				if @varying_mc>0
					select @burden = isnull(@burden,0) + ((1.0/isnull(@parts_per_hour,1.0)) * isnull(@varying_mc,0))
				if @indirect_mc>0
					select @burden = isnull(@burden,0) + ((1.0/isnull(@parts_per_hour,1.0)) * isnull(@indirect_mc,0))
				if @sga_mc>0
					select @burden = isnull(@burden,0) + ((1.0/isnull(@parts_per_hour,1.0)) * isnull(@sga_mc,0))
			end
	
		if @parttype in ('M', 'O')
			select	@material_cum = isnull(@material_cum,0) + isnull(@material,0),
				@labor_cum    = isnull(@labor_cum,0) + isnull(@labor,0),
				@burden_cum   = isnull(@burden_cum,0) + isnull(@burden,0), 
				@other_cum    = isnull(@other_cum,0) + isnull(@other,0)
		else
			if ((select a.flow_route_window 
				from	activity_codes a
					join part_machine b on b.activity = a.code
				where	b.part = @part) = 'w_create_flow_route_outside_version2')
				select	@material_cum = isnull(@material_cum,0) + isnull(@material,0),
					@labor_cum    = isnull(@labor_cum,0) + isnull(@labor,0),
					@burden_cum   = isnull(@burden_cum,0) + isnull(@burden,0), 
					@other_cum    = isnull(@other_cum,0) + isnull(@other,0)
			else    
				select	@material_cum = isnull(@material,0),
					@labor_cum    = isnull(@labor,0),
					@burden_cum   = isnull(@burden,0), 
					@other_cum    = isnull(@other,0)
					
		select	@cost_cum     = isnull(@material_cum,0.0)+
					isnull(@burden_cum,0.0)  +
					isnull(@labor_cum,0.0)   +
					isnull(@other_cum,0.0)
		select	@cost         = isnull(@material,0.0)+
					isnull(@burden,0.0)  +
					isnull(@labor,0.0)   +
					isnull(@other,0.0)
			
		--	update part_standard table with the new values for the current part					
		set rowcount 0 
		if @cost_bucket='S'
		begin  
			update	part_standard 
			set	cost        =isnull(@cost,0.0),
				material    =isnull(@material,0.0),
				labor       =isnull(@labor,0.0),
				burden      =isnull(@burden,0.0),
				other       =isnull(@other,0.0),
				cost_cum    =isnull(@cost_cum,0.0),
				material_cum=isnull(@material_cum,0.0),
				burden_cum  =isnull(@burden_cum,0.0),
				other_cum   =isnull(@other_cum,0.0),
				labor_cum   =isnull(@labor_cum,0.0),
				flag        =1,
				cost_changed_date=getdate() 
			where	part=@part
			
			select @count = count(1) from #duplicate_parts where parentpart=@parent_part and part=@part
			if @count = 0 
			begin  
				insert into #duplicate_parts values ( @parent_part, @part )
				set rowcount 0 
				--	update parent too
				update	part_standard
				set	material_cum=material_cum + (isnull(@material_cum,0.0) * @bom_qty * @conversion),
					labor_cum   =labor_cum    + (isnull(@labor_cum,0.0) * @bom_qty * @conversion),
					burden_cum  =burden_cum   + (isnull(@burden_cum,0.0) * @bom_qty * @conversion),
					other_cum   =other_cum    + (isnull(@other_cum,0.0) * @bom_qty * @conversion)
				where	part=@parent_part
			end          
		end
		else if @cost_bucket='Q'
		begin  
			update	part_standard
			set	qtd_cost        =isnull(@cost,0.0),
				qtd_material    =isnull(@material,0.0),
				qtd_labor       =isnull(@labor,0.0),
				qtd_burden      =isnull(@burden,0.0),
				qtd_other       =isnull(@other,0.0),
				qtd_cost_cum    =isnull(@cost_cum,0.0),
				qtd_material_cum=isnull(@material_cum,0.0),
				qtd_burden_cum  =isnull(@burden_cum,0.0),
				qtd_other_cum   =isnull(@other_cum,0.0),
				qtd_labor_cum   =isnull(@labor_cum,0.0),
				flag        =1,
				qtd_changed_date=getdate() 
			where part=@part
			
			select @count = count(1) from #duplicate_parts where parentpart=@parent_part and part=@part
			if @count = 0 
			begin  
				insert into #duplicate_parts values ( @parent_part, @part )
				set rowcount 0 

				update	part_standard 
				set	qtd_material_cum=qtd_material_cum + (isnull(@material_cum,0.0) * @bom_qty * @conversion),
					qtd_labor_cum   =qtd_labor_cum    + (isnull(@labor_cum,0.0) * @bom_qty * @conversion),
					qtd_burden_cum  =qtd_burden_cum   + (isnull(@burden_cum,0.0) * @bom_qty * @conversion),
					qtd_other_cum   =qtd_other_cum    + (isnull(@other_cum,0.0) * @bom_qty * @conversion)
				where	part=@parent_part
			end         
		end
		else if @cost_bucket='P'
		begin  
			update	part_standard
			set	planned_cost        =isnull(@cost,0.0),
				planned_material    =isnull(@material,0.0),
				planned_labor       =isnull(@labor,0.0),
				planned_burden      =isnull(@burden,0.0),
				planned_other       =isnull(@other,0.0),
				planned_cost_cum    =isnull(@cost_cum,0.0),
				planned_material_cum=isnull(@material_cum,0.0),
				planned_burden_cum  =isnull(@burden_cum,0.0),
				planned_other_cum   =isnull(@other_cum,0.0),
				planned_labor_cum   =isnull(@labor_cum,0.0),
				flag        =1,
				planned_changed_date=getdate() 
			where	part=@part
			
			select @count = count(1) from #duplicate_parts where parentpart=@parent_part and part=@part
			if @count = 0 
			begin  
				insert into #duplicate_parts values ( @parent_part, @part )
				set rowcount 0 

				update	part_standard 
				set	planned_material_cum=planned_material_cum + (isnull(@material_cum,0.0) * @bom_qty * @conversion),
					planned_labor_cum   =planned_labor_cum    + (isnull(@labor_cum,0.0) * @bom_qty * @conversion),
					planned_burden_cum  =planned_burden_cum   + (isnull(@burden_cum,0.0) * @bom_qty * @conversion),
					planned_other_cum   =planned_other_cum    + (isnull(@other_cum,0.0) * @bom_qty * @conversion)
				where	part=@parent_part
			end         
		end
		else if @cost_bucket='F'
		begin
			update part_standard
			set	frozen_cost        =isnull(@cost,0.0),
				frozen_material    =isnull(@material,0.0),
				frozen_labor       =isnull(@labor,0.0),
				frozen_burden      =isnull(@burden,0.0),
				frozen_other       =isnull(@other,0.0),
				frozen_cost_cum    =isnull(@cost_cum,0.0),
				frozen_material_cum=isnull(@material_cum,0.0),
				frozen_burden_cum  =isnull(@burden_cum,0.0),
				frozen_other_cum   =isnull(@other_cum,0.0),
				frozen_labor_cum   =isnull(@labor_cum,0.0),
				flag        =1,
				frozen_changed_date=getdate() 
			where	part=@part
			
			select @count = count(1) from #duplicate_parts where parentpart=@parent_part and part=@part
			if @count = 0 
			begin  
				insert into #duplicate_parts values ( @parent_part, @part )
				set rowcount 0 

				update	part_standard
				set	frozen_material_cum=frozen_material_cum + (isnull(@material_cum,0.0) * @bom_qty * @conversion),
					frozen_labor_cum   =frozen_labor_cum    + (isnull(@labor_cum,0.0) * @bom_qty * @conversion),
					frozen_burden_cum  =frozen_burden_cum   + (isnull(@burden_cum,0.0) * @bom_qty * @conversion),
					frozen_other_cum   =frozen_other_cum    + (isnull(@other_cum,0.0) * @bom_qty * @conversion)
				where	part=@parent_part
			end         
		end

		set rowcount 0 
		delete from #bom_parts_adnl where rowno = @rowno
		
		--	get next set of data 
		set rowcount 1  
		select	@rowno = rowno,
			@parent_part=parent_part,
			@part = part,
			@bom_qty = isnull(bom_qty,1),
			@bom_level = bom_level,
			@bom_uom = bom_uom
		from	#bom_parts_adnl
	end -- (3e)
	drop table #duplicate_parts
	set rowcount 0 
commit transaction  
end -- (1e)

GO
