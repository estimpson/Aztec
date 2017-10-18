SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [custom].[usp_report_OPHistory] @FromDate datetime, @ThroughDate datetime
as
Begin

--custom.usp_report_OPHistory '2012-07-01' , '2012-07-31'

--Get Outside Processor List

Declare @OutsideProcessors table (

OutsideProcessor varchar(15) Primary Key

)

Insert @OutsideProcessors

Select 
	code
From
	vendor
Where
	coalesce(outside_processor, 'N') = 'Y'


-- Get History of Transactions for Outside Processors

Declare @Transactions table 
(
TransactionType varchar(10),
FromLocation varchar(15),
ToLocation varchar(15),
DayOfTransaction datetime,
Part varchar(25),
Quantity numeric(20,6)
)

Insert @Transactions 

Select 
	type,
	From_loc,
	to_loc,
	ft.fn_truncDaTe('dd',date_stamp),
	part,
	Quantity
From
	audit_trail
Where
	date_stamp>= @FromDate and
	date_stamp<@ThroughDate and
	(	from_loc in ( Select * From @OutsideProcessors) or
		to_loc in ( Select * from @OutsideProcessors )
	)

Select *
	From
	@Transactions









		




End
GO
