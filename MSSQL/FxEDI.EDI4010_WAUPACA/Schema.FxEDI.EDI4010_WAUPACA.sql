
/*
Create Schema.FxEDI.EDI4010_WAUPACA.sql
*/

use FxEDI
go

-- Create the database schema
if	schema_id('EDI4010_WAUPACA') is null begin
	exec sys.sp_executesql N'create schema EDI4010_WAUPACA authorization dbo'
end
go

