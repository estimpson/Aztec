
/*
Create table fx21st.dbo.WorkOrderObjects
*/

--use fx21st
--go

begin transaction
go

exec sp_rename 'dbo.WorkOrderObjects', 'WorkOrderObjects_old'
go

--drop table dbo.WorkOrderObjects
if	objectproperty(object_id('dbo.WorkOrderObjects'), 'IsTable') is null begin

	create table dbo.WorkOrderObjects
	(	Serial int unique
	,	WorkOrderNumber varchar(50) not null
	,	WorkOrderDetailLine float not null default (0)
	,	Status int not null default(0)
	,	Type int not null default(0)
	,	PartCode varchar(25) not null
	,	PackageType varchar(25) null
	,	OperatorCode varchar(5) not null
	,	Quantity numeric(20,6) not null
	,	LotNumber varchar(20) null
	,	CompletionDT datetime null
	,	BackflushNumber varchar(50) null references dbo.BackflushHeaders(BackflushNumber)
	,	UndoBackflushNumber varchar(50) null references dbo.BackflushHeaders(BackflushNumber)
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	foreign key
		(	WorkOrderNumber
		,	WorkOrderDetailLine
		) references dbo.WorkOrderDetails
		(	WorkOrderNumber
		,	Line
		)
	)
end
go

insert
	dbo.WorkOrderObjects
(	Serial
,   WorkOrderNumber
,   WorkOrderDetailLine
,   Status
,   Type
,   PartCode
,   PackageType
,   OperatorCode
,   Quantity
,   CompletionDT
,   BackflushNumber
,   UndoBackflushNumber
,   RowCreateDT
,   RowCreateUser
,   RowModifiedDT
,   RowModifiedUser
)
select
	woo.Serial
,   woo.WorkOrderNumber
,   woo.WorkOrderDetailLine
,   woo.Status
,   woo.Type
,   woo.PartCode
,   woo.PackageType
,   woo.OperatorCode
,   woo.Quantity
,   woo.CompletionDT
,   woo.BackflushNumber
,   woo.UndoBackflushNumber
,   woo.RowCreateDT
,   woo.RowCreateUser
,   woo.RowModifiedDT
,   woo.RowModifiedUser
from
	dbo.WorkOrderObjects_old woo
go

select
	*
from
	dbo.WorkOrderObjects woo
go

drop table
	dbo.WorkOrderObjects_old
go

--commit
rollback
go

