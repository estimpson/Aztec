SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [FT].[ftsp_RebuildXRt]
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
execute	FT.ftsp_RebuildXRt
--<Debug>
	@Debug = 1
--</Debug>

Author:
Eric Stimpson
Copyright © 2004 Fore-Thought, LLC

Process:
--	I.	Replace previous with current.
--		A.	BillOfMaterial.
--		B.	Part Router.
--	II.	Truncate eXpanded Router.
--	III.	Rebuild eXpanded Router.
*/

--<Debug>
declare	@ProcStartDT datetime
declare	@StartDT datetime
if @Debug & 1 = 1 begin
	print	'START.   ' + Convert ( varchar (50), @StartDT )
	select	@ProcStartDT = GetDate ( )
end
--</Debug>

--<Tran>
if @@TranCount = 0 begin
	begin transaction RebuildXRtTran
end
save transaction RebuildXRtTran
--</Tran>

--	Declarations:
declare	@ProcResult integer,
	@Error integer

--	I.	Replace previous with current.
--<Debug>
if @Debug & 1 = 1 begin
	print	'I.	Replace previous with current...'
	select	@StartDT = GetDate ( )
end
--</Debug>
--		A.	BillOfMaterial.
--<Debug>
if @Debug & 1 = 1 begin
	print	'	A.	BillOfMaterial.'
end
--</Debug>
truncate table
	FT.BOM
--<Error Handling>
select	@Error = @@Error
if @Error != 0 begin
--<Debug>
	if @Debug & 1 = 1 begin
		print	'Error removing previous BillOfMaterial.'
		print	'Error: (' + Convert ( varchar, @Error ) + ')'
	end
--</Debug>
	rollback tran RebuildXRtTran
	return -100
end
--</Error Handling>

insert
	FT.BOM
(	BOMID
,	ParentPart
,	ChildPart
,	StdQty
,	ScrapFactor
,	SubstitutePart
)
select
	BOMID
,	ParentPart
,	ChildPart
,	StdQty
,	ScrapFactor
,	SubstitutePart
from
	FT.vwBOM

--<Error Handling>
select	@Error = @@Error
if @Error != 0 begin
--<Debug>
	if @Debug & 1 = 1 begin
		print	'Error moving current BillOfMaterial to previous BillOfMaterial.'
		print	'Error: (' + Convert ( varchar, @Error ) + ')'
	end
--</Debug>
	rollback tran RebuildXRtTran
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
select	@Error = @@Error
if @Error != 0 begin
--<Debug>
	if @Debug & 1 = 1 begin
		print	'Error removing prevous Part Router.'
		print	'Error: (' + Convert ( varchar, @Error ) + ')'
	end
--</Debug>
	rollback tran RebuildXRtTran
	return -100
end
--</Error Handling>

insert	FT.PartRouter
select
	Part
,   BufferTime
,   RunRate
,   CrewSize
from	FT.vwPRt
--<Error Handling>
select	@Error = @@Error
if @Error != 0 begin
--<Debug>
	if @Debug & 1 = 1 begin
		print	'Error moving current Part Router to previous Part Router.'
		print	'Error: (' + Convert ( varchar, @Error ) + ')'
	end
--</Debug>
	rollback tran RebuildXRtTran
	return -100
end
--</Error Handling>
--<Debug>
if @Debug & 1 = 1 begin
	print	'...Previous replaced.   ' + Convert ( varchar, DateDiff ( ms, @StartDT, GetDate ( ) ) ) + ' ms'
end
--</Debug>

--	II.	Truncate eXpanded Router.
--<Debug>
if @Debug & 1 = 1 begin
	print	'II.	Truncate eXpanded Router...'
	select	@StartDT = GetDate ( )
end
--</Debug>
truncate table
	FT.XRt

--<Error Handling>
select	@Error = @@Error
if @Error != 0 begin
--<Debug>
	if @Debug & 1 = 1 begin
		print	'Error truncating XRt.'
		print	'Error: (' + Convert ( varchar, @Error ) + ')'
	end
--</Debug>
	rollback tran RebuildXRtTran
	return -100
end
--</Error Handling>
--<Debug>
if @Debug & 1 = 1 begin
	print	'...Truncated.   ' + Convert ( varchar, DateDiff ( ms, @StartDT, GetDate ( ) ) ) + ' ms'
end
--</Debug>

--	III.	Rebuild eXpanded Router.
--<Debug>
if @Debug & 1 = 1 begin
	print	'III.	Rebuild eXpanded Router...'
	select	@StartDT = GetDate ( )
end
--</Debug>
execute	@ProcResult = FT.ftsp_BuildXRt
--<Debug>
	@Debug = @Debug
--</Debug>

--<Error Handling>
select	@Error = @@Error
if @ProcResult != 0 or @Error != 0 begin
--<Debug>
	if @Debug & 1 = 1 begin
		print	'Error executing ftsp_BuildXRt.'
		print	'ProcResult: (' + Convert ( varchar, @ProcResult ) + ')'
		print	'Error: (' + Convert ( varchar, @Error ) + ')'
	end
--</Debug>
	rollback tran RebuildXRtTran
	return -100
end
--</Error Handling>
--<Debug>
if @Debug & 1 = 1 begin
	print	'...Rebuilt.   ' + Convert ( varchar, DateDiff ( ms, @StartDT, GetDate ( ) ) ) + ' ms'
end
--</Debug>
--<Debug>
if @Debug & 1 = 1 begin
	print	'FINISHED.   ' + Convert ( varchar, DateDiff ( ms, @ProcStartDT, GetDate ( ) ) ) + ' ms'
end
--</Debug>
commit tran RebuildXRtTran
GO
