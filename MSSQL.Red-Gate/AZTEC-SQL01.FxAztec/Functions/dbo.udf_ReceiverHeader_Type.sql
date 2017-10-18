SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[udf_ReceiverHeader_Type]
(	@ReceiverID int)
returns	int
as
begin
	declare
		@RecieverHeaderType int
	
	select
		@RecieverHeaderType = Type
	from
		dbo.ReceiverHeaders
	where
		ReceiverID = @ReceiverID
	
	return
		@RecieverHeaderType
end
GO
