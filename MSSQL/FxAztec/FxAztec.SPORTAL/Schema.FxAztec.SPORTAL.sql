
/*
Create Schema.FxAztec.SPORTAL.sql
*/

use FxAztec
go

-- Create the database schema
if	schema_id('SPORTAL') is null begin
	exec sys.sp_executesql N'create schema SPORTAL authorization dbo'
end
go

