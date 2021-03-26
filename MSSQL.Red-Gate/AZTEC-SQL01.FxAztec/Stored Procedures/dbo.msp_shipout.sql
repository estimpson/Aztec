SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[msp_shipout] (
	@shipper	INTEGER,
	@invdate	DATETIME=NULL )
AS
---------------------------------------------------------------------------------------
--	This procedure performs a ship out on a shipper.
--
--	Modifications:	01 MAR 1999, Harish P. Gubbi	Original.
--			08 JUL 1999, Eric E. Stimpson	Reformatted.
--			04 AUG 1999, Eric E. Stimpson	Removed operator and pronumber from parameters.
--			11 AUG 1999, Eric E. Stimpson	Modified audit_trail generation to include pallets.
--			26 SEP 1999, Eric E. Stimpson	Added where condition to #3 to prevent data loss.
--			06 JAN 2000, Eric E. Stimpson	Add EDI shipout procedure.
--			08 JAN 2000, Eric E. Stimpson	Add result set for success.
--			25 JAN 2000, Eric E. Stimpson	Rewrite invoice number assigning to prevent lockup.
--			11 MAY 2000, Chris B. Rogers	added 6a.
--			08 AUG 2002, Harish G P		Included date as an argument and used the same in the script
--			08 AUG 2002, Harish G P		Commented out release dt & no updation on shipper detail
--			02 JAN 2003, Harish G P		Made changes to bill of lading updation
--			04 APR 2003, Harish G P		Changes to the shipper count where clause
--			29 JUL 2016, ASB	FT				Return error and send email if pro number is not entered for and destination like AF[0-9]% Section 1a
--			25 SEP 2018, ASB	FT		Added 24874 to check from Pro Number
--
--	Parameters:	@shipper	Mandatory
--
--	Returns:	0	success
--			100	shipper not staged
--
--	Process:
--	1.	Declare all the required local variables.
--	2.	Update shipper header to show shipped status and date and time shipped.
--	3.	Update shipper detail with date shipped and week no. and release date and no.
--	4.	Generate audit trail records for inventory to be relieved.
--	5.	Call EDI shipout procedure.
--	6.	Relieve inventory.
--	6a.	Update part_vendor table for outside processed part
--	7.	Adjust part online quantities for inventory.
--	8.	Relieve order requirements.
--	9.	Close bill of lading.
--	10.	Assign invoice number.
---------------------------------------------------------------------------------------
SET ANSI_WARNINGS off

	
--- <Error Handling>
declare
	@result int
,	@tranDT datetime
,	@CallProcName sysname
,	@TableName sysname
,	@ProcName sysname = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)
,	@ProcReturn integer
,	@ProcResult integer
,	@Error integer
,	@RowCount integer
--- </Error Handling>

--	0.  Reconcile shipper.
--- <Call>	
set	@CallProcName = 'dbo.msp_reconcile_shipper'
execute
	@ProcReturn = dbo.msp_reconcile_shipper
	@shipper = @shipper

set	@Error = @@Error
if	@Error != 0 begin
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran @ProcName
end
if	@ProcReturn != 0 begin
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	rollback tran @ProcName
end
--- </Call>

--	1.	Declare all the required local variables.
DECLARE	@returnvalue	INTEGER,
	@invoicenumber	INTEGER,
	@cnt		INTEGER,
	@bol		INTEGER

	--1a Return Error and send email if pro number is missing for Ford Af destinations
IF EXISTS ( SELECT 1 FROM 
	shipper 
	Where	destination LIKE 'AF[0-9]%' AND
				NULLIF(pro_number, '') IS NULL AND
				id = @shipper 
			)
Begin	

SET ANSI_WARNINGS ON
Declare @ShipmentAlert table
		(	Shipper int,
			Note varchar(100)
		)

Insert	@ShipmentAlert
	
	Select	id,
				'Ship-out failed. Pro Number not enetered on shipper. Enter pro number and ship'
		FROM 
	shipper 
	Where	(destination LIKE 'AF[0-9]%' or destination = '24874') AND
				NULLIF(pro_number, '') IS NULL AND
				id = @shipper 
		
if exists ( Select 1 from @ShipmentAlert ) begin

SELECT *
INTO
	#ProNumberAlertsEmail
FROM
	@ShipmentAlert
	

DECLARE
			@html nvarchar(max),
			@EmailTableName sysname  = N'#ProNumberAlertsEmail'
		
		exec [FT].[usp_TableToHTML]
				@tableName = @Emailtablename
			,	@orderBy = N'Shipper'
			,	@html = @html OUTPUT
			,	@includeRowNumber = 0
			,	@camelCaseHeaders = 1
		
		DECLARE
			@EmailBody NVARCHAR(MAX)
		,	@EmailHeader NVARCHAR(MAX) = 'Failed Shipout due to missing pro number - no action required' 

		SELECT
			@EmailBody =
				N'<H1>' + @EmailHeader + N'</H1>' +
				@html

	--print @emailBody

	EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'FxAlerts'-- sysname
	,		@recipients = 'rjohnson@aztecmfgcorp.com;mkroll@aztecmfgcorp.com;rreyna@aztecmfgcorp.com' -- varchar(max)
	,		@copy_recipients = 'rjohnson@aztecmfgcorp.com; aboulanger@fore-thought.com' -- varchar(max)
	, 		@subject = @EmailHeader
	,		@body = @EmailBody
	,  		@body_format = 'HTML'
	,		@importance = 'High' 
		
		declare		@ShipperString varchar(10)
		select		@ShipperString = convert(varchar(10), @shipper)
		
		RAISERROR (N'Shipout failed. Enter pro number of shipper %s.', -- Message text.
           16, -- Severity,
           1, -- State,
           @ShipperString
           )
          return -1
		  	  
		END
        SET ANSI_WARNINGS OFF
		END

--	2.	Update shipper header to show shipped status and date and time shipped.
IF	@invdate IS NULL 
	SELECT	@invdate = GETDATE ()
	
UPDATE	shipper
SET	status = 'C',
	date_shipped = @invdate,
	time_shipped = @invdate
WHERE	id = @shipper AND
	status = 'S'

IF @@rowcount = 0
	RETURN -1

--	3.	Update shipper detail with date shipped and week no. and release date and no.
/*
update	shipper_detail
set	date_shipped = shipper.date_shipped,
	week_no = datepart ( wk, shipper.date_shipped ),
	release_date = order_detail.due_date,
	release_no = order_detail.release_no
from	shipper_detail
	join shipper on shipper_detail.shipper = shipper.id
	left outer join order_detail on shipper_detail.order_no = order_detail.order_no and
		shipper_detail.part_original = order_detail.part_number and
		IsNull ( shipper_detail.suffix, 0 ) = IsNull ( order_detail.suffix, 0 ) and
		order_detail.due_date = (
			select	Min ( od2.due_date )
			from	order_detail od2
			where	shipper_detail.order_no = od2.order_no and
				shipper_detail.part_original = od2.part_number and
				IsNull ( shipper_detail.suffix, 0 ) = IsNull ( od2.suffix, 0 ) )
where	shipper = @shipper
*/

update	shipper_detail
set	date_shipped = shipper.date_shipped,
	week_no = datepart ( wk, shipper.date_shipped )
from	shipper_detail
	join shipper on shipper_detail.shipper = shipper.id
where	shipper = @shipper

--	4.	Generate audit trail records for inventory to be relieved.
insert	audit_trail (
	serial,
	date_stamp,
	type,
	part,
	quantity,
	remarks,
	price,
	salesman,
	customer,
	vendor,
	po_number,
	operator,
	from_loc,
	to_loc,
	on_hand,
	lot,
	weight,
	status,
	shipper,
	unit,
	workorder,
	std_quantity,
	cost,
	custom1,
	custom2,
	custom3,
	custom4,
	custom5,
	plant,
	notes,
	gl_account,
	package_type,
	suffix,
	due_date,
	group_no,
	sales_order,
	release_no,
	std_cost,
	user_defined_status,
	engineering_level,
	parent_serial,
	destination,
	sequence,
	object_type,
	part_name,
	start_date,
	field1,
	field2,
	show_on_shipper,
	tare_weight,
	kanban_number,
	dimension_qty_string,
	dim_qty_string_other,
	varying_dimension_code )
	select	object.serial,
		shipper.date_shipped,
		IsNull ( shipper.type, 'S' ),
		object.part,
		IsNull ( object.quantity, 1),
		(	case	shipper.type
				when 'Q' then 'Shipping'
				when 'O' then 'Out Proc'
				when 'V' then 'Ret Vendor'
				else 'Shipping'
			end ),
		IsNull ( shipper_detail.price, 0 ),
		shipper_detail.salesman,
		destination.customer,
		destination.vendor,
		object.po_number,
		IsNull ( shipper_detail.operator, '' ),
		object.location,
		destination.destination,
		part_online.on_hand,
		object.lot,
		object.weight,
		object.status,
		convert ( varchar, @shipper ),
		object.unit_measure,
		object.workorder,
		object.std_quantity,
		object.cost,
		object.custom1,
		object.custom2,
		object.custom3,
		object.custom4,
		object.custom5,
		object.plant,
		shipper_detail.note,
		shipper_detail.account_code,
		object.package_type,
		object.suffix,
		object.date_due,
		shipper_detail.group_no,
		convert ( varchar, shipper_detail.order_no ),
		shipper_detail.release_no,
		object.std_cost,
		object.user_defined_status,
		object.engineering_level,
		object.parent_serial,
		shipper.destination,
		object.sequence,
		object.type,
		object.name,
		object.start_date,
		object.field1,
		object.field2,
		object.show_on_shipper,
		object.tare_weight,
		object.kanban_number,
		object.dimension_qty_string,
		object.dim_qty_string_other,
		object.varying_dimension_code
	from	object
		join shipper on shipper.id = @shipper
		left outer join shipper_detail on shipper_detail.shipper = @shipper and
			object.part = shipper_detail.part_original and
			Coalesce ( object.suffix, (
				select	Min ( sd.suffix )
				from	shipper_detail sd
				where	sd.shipper = @shipper and
					object.part = sd.part_original ), 0 ) = IsNull ( shipper_detail.suffix, 0 )
		join destination on shipper.destination = destination.destination
		left outer join part_online on object.part = part_online.part
	where	object.shipper = @shipper

--	5.	Call EDI shipout procedure.
execute edi_msp_shipout @shipper

--	6.	Relieve inventory.
delete	object
from	object
	join shipper on object.shipper = shipper.id
where	object.shipper = @shipper and
	IsNull ( shipper.type, '' ) <> 'O'

update	object
set	location = shipper.destination,
	destination = shipper.destination,
	status = 'P'
from	object
	join shipper on object.shipper = shipper.id
where	object.shipper = @shipper and
	shipper.type = 'O'


if	(	select
			s.type
		from
			dbo.shipper s
		where
			s.id = @shipper
	) = 'O' begin
	
	declare
		@user varchar(10)
	,	@vendorShipTo varchar(20)
	,	@rawPartCode varchar(25)
	,	@rawPartStandardQty numeric(20,6)
	
	select
		@user = s.operator
	,	@vendorShipTo = s.destination
	from
		dbo.shipper s
	where
		id = @shipper
	
	declare
		shipperLines cursor local for
	select
		PartCode = part_original
	,	PackedQty = qty_packed
	from
		dbo.shipper_detail sd
	where
		sd.shipper = @shipper
		and sd.qty_packed > 0
	
	open shipperLines
	
	while
		1 = 1 begin
		
		fetch
			shipperLines
		into
			@rawPartCode
		,	@rawPartStandardQty
		
		if	@@FETCH_STATUS != 0 begin
			break
		end
	
		set	@CallProcName = 'dbo.usp_OutsideProcessing_AutocreateFirmPOLineItem'
		execute
			@ProcReturn = dbo.usp_OutsideProcessing_AutocreateFirmPOLineItem
			@User = @User
		,	@VendorShipFrom = @vendorShipTo
		,	@RawPartCode = @rawPartCode
		,	@RawPartStandardQty = @rawPartStandardQty
		,	@TranDT = @TranDT out
		,	@Result = @ProcResult out
		
		set	@Error = @@Error
		if	@Error != 0 begin
			set	@Result = 900501
			RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
			rollback tran @ProcName
			return	@Result
		end
		if	@ProcReturn != 0 begin
			set	@Result = 900502
			RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
			rollback tran @ProcName
			return	@Result
		end
		if	@ProcResult != 0 begin
			set	@Result = 900502
			RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
			rollback tran @ProcName
			return	@Result
		end
		--- </Call>
	end
end
--- </Body>
--	6a.	Update part_vendor table for outside processed part
update	part_vendor
set	accum_shipped = isnull(accum_shipped,0) + 
			isnull((select	sum ( object.std_quantity ) 
				from	object
				where	object.shipper = @shipper and
					object.part = pv.part ),0)
from	part_vendor pv,
	shipper s,
	destination d
where	s.id = @shipper and
	s.type = 'O' and
	d.destination = s.destination and
	pv.vendor = d.vendor

--	7.	Adjust part online quantities for inventory.
update	part_online
set	on_hand = (
		select	Sum ( std_quantity )
		from	object
		where	part_online.part = object.part and
			object.status = 'A' )
from	part_online
	join shipper_detail on shipper_detail.shipper = @shipper and
		shipper_detail.part_original = part_online.part

--	8.	Relieve order requirements.
execute @returnvalue = msp_update_orders @shipper

if @returnvalue < 0
	return @returnvalue

--	9.	Close bill of lading.
select	@bol = bill_of_lading_number
from	shipper
where	id = @shipper

select	@cnt = count(1)
from	shipper
where	bill_of_lading_number = @bol and
	(isnull(status,'O') in ('S','O')) 

if isnull(@cnt,0) = 0
	update	bill_of_lading
	set	status = 'C'
	from	bill_of_lading
		join shipper on shipper.id = @shipper and
		bill_of_lading.bol_number = shipper.bill_of_lading_number

--	10.	Assign invoice number.
update	parameters
set	next_invoice = next_invoice + 1

select	@invoicenumber = next_invoice - 1
from	parameters

while exists (
	select	invoice_number
	from	shipper
	where	invoice_number = @invoicenumber )
begin -- (1B)
	select	@invoicenumber = @invoicenumber + 1

end -- (1B)

update	parameters
set	next_invoice = @invoicenumber + 1

update	shipper
set	invoice_number = @invoicenumber
where	id = @shipper

if	exists
		(	select
  				*
  			from
  				dbo.shipper s
			where
				s.id = @shipper
				and s.customer = 'MAGNA'
  		) begin

	execute
		@ProcReturn = custom.usp_Magna_AddSurchargeInvoiceItems
		@Shipper = @Shipper
end

select 0
return 0
GO
