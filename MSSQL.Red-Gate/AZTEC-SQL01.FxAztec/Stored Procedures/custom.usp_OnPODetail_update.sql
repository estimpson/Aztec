SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [custom].[usp_OnPODetail_update]
	@Result INTEGER = NULL OUT
AS
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. custom.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare
	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
ELSE BEGIN
	SAVE TRAN @ProcName
END
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
declare
    @InsertedPONumber int
,   @InsertedBalance numeric(20, 6)
,   @DeletedBalance numeric(20, 6)


-- Insert statements for trigger here

if	exists
	(	select
	 		*
	 	from
	 		#deleted del
			join #inserted ins
				on del.po_number = ins.po_number
				and del.part_number = ins.part_number
				and del.date_due = ins.date_due
				and del.row_id = ins.row_id
		where
			coalesce(del.balance, -1) != coalesce(ins.balance, -1)
	)
    and not exists
		(	select
				*
			from
				#deleted del
			where
				coalesce(del.#deleted, '') = 'Y'
			union
			select
				*
			from
				#inserted ins
			where
				coalesce(ins.#deleted, '') = 'Y'
		)
    begin

        select
            @InsertedPONumber = min(po_number)
        from
            #inserted
        select
            @InsertedBalance = min(balance)
        from
            #inserted
        select
            @DeletedBalance = min(balance)
        from
            #deleted

        IF (
            @DeletedBalance > 0
            AND @InsertedBalance < 0
            )
            AND EXISTS ( SELECT
                            1
                            FROM
                            po_header
                            JOIN vendor
                                ON po_header.vendor_code = vendor.code
                            WHERE
                            po_number = @InsertedPONumber
                            AND po_header.type = 'B'
                            AND COALESCE(vendor.outside_processor, '') = 'Y' )
            BEGIN



                declare @tableHTML nvarchar(max);

                set @tableHTML = N'<H1>Negative PO Balance</H1>' + N'<table border="1">'
                    + N'<tr><th>PO Number</th><th>Due Date</th>' + N'<th>Part Number</th>'
                    + N'<th>Old Balance</th><th>New Balance</th></tr>' + cast((
                                                                                select
                                                                                td = Ins.po_number
                                                                                ,''
                                                                                ,td = Ins.Date_due
                                                                                ,''
                                                                                ,td = Ins.Part_number
                                                                                ,''
                                                                                ,td = Del.balance
                                                                                ,''
                                                                                ,td = Ins.balance
                                                                                from
                                                                                Inserted Ins
                                                                                join Deleted Del
                                                                                    on Ins.po_number = Del.po_number
                                                                                        and Ins.row_id = Del.row_id
                                                                                for
                                                                                xml path('tr')
                                                                                ,   type
                                                                                ) as nvarchar(max)) + N'</table>';

                EXEC msdb.dbo.sp_send_dbmail
                    @profile_name = 'FxAlerts'
                , -- sysname
                    @recipients = 'rjohnson@aztecmfgcorp.com'
                , -- varchar(max)
                    @copy_recipients = 'aboulanger@fore-thought.com;rreyna@aztecmfgcorp.com;rvasquez@aztecmfgcorp.com'
                , -- varchar(max)
                    @subject = N'PO Detail Balance is Less Than Zero'
                , -- nvarchar(255)
                    @body = @TableHTML
                , -- nvarchar(max)
                    @body_format = 'HTML'
                , -- varchar(20)
                    @importance = 'High' -- varchar(6)

            END
    END
--- </Body>

---	<CloseTran AutoCommit=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
---	</CloseTran AutoCommit=Yes>

---	<Return>
set	@Result = 0
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

declare
	@Param1 scalar_data_type

set	@Param1 = test_value

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = custom.usp_OnPODetail_update
	@Param1 = @Param1
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

GO
