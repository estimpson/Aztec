SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[fn_MES_InventoryInquiry]
(	@Serial int
)
returns @inventoryInquiry table
(	Serial int
,	InventoryStatus varchar(25)
,	PartCode varchar(25)
,	PartDescription varchar(100)
,	LocationCode varchar(10)
,	Qty numeric(20,6)
,	Unit char(2)
,	Status varchar(30)
,	TransType char(2)
,	TransDT datetime
,	TransDescription varchar(10)
,	TransQty numeric(20,6)
,	TransLocation varchar(10)
)
as
begin
--- <Body>
	declare
		@auditTrail table
	(	Serial int
	,	Part varchar(25)
	,	PartDescription varchar(100)
	,	Status varchar(30)
	,	TransType char(2)
	,	TransDT datetime
	,	TransDescription varchar(10)
	,	TransQty numeric(20,6)
	,	Location varchar(10)
	)
	
	insert
		@auditTrail
	select
		Serial = at.serial
	,	Part = at.part
	,	PartDescription = coalesce(p.name, at.part_name)
	,	Status = at.user_defined_status
	,	TransType = at.type
	,	TransDT = at.date_stamp
	,	TransDescription = at.remarks
	,	TransQty = at.std_quantity
	,	Location = at.to_loc
	from
		dbo.audit_trail at
		left join dbo.part p
			on p.part = at.part
		left join dbo.part_inventory pi
			on pi.part = at.part
	where
		serial = @Serial
	
	insert
		@inventoryInquiry
	select
		Serial = coalesce(o.serial, atLastTrans.Serial)
	,	InventoryStatus = case when o.serial is not null then 'Inventory' else 'Not In Inventory' end
	,	PartCode = coalesce(o.part, atLastTrans.Part)
	,	PartDescription = coalesce(p.name, atLastTrans.PartDescription)
	,	LocationCode = coalesce(o.location, atLastTrans.Location)
	,	Qty = coalesce(o.std_quantity, 0)
	,	Unit = pi.standard_unit
	,	Status = coalesce(o.user_defined_status, atLastTrans.Status)
	,	TransType = at.TransType
	,	TransDT = at.TransDT
	,	TransDescription = at.TransDescription
	,	TransQty = at.TransQty
	,	TransLocation = at.Location
	from
		@auditTrail at
		join @auditTrail atLastTrans
			on atLastTrans.Serial = at.Serial
			and atLastTrans.TransDT = (select max(TransDT) from @auditTrail where Serial = atLastTrans.serial)
		left join dbo.object o
			on o.serial = at.Serial
		join dbo.part p
			on p.part = at.Part
		join dbo.part_inventory pi
			on pi.part = at.Part
	order by
		at.TransDT

--- </Body>

---	<Return>
	return
end
GO
