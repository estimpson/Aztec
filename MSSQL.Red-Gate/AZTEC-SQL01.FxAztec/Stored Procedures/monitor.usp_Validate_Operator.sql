SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [monitor].[usp_Validate_Operator]
(	@OperatorCode varchar (5))
as
/*
Message Number:
60001

Example:
Positive Test syntax {
execute	monitor.usp_Validate_Operator
	@OperatorCode = 'N1008'
}

Positive Results {
Table 'employee'. Scan count 1, logical reads 2, physical reads 0, read-ahead reads 0.
}

Negative Test syntax {
execute	monitor.usp_Validate_Operator
	@OperatorCode = 'N1008'
}

Negative Results {
Table 'employee'. Scan count 1, logical reads 2, physical reads 0, read-ahead reads 0.
Msg 60001, Level 16, State 1, Procedure usp_Validate_Operator, Line 24
The operator ttttt is invalid and is required.
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

--	I.	Validate that the specified operator is valid.
if	not exists
	(	select	1
		from	dbo.employee
		where	employee.operator_code = @OperatorCode) begin
	set	@ProcResult = 60001
	RAISERROR (@ProcResult, 16, 1, @OperatorCode)
	return	@ProcResult
end

--	Valid:
return	0
GO
