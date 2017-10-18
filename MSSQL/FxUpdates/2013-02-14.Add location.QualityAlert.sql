
if	not exists
		(	select
				*
			from
				INFORMATION_SCHEMA.columns c
			where
				c.TABLE_SCHEMA + '.' + c.TABLE_NAME + '.' + c.COLUMN_NAME = 'dbo.location.QualityAlert'
		) begin
	alter table dbo.location add QualityAlert bit
end
go
