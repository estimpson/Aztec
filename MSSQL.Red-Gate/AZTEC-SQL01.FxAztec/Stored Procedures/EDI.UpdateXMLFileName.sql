SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [EDI].[UpdateXMLFileName]
	@ID int
as
begin transaction
	set nocount on

	update	EDI.EDIDocuments 
	set		FileName = CONVERT(varchar, CONVERT(bigint, RowTS)) + '_' + FileName 
	where	(ID = @ID)	
	
	select @@ROWCOUNT as RowsChanged

commit transaction


GO
