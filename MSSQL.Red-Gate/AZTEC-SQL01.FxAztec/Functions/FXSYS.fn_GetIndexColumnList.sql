SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [FXSYS].[fn_GetIndexColumnList]
(	@TableID int
,	@IndexID int)
returns varchar(max)
as
begin
	declare
		@ColumnList varchar(max)
	,	@Column sysname
	
	set	@ColumnList = ''
	
	declare
		IndexColumns
	cursor local for
	select
		c.name
	from
		sys.index_columns ic
		join sys.columns c on
			ic.object_id = c.object_id
			and
				ic.column_id = c.column_id
	where
		ic.object_id = @TableID
		and
			ic.index_id = @IndexID
	order by
		ic.index_column_id
	
	open
		IndexColumns

	fetch
		IndexColumns
	into
		@Column
	
	set @ColumnList = @Column
	
	fetch
		IndexColumns
	into
		@Column
	
	while @@fetch_status = 0 begin
	
		set @ColumnList = @ColumnList + ', ' + @Column
		
		fetch
			IndexColumns
		into
			@Column
	end
	
	close
		IndexColumns
	
	deallocate
		IndexColumns
	
	return @ColumnList
end
GO
