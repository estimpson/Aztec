SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_getnotes] 
(@part varchar(25) = null, 
 @orderno numeric ( 8,0) = null ) as
----------------------------------------------------------------------------------------------
--
--	Procedure to append notes from different tables required to store in work orders
--
--	Parameters	@part		- part
--			@orderno	- order no
--
--	Developed	Harish Gubbi 	11/23/99
--
--	Declarations
--	Initilization
--	Get activity router notes
--	Get notes for shipper & bill of lading
--	Append values to notes
--	Get notes from order_header
--	Append values to notes
--	Get notes from order_header
--	Append values to notes
----------------------------------------------------------------------------------------------

--	Declarations
declare @notes		varchar(255),
	@destination	varchar(10),
	@notestemp1	varchar(255),
	@notestemp2	varchar(255)

--	Initilization
select	@notes=''

--	Get activity router notes
select	@notes = isnull(notes,'')
from	activity_router
where	parent_part = @part and
	sequence = 1
	
--	Get notes for shipper & bill of lading
select	@notestemp1 = isnull(note_for_shipper,''),
	@notestemp2 = isnull(note_for_bol,'')
from	destination_shipping
	join order_header od on od.destination = destination_shipping.destination
where	od.order_no = @orderno 			

--	Append values to notes
select	@notes = isnull(rtrim(@notes),'') + isnull(@notestemp1,'') + isnull(@notestemp2,'')

--	Get notes from order_header
select	@notestemp1 = notes
from	order_header
where	order_no = @orderno

--	Append values to notes
select	@notes = isnull(rtrim(@notes),'') + isnull(@notestemp1,'')

--	Get notes from order_header
select	@notestemp1 = notes
from	order_detail
where	order_no = @orderno and
	part_number = @part

--	Append values to notes
select	@notes = isnull(rtrim(@notes),'') + isnull(@notestemp1,'')

select	@notes
GO
