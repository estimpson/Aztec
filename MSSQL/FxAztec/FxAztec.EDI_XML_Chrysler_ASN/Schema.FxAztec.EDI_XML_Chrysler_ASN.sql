
/*
Create schema Schema.FxAztec.EDI_XML_Chrysler_ASN.sql
*/

use FxAztec
go

-- Create the database schema
if	schema_id('EDI_XML_Chrysler_ASN') is null begin
	exec sys.sp_executesql N'create schema EDI_XML_Chrysler_ASN authorization dbo'
end
go

