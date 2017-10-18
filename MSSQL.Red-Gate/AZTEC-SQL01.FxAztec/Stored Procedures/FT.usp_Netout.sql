SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [FT].[usp_Netout]
--	<Debug>
(	@Debug integer = 0 )
--	</Debug>
as
/*
Arguments:
None

Result set:
None

Description:
Calculate net requirements.

Example:
--	Cannot be tested directly.  Call FT.usp_StoreNetout.

Author:
Eric Stimpson
Copyright © 2004 Fore-Thought, LLC

Process:
--	I.	Netout.
--		A.	Loop lowlevel code.
--			1.	Loop available inventory.
--				a.	Loop requirements.
--					1)	Assign inventory.
--						i.)	Demand exceeds inventory.
--						ii.)	Inventory exceeds demand.
--			2.	Assign available inventory to WIP.
--			3.	Recalc balance.
--	II.	Finished
*/

--<Debug>
declare	@ProcStartDT datetime
declare	@StartDT datetime
if @Debug & 1 = 1 begin
	select	@StartDT = GetDate ( )
	select	@ProcStartDT = GetDate ( )
	print	'Netout START.   ' + Convert ( varchar (50), @ProcStartDT )
end
--</Debug>

--	I.	Netout.
--	Loop through demand in Net MPS datastructure and assign on hand and WIP
--	on hand quantities, resulting in net demand.
declare	@LowLevel integer
select	@LowLevel = 0

--		A.	Loop lowlevel code.
while @LowLevel <=
(	select	Max ( LowLevel )
	from	#NetMPS )
begin
--	<Debug>
	if @Debug & 2 = 2
		insert
			#Debug
		(	Name,
			Value )
		select
			'LowLevel',
			@LowLevel
--	</Debug>

--			1.	Loop available inventory.
--	<Cursor>
	declare	PartsOnHand cursor local for
	select	Part,
		OnHand
	from	#OnHand
	where	OnHand > 0 and
		LowLevel = @LowLevel
	order by
		Part
--	</Cursor>

	open	PartsOnHand

	declare	@Part varchar (25),
		@OnHand float

	fetch	PartsOnHand
	into	@Part,
		@OnHand

--	<Cursor>
	while @@fetch_status = 0
--	</Cursor>
	begin
--	<Debug>
		if @Debug & 2 = 2
		begin
			insert
				#Debug
			(	Name,
				Value )
			select	'Part',
				@Part
			insert	#Debug
			(	Name,
				Value )
			select	'OnHand',
				@OnHand
		end
--	</Debug>
--				a.	Loop requirements.
--	<Cursor>
		declare	Requirements cursor local for
		select	ID,
			Balance,
			OrderNo,
			LineID,
			Sequence
		from	#NetMPS
		where	Part = @Part and
			Balance > 0
		order by
			RequiredDT asc
--	</Cursor>

		open	Requirements

		declare	@ReqID integer,
			@Balance float,
			@OrderNo integer,
			@LineID integer,
			@Sequence integer

		fetch	Requirements
		into	@ReqID,
			@Balance,
			@OrderNo,
			@LineID,
			@Sequence

--	<Cursor>
		while	@@fetch_status = 0 and @OnHand > 0
--	</Cursor>
		begin
--	<Debug>
			if @Debug & 2 = 2
			begin
				insert	#Debug
				(	Name,
					Value )
				select	'ReqID',
					@ReqID
				insert	#Debug
				(	Name,
					Value )
				select	'Balance',
					@Balance
				insert	#Debug
				(	Name,
					Value )
				select	'OrderNO',
					@OrderNO
				insert	#Debug
				(	Name,
					Value )
				select	'LineID',
					@LineID
				insert	#Debug
				(	Name,
					Value )
				select	'Sequence',
					@Sequence
			end
--	</Debug>

--					1)	Assign inventory.
			if @Balance > @OnHand
			begin
--	<Debug>
				if @Debug & 2 = 2
					insert	#Debug
					(	Name )
					select	'Use total quantity'
--	</Debug>
--						i.)	Demand exceeds inventory.
				update	#NetMPS
				set	Balance = @Balance - @OnHand,
					OnHandQty = OnHandQty + @OnHand
				where	ID = @ReqID

				insert	#X
				(	Part,
					OnhandQty,
					OrderNo,
					LineID,
					Sequence,
					WIPQty )
				select	Part = @Part,
					OnhandQty = @OnHand,
					OrderNo = @OrderNo,
					LineID = @LineID,
					Sequence = @Sequence + Sequence,
					WIPQty = @OnHand * XQty * XScrap
				from	FT.XRt
				where	XRt.TopPart = @Part and
					XRt.Sequence > 0

				select	@OnHand = 0

--	<Debug>
				if @Debug & 2 = 2
					insert	#Debug
					(	Name,
						Value )
					select	'OnHand',
						@OnHand
--	</Debug>
			end
			else
			begin
--	<Debug>
				if @Debug & 2 = 2
					insert	#Debug
					(	Name )
					select	'Use partial quantity'
--	</Debug>

--						ii.)	Inventory exceeds demand.
				update	#NetMPS
				set	Balance = 0,
					OnHandQty = OnHandQty + @Balance
				where	ID = @ReqID

				insert
					#X
				(	Part,
					OnhandQty,
					OrderNo,
					LineID,
					Sequence,
					WIPQty )
				select
					Part = @Part,
					OnhandQty = @Balance,
					@OrderNo,
					@LineID,
					Sequence = @Sequence + Sequence,
					WIPQty = @Balance * XQty * XScrap
				from
					FT.XRt
				where
					XRt.TopPart = @Part
					and
						XRt.Sequence > 0

				select	@OnHand = @OnHand - @Balance

--	<Debug>
				if @Debug & 2 = 2
					insert	#Debug
					(	Name,
						Value )
					select	'OnHand',
						@OnHand
--	</Debug>
			end

			fetch	Requirements
			into	@ReqID,
				@Balance,
				@OrderNo,
				@LineID,
				@Sequence
		end

--	<Cursor>
		close	Requirements
		deallocate
			Requirements
--	</Cursor>

		fetch	PartsOnHand
		into	@Part,
			@OnHand
	end

--	<Cursor>
	close	PartsOnHand
	deallocate
		PartsOnHand
--	</Cursor>

	select	@LowLevel = @LowLevel + 1

--	<Debug>
	if @Debug & 2 = 2
		insert	#Debug
		(	Name )
		select	'Set WIPQty'
--	</Debug>

--			2.	Assign available inventory to WIP.
	update	#NetMPS
	set	WIPQty = IsNull (
		(	select	Sum ( WIPQty )
			from	#X
			where	#NetMPS.OrderNo = #X.OrderNo and
				#NetMPS.LineID = #X.LineID and
				#NetMPS.Sequence = #X.Sequence ), 0 )
	where	LowLevel = @LowLevel

--	<Debug>
	if @Debug & 2 = 2
		insert	#Debug
		(	Name )
		select	'Set Next Balance'
--	</Debug>

--			3.	Recalc balance.
	update	#NetMPS
	set	Balance = Balance - WIPQty
	where	LowLevel = @LowLevel

--	<Debug>
	if @Debug & 2 = 2
		insert	#Debug
		(	Name,
			Value )
		select	'Rows',
			@@RowCount
--	</Debug>
end

--	II.	Finished
--<Debug>
if @Debug & 1 = 1 begin
	print	'FINISHED.   ' + Convert ( varchar, DateDiff ( ms, @ProcStartDT, GetDate ( ) ) ) + ' ms'
end
--</Debug>
GO
