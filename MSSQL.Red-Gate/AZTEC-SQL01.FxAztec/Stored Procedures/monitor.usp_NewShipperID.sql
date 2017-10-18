SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [monitor].[usp_NewShipperID]
(	@NewShipperID integer out,
	@Result integer out)
as
/*
Example:
Test syntax {
begin tran NewShipperID_Test

declare	@NewShipperID integer

declare	@ProcReturn integer,
	@ProcResult integer,
	@Error integer

execute	@ProcReturn = monitor.usp_NewShipperID
	@NewShipperID = @NewShipperID out,
	@Result = @ProcResult out

set	@Error = @@error

select	ProcReturn = @ProcReturn, ProcResult = @ProcResult, Error = @Error, NewShipper = @NewShipperID, NextShipper = shipper
from	parameters

rollback
}

Results {
Table 'parameters'. Scan count 1, logical reads 2, physical reads 0, read-ahead reads 0.
Table 'shipper'. Scan count 1, logical reads 3, physical reads 0, read-ahead reads 0.
Table 'parameters'. Scan count 1, logical reads 2, physical reads 0, read-ahead reads 0.
Table 'admin'. Scan count 1, logical reads 1, physical reads 0, read-ahead reads 0.
Table 'parameters'. Scan count 1, logical reads 2, physical reads 0, read-ahead reads 0.
ProcReturn  ProcResult  Error       NewShipper  NextShipper
----------- ----------- ----------- ----------- -----------
0           0           0           3063776     3063777
Table 'parameters'. Scan count 1, logical reads 2, physical reads 0, read-ahead reads 0.
}
*/
set nocount on
set	@Result = 999999

--- <Error Handling>
declare	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty (@@procid, 'OwnerId')) + '.' + object_name (@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes>
declare	@TranCount smallint
set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
save tran @ProcName
--- </Tran>

--	I.	Run mold.
select	@NewShipperID = shipper
from	parameters with (TABLOCKX)

while	exists
	(	select	id
		from	shipper
		where	id  = @NewShipperID) begin

	set	@NewShipperID = @NewShipperID + 1
end

update	parameters
set	shipper = @NewShipperID + 1

--- <CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
--- </CloseTran Required=Yes AutoCreate=Yes>

--	II.	Return.
set	@Result = 0
return	@Result
GO
