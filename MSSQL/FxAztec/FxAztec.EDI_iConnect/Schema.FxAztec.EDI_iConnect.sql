
/*
Create schema Schema.FxAztec.EDI_iConnect.sql
*/

use FxAztec
go

-- Create the database schema
if	schema_id('EDI_iConnect') is null begin
	exec sys.sp_executesql N'create schema EDI_iConnect authorization dbo'
end
go

