
/*
Create schema Schema.Fx.Fx.sql
*/

--use Fx
--go

-- Create the database schema
if	schema_id('Fx') is null begin
	exec sys.sp_executesql N'create schema Fx authorization dbo'
end
go

