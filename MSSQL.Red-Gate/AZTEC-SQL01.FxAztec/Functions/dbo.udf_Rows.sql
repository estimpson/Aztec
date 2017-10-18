SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create function [dbo].[udf_Rows]
(	@Rows int)
returns @RowTable table 
(	RowNumber int primary key)
as
begin
	declare	@RowNumber int
	set	@RowNumber = 0
	
	while	@RowNumber < @Rows begin
		set	@RowNumber = @RowNumber + 1
		
		insert	@RowTable
		select	@RowNumber
	end
	
	return
end
GO
