SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_MES_SetSubstituteMaterial]
	@Operator varchar(5)
,	@PrimaryBOMID int
,	@SubstitutePart varchar(25)
,	@SubstitutionRate numeric(20,6)
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
save tran @ProcName
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*	Determine the appropriate action based on the passed values and the existance of a substitute material. */
/*		Delete substitution if the specified substitute material is null. */
if	@SubstitutePart is null begin

	--- <Call>	
	set	@CallProcName = 'dbo.usp_WorkOrders_DeleteSubstituteMaterial'
	execute
		@ProcReturn = dbo.usp_WorkOrders_DeleteSubstituteMaterial
		@Operator = @Operator
	,	@PrimaryBOMID = @PrimaryBOMID
	,	@TranDT = @TranDT out
	,	@Result = @ProcResult out
	
	set	@Error = @@Error
	if	@Error != 0 begin
		set	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcResult != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	--- </Call>
end

/*		Update substitution if it already exists. */
else if
	exists
	(	select
	 		*
	 	from
	 		dbo.MES_JobBillOfMaterials mjbom
	 	where
	 		mjbom.SubForRowID = @PrimaryBOMID
	) begin
	
	--- <Call>	
	set	@CallProcName = 'dbo.usp_WorkOrders_EditSubstituteMaterial'
	execute
		@ProcReturn = dbo.usp_WorkOrders_EditSubstituteMaterial
		@Operator = @Operator
	,	@PrimaryBOMID = @PrimaryBOMID
	,	@SubstitutePart = @SubstitutePart
	,	@SubstitutionRate = @SubstitutionRate
	,	@TranDT = @TranDT out
	,	@Result = @ProcResult out
	
	set	@Error = @@Error
	if	@Error != 0 begin
		set	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcResult != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	--- </Call>
end

/*		Create substitution. */
else
	begin

	--- <Call>	
	set	@CallProcName = 'dbo.usp_WorkOrders_CreateSubstituteMaterial'
	execute
		@ProcReturn = dbo.usp_WorkOrders_CreateSubstituteMaterial
		@Operator = @Operator
	,	@PrimaryBOMID = @PrimaryBOMID
	,	@SubstitutePart = @SubstitutePart
	,	@SubstitutionRate = @SubstitutionRate
	,	@TranDT = @TranDT out
	,	@Result = @ProcResult out
	
	set	@Error = @@Error
	if	@Error != 0 begin
		set	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcResult != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	--- </Call>
end

--- </Body>

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
	@Operator varchar(5)
,	@PrimaryBOMID int
,	@SubstitutePart varchar(25)
,	@SubstitutionRate numeric(20,6)

set	@Operator = '01956'
set	@PrimaryBOMID = 3
set	@SubstitutePart = null
set	@SubstitutionRate = -1

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_MES_SetSubstituteMaterial
	@Operator = @Operator
,	@PrimaryBOMID = @PrimaryBOMID
,	@SubstitutePart = @SubstitutePart
,	@SubstitutionRate = @SubstitutionRate
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
