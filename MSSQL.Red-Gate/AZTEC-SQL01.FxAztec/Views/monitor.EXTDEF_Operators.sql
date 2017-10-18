SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [monitor].[EXTDEF_Operators]
as
select	OperatorID =
	(	select	count(1)
		from	dbo.employee emp1
		where	operator_code <= employee.operator_code),
	OperatorName = name,
	OperatorCode = operator_code,
	OperatorPWD = password,
	OperatorLoginValidation = binary_checksum(operator_code, password)
from	dbo.employee
GO
