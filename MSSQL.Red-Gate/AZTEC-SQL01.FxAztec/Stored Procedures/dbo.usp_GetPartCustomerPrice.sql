SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_GetPartCustomerPrice] 
as
	set nocount on

	select part, customer, null as 'effective_date', blanket_price
	from part_customer
GO
