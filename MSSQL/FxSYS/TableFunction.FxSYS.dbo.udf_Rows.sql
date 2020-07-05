
/*
Create function TableFunction.FxSYS.dbo.udf_Rows.sql
*/

use FxSYS
go

if	objectproperty(object_id('dbo.udf_Rows'), 'IsTableFunction') = 1 begin
	drop function dbo.udf_Rows
end
go

create function dbo.udf_Rows
(	@RowCount int
)
returns @Rows table
(	RowNumber int not null primary key
)
as
begin
--- <Body>
	if	@RowCount <= power(2, 16) begin
		insert
			@Rows
		(	RowNumber
		)
		select
			r.RowNumber
		from
			dbo.Rows r
		where
			r.RowNumber <= @RowCount
	end else begin
		insert
			@Rows
		(	RowNumber
		)
		select
			r.RowNumber + r2.RowNumber
		from
			(	select
					RowNumber = (r.RowNumber - 1) * power(2, 16)
				from
					dbo.Rows r
				where
					r.RowNumber - 1 <= @RowCount / power(2, 16)
			) r2
			cross join dbo.Rows r
		where
			r.RowNumber + r2.RowNumber <= @RowCount
	end
--- </Body>

---	<Return>
	return
end
go

select
	*
from
	dbo.udf_Rows(1000000) ur
order by
	ur.RowNumber
