
/*
Create schema Schema.FxEDI.FS.sql
*/

use FxEDI
go

-- Create the database schema
if	schema_id('FS') is null begin
	exec sys.sp_executesql N'create schema FS authorization dbo'
end
go

