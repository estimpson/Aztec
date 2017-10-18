SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[usp_ReceivingDock_CreateReceiverLines_fromReceiverHeader]
(	@ReceiverID INT,
	@Result INT OUTPUT)
AS
SET ANSI_WARNINGS OFF
SET NOCOUNT ON
SET	@Result = 999999

--- <ErrorHandling>
DECLARE
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn INTEGER,
	@ProcResult INTEGER,
	@Error INTEGER,
	@RowCount INTEGER

SET	@ProcName = USER_NAME(OBJECTPROPERTY (@@procid, 'OwnerId')) + '.' + OBJECT_NAME (@@procid)  -- e.g. dbo.usp_Test
--- </ErrorHandling>

--- <Tran required=Yes autoCreate=Yes>
DECLARE
	@TranCount SMALLINT
SET	@TranCount = @@TranCount
IF	@TranCount = 0 BEGIN
	BEGIN TRAN @ProcName
END
SAVE TRAN @ProcName
--- </Tran>

--	Create receiver lines for Purchase Orders:
IF	dbo.udf_TypeName('ReceiverHeaders', dbo.udf_ReceiverHeader_Type(@ReceiverID)) = 'Purchase Order' BEGIN

	---< Check to see if Ship From is Valid for Receiver Type > -- Added 2014-04-30 Andre S. Boulanger Fore-Theought, LLC
	DECLARE @ShipFromType BIT,
			@VendorType BIT,
			@ReceiverShipFrom VARCHAR(20)

	SELECT @ReceiverShipFrom = ShipFrom
	FROM
		dbo.ReceiverHeaders
	WHERE
		ReceiverID = @ReceiverID
	
	SELECT @ShipFromType = 1
	FROM 
		dbo.destination d
	JOIN
	vendor v ON v.code = d.vendor
	WHERE d.plant IS NOT NULL AND
	COALESCE(outside_processor, 'N') = 'Y' AND
	d.plant = @ReceiverShipFrom

	SELECT @vendorType = 1
	FROM 
		dbo.destination d
	JOIN
	vendor v ON v.code = d.vendor
	WHERE d.plant IS NOT NULL AND
	COALESCE(outside_processor, 'N') = 'Y' AND
	d.vendor = @ReceiverShipFrom

	IF	COALESCE(@ShipFromType,0) = 1 OR COALESCE(@VendorType,0) = 1 BEGIN
		SET	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s . You must use an Outside Processor Receiver type for this Ship From. Put away current receiver and start again.', 16, 1, @ProcName, @Error, @CallProcName)
		ROLLBACK TRAN @ProcName
		RETURN @Result
	END

	--- <Call>	
	SET	@CallProcName = 'dbo.usp_ReceivingDock_CreateReceiverLines_fromPOReceiverHeader'
	EXECUTE
		@ProcReturn = dbo.usp_ReceivingDock_CreateReceiverLines_fromPOReceiverHeader
		@ReceiverID = @ReceiverID,
		@Result = @ProcResult OUT
	
	SET	@Error = @@Error
	IF	@Error != 0 BEGIN
		SET	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		ROLLBACK TRAN @ProcName
		RETURN @Result
	END
	IF	@ProcReturn != 0 BEGIN
		SET	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		ROLLBACK TRAN @ProcName
		RETURN @Result
	END
	IF	@ProcResult != 0 BEGIN
		SET	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		ROLLBACK TRAN @ProcName
		RETURN @Result
	END
	--- </Call>
END
ELSE IF dbo.udf_TypeName('ReceiverHeaders', dbo.udf_ReceiverHeader_Type(@ReceiverID)) = 'Outside Process' BEGIN

	--- <Call>	
	SET	@CallProcName = 'dbo.usp_ReceivingDock_CreateReceiverLines_fromOutPReceiverHeader'
	EXECUTE
		@ProcReturn = dbo.usp_ReceivingDock_CreateReceiverLines_fromOutPReceiverHeader
		@ReceiverID = @ReceiverID,
		@Result = @ProcResult OUT
	
	SET	@Error = @@Error
	IF	@Error != 0 BEGIN
		SET	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		ROLLBACK TRAN @ProcName
		RETURN @Result
	END
	IF	@ProcReturn != 0 BEGIN
		SET	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		ROLLBACK TRAN @ProcName
		RETURN @Result
	END
	IF	@ProcResult != 0 BEGIN
		SET	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return @Result
	end
	--- </Call>
end
else if dbo.udf_TypeName('ReceiverHeaders', dbo.udf_ReceiverHeader_Type(@ReceiverID)) = 'RMA' begin

	--- <Call>	
	set	@CallProcName = 'dbo.usp_ReceivingDock_CreateReceiverLines_fromRMAReceiverHeader'
	execute
		@ProcReturn = dbo.usp_ReceivingDock_CreateReceiverLines_fromRMAReceiverHeader
		@ReceiverID = @ReceiverID,
		@Result = @ProcResult out
	
	set	@Error = @@Error
	if	@Error != 0 begin
		set	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return @Result
	end
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return @Result
	end
	if	@ProcResult != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return @Result
	end
	--- </Call>
end
else if dbo.udf_TypeName('ReceiverHeaders', dbo.udf_ReceiverHeader_Type(@ReceiverID)) = 'Plant Transfer' begin

	--- <Call>	
	set	@CallProcName = 'dbo.usp_ReceivingDock_CreateReceiverLines_fromPlantTReceiverHeader'
	execute
		@ProcReturn = dbo.usp_ReceivingDock_CreateReceiverLines_fromPlantTReceiverHeader
		@ReceiverID = @ReceiverID,
		@Result = @ProcResult out
	
	set	@Error = @@Error
	if	@Error != 0 begin
		set	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return @Result
	end
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return @Result
	end
	if	@ProcResult != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return @Result
	end
	--- </Call>
end

--- <CloseTran required=Yes autoCreate=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
--- </CloseTran>

---	<Return success=True>
set	@Result = 0
return	@Result
--- </Return>

/*
begin transaction
go

exec dbo.usp_ReceivingDock_CreateReceiverLines_fromReceiverHeader 3, 0

select
	*
from
	dbo.ReceiverLines rl
go

rollback
go
*/


GO
