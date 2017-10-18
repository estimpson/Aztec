
/*
Create schema Schema.FxEDI.FTP.sql
*/

use FxEDI
go

-- Create the database schema
if	schema_id('FTP') is null begin
	exec sys.sp_executesql N'create schema FTP authorization dbo'
end
go

