
/*
Create schema Schema.FxAztec.SHIP.sql
*/

use FxAztec
go

-- Create the database schema
if	schema_id('SHIP') is null begin
	exec sys.sp_executesql N'create schema SHIP authorization dbo'
end
go

