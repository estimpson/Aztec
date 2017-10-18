SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [EDI].[InsertXML] 
	@Status int,
	@FileName nvarchar(128),
	@Data xml
as
begin transaction
	set nocount on

    insert into EDI.EDIdocuments
    (
		Status
     ,	FileName
     ,	Data        
    )
    values
    (
		@Status
     ,	@FileName
     ,	@Data
     )   
             
	select cast(SCOPE_IDENTITY() as int) as NewRecordID

commit transaction


GO
