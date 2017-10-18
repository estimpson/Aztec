SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


Create procedure [dbo].[usp_RawLabel] @Serial int
as
begin
Select
	serial,
	Quantity,
	part,
	name,
	po_number,
	location,
	operator,
	last_date,
	lot
From
	object
where
	object.serial = @serial
end

GO
