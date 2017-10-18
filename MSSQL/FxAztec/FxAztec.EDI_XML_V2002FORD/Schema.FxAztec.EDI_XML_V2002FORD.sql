
/*
Create schema Schema.FxAztec.EDI_XML_V2002FORD.sql
*/

use FxAztec
go

-- Create the database schema
if	schema_id('EDI_XML_V2002FORD') is null begin
	exec sys.sp_executesql N'create schema EDI_XML_V2002FORD authorization dbo'
end
go

