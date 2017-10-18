
/*
Create schema Schema.FxAztec.EDI_XML.sql
*/

use FxAztec
go

-- Create the database schema
if	schema_id('EDI_XML') is null begin
	exec sys.sp_executesql N'create schema EDI_XML authorization dbo'
end
go

