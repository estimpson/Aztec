
/*
Create table fx21st.dbo.vwGetDate
*/

--use fx21st
--go

--drop table dbo.vwGetDate
if	objectproperty(object_id('dbo.vwGetDate'), 'IsView') = 1 begin
	drop view dbo.vwGetDate
end
go

create view dbo.vwGetDate
as
select
	CurrentDatetime = getdate()
go

