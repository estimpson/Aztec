SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [FT].[sp_AddForeignKeys]
as
declare
	@ForeignKeyName sysname
,	@TableSchema sysname
,	@TableName sysname
,	@ColumnName sysname
,	@UniqueTableSchema sysname
,	@UniqueTableName sysname
,	@UniqueColumnName sysname
,	@CreateForeignKeySyntax nvarchar(max)
,	@UniqueColumnList nvarchar(max)

declare	ForeignKeys cursor local for
select distinct
	CONSTRAINT_NAME
,	TABLE_SCHEMA
,	TABLE_NAME
,	UNIQUE_CONSTRAINT_SCHEMA
,	UNIQUE_TABLE_NAME
from
	FT.REFERENTIAL_CONSTRAINT_DEFS
where
	CONSTRAINT_NAME not in
		(	select
				CONSTRAINT_NAME
			from
				FT.REFERENTIAL_CONSTRAINTS_COLUMN_USAGE
		)
	and CONSTRAINT_NAME not in ('FK__BackflushHeaders__21DB904F', 'FK__WorkOrderDetailB__22CFB488', 'FK__WorkOrderObjects__23C3D8C1')

open
	ForeignKeys

fetch
	ForeignKeys
into
	@ForeignKeyName
,	@TableSchema
,	@TableName
,	@UniqueTableSchema
,	@UniqueTableName

while	@@FETCH_STATUS = 0 begin
	
	set	@CreateForeignKeySyntax = N'alter table [' + @UniqueTableSchema + '].[' + @TableName + '] add constraint ' + @ForeignKeyName + ' foreign key ('
	
	declare	ForeignKeyColumns cursor local for
	select
		COLUMN_NAME
	,	UNIQUE_COLUMN_NAME
	from
		FT.REFERENTIAL_CONSTRAINT_DEFS
	where
		CONSTRAINT_NAME = @ForeignKeyName and
		TABLE_NAME = @TableName
	
	open
		ForeignKeyColumns
	
	fetch
		ForeignKeyColumns
	into
		@ColumnName
	,	@UniqueColumnName
		
	set	@CreateForeignKeySyntax = @CreateForeignKeySyntax + @ColumnName
	set	@UniqueColumnList = @UniqueColumnName
	
	fetch
		ForeignKeyColumns
	into
		@ColumnName
	,	@UniqueColumnName
		
	while	@@FETCH_STATUS = 0 begin
		set	@CreateForeignKeySyntax = @CreateForeignKeySyntax + ',' + @ColumnName
		set	@UniqueColumnList = @UniqueColumnList + ',' + @UniqueColumnName
		
		fetch
			ForeignKeyColumns
		into
			@ColumnName
		,	@UniqueColumnName
	end
	
	close
		ForeignKeyColumns
	
	deallocate
		ForeignKeyColumns
	
	set	@CreateForeignKeySyntax = @CreateForeignKeySyntax + ') references [' + @UniqueTableSchema + '].[' + @UniqueTableName + '] (' + @UniqueColumnList + ')'
	
	execute	sp_executesql @CreateForeignKeySyntax
	
	fetch
		ForeignKeys
	into
		@ForeignKeyName
	,	@TableSchema
	,	@TableName
	,	@UniqueTableSchema
	,	@UniqueTableName
	
	set	@CreateForeignKeySyntax = ''
	set	@UniqueColumnList = ''
end

close
	ForeignKeys

truncate table
	FT.REFERENTIAL_CONSTRAINT_DEFS
GO
