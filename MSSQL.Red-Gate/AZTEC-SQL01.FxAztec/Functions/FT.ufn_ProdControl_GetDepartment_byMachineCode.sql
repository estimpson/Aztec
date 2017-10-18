SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [FT].[ufn_ProdControl_GetDepartment_byMachineCode]
(	@MachineCode varchar (10))
returns varchar (25)
as
/*
Example:
select	FT.ufn_ProdControl_GetDepartment_byMachineCode
	(	'10M1700')

Assertions:
1.	MachineCode [location.code] must be unique
	a.	Enforcement - primary key

Statistics:
Test syntax {
declare	@MachineCode varchar (10)

set	@MachineCode = '10M1700'

declare	@Department varchar (25)

select	@Department = group_no
from	location
where	code = @MachineCode
}

Results {
Table 'location'. Scan count 1, logical reads 2, physical reads 0, read-ahead reads 0.
}
*/
begin
	declare	@Department varchar (25)
	
	select	@Department = group_no
	from	location
	where	code = @MachineCode
	
	return	@Department
end
GO
