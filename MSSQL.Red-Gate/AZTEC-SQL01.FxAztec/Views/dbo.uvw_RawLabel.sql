SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[uvw_RawLabel]
as

Select
	serial,
	Quantity,
	part.part part,
	part.name name,
	po_number,
	location,
	operator,
	last_date,
	lot
From
	object
join
	part on object.part = part.part

GO
