SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE FUNCTION [dbo].[ufn_GetUserAccess] ()
RETURNS TABLE (
[SecurityID] [uniqueidentifier] NULL,
[ResourceID] [uniqueidentifier] NULL,
[Status] [int] NULL,
[Type] [int] NULL)
WITH EXECUTE AS CALLER
EXTERNAL NAME [FxSecurity_UserAccess_CLR].[UserAccess].[InitMethod]
GO
