SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[TableStructure] as
select
	TableName = object_name(id)
,	colorder
,	name
,	usertype
,	type
,	length
,	prec
,	scale
,	isnullable
,	IsIdentity = columnproperty(id, name, 'IsIdentity')
from
	sys.syscolumns sc
where
	objectproperty(id, 'IsUserTable') = 1
GO
