
/*
Create Schema.FxAztec.SUPPLIEREDI.sql
*/

use FxAztec
go

-- Create the database schema
if	schema_id('SUPPLIEREDI') is null begin
	exec sys.sp_executesql N'create schema SUPPLIEREDI authorization dbo'
end
go

