
/*
Create table fx21st.custom.WorkOrderDetailMattecSchedule
*/

--use fx21st
--go

--drop table custom.WorkOrderDetailMattecSchedule
if	objectproperty(object_id('custom.WorkOrderDetailMattecSchedule'), 'IsTable') is null begin

	create table custom.WorkOrderDetailMattecSchedule
	(	WorkOrderNumber varchar(50) not null
	,	WorkOrderDetailLine float not null default (0)
	,	QtyMattec numeric(20,6) not null
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	primary key
		(	WorkOrderNumber
		,	WorkOrderDetailLine
		)
	,	foreign key
		(	WorkOrderNumber
		,	WorkOrderDetailLine
		) references dbo.WorkOrderDetails
		(	WorkOrderNumber
		,	Line
		) on delete cascade on update cascade
	)
end
go

