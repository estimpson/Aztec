SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[fn_MES_NetMPS]
()
returns @NetMPS table
(	ID int not null IDENTITY(1, 1) primary key
,	ShipToCode varchar(20) null
,	OrderNo int default (-1) not null
,	LineID int not null
,	Part varchar(25) not null
,	RequiredDT datetime not null --default (getdate()) 
,	GrossDemand numeric(30,12) not null
,	Balance numeric(30,12) not null
,	OnHandQty numeric(30,12) default (0) not null
,	WIPQty numeric(30,12) default (0) not null
,	BuildableQty numeric(30,12) null
,	LowLevel int not null
,	Sequence int not null
,	AccumGrossDemand numeric(30,12) null
,	AccumBalance numeric(30,12) null
,	unique
	(	OrderNo
	,	LowLevel
	,	ID
	)
,	unique
	(	Part
	,	Sequence
	,	OrderNo
	,	ID
	)
,	unique
	(	OrderNo
	,	LineID
	,	LowLevel
	,	OnHandQty
	,	ID
	)
,	unique
	(	ShipToCode
	,	Part
	,	ID
	)
)
as
begin
-- <Body>
	insert
		@NetMPS
	(	ShipToCode
	,	OrderNo
	,	LineID
	,	Part
	,	RequiredDT
	,	GrossDemand
	,	Balance
	,	OnHandQty
	,	WIPQty
	,	LowLevel
	,	Sequence)
	select
		ShipToCode = od.destination
	,	fgn.OrderNo
	,	fgn.LineID
	,	fgn.Part
	,	fgn.RequiredDT
	,	fgn.GrossDemand
	,	fgn.Balance
	,	fgn.OnHandQty
	,	fgn.WIPQty
	,	fgn.LowLevel
	,	fgn.Sequence
	from
		dbo.fn_GetNetout() fgn
		left join dbo.order_detail od
			on od.order_no = fgn.OrderNo
			and od.id = fgn.LineID
			and od.part_number = fgn.Part
	order by
		od.destination
	,	fgn.Part
	,	fgn.RequiredDT
	
	update
		nm
	set	BuildableQty = 
		(	select
				min(nm2.OnHandQty / (xr.XQty * xr.XScrap))
			from
				FT.XRt xr
				join @NetMPS nm2
					on nm2.OrderNo = nm.OrderNo
					and nm2.LineID = nm.LineID
					and nm2.Sequence = nm.Sequence + xr.Sequence
				left join FT.XRt xrC
					on xrC.TopPart = xr.ChildPart
					and xrC.Sequence > 0
			where
				xr.TopPart = nm.Part
				and xrC.TopPart is null
		)
	from
		@NetMPS nm
	
	update
		nm
	set
		AccumGrossDemand = (select sum(nm2.GrossDemand) from @NetMPS nm2 where coalesce(nm.ShipToCode, '') = coalesce(nm2.ShipToCode, '') and nm.Part = nm2.Part and nm.ID >= nm2.ID)
	,	AccumBalance = (select sum(nm2.Balance) from @NetMPS nm2 where coalesce(nm.ShipToCode, '') = coalesce(nm2.ShipToCode, '') and nm.Part = nm2.Part and nm.ID >= nm2.ID)
	from
		@NetMPS nm
	-- </Body>

--	<Return>
	return
end
GO
