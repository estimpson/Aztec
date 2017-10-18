SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE  [dbo].[usp_EMailMissingASNs]
--	@Param1 [scalar_data_type] ( = [default_value] ) ...
	@TranDT DATETIME OUT
,	@Result INTEGER OUT
AS
SET NOCOUNT ON
SET ANSI_WARNINGS OFF
SET	@Result = 999999
SET	ANSI_WARNINGS ON

--- <Error Handling>
DECLARE
	@CallProcName sysname,
	@TableName sysname  = N'#MissingASNs',
	@ProcName sysname,
	@ProcReturn INTEGER,
	@ProcResult INTEGER,
	@Error INTEGER,
	@RowCount INTEGER

SET	@ProcName = USER_NAME(OBJECTPROPERTY(@@procid, 'OwnerId')) + '.' + OBJECT_NAME(@@procid)  -- e.g. <schema_name, sysname, dbo>.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
DECLARE
	@TranCount SMALLINT

SET	@TranCount = @@TranCount
IF	@TranCount = 0 BEGIN
	BEGIN TRAN @ProcName
END
ELSE BEGIN
	SAVE TRAN @ProcName
END
SET	@TranDT = COALESCE(@TranDT, GETDATE())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>

DECLARE @Shipments TABLE 
	(
	ShipperID VARCHAR(25),
	DateShipped DATETIME,
	Operator VARCHAR(50),
	Destination VARCHAR(25),
	TradingPartnerCode VARCHAR(25), PRIMARY KEY (ShipperID)
	)

DECLARE	@Date1 DATETIME,
		@Date2 DATETIME

SELECT	@Date1 = DATEADD(MINUTE,-60, GETDATE())
SELECT	@Date2 = DATEADD(MINUTE,-10, GETDATE())

INSERT	@Shipments
	SELECT
		CASE WHEN es.trading_partner_code LIKE '%Mazda%' THEN RIGHT((REPLICATE('0', 6) +CONVERT(VARCHAR(20), s.id)),6) ELSE CONVERT(VARCHAR(15),s.id) END,
		s.date_shipped,
		MAX(e.name),
		s.destination,
		es.trading_partner_code
	FROM 
		dbo.Shipping_EDIDocuments sedi
	JOIN
		shipper s ON s.id = sedi.LegacyShipperID
	JOIN
		edi_setups es ON s.destination = es.destination
	JOIN
		shipper_detail sd ON s.id = sd.shipper
	LEFT JOIN
		employee e ON sd.operator = e.operator_code
	WHERE
		status IN ( 'Z', 'C') AND 
		s.date_shipped >= @Date1 AND  s.date_shipped <= @Date2  AND
		sedi.OverlayGroup IS NOT NULL AND
        ISNULL(sedi.FileStatus,0) <0
	GROUP BY
		s.id,
		s.date_shipped,
		s.destination,
		es.trading_partner_code
	
	



	
DECLARE @Exceptions TABLE 
	(
	ShipperID INT,
	Destination VARCHAR(25),
	DateShipped DATETIME,
	Operator VARCHAR(25),
	TradingPartnerCode VARCHAR(25),  PRIMARY KEY (ShipperID)
	)

INSERT
	@Exceptions
SELECT 
	Shipments.ShipperID,
	Shipments.Destination,
	Shipments.DateShipped,
	Shipments.Operator,
	Shipments.TradingPartnerCode 
FROM 
	@Shipments Shipments

ORDER BY 5,1

SELECT * INTO #MissingASNs FROM @Exceptions

--Select * From @Exceptions
	

IF EXISTS (SELECT 1 FROM @Exceptions)

BEGIN
		
		DECLARE
			@html NVARCHAR(MAX)
		
		EXEC [FT].[usp_TableToHTML]
			@tableName = @tablename
		,	@html = @html OUT
		
		DECLARE
			@EmailBody NVARCHAR(MAX)
		,	@EmailHeader NVARCHAR(MAX) = 'Please Verify / Correct / Send ASNs on iExchange' 

		SELECT
			@EmailBody =
				N'<H1>' + @EmailHeader + N'</H1>' +
				@html

	--print @emailBody

	EXEC msdb.dbo.sp_send_dbmail
		@profile_name = 'FxAlerts'
	,  	@recipients = 'rreyna@aztecmfgcorp.com; rjohnson@aztecmfgcorp.com;aboulanger@fore-thought.com;mkroll@aztecmfgcorp.com;hi-lo@aztecmfgcorp.com;rhines@aztecmfgcorp.com'
	, 	@subject = @EmailHeader
	,  	@body = @EmailBody
	,  	@body_format = 'HTML'
					
END
--- </Body>

---	<Return>
SET	@Result = 0
RETURN
	@Result
--- </Return>

/*
Example:
Initial queries
{

}

Test syntax
{

set statistics io on
set statistics time on
go


begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_EMailMissingASNs
	--@Param1 = @Param1
	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

if	@@trancount > 0 begin
	commit
end
go

set statistics io off
set statistics time off
go

}

Results {
}
*/















GO
