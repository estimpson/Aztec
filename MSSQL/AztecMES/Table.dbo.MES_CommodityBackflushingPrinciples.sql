
/*
Create table fx21st.dbo.MES_CommodityBackflushingPrinciples
*/

--use fx21st
--go

--drop table dbo.MES_CommodityBackflushingPrinciples
if	objectproperty(object_id('dbo.MES_CommodityBackflushingPrinciples'), 'IsTable') is null begin

	create table dbo.MES_CommodityBackflushingPrinciples
	(	Commodity varchar(25) not null references dbo.commodity(id) on update cascade on delete cascade unique
	,	Status int not null default(0)
	,	BackflushingPrinciple int not null default(0) -- Type Defn (dbo.MES_BackflushingPrinciples.Type).
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	)
end
go

