SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create function [dbo].[udf_Decrypt]
(	@EData varchar(8000),
	@Key varchar(8000))
returns	varchar(8000)
begin
	DECLARE @retVal INT
	DECLARE @comHandle INT
	DECLARE @errorSource VARCHAR(8000)
	DECLARE @errorDescription VARCHAR(8000)
	DECLARE @retString VARCHAR(8000); set @retString = null;

	-- Initialize the DevPowerEncrypt.EnCrypt component.
	EXEC @retVal = sp_OACreate 'DevPowerEncrypt.EnCrypt', @comHandle OUTPUT
	IF (@retVal <> 0)
	BEGIN
		-- Trap errors if any
		EXEC sp_OAGetErrorInfo @comHandle, @errorSource OUTPUT, @errorDescription OUTPUT
--		SELECT 'Create', [Error Source] = @errorSource, [Description] = @errorDescription
		set	@retString = @errorDescription
		RETURN	@retString
	END

	-- Call Decrypt into the component
	EXEC @retVal = sp_OAMethod @comHandle, 'decrypt', @retString OUTPUT, @sFrom=@EData, @sKey = @Key
	IF (@retVal <> 0)
	BEGIN
		-- Trap errors if any
		EXEC sp_OAGetErrorInfo @comHandle, @errorSource OUTPUT, @errorDescription OUTPUT
--		SELECT 'Call', [Error Source] = @errorSource, [Description] = @errorDescription
		set	@retString = @errorDescription
		RETURN	@retString
	END

	-- Release the reference to the COM object
	EXEC sp_OADestroy @comHandle
	
	return	@retString
end
GO
