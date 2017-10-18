SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[usp_PriceAdmin_GetOldestActivated]
as
	set nocount on

	select	min(BlanketPriceChanges.EffectiveDate) as edate
    from	BlanketPriceChanges  
	where	(BlanketPriceChanges.Activated = 1) and  
			(BlanketPriceChanges.Cleared = 0)
GO
