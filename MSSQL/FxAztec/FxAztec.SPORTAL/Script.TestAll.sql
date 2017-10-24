use FxAztec
go

declare
	@SupplierCode varchar(20) = 'MAR0200'
,	@SupplierPartCode varchar(50) = '12311 - 0V170'
,	@InternalPartCode varchar(25) = '3246 - OP5'
,	@QuantityPerObject numeric(20,6) = 200
,	@ObjectCount int = 10
,	@LotNumber varchar(100) = 'TEST'
,	@FirstNewSerial int

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = SPORTAL.usp_SupplierPart_CreateNewPreobjects
	@SupplierCode = @SupplierCode
,	@SupplierPartCode = @SupplierPartCode
,	@InternalPartCode = @InternalPartCode
,	@QuantityPerObject = @QuantityPerObject
,	@ObjectCount = @ObjectCount
,	@LotNumber = @LotNumber
,	@FirstNewSerial = @FirstNewSerial out
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @FirstNewSerial, @TranDT, @ProcResult

execute
	@ProcReturn = SPORTAL.usp_Preobject_ChangeLot
	@SupplierCode = @SupplierCode
,	@Serial = @FirstNewSerial
,	@NewLot = 'TEST1'

execute
	SPORTAL.usp_Q_Lots_BySupplier
	@SupplierCode = @SupplierCode

execute
	@ProcReturn = SPORTAL.usp_Q_Preobjects_BySupplierLot
	@SupplierCode = @SupplierCode
,	@LotNumber = @LotNumber

execute
	@ProcReturn = SPORTAL.usp_Preobject_ChangeQuantity
	@SupplierCode = @SupplierCode
,	@Serial = @FirstNewSerial
,	@NewQuantity = 4
,	@TranDT = @TranDT out

execute
	@ProcReturn = SPORTAL.usp_Q_SerialObjectBatches_BySupplier
	@SupplierCode = @SupplierCode

execute
	@ProcReturn = SPORTAL.usp_Q_Preobjects_BySupplierBatch
	@SupplierCode = @SupplierCode
,	@FirstSerial = @FirstNewSerial

execute
	@ProcReturn = SPORTAL.usp_Q_Preobjects_BySupplierSerialList
	@SupplierCode = @SupplierCode
,	@SerialList = @FirstNewSerial

execute @ProcReturn = SPORTAL.usp_Q_Preobjects_ByAnyMethod
	@SupplierCode = @SupplierCode
,	@FirstSerial = @FirstNewSerial
,	@LotNumber = ''
,	@SerialList = ''

execute @ProcReturn = SPORTAL.usp_Q_Preobjects_ByAnyMethod
	@SupplierCode = @SupplierCode
,	@FirstSerial = ''
,	@LotNumber = @LotNumber
,	@SerialList = ''

execute @ProcReturn = SPORTAL.usp_Q_Preobjects_ByAnyMethod
	@SupplierCode = @SupplierCode
,	@FirstSerial = ''
,	@LotNumber = ''
,	@SerialList = @FirstNewSerial
go

if	@@trancount > 0 begin
	rollback
end
go
