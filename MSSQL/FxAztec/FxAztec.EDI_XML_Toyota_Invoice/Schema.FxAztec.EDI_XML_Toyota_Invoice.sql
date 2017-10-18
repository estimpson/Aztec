
/*
Create schema Schema.FxAztec.EDI_XML_Toyota_Invoice.sql
*/

use FxAztec
go

-- Create the database schema
if	schema_id('EDI_XML_Toyota_Invoice') is null begin
	exec sys.sp_executesql N'create schema EDI_XML_Toyota_Invoice authorization dbo'
end
go

