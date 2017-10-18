
/*
Create table Fx.dbo.InventoryControl_QualityBatch_Headers
*/

--use Fx
--go

--drop table dbo.InventoryControl_QualityBatch_Headers
if	objectproperty(object_id('dbo.InventoryControl_QualityBatch_Headers'), 'IsView') = 1 begin
	drop view dbo.InventoryControl_QualityBatch_Headers
end
go

create view dbo.InventoryControl_QualityBatch_Headers
as
select
	icqbh.QualityBatchNumber
,	icqbh.Status
,	icqbh.Type
,	icqbh.Description
,	icqbh.SortBeginDT
,	icqbh.SortEndDT
,	SortCompleted = case when exists(select * from dbo.InventoryControl_QualityBatchObjects where QualityBatchNumber = icqbh.QualityBatchNumber and Status = 0) then 0 else 1 end
,	icqbh.SortCount
,	icqbh.SortedCount
,	icqbh.ScrapCount
,	ScrappedQuantity =
		(	select
				sum(at.std_quantity)
			from
				dbo.audit_trail at
			where
				at.serial in
					(	select
							Serial
						from
							dbo.InventoryControl_QualityBatchObjects icqbo
						where
							QualityBatchNumber = icqbh.QualityBatchNumber
					)
				and at.date_stamp between icqbh.SortBeginDT and coalesce(icqbh.SortEndDT, getdate())
				and at.type = 'Q'
				and to_loc in ('S')
		)
,	icqbh.ScrapQuantity
,	icqbh.RowID
from
	dbo.InventoryControl_QualityBatchHeaders icqbh
go

select
	*
from
	dbo.InventoryControl_QualityBatch_Headers icqbh
go

