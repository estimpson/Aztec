SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROCEDURE [dbo].[xp_Security_DeleteAccess] (@SecurityID [uniqueidentifier], @ResourceID [uniqueidentifier], @Message [nvarchar] (4000)=NULL OUTPUT)
WITH EXECUTE AS CALLER
AS EXTERNAL NAME [SQLCLR_StoredProcedure_DeleteAccess].[StoredProcedures].[DeleteAccess]
GO
