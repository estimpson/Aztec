SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [FT].[sp_DropForeignKeys]
as
if	not exists
	(	select
			*
		from
			FT.REFERENTIAL_CONSTRAINT_DEFS) begin

	insert
		FT.REFERENTIAL_CONSTRAINT_DEFS
	select
		*
	from
		FT.REFERENTIAL_CONSTRAINTS_COLUMN_USAGE
	order by
		CONSTRAINT_NAME
	,	ORDINAL_POSITION

	declare
		@ForeignKeyName sysname
	,	@TableSchema sysname
	,	@TableName sysname
	,	@DropForeignKeySyntax nvarchar(max)

	declare	ForeignKeys cursor local for
	select distinct
		CONSTRAINT_NAME
	,	TABLE_SCHEMA
	,	TABLE_NAME
	from
		FT.REFERENTIAL_CONSTRAINT_DEFS

	open
		ForeignKeys

	fetch
		ForeignKeys
	into
		@ForeignKeyName
	,	@TableSchema
	,	@TableName

	while	@@FETCH_STATUS = 0 begin
		
		set	@DropForeignKeySyntax = N'alter table [' + @TableSchema + '].[' + @TableName + '] drop constraint ' + @ForeignKeyName
		
		execute	sp_executesql @DropForeignKeySyntax
		
		fetch
			ForeignKeys
		into
			@ForeignKeyName
		,	@TableSchema
		,	@TableName
	end

	close	ForeignKeys
end
GO
