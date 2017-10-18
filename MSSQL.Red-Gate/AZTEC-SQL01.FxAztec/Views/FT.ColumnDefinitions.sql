SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [FT].[ColumnDefinitions]
as
with ColumnDefinitions
(	DatabaseName, TableName, Ordinal, ColumnName, DataType, IsIdentity, DefaultConstraint, IsNullable)
as
(	select
		DatabaseName = 'FxCoreModel'
	,	TableName = isc.TABLE_SCHEMA + '.' + isc.TABLE_NAME
	,	Ordinal = isc.ORDINAL_POSITION
	,	ColumnName = case isc.COLUMN_NAME when 'LineNo' then '[LineNo]' else isc.COLUMN_NAME end
	,	DataType = DATA_TYPE +
			case
				when isc.DATA_TYPE in ('varchar', 'char', 'nvarchar', 'nchar', 'binary', 'varbinary') and convert(varchar, isc.CHARACTER_MAXIMUM_LENGTH) = -1 then '(max)'
				when isc.DATA_TYPE in ('varchar', 'char', 'nvarchar', 'nchar', 'binary', 'varbinary') then '(' + convert(varchar, isc.CHARACTER_MAXIMUM_LENGTH) + ')'
				when isc.DATA_TYPE in ('numeric', 'decimal') then '(' + convert(varchar, isc.NUMERIC_PRECISION) + ',' + convert(varchar, isc.NUMERIC_SCALE) + ')'
				else ''
			end
	,	IsIdentity = case when columnproperty(object_id(isc.TABLE_SCHEMA + '.' + isc.TABLE_NAME), isc.COLUMN_NAME, 'IsIdentity') = 1 then 'identity' else '' end
	,	DefaultConstraint = coalesce('default ' + isc.COLUMN_DEFAULT, '')
	,	IsNullable = case isc.IS_NULLABLE when 'YES' then 'null' else 'not null' end
	from
		INFORMATION_SCHEMA.TABLES ist
		join INFORMATION_SCHEMA.COLUMNS isc
			on ist.TABLE_CATALOG = isc.TABLE_CATALOG
			and ist.TABLE_NAME = isc.TABLE_NAME
			and ist.TABLE_SCHEMA = isc.TABLE_SCHEMA
	where
		not exists
		(	select
				*
			from
				INFORMATION_SCHEMA.views isv
			where
				ist.TABLE_CATALOG + '.' + ist.TABLE_SCHEMA + '.' + ist.TABLE_NAME = isv.TABLE_CATALOG + '.' + isv.TABLE_SCHEMA + '.' + isv.TABLE_NAME
		)
		and not exists
		(	select
				*
			from
				FxSys.FXSYS.EmpowerUDOs euo
			where
				euo.Type = 1
				and euo.ObjectName = ist.TABLE_SCHEMA + '.' + ist.TABLE_NAME
		)
)
select
	cd.DatabaseName
,	cd.TableName
,	cd.Ordinal
,	cd.ColumnName
,	cd.DataType
,	cd.IsIdentity
,	cd.DefaultConstraint
,	cd.IsNullable
,	ColumnChecksum = convert(bigint, binary_checksum(*))
from
	ColumnDefinitions cd
GO
