SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [FT].[udf_AdjustDT]
(	@ColumnDT datetime)
returns datetime
as
begin
	declare
		@AdjustedDT datetime
	
	select
		@AdjustedDT = coalesce (dateadd (week, datediff (week, dg.Value, getdate()), @ColumnDT), @ColumnDT)
	from
		FT.DTGlobals dg
	where
		Name = 'AdjustDT'
	
	return
		@AdjustedDT
end
GO
