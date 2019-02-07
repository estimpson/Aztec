
/*
Create Schema.FxAztec.RFR.sql
RF Receiving
*/

use FxAztec
go

-- Create the database schema
if	schema_id('RFR') is null begin
	exec sys.sp_executesql N'create schema RFR authorization dbo'
end
go

