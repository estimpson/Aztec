SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create PROCEDURE [FT].[ftsp_IncUpdXRt]
(
--<Debug>
	@Debug integer = 0
--</Debug>
)
as
/*
Arguments:
None

Result set:
None

Description:
Calculate the eXpanded Router datastructure.

Example:
begin transaction
execute	FT.ftsp_IncUpdXRt
--<Debug>
	@Debug = 1
--</Debug>
rollback
--commit

Author:
Eric Stimpson
Copyright © 2004 Fore-Thought, LLC

Process:
I.	Get differences.
	A.	Compare BOM.
		1.	Get current.
		2.	Compare current to previous.
	B.	Compare Part Router.
		1.	Get current.
		2.	Compare current to previous.
II.	Replace previous with current.
	A.	BOM.
	B.	Part Router.
III.	Remove obsolete from eXpanded Router.
IV.	Build eXpanded Router for deleted records.
*/
set nocount on

--<Debug>
declare	@ProcStartDT datetime
declare	@StartDT datetime
if @Debug & 1 = 1 begin
	set	@StartDT = GetDate ()
	print	'START.   ' + Convert (varchar (50), @StartDT)
	set	@ProcStartDT = GetDate ()
end
--</Debug>

--<Tran>
if @@TranCount = 0 begin
	begin transaction IncUpdXRtTran
end
save transaction IncUpdXRtTran
--</Tran>

--	Declarations:
declare	@ProcResult integer,
	@Error integer

declare @RegenParts table
(	Part varchar (25))

--	I.	Get differences.
--<Debug>
if @Debug & 1 = 1 begin
	print	'I.	Get differences...'
	set	@StartDT = GetDate ()
end
--</Debug>
--		A.	Compare BOM.
--<Debug>
if @Debug & 1 = 1 begin
	print	'	A.	Compare BOM.'
end
--</Debug>
--			1.	Get current.
--<Debug>
if @Debug & 1 = 1 begin
	print	'		1.	Get current.'
end
--</Debug>
declare @BOM table
(
	BOMID int primary key
,	ParentPart varchar (25)
,	ChildPart varchar (25)
,	StdQty numeric (20,6)
,	ScrapFactor numeric (20,6)
,	SubstitutePart bit
,	unique
	(
		BOMID
	,	StdQty
	)
)

/*
create table @BOM
(
	BOMID int primary key
,	ParentPart varchar (25)
,	ChildPart varchar (25)
,	StdQty numeric (20,6)
,	ScrapFactor numeric (20,6)
,	SubstitutePart bit
,	unique
	(
		BOMID
	,	StdQty
	)
)
*/

insert
	@BOM
select
	BOMID
,	ParentPart
,	ChildPart
,	StdQty
,	ScrapFactor
,	SubstitutePart
from
	FT.vwBOM

--			2.	Compare current to previous.
--<Debug>
if @Debug & 1 = 1 begin
	print	'		2.	Compare current to previous.'
end
--</Debug>
insert	@RegenParts
select
	Part = isnull (BOM.ParentPart, TBOM.ParentPart)
from
	FT.BOM BOM
	full outer join @BOM TBOM on BOM.BOMID = TBOM.BOMID
where	BOM.BOMID is null or
	TBOM.BOMID is null or
	BOM.StdQty != TBOM.StdQty or
	BOM.ChildPart != TBOM.ChildPart

/*
select	Part = isnull (BOM.ParentPart, TBOM.ParentPart)
from	FT.BOM BOM
	full outer join FT.vwBOM TBOM on BOM.BOMID = TBOM.BOMID
where	BOM.BOMID is null or
	TBOM.BOMID is null or
	BOM.StdQty != TBOM.StdQty
*/

--		B.	Compare Part Router.
--<Debug>
if @Debug & 1 = 1 begin
	print	'	B.	Compare Part Router.'
end
--</Debug>
--			1.	Get current.
--<Debug>
if @Debug & 1 = 1 begin
	print	'		1.	Get current.'
end
--</Debug>
declare @PartRouter table
(	Part varchar (25),
	BufferTime numeric (20,6),
	RunRate numeric (22,15),
	CrewSize numeric (20,6),
	unique (Part, BufferTime),
	unique (Part, RunRate))

/*
create table @PartRouter
(	Part varchar (25),
	BufferTime numeric (20,6),
	RunRate numeric (22,15),
	CrewSize numeric (20,6),
	unique (Part, BufferTime),
	unique (Part, RunRate))
*/

insert	@PartRouter
select
	Part,
	BufferTime,
	RunRate,
	CrewSize
from
	FT.vwPRT

--			2.	Compare current to previous.
--<Debug>
if @Debug & 1 = 1 begin
	print	'		2.	Compare current to previous.'
end
--</Debug>
insert	@RegenParts
select	IsNull (PartRouter.Part, TPartRouter.Part)
from	FT.PartRouter PartRouter
	full outer join @PartRouter TPartRouter on PartRouter.Part = TPartRouter.Part
where	PartRouter.Part is null or
	TPartRouter.Part is null or
	PartRouter.BufferTime != TPartRouter.BufferTime or
	PartRouter.RunRate != TPartRouter.RunRate
--<Debug>
if @Debug & 1 = 1 begin
	print	'...Differences calculated.   ' + Convert (varchar, DateDiff (ms, @StartDT, GetDate ())) + ' ms'
end
--</Debug>

--	II.	Replace previous with current.
--<Debug>
if @Debug & 1 = 1 begin
	print	'II.	Replace previous with current...'
	set	@StartDT = GetDate ()
end
--</Debug>
--		A.	BOM.
--<Debug>
if @Debug & 1 = 1 begin
	print	'	A.	BOM.'
end
--</Debug>
truncate table
	FT.BOM
--<Error Handling>
set	@Error = @@Error
if @Error != 0 begin
--<Debug>
	if @Debug & 1 = 1 begin
		print	'Error removing obsolete BOM.'
		print	'Error: (' + Convert (varchar, @Error) + ')'
	end
--</Debug>
	rollback tran IncUpdXRtTran
	return -100
end
--</Error Handling>

insert
	FT.BOM
select
	BOMID
,	ParentPart
,	ChildPart
,	StdQty
,	ScrapFactor
,	SubstitutePart
from
	@BOM

--<Error Handling>
set	@Error = @@Error
if @Error != 0 begin
--<Debug>
	if @Debug & 1 = 1 begin
		print	'Error inserting new BOM.'
		print	'Error: (' + Convert (varchar, @Error) + ')'
	end
--</Debug>
	rollback tran IncUpdXRtTran
	return -100
end
--</Error Handling>

--		B.	Part Router.
--<Debug>
if @Debug & 1 = 1 begin
	print	'	B.	Part Router.'
end
--</Debug>
truncate table
	FT.PartRouter
--<Error Handling>
set	@Error = @@Error
if @Error != 0 begin
--<Debug>
	if @Debug & 1 = 1 begin
		print	'Error removing obsolete Part Router.'
		print	'Error: (' + Convert (varchar, @Error) + ')'
	end
--</Debug>
	rollback tran IncUpdXRtTran
	return -100
end
--</Error Handling>

insert
	FT.PartRouter
select
	Part,
	BufferTime,
	RunRate,
	CrewSize
from	@PartRouter
--<Error Handling>
set	@Error = @@Error
if @Error != 0 begin
--<Debug>
	if @Debug & 1 = 1 begin
		print	'Error inserting new Part Router.'
		print	'Error: (' + Convert (varchar, @Error) + ')'
	end
--</Debug>
	rollback tran IncUpdXRtTran
	return -100
end
--</Error Handling>

--<Debug>
if @Debug & 1 = 1 begin
	print	'...Previous replaced.   ' + Convert (varchar, DateDiff (ms, @StartDT, GetDate ())) + ' ms'
end
--</Debug>

--	III.	Remove obsolete from eXpanded Router.
--<Debug>
if @Debug & 1 = 1 begin
	print	'III.	Remove obsolete from eXpanded Router...'
	set	@StartDT = GetDate()
end
--</Debug>
declare	@RemovedTopParts table
(	TopPart varchar (25) primary key)

/*
create table @RemovedTopParts
(	TopPart varchar (25) primary key)
*/

insert	@RemovedTopParts
select	XRt.TopPart
from	FT.XRt XRT
where	XRt.ChildPart in (select Part from @RegenParts)
group by
	XRt.TopPart

delete	FT.XRt
where	TopPart in
	(	select	TopPart
		from	@RemovedTopParts)
--<Error Handling>
set	@Error = @@Error
if @Error != 0 begin
--<Debug>
	if @Debug & 1 = 1 begin
		print	'Error deleting obsolete XRt.'
		print	'Error: (' + Convert (varchar, @Error) + ')'
	end
--</Debug>
	rollback tran IncUpdXRtTran
	return -100
end
--</Error Handling>
--<Debug>
if @Debug & 1 = 1 begin
	print	'...Removed.   ' + Convert (varchar, DateDiff (ms, @StartDT, GetDate ())) + ' ms'
end
--</Debug>

--	IV.	Build eXpanded Router for deleted records.
--<Debug>
if @Debug & 1 = 1 begin
	print	'IV.	Build eXpanded Router for deleted records...'
	set	@StartDT = GetDate()
end
--</Debug>
execute	@ProcResult = FT.ftsp_BuildXRt
--<Debug>
	@Debug = @Debug
--</Debug>

--<Error Handling>
set	@Error = @@Error
if @ProcResult != 0 or @Error != 0 begin
--<Debug>
	if @Debug & 1 = 1 begin
		print	'Error executing ftsp_BuildXRt.'
		print	'ProcResult: (' + Convert (varchar, @ProcResult) + ')'
		print	'Error: (' + Convert (varchar, @Error) + ')'
	end
--</Debug>
	rollback tran IncUpdXRtTran
	return -100
end
--</Error Handling>
--<Debug>
if @Debug & 1 = 1 begin
	print	'...Built.   ' + Convert (varchar, DateDiff (ms, @StartDT, GetDate ())) + ' ms'
end
--</Debug>
--<Debug>
if @Debug & 1 = 1 begin
	print	'FINISHED.   ' + Convert (varchar, DateDiff (ms, @ProcStartDT, GetDate ())) + ' ms'
end
--</Debug>
GO
