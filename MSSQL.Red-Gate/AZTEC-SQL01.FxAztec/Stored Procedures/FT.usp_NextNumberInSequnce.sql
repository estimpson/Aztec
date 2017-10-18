SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [FT].[usp_NextNumberInSequnce]
	@KeyName sysname
,	@NextNumber varchar(50) out
,	@TranDT datetime out
,	@Result integer out
as
/*
Example:
Initial queries {
}

Test syntax {
declare
	@KeyName sysname
,	@NextNumber varchar(50)

set	@KeyName = 'dbo.ReceiverHeaders.ReceiverID'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = FT.usp_NextNumberInSequnce
	@KeyName = @KeyName
,	@NextNumber = @NextNumber out
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @NextNumber, @TranDT, @ProcResult
go

rollback
go

}

Results {
}
*/
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. FT.usp_Test
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
if	not exists
	(	select
			*
		from
			FT.NumberSequence with (UPDLOCK)
			join FT.NumberSequenceKeys on
				FT.NumberSequence.NumberSequenceID = FT.NumberSequenceKeys.NumberSequenceID
		where
			FT.NumberSequenceKeys.KeyName = @KeyName
	) begin
	set @Result = 999999
	raiserror('Error encountered in procedure %s.  Invalid KeyName %s.', 16, 1, @ProcName, @KeyName)
	rollback tran @ProcName
	return @Result
end
---	</ArgumentValidation>

--- <Body>
declare
	@Value bigint
,	@NumberMask varchar(50)

--	Get and increment the next value.
select
	@Value = FT.NumberSequence.NextValue
,	@NumberMask = FT.NumberSequence.NumberMask
from
	FT.NumberSequence with (UPDLOCK)
	join FT.NumberSequenceKeys on
		FT.NumberSequence.NumberSequenceID = FT.NumberSequenceKeys.NumberSequenceID
where
	FT.NumberSequenceKeys.KeyName = @KeyName

--- <Update rows="1">
set	@TableName = 'FT.NumberSequence'

update
	FT.NumberSequence
set
	NextValue = NextValue + 1
from
	FT.NumberSequence
	join FT.NumberSequenceKeys on
		FT.NumberSequence.NumberSequenceID = FT.NumberSequenceKeys.NumberSequenceID
where
	FT.NumberSequenceKeys.KeyName = @KeyName

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Update>

--	Mask the next value to create the next number.
select
	@NextNumber = FT.udf_NumberFromMaskAndValue (@NumberMask, @Value, @TranDT)

--- </Body>

---	<Return>
set	@Result = 0
return
	@Result
--- </Return>
GO
