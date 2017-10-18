/*
drop table
	tempdb..X

drop table
	tempdb..Y
*/
drop table
	tempdb..X

drop table
	tempdb..Y
go

set nocount on

create table
	tempdb..X
(	Sequence int
,	Suffix int
,	QtyWIP numeric(20,6)
)

create table
	tempdb..Y
(	BOMID int
,	Serial int
,	QtyIssue numeric(20,6)
,	Suffix int
)

declare
	@LowLevel int

set	@LowLevel = 0

while
	@LowLevel <=
	(	select
			max(LowLevel)
		from
			tempdb..NetMPS
	) begin
	
	declare partsQtyAvailable cursor local for
	select
		oh.Serial
	,	oh.Part
	,	oh.QtyAvailable - oh.QtyToIssue
	,	oh.Suffix
	from
		tempdb..OnHand oh
	where
		oh.QtyAvailable > oh.QtyToIssue
		and oh.LowLevel = @LowLevel
	order by
		oh.AllocationSequence
	,	oh.AllocationDT
	
	open partsQtyAvailable
	
	declare
		@Serial int
	,	@PartInventory varchar(25)
	,	@QtyAvailable numeric(20,6)
	,	@InventorySuffix int
	
	while
		1 = 1 begin
		
		fetch
			PartsQtyAvailable
		into
			@Serial
		,	@PartInventory
		,	@QtyAvailable
		,	@InventorySuffix
		
		if	@@FETCH_STATUS != 0 begin
			break
		end
		
		declare
			@ReqID int
		,	@SubForBOMID int
		,	@SubDownRate numeric(20,6)
		,	@SubRate numeric(20,6)
		,	@Balance numeric(30,12)
		,	@InventorySequence int
		
		declare requirements cursor local for
		select
			nm.ID
		,	nm.SubForBOMID
		,	nm.SubDownRate
		,	nm.SubRate
		,	nm.Balance
		,	nm.Sequence
		from
			tempdb..NetMPS nm
		where
			nm.Part = @PartInventory
			and coalesce(nm.Suffix, -1) = coalesce(@InventorySuffix, -1)
			and nm.Balance > 0
		order by
			nm.BOMLevel
		
		open
			requirements
		
		while
			1 = 1
			and @QtyAvailable > 0 begin
			
			fetch
				requirements
			into
				@ReqID
			,	@SubForBOMID
			,	@SubDownRate
			,	@SubRate
			,	@Balance
			,	@InventorySequence
			
			if	@@fetch_status != 0 begin
				break
			end
			
			/*	1. In this pass we are not exceeding substitution let down. */
			declare
				@AllocableBalance numeric(20,6)
			
			set	@AllocableBalance =
				@Balance *
					coalesce(@SubDownRate, 1)
			
			if	@AllocableBalance > @QtyAvailable begin
				update
					nm
				set
					Balance = nm.Balance - @QtyAvailable
				,	QtyAvailable = nm.QtyAvailable + @QtyAvailable
				from
					tempdb..NetMPS nm
				where
					ID = @ReqID
				
				insert
					tempdb..X
				(	Sequence
				,	Suffix
				,	QtyWIP
				)
				select
					Sequence = @InventorySequence + xr.Sequence
				,	Suffix = xr.Suffix
				,   QtyWIP = @QtyAvailable * (xr.XQty * xr.XScrap * xr.XSuffix)
				from
					tempdb..XRt xr
				where
					xr.TopPart = @PartInventory
					and xr.Sequence > 0
					and coalesce(xr.Suffix, -1) = coalesce(@InventorySuffix, -1)
				
				insert
					tempdb..Y
				(	BOMID
				,	Serial
				,	QtyIssue
				,	Suffix
				)
				select
					nm.BOMID
				,	@Serial
				,	@QtyAvailable
				,	@InventorySuffix
				from
					tempdb..NetMPS nm
				where
					ID = @ReqID
				
				set	@QtyAvailable = 0
			end
			else begin
				update
					nm
				set
					Balance = nm.Balance - @AllocableBalance
				,	QtyAvailable = nm.QtyAvailable + @AllocableBalance
				from
					tempdb..NetMPS nm
				where
					ID = @ReqID
				
				insert
					tempdb..X
				(	Sequence
				,	Suffix
				,	QtyWIP
				)
				select
					Sequence = @InventorySequence + xr.Sequence
				,	Suffix = xr.Suffix
				,   QtyWIP = @AllocableBalance * (xr.XQty * xr.XScrap * xr.XSuffix)
				from
					tempdb..XRt xr
				where
					xr.TopPart = @PartInventory
					and xr.Sequence > 0
					and coalesce(xr.Suffix, -1) = coalesce(@InventorySuffix, -1)
				
				insert
					tempdb..Y
				(	BOMID
				,	Serial
				,	QtyIssue
				,	Suffix
				)
				select
					nm.BOMID
				,	@Serial
				,	@AllocableBalance
				,	@InventorySuffix
				from
					tempdb..NetMPS nm
				where
					ID = @ReqID
				
				set	@QtyAvailable = @QtyAvailable - @AllocableBalance
			end
		end
		
		close
			requirements
		
		deallocate
			requirements
	end
	
	close
		partsQtyAvailable
	
	deallocate
		partsQtyAvailable
	
	set	@LowLevel = @LowLevel + 1
	
	update
		nm
	set
		QtyWIP = coalesce
		(	(	select
					sum(QtyWIP)
				from
					tempdb..X x
				where
					x.Sequence = nm.Sequence
					and coalesce(x.Suffix, -1) = coalesce(nm.Suffix, -1)
			)
		,	0
		)
	from
		tempdb..NetMPS nm
	where
		nm.LowLevel = @LowLevel
	
	update
		nm
	set
		Balance = nm.Balance - nm.QtyWIP
	from
		tempdb..NetMPS nm
	where
		nm.LowLevel = @LowLevel
end

/*	Aggregate allocated substitutes. */
set	@LowLevel =
	(	select
			max(LowLevel)
		from
			tempdb..NetMPS
	)

while
	@LowLevel > 0 begin
	
	update
		nm
	set
		QtySubAlloc = coalesce
		(	(	select
					sum(nm1.QtyAvailable / (xr.XQty * xr.XScrap * xr.XSuffix))
				from
					tempdb..XRt xr
					join tempdb..NetMPS nm1
						on nm1.Part = xr.ChildPart
						and coalesce(nm1.Suffix, -1) = coalesce(xr.Suffix, -1)
				where
					xr.TopPart = nm.Part
					and nm1.SubForBOMID = nm.BOMID
			)
		,	0
		)
	from
		tempdb..NetMPS nm
	where
		nm.LowLevel = @LowLevel
	
	/*	Refactor...Add in more available material for substitutions. */
	
	update
		nm
	set	QtyBuildable = coalesce
		(	(	select
					min((nm1.QtyAvailable + nm1.QtySubAlloc) / (xr.XQty * xr.XScrap * xr.XSuffix))
				from
					tempdb..XRt xr
					join tempdb..NetMPS nm1
						on nm1.Part = xr.ChildPart
						and coalesce(nm1.Suffix, -1) = coalesce(xr.Suffix, -1)
				where
					xr.TopPart = nm.Part
					and xr.BOMLevel = 1
					and nm1.SubForBOMID != nm.BOMID
			)
		,	0
		)
	from
		tempdb..NetMPS nm

	set	@LowLevel = @LowLevel - 1
end

select
	*
from
	tempdb..NetMPS nm

select
	*
from
	tempdb..Y

select
	coalesce(oh.Serial, -1)
,	nm.Part
,	nm.BOMLevel
,	nm.Sequence
,	Suffix = 0
,	BOMID = coalesce(nm.BOMID, -1)
,	AllocationDT = oh.AllocationDT
,	QtyPer = nm.XQty
,	QtyAvailable = oh.QtyAvailable - coalesce(
	(	select
			sum(QtyIssue)
		from
			tempdb..Y y
		where
			y.Serial = oh.Serial
			and y.BOMID < nm.BOMID
		)
	,	0
	)
,	QtyRequired = nm.Balance + nm.QtyAvailable + nm.QtyWIP
,	QtyIssue = yInvAllocation.QtyIssue
,	QtyOverage =
		case
			when oh.Serial is null then nm.Balance
			when oh.Serial =
				(	select
						max(Serial)
					from
						tempdb..OnHand
					where
						Part = nm.Part
						and AllocationDT = coalesce(LastAllocation.LastAllocated, oh.AllocationDT)
				) then nm.Balance
			else 0
		end
from
	tempdb..NetMPS nm
	left join tempdb..Y yInvAllocation
		on nm.BOMID = yInvAllocation.BOMID
	left join tempdb..OnHand oh
		on yInvAllocation.Serial = oh.Serial
	left join
	(	select
			Part
		,	LastAllocated = max(AllocationDT)
		from
			tempdb..OnHand
		group by
			Part
	) LastAllocation
		on oh.Part = LastAllocation.Part
	join
	(	select
			Part
		,	TotalRequirement = sum(XQty)
		from
			tempdb..NetMPS
		group by
			Part
	) TotalRequirement
		on nm.Part = TotalRequirement.Part
order by
	nm.Sequence
,	oh.AllocationDT