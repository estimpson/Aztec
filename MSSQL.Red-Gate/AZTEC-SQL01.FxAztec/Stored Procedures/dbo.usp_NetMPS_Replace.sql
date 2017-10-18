SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_NetMPS_Replace]
	@TranDT datetime = null out
,	@Result integer = null out
as
set nocount on
set ansi_warnings off
set	@Result = 999999

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare
	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
else begin
	save tran @ProcName
end
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*	Create new NetMPS table. */
if	objectproperty(object_id('dbo.NetMPS_New'), 'IsTable') is not null begin
	drop table dbo.NetMPS_New
end

create table dbo.NetMPS_New
(	Status int not null default(0)
,	Type int not null default(0)
,	OrderNo int default (-1) not null
,	LineID int not null
,	Part varchar(25) not null
,	RequiredDT datetime not null
,	GrossDemand numeric(30,12) not null
,	Balance numeric(30,12) not null
,	OnHandQty numeric(30,12) default (0) not null
,	InTransitQty numeric(30,12) default (0) not null
,	WIPQty numeric(30,12) default (0) not null
,	LowLevel int not null
,	Sequence int not null
,	RowID int identity(1,1) primary key clustered
,	RowCreateDT datetime default(getdate())
,	RowCreateUser sysname default(suser_name())
,	RowModifiedDT datetime default(getdate())
,	RowModifiedUser sysname default(suser_name())
)

insert
	dbo.NetMPS_New
(	Type
,	OrderNo
,	LineID
,	Part
,	RequiredDT
,	GrossDemand
,	Balance
,	OnHandQty
,	InTransitQty
,	WIPQty
,	LowLevel
,	Sequence
)
select
	Type = case when fgn.OrderNo > 0 then 1 else 2 end
,	fgn.OrderNo
,   fgn.LineID
,   fgn.Part
,   fgn.RequiredDT
,   fgn.GrossDemand
,   fgn.Balance
,   fgn.OnHandQty
,   fgn.InTransitQty
,   fgn.WIPQty
,   fgn.LowLevel
,   fgn.Sequence
from
	dbo.fn_GetNetout() fgn

/*	Replace NetMPS table. */
if	objectproperty(object_id('dbo.NetMPS'), 'IsTable') is not null begin
	drop table dbo.NetMPS
end

exec sp_rename 'dbo.NetMPS_New', 'NetMPS'
--- </Body>

---	<CloseTran AutoCommit=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
---	</CloseTran AutoCommit=Yes>

---	<Return>
set	@Result = 0
return
	@Result
--- </Return>

/*
Example:
Initial queries
{

}

Test syntax
{

set statistics io on
set statistics time on
go

declare
	@Param1 [scalar_data_type]

set	@Param1 = [test_value]

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_NetMPS_Replace
	@Param1 = @Param1
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

if	@@trancount > 0 begin
	rollback
end
go

set statistics io off
set statistics time off
go

}

Results {
}
*/
GO
