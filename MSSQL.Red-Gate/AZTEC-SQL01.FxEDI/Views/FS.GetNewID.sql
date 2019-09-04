SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [FS].[GetNewID]
as
select
	Value = newid()
GO
