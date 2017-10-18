
/*
Create schema Schema.FxAztec.EDI_XML_V2040.sql
*/

use FxAztec
go

-- Create the database schema
if	schema_id('EDI_XML_V2040') is null begin
	exec sys.sp_executesql N'create schema EDI_XML_V2040 authorization dbo'
end
go

