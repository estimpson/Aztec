CREATE TABLE [dbo].[BlanketPriceChanges]
(
[Part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[EffectiveDate] [datetime] NOT NULL,
[BlanketPrice] [numeric] (20, 6) NOT NULL,
[CustomerPO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Activated] [int] NOT NULL CONSTRAINT [DF__BlanketPr__Activ__24927208] DEFAULT ((0)),
[UserCode] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UserName] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ChangedDate] [datetime] NULL,
[ActivatedDate] [datetime] NULL,
[Cleared] [int] NOT NULL CONSTRAINT [DF__BlanketPr__Clear__25869641] DEFAULT ((0)),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__BlanketPr__RowCr__267ABA7A] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__BlanketPr__RowCr__276EDEB3] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[PriceAdmin_InsertBlanketPriceChangesLog] on [dbo].[BlanketPriceChanges] 
for insert, update, delete
as

set nocount on

--- <Error Handling>
declare	
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn int,
	@ProcResult int,
	@Error int,
	@RowCount int,
	@TranDT datetime

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



declare
	@rowcountInsert int,
	@rowcountDelete int
	
set	@TableName = 'dbo.BlanketPriceChangesLog'


-- Insert code
select @rowcountInsert = count(*) from inserted

if @rowcountInsert > 0 begin
	-- price update and/or effective date update and/or customer po update
	insert
			BlanketPriceChangesLog (
			Part,
			Customer,
			PreviousEffectiveDate,
			NewEffectiveDate,
			PreviousBlanketPrice,
			NewBlanketPrice,
			CurrentBlanketPrice,
			PreviousCustomerPO,
			NewCustomerPO,
			CurrentCustomerPO,
			UserCode,
			UserName,
			ChangedDate)
	select
			Part = inserted.Part,
			Customer = inserted.Customer,
			PreviousEffectiveDate = deleted.EffectiveDate,
			NewEffectiveDate = nullif (inserted.EffectiveDate, deleted.EffectiveDate), -- only insert new effective date if it changed
			PreviousBlanketPrice = nullif(deleted.BlanketPrice, inserted.BlanketPrice),  -- only insert previous blanket price if a new one was inserted
			NewBlanketPrice = nullif (inserted.BlanketPrice, deleted.BlanketPrice), -- only insert new blanket price if it changed
			CurrentBlanketPrice = pc.blanket_price,
			PreviousCustomerPO = nullif(deleted.CustomerPO, inserted.CustomerPO),
			NewCustomerPO = nullif(inserted.CustomerPO, deleted.CustomerPO),
			CurrentCustomerPO = oh.customer_po,
			UserCode = inserted.UserCode,
			UserName = inserted.UserName,
			ChangedDate = getdate()
	from
			inserted join
			deleted on inserted.RowID = deleted.RowID join
			part_customer pc on inserted.Part = pc.part and
			inserted.Customer = pc.customer	right outer join
			order_header oh on oh.customer = pc.customer and
			oh.blanket_part = pc.part and
			oh.order_no = (	select	max(order_no)
							from	dbo.order_header oh1 
							where	oh1.customer = pc.customer and
									oh1.blanket_part = pc.part	)
	where
			inserted.Activated = 0 and
			(	inserted.BlanketPrice <> deleted.BlanketPrice or
				inserted.EffectiveDate <> deleted.EffectiveDate or
				inserted.CustomerPO <> deleted.CustomerPO	)
			
	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	if	@Error != 0 begin
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	
	
/*	
	-- blanket price activation
	insert
			BlanketPriceChangesLog (
			Part,
			Customer,
			NewEffectiveDate,
			NewBlanketPrice,
			Activated,
			ActivatedDate,
			UserCode,
			UserName)
	select
			Part = inserted.Part,
			Customer = inserted.Customer,
			CurrentEffectiveDate = inserted.EffectiveDate,
			CurrentBlanketPrice = inserted.BlanketPrice,
			Activated = 1,
			ActivatedDate = getdate(),
			UserCode = inserted.UserCode,
			UserName = inserted.UserName
	from
			inserted join
			deleted on inserted.RowID = deleted.RowID
	where
			inserted.Activated = 1
		
	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	if	@Error != 0 begin
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end	
*/


	-- new part/customer combination
	insert
			BlanketPriceChangesLog (
			Part,
			Customer,
			NewEffectiveDate,
			CurrentBlanketPrice,
			NewBlanketPrice,
			CurrentCustomerPO,
			NewCustomerPO,
			UserCode,
			UserName,
			ChangedDate)
	select
			Part = inserted.Part,
			Customer = inserted.Customer,
			NewEffectiveDate = inserted.EffectiveDate,
			CurrentBlanketPrice = pc.blanket_price,
			NewBlanketPrice = inserted.BlanketPrice,
			CurrentCustomerPO = oh.customer_po,
			NewCustomerPO = inserted.CustomerPO,
			UserCode = inserted.UserCode,
			UserName = inserted.UserName,
			ChangedDate = getdate()
	from
			inserted left join
			deleted on inserted.RowID = deleted.RowID join
			part_customer pc on 
			inserted.Part = pc.part and
			inserted.Customer = pc.customer right outer join
			order_header oh on oh.customer = pc.customer and
			oh.blanket_part = pc.part and
			oh.order_no = (	select	max(order_no)
							from	dbo.order_header oh1 
							where	oh1.customer = pc.customer and
									oh1.blanket_part = pc.part	)
	where
			deleted.RowID is null
		
	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	if	@Error != 0 begin
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end	
end


-- Delete
select @rowcountDelete = count(*) from deleted

if @rowcountDelete > 0 begin	
	insert
			BlanketPriceChangesLog (
			Part,
			Customer,
			PreviousEffectiveDate,
			PreviousBlanketPrice,
			PreviousCustomerPO,
			Deleted,
			UserCode,
			UserName,
			ChangedDate)
	select	
			Part = deleted.Part,
			Customer = deleted.Customer,
			PreviousEffectiveDate = deleted.EffectiveDate,
			PreviousBlanketPrice = deleted.BlanketPrice,
			PreviousCustomerPO = deleted.CustomerPO,
			Deleted = 1,
			UserCode = deleted.UserCode,
			UserName = deleted.UserName,
			ChangedDate = getdate()
	from
			deleted left join
			inserted on inserted.RowID = deleted.RowID join
			part_customer pc on 
			deleted.Part = pc.part and
			deleted.Customer = pc.customer
	where
			inserted.RowID is null
			
	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	if	@Error != 0 begin
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end	
end



--<CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit transaction @ProcName
end
--</CloseTran Required=Yes AutoCreate=Yes>

--	IV.	Return.
return 
GO
