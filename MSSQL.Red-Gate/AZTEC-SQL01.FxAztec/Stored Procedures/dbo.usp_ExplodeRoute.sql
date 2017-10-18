SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_ExplodeRoute]
@TopPart varchar(25)
as

set nocount on

declare @XRt table
(	ID int identity primary key,
	TopPart varchar (25) not null,
	ChildPart varchar (25) not null,
	BOMID int null,
	Sequence smallint null,
	BOMLevel smallint default (0) not null,
	XQty float default (1) not null,
	XBufferTime float default (0) not null,
	XRunRate float default (0) not null,
	BeginOffset int default (0) not null,
	EndOffset int default (2147483647) not null,
	Infinite smallint default (0) not null,
	unique (BOMLevel, Infinite, ID),
	unique (BOMID, TopPart, BOMLevel, BeginOffset, EndOFfset, Infinite, ID),
	unique (TopPart, BeginOffset, Sequence, ID))

insert
	@XRt
(	TopPart,
	ChildPart)
select
	@TopPart
,	@TopPart

while @@RowCount > 0 begin
--		B.	Loading children.
	update
		@XRt
	set
		Infinite = 1
	from
		@XRt XRt
	where
		exists
		(	select
				1
			from
				@XRt XRt1
			where
				XRt.TopPart = XRt1.TopPart and
				XRt.BOMLevel > XRt1.BOMLevel and
				XRt.BeginOffset between XRt1.BeginOffset and XRt1.EndOffset and
				XRt.BOMID = XRt1.BOMID)

	insert
		@XRt
	(	TopPart, ChildPart, BOMID, BOMLevel, XQty, XBufferTime, XRunRate, BeginOffset, EndOffset)
	select
		XRt.TopPart,
		BOM.ChildPart,
		BOM.BOMID,
		BOMLevel + 1,
		XQty * StdQty,
		XBufferTime + IsNull (PartRouter.BufferTime, 0),
		XRunRate + IsNull (PartRouter.RunRate, 0),
		BeginOffset + ((EndOffset - BeginOffset) /
		(	select
				count (1)
			from
				(	select
						ParentPart = bom.parent_part
					,	ChildPart = bom.part
					,	BOMID = null
					,	StdQty = bom.std_qty
					from
						bill_of_material bom
				) BOM2
			where
				XRt.ChildPart = BOM2.ParentPart)) *
		(	select
				count (1)
			from
				(	select
						ParentPart = bom.parent_part
					,	ChildPart = bom.part
					,	BOMID = null
					,	StdQty = bom.std_qty
					from
						bill_of_material bom
				) BOM2
			where
				XRt.ChildPart = BOM2.ParentPart and
				BOM.ChildPart > BOM2.ChildPart) + 1,
		BeginOffset + ((EndOffset - BeginOffset) /
		(	select
				count (1)
			from
				(	select
						ParentPart = bom.parent_part
					,	ChildPart = bom.part
					,	BOMID = null
					,	StdQty = bom.std_qty
					from
						bill_of_material bom
				) BOM2
			where
				XRt.ChildPart = BOM2.ParentPart)) *
		(	select
				count (1)
			from
				(	select
						ParentPart = bom.parent_part
					,	ChildPart = bom.part
					,	BOMID = null
					,	StdQty = bom.std_qty
					from
						bill_of_material bom
				) BOM2
			where
				XRt.ChildPart = BOM2.ParentPart and
				BOM.ChildPart >= BOM2.ChildPart)
	from
		@XRt XRt
		join
		(	select
				ParentPart = bom.parent_part
			,	ChildPart = bom.part
			,	BOMID = null
			,	StdQty = bom.std_qty
			from
				bill_of_material bom
		) BOM on XRt.ChildPart = BOM.ParentPart
		left outer join
		(	select
				Part = part
			,	RunRate = 1 / nullif (parts_per_hour, 0)
			,	BufferTime = 0
			from
				dbo.part_machine pm
			where
				sequence = 1
		) PartRouter on BOM.ChildPart = PartRouter.Part
	where
		Infinite = 0 and
		BOMLevel =
		(	select
				Max (BOMLevel)
			from
				@XRt)
end

update	@XRt
set	Sequence =
	(	select	count (1)
		from	@XRt XRtC
		where	XRtC.TopPart = XRt.TopPart and
			XRtC.BeginOffset < XRt.BeginOffset)
from	@XRt XRt

select
	TopPart
,   ChildPart
,	Structure = space(BOMLevel * 3) + ChildPart
,	Machine = (select max(machine) from part_machine where part = ChildPart and sequence = 1)
,	Vendor = (select max(vendor) from part_vendor where part = ChildPart)
,	Vendor = (select name from vendor where code = (select max(vendor) from part_vendor where part = ChildPart))
,	Description = (select name from part where part = ChildPart)
,	PartClass = (select class from part where part = ChildPart)
,	PartType = (select type from part where part = ChildPart)
,	Commodity = (select commodity from part where part = ChildPart)
,	ProductLine = (select product_line from part where part = ChildPart)
,	OnHand = (select sum(std_quantity) from object where part = ChildPart and status = 'A')
,   BOMID
,   BOMLevel
,   XQty
,   XBufferTime
,   XRunRate
,   Infinite
from
	@XRt
order by
	TopPart
,	Sequence

GO
