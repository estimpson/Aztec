SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [FT].[TableKeyDefinitions]
as
select
	KeyName = kc.name
,	TableSchema = kcu.TABLE_SCHEMA
,	TableName = kcu.TABLE_NAME
,	ColumnName = kcu.COLUMN_NAME
,	Ordinal = kcu.ORDINAL_POSITION
,	ClusteredKey = objectproperty(kc.object_id, 'CnstIsClustKey')
from
	sys.key_constraints kc
	join INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
		on kcu.CONSTRAINT_SCHEMA = schema_name(kc.schema_id)
		and kcu.CONSTRAINT_NAME = kc.name
where
	kcu.TABLE_SCHEMA + '.' + kcu.TABLE_NAME not in
	(	select
			euo.ObjectName
		from
			FxSys.FXSYS.EmpowerUDOs euo
	)
GO
