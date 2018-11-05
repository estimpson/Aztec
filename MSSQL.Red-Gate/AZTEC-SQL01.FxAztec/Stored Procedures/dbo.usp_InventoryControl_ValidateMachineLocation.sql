SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[usp_InventoryControl_ValidateMachineLocation]
	@MachineLocation varchar(10)
,	@TranDT datetime out
,	@Result integer out
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
if not exists (
	select 
		1 
	from 
		dbo.location l 
	where 
		l.code = @MachineLocation ) begin

	set	@Result = 999998
	raiserror ('Location %s was not found in the system.', 16, 1, @MachineLocation)
	rollback tran @ProcName
	return
end

if ( (
	select 
		l.[type] 
	from 
		dbo.location l 
	where 
		l.code = @MachineLocation ) <> 'MC') begin

	set	@Result = 999999
	raiserror ('Location %s is not a machine location.', 16, 1, @MachineLocation)
	rollback tran @ProcName
	return
end
--- </Body>


--<CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit transaction @ProcName
end
--</CloseTran Required=Yes AutoCreate=Yes>

--	Success.
set	@Result = 0
return
	@Result

GO
