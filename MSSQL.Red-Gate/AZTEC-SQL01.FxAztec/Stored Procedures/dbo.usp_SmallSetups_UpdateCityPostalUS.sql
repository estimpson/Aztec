SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[usp_SmallSetups_UpdateCityPostalUS] (	
	@statecode char(2),
	@city varchar(100),
	@county varchar(100),
	@zipcode char(5),
	@zipcodetype varchar(50),
	@latitude real,
	@longitude real,
	@TranDT datetime = null out,
	@Result int = 0 out)
as

set nocount on
set	@Result = 999999

--- <Error Handling>
declare	
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn int,
	@ProcResult int,
	@Error int,
	@RowCount int
	
set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
save tran @ProcName
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

	
		
-- Update CityPostalUS
set		@TableName = 'dbo.CityPostalUS'
update 
		dbo.CityPostalUS
set 
		StateCode = @statecode
	,	City = @city
	,	County = @county
	,	ZipCode = @zipcode
	,	ZipCodeType = @zipcodetype
	,	Latitude = @latitude
	,	Longitude = @longitude
where	
		StateCode = @statecode

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return @Result
end



--<CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit transaction @ProcName
end
--</CloseTran Required=Yes AutoCreate=Yes>

--	IV.	Return.
set	@Result = 0
return @Result
GO
