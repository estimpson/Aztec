SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[usp_InventoryControl_CycleCount_AddObject]
	@User VARCHAR(10)
,	@CycleCountNumber VARCHAR(50)
,	@Serial INT = NULL
,	@TranDT DATETIME = NULL OUT
,	@Result INTEGER = NULL OUT
AS
SET NOCOUNT ON
SET ANSI_WARNINGS OFF
SET	@Result = 999999

--- <Error Handling>
DECLARE
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn INTEGER,
	@ProcResult INTEGER,
	@Error INTEGER,
	@RowCount INTEGER

SET	@ProcName = USER_NAME(OBJECTPROPERTY(@@procid, 'OwnerId')) + '.' + OBJECT_NAME(@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
DECLARE
	@TranCount SMALLINT

SET	@TranCount = @@TranCount
IF	@TranCount = 0 BEGIN
	BEGIN TRAN @ProcName
END
ELSE BEGIN
	SAVE TRAN @ProcName
END
SET	@TranDT = COALESCE(@TranDT, GETDATE())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*	If no #serialList exists, create one and add the passed serial to it. */
IF	OBJECT_ID('tempdb..#serialList') IS NULL BEGIN
	CREATE TABLE #serialList
	(	serial INT
	,	RowID INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	)
	
	INSERT
		#serialList
	SELECT
		Serial = @Serial
	WHERE
		@Serial IS NOT NULL
END

/*	Add serial(s) to cycle count objects. */
--- <Insert rows="*">
SET	@TableName = 'dbo.CycleCountHeaders'

INSERT
	dbo.InventoryControl_CycleCountObjects
(	CycleCountNumber
,	Line
,	Serial
,	Part
,	OriginalQuantity
,	Unit
,	OriginalLocation
)
SELECT
	CycleCountNumber = @CycleCountNumber
,	Line = COALESCE(icco.MaxLine, 0) + ROW_NUMBER() OVER (ORDER BY cco.RowID, cco.Serial)
,	Serial
,	Part
,	OriginalQuantity
,	Unit
,	OriginalLocation
FROM
	(	SELECT
			RowID = sl.RowID
		,	Serial = sl.serial
		,	Part = o.part
		,	OriginalQuantity = COALESCE(o.std_quantity,0)
		,	Unit = pi.standard_unit
		,	OriginalLocation = o.location
		FROM
			#serialList sl
			JOIN dbo.object o
				ON o.serial = sl.serial
			JOIN dbo.part p
				ON p.part = o.part
			JOIN dbo.part_inventory pi
				ON pi.part = o.part
		--union all
		--select
		--	RowID = sl.RowID
		--,	Serial = sl.serial
		--,	Part = at.part
		--,	Quantity = at.std_quantity
		--,	Unit = pi.standard_unit
		--,	Location = at.location
		--from
		--	#serialList sl
		--	join dbo.audit_trail atLast
		--		on atLast.serial = sl.serial
		--		and atLast.id =
		--		(	select
		--				max(id)
		--			from
		--				dbo.audit_trail
		--			where
		--				serial = sl.serial
		--		)
		--	join dbo.part p
		--		on p.part = atLast.part
		--	join dbo.part_inventory pi
		--		on pi.part = atLast.part
		--where
		--	sl.serial not in
		--	(	select
		--			serial
		--		from
		--			dbo.object
		--	)
	) cco
	LEFT JOIN
	(	SELECT
			MaxLine = MAX(Line)
		FROM
			dbo.InventoryControl_CycleCountObjects icco
		WHERE
			CycleCountNumber = @CycleCountNumber
	) icco ON 1 = 1

SELECT
	@Error = @@Error,
	@RowCount = @@Rowcount

IF	@Error != 0 BEGIN
	SET	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	ROLLBACK TRAN @ProcName
	RETURN
END
--- </Insert>
--- </Body>

--- <Tran AutoClose=Yes>
IF	@TranCount = 0 BEGIN
	COMMIT TRAN @ProcName
END
--- </Tran>

---	<Return>
SET	@Result = 0
RETURN
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
	@User varchar(10)
,	@CycleCountNumber varchar(50)
,	@Serial int = null

set	@User = 'mon'
set	@CycleCountNumber = '0'
set	@Serial = '0'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_InventoryControl_CycleCount_AddObject
	@User = @User
,	@CycleCountNumber = @CycleCountNumber
,	@Serial = @Serial
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
