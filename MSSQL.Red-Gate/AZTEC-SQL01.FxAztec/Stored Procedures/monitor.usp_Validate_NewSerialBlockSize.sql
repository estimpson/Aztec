SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [monitor].[usp_Validate_NewSerialBlockSize]
(	@SerialBlockSize int)
as
/*
Message Number:
1000006

Example:
Positive Test syntax {
execute	monitor.usp_Validate_NewSerialBlockSize
	@SerialBlockSize = 10
}

Positive Results {
}

Negative Test syntax {
execute	monitor.usp_Validate_NewSerialBlockSize
	@SerialBlockSize = -1

Negative Results {
Msg 1000005, Level 16, State 1, Procedure usp_Validate_JCQuantity, Line 54
Quantity -1 is invalid.  Quantity must be greater than zero for this transaction..
}

Null Test syntax {
execute	monitor.usp_Validate_NewSerialBlockSize
	@SerialBlockSize = null

Null Results {
Msg 1000005, Level 16, State 1, Procedure usp_Validate_JCQuantity, Line 54
Quantity 0 is invalid.  Quantity must be greater than zero for this transaction..
}
*/
set nocount on
--- <Error Handling>
declare	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty (@@procid, 'OwnerId')) + '.' + object_name (@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--	I.	Validate that the specified block size (number of serials) is greater than zero.
if	not coalesce (@SerialBlockSize, -1) > 0 begin
	set	@ProcResult = 1000006
	RAISERROR ('Quantity %d is invalid.  Quantity must be greater than zero for this transaction.', 16, 1, @SerialBlockSize)
	return	@ProcResult
end

--	Valid:
return	0
GO
