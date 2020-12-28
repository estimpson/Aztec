
/*
Create Schema.FxAztec.CDC.sql
*/

use FxAztec
go

-- Create the database schema
if	schema_id('CDC') is null begin
	exec sys.sp_executesql N'create schema CDC authorization dbo'
end
go

