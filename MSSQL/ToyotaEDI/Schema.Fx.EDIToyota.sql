
/*
Create schema Schema.Fx.EDIToyota.sql
*/

--use Fx
--go

-- Create the database schema
if	schema_id('EDIToyota') is null begin
	exec sys.sp_executesql N'create schema EDIToyota authorization dbo'
end
go

