SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [FT].[ftsp_BuildXRt]
(
--<Debug>
	@Debug integer = 0--</Debug>
)
as
/*
Arguments:
None

Result set:
None

Description:
Build XRt for all missing rows.

Example:
execute	FT.ftsp_BuildXRt
--<Debug>
	@Debug = 1--</Debug>

Author:
Eric Stimpson
Copyright © 2004 Fore-Thought, LLC

Process:
I.	Create an empty copy of eXpanded Router table.
II.	Populate #eXpanded Router datastructure.
	A.	Load all missing parts.
	B.	Loading children.
		1.	Mark infinites.
II.	Set sequence on #eXpanded Routers.
III.	Write new #eXpanded Routers to permanent table.
*/
set nocount on

--<Debug>
declare	@ProcStartDT datetime
declare	@StartDT datetime
if @Debug & 1 = 1 begin
	select	@StartDT = GetDate ()
	print	'Start	' + Convert (varchar (50), @StartDT)
	select	@ProcStartDT = GetDate ()
end--</Debug>

--<Tran>
if @@TranCount = 0 begin
	begin transaction BuildXRtTran
end
else	begin
	save transaction BuildXRtTran
end
--</Tran>

--	Declarations:
declare	@ProcResult int,
	@Error int

--	I.	Create an empty copy of eXpanded Router table.
--<Debug>
if @Debug & 1 = 1 begin
	print	'I.	Create an empty copy of eXpanded Router table.'
end--</Debug>
declare @XRt table
(	ID int identity primary key,
	TopPart varchar (25) not null,
	ChildPart varchar (25) not null,
	BOMID int null,
	Sequence smallint null,
	BOMLevel smallint default (0) not null,
	XQty float default (1) not null,
	XScrap float default (1) not null,
	XBufferTime float default (0) not null,
	XRunRate float default (0) not null,
	BeginOffset int default (0) not null,
	EndOffset int default (2147483647) not null,
	Infinite smallint default (0) not null,
	unique (BOMLevel, Infinite, ID),
	unique (BOMID, TopPart, BOMLevel, BeginOffset, EndOFfset, Infinite, ID),
	unique (TopPart, BeginOffset, Sequence, ID))

--	II.	Populate #eXpanded Router datastructure.
--<Debug>
if @Debug & 1 = 1 begin
	print	'II.	Populate #eXpanded Router datastructure...'
	select	@StartDT = GetDate ()
end--</Debug>
--		A.	Load all missing parts.
--<Debug>
if @Debug & 1 = 1 begin
	print	'	A.	Load all missing parts.'
end--</Debug>
insert
	@XRt
(	TopPart
,	ChildPart
)
select
	Part
,	Part
from
	FT.PartRouter PartRouter
where
	not exists
	(
		select
			1
		from
			FT.XRt XRt
		where
			PartRouter.Part = XRt.TopPart
	)

while @@RowCount > 0 begin
--		B.	Loading children.
--<Debug>
	if @Debug & 1 = 1 begin
		print	'	B.	Loading children.'
	end--</Debug>
--			1.	Mark infinites.
--<Debug>
	if @Debug & 1 = 1 begin
		print	'		1.	Mark infinites.'
	end--</Debug>
	update	@XRt
	set	Infinite = 1
	from	@XRt XRt
	where	exists
		(	select	1
			from	@XRt XRt1
			where	XRt.TopPart = XRt1.TopPart and
				XRt.BOMLevel > XRt1.BOMLevel and
				XRt.BeginOffset between XRt1.BeginOffset and XRt1.EndOffset and
				XRt.BOMID = XRt1.BOMID)

	insert	@XRt
	(	TopPart, ChildPart, BOMID, BOMLevel, XQty, XScrap, XBufferTime, XRunRate, BeginOffset, EndOffset)
	select
		XRt.TopPart,
		BOM.ChildPart,
		BOM.BOMID,
		BOMLevel + 1,
		XQty * StdQty,
		XScrap * ScrapFactor,
		XBufferTime + IsNull (PartRouter.BufferTime, 0),
		XRunRate + IsNull (PartRouter.RunRate, 0),
		BeginOffset + ((EndOffset - BeginOffset) /
		(	select
				count (1)
			from
				FT.BOM BOM2
			where
				XRt.ChildPart = BOM2.ParentPart
				and
					BOM2.SubstitutePart = 0
		)) *
		(	select
				count (1)
			from
				FT.BOM BOM2
			where
				XRt.ChildPart = BOM2.ParentPart
				and
					BOM.ChildPart > BOM2.ChildPart
				and
					BOM2.SubstitutePart = 0
		) + 1,
		BeginOffset + ((EndOffset - BeginOffset) /
		(	select
				count (1)
			from
				FT.BOM BOM2
			where
				XRt.ChildPart = BOM2.ParentPart
				and
					BOM2.SubstitutePart = 0
		)) *
		(	select
				count (1)
			from
				FT.BOM BOM2
			where
				XRt.ChildPart = BOM2.ParentPart
				and
					BOM.ChildPart >= BOM2.ChildPart
				and
					BOM2.SubstitutePart = 0
		)
	from
		@XRt XRt
		join FT.BOM BOM on
			XRt.ChildPart = BOM.ParentPart
			and
				BOM.SubstitutePart = 0
		left outer join FT.PartRouter PartRouter on
			BOM.ChildPart = PartRouter.Part
	where
		Infinite = 0
		and
			BOMLevel = (select Max(BOMLevel) from @XRt)
end
--<Debug>
if @Debug & 1 = 1 begin
	print	'...@XRt populated.   ' + Convert (varchar, DateDiff (ms, @StartDT, GetDate ())) + ' ms'
end--</Debug>

--	II.	Set sequence on #eXpanded Routers.
--<Debug>
if @Debug & 1 = 1 begin
	print	'II.	Set sequence on #eXpanded Routers...'
	select	@StartDT = GetDate ()
end--</Debug>

update
	@XRt
set	Sequence =
	(	select	count (1)
		from	@XRt XRtC
		where	XRtC.TopPart = XRt.TopPart and
			XRtC.BeginOffset < XRt.BeginOffset)
from	@XRt XRt
--<Debug>
if @Debug & 1 = 1 begin
	print	'...Sequence set.   ' + Convert (varchar, DateDiff (ms, @StartDT, GetDate ())) + ' ms'
end--</Debug>

--	III.	Write new #eXpanded Routers to permanent table.
--<Debug>
if @Debug & 1 = 1 begin
	print	'III.	Write new #eXpanded Routers to permanent table...'
	select	@StartDT = GetDate ()
end--</Debug>
insert	FT.XRt
(	TopPart, ChildPart, BOMID, Sequence, BOMLevel, XQty, XScrap, XBufferTime, XRunRate, BeginOffset, EndOffset, Infinite)
select	TopPart, ChildPart, BOMID, Sequence, BOMLevel, XQty, XScrap, XBufferTime, XRunRate, BeginOffset, EndOffset, Infinite
from	@XRt
--<ErrorHnd>
select	@Error = @@Error
if @Error != 0 begin
--<Debug>
	if @Debug & 1 = 1 begin
		print	'Error writing new eXpanded Routers to permanent table.'
		print	'Error: (' + Convert (varchar, @Error) + ')'
	end--</Debug>
--<Tran>
	rollback tran BuildXRtTran--</Tran>
end--</ErrorHnd>
--<Debug>
if @Debug & 1 = 1 begin
	print	'...Written.   ' + Convert (varchar, DateDiff (ms, @StartDT, GetDate ())) + ' ms'
end--</Debug>
--<Debug>
if @Debug & 1 = 1 begin
	print	'Finished.   ' + Convert (varchar, DateDiff (ms, @ProcStartDT, GetDate ())) + ' ms'
end--</Debug>
GO
