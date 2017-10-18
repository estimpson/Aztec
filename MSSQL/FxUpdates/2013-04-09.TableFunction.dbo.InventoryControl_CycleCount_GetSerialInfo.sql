
if	objectproperty(object_id('dbo.InventoryControl_CycleCount_GetSerialInfo'), 'IsTableFunction') = 1 begin
	drop function dbo.InventoryControl_CycleCount_GetSerialInfo
end
go

create function dbo.InventoryControl_CycleCount_GetSerialInfo
(	@Serial int
)
returns @SerialInfo table
(	Serial int
,	Part varchar(25)
,	Quantity numeric(20,6)
,	Unit char(2)
,	Location varchar(10)
,	LastTrans varchar(10)
,	LastTransDT datetime
,	LastTransID int
,	Recover int
)
as
begin
--- <Body>
	insert
		@SerialInfo
	(	Serial
	,	Part
	,	Quantity
	,	Unit
	,	Location
	,	LastTrans
	,	LastTransDT
	,	LastTransID
	,	Recover
	)
	select
		Serial = coalesce(o.serial, atLast.serial)
	,	Part = coalesce(o.part, atLast.part)
	,	Quantity = coalesce(o.quantity, atLast.quantity)
	,	Unit = coalesce(o.unit_measure, atLast.unit)
	,	Location = coalesce(o.location, atLast.from_loc)
	,	LastTrans = atLast.remarks
	,	LastTransDT = atLast.date_stamp
	,	LastTransID = atLast.ID
	,	Recover = case when o.serial is null then 1 else 0 end
	from
		dbo.audit_trail atLast
		left join dbo.object o
			on o.serial = @Serial
	where
		atLast.serial = @Serial
		and atLast.id =
			(	select
					max(at1.id)
				from
					dbo.audit_trail at1
				where
					at1.serial = @Serial
					and at1.date_stamp =
						(	select
								max(at2.date_stamp)
							from
								dbo.audit_trail at2
							where
								at2.serial = @Serial
						)
			)
	
	if	@@ROWCOUNT = 0 begin
		insert
			@SerialInfo
		(	Serial
		,	Part
		,	Quantity
		,	Unit
		,	Location
		,	LastTrans
		,	LastTransDT
		)
		select
			Serial = null
		,	Part = null
		,	Quantity = null
		,	Unit = null
		,	Location = null
		,	LastTrans = 'Not Found'
		,	LastTransDT = null
	end
--- </Body>

---	<Return>
	return
end
go

select
	icccgsi.Serial
,	icccgsi.Part
,	icccgsi.Quantity
,	icccgsi.Unit
,	icccgsi.Location
,	icccgsi.LastTrans
,	icccgsi.LastTransDT
,	icccgsi.Recover
from
	dbo.InventoryControl_CycleCount_GetSerialInfo(-1) icccgsi
go

select
	*
from
	dbo.InventoryControl_CycleCount_GetSerialInfo(497918) icccgsi

select
	Serial = atLast.serial
,	Part = atLast.part
,	Quantity = atLast.quantity
,	Unit = atLast.unit
,	Location = atLast.from_loc
,	LastTrans = atLast.remarks
,	LastTransDT = atLast.date_stamp
from
	dbo.audit_trail atLast
where
	atLast.serial = 497918
	and atLast.id =
		(	select
				max(at1.id)
			from
				dbo.audit_trail at1
			where
				at1.serial = 497918
				and at1.date_stamp =
					(	select
							max(at2.date_stamp)
						from
							dbo.audit_trail at2
						where
							at2.serial = 497918
					)
		)
