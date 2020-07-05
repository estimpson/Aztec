
/*
Create Table.FxSYS.dbo.Rows.sql
*/

use FxSYS
go

/*
exec FT.sp_DropForeignKeys

drop table dbo.Rows

exec FT.sp_AddForeignKeys
*/
if	objectproperty(object_id('dbo.Rows'), 'IsTable') is null begin

	create table dbo.Rows
	(	RowNumber int primary key
	)
end
go
set nocount on

truncate table
	dbo.Rows
go

declare
	@row int = 0

while
	@row < power(2, 16) begin

	insert
		dbo.Rows
	(
		RowNumber
	)
	values
	(
		@row + 1
	)
	
	set @row += 1
end
go
