SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[InventoryControl_QualityBatch_Objects]
as
select
	icqbo.QualityBatchNumber
,	icqbo.Line
,	icqbo.Serial
,	icqbo.Status
,	icqbo.Type
,	icqbo.Part
,	icqbo.OriginalQuantity
,	ScrappedQuantity = (select sum(at.std_quantity) from dbo.audit_trail at where at.serial = icqbo.Serial and at.date_stamp between icqbh.SortBeginDT and coalesce(icqbh.SortEndDT, getdate()) and at.type = 'Q' and to_loc in ('S'))
,	RemainingQuantity = coalesce(o.std_quantity, 0)
,	icqbo.Unit
,	icqbo.OriginalStatus
,	CurrentStatus = o.user_defined_status
,	icqbo.NewStatus
,	icqbo.ScrapQuantity
,	icqbo.Notes
,	icqbo.RowID
,	BoxLabelFormat = pi.label_format
,	Change = convert(char(1000), '')
,	IsSelected = 0
,	MarkAll = 0
from
	dbo.InventoryControl_QualityBatchObjects icqbo
	join dbo.InventoryControl_QualityBatchHeaders icqbh
		on icqbh.QualityBatchNumber = icqbo.QualityBatchNumber
	left join dbo.object o
		on o.serial = icqbo.Serial
	left join dbo.part_inventory pi
		on pi.part = icqbo.Part
GO
