SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create view [FxFS].[GetNewID]
as
select
	Value = newid()

GO
