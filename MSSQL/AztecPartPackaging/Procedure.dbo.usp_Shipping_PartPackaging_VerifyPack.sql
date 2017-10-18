
/*
Create procedure FxClientDB.dbo.usp_Shipping_PartPackaging_VerifyPack
*/

--use FxClientDB
--go

if	objectproperty(object_id('dbo.usp_Shipping_PartPackaging_VerifyPack'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_Shipping_PartPackaging_VerifyPack
end
go

create procedure dbo.usp_Shipping_PartPackaging_VerifyPack
	@ShipperID int
,	@ShipperPart varchar(35)
,	@PackagingCode varchar(20)
,	@DefaultPackagingCode varchar(20) out
,	@PackDisabled tinyint out
,	@PackEnabled tinyint out
,	@PackWarn tinyint out
,	@TranDT datetime out
,	@Result integer out
as
set nocount on
set ansi_warnings off
set	@Result = 999999

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare
	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
else begin
	save tran @ProcName
end
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

--- <Body>
/*	Read and return requested information. */
select
	@DefaultPackagingCode =
		(	select
				max(PackagingCode)
			from
				dbo.Shipping_PartPackaging_Setup
			where
				ShipperID = @ShipperID
				and ShipperPart = @ShipperPart
				and PackDefault = 1
		)
,	@PackDisabled = coalesce(spps.PackDisabled, Defaults.PackDisabled)
,	@PackEnabled = coalesce(spps.PackEnabled, Defaults.PackEnabled)
,	@PackWarn = coalesce(spps.PackWarn, Defaults.PackWarn)
from
	(	select
			PackDisabled = 1
		,	PackEnabled = 0
		,	PackWarn = 0
	) Defaults
	left join dbo.Shipping_PartPackaging_Setup spps
		on spps.ShipperID = @ShipperID
		and spps.ShipperPart = @ShipperPart
		and spps.PackagingCode = @PackagingCode
--- </Body>

if	@TranCount = 0 begin
	commit tran @ProcName
	return
end

---	<Return>
set	@Result = 0
return
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

declare
	@ShipperID int
,	@ShipperPart varchar(35)
,	@PackagingCode varchar(20)
,	@DefaultPackagingCode varchar(20)
,	@PackDisabled tinyint
,	@PackEnabled tinyint
,	@PackWarn tinyint

set	@ShipperID = 56583
set	@ShipperPart = '2759'
set	@PackagingCode = 'PLT91'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_Shipping_PartPackaging_VerifyPack
	@ShipperID = @ShipperID
,	@ShipperPart = @ShipperPart
,	@PackagingCode = @PackagingCode
,	@DefaultPackagingCode = @DefaultPackagingCode out
,	@PackDisabled = @PackDisabled out
,	@PackEnabled = @PackEnabled out
,	@PackWarn = @PackWarn out
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

if	@@trancount > 0 begin
	rollback
end
go

set statistics io off
set statistics time off
go

}

Results {
}
*/
go

