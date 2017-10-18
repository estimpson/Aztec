
/*
Create view fx21st.dbo.MES_BackflushDetails
*/

--use fx21st
--go

--drop table dbo.MES_BackflushDetails
if	objectproperty(object_id('dbo.MES_BackflushDetails'), 'IsView') = 1 begin
	drop view dbo.MES_BackflushDetails
end
go

create view dbo.MES_BackflushDetails
as
select
	bh.SerialProduced
,	bh.PartProduced
,	bh.TranDT
,	bh.BackflushNumber
,	bh.WorkOrderNumber
,	bh.WorkOrderDetailLine
,	WODID = wod.RowID
,	bd.SerialConsumed
,	bd.PartConsumed
,	atCreate.lot
,	bd.QtyIssue
,	bd.QtyOverage
from
	dbo.BackflushHeaders bh
	join dbo.BackflushDetails bd
		on bh.BackflushNumber = bd.BackflushNumber
	join dbo.WorkOrderDetails wod
		on wod.WorkOrderNumber = bh.WorkOrderNumber
		and wod.Line = bh.WorkOrderDetailLine
	left join dbo.audit_trail atCreate
		on atCreate.type in ('R', 'J', 'A', 'B')
		and atCreate.date_stamp = (select min(date_stamp) from dbo.audit_trail where serial = bd.SerialConsumed)
		and atCreate.serial = bd.SerialConsumed
go

select
	*
from
	dbo.MES_BackflushDetails mbd
go

