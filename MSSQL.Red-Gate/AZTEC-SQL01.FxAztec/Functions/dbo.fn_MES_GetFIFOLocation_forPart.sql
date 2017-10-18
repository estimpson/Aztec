SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[fn_MES_GetFIFOLocation_forPart]
(	@Part varchar(25)
,	@Status varchar(1) = 'A'
,	@Plant varchar(10) = null
,	@Location varchar(10) = null
,	@GroupNo varchar(25) = null 
,	@Secured char(1) = 'N'
)
returns varchar(10)
as 
begin
	declare @Objects table
	(	ID int not null IDENTITY(1, 1) primary key
	,	Serial int
	,	Location varchar(10)
	,	Quantity numeric(20, 6)
	,	BreakoutSerial int null
	,	FirstDT datetime null
	,	IsInFifo char(1)
	)

	insert
		@Objects
	(	Serial
	,	Location
	,	Quantity
	,	BreakoutSerial
	,	FirstDT
	,	IsInFifo
	)
	select
		Serial
	,	Location
	,	Quantity
	,	BreakoutSerial
	,	FirstDT
	,	IsInFifo
	from
		dbo.fn_MES_GetPartFIFO(@Part, @Status, @Plant, @Location, @GroupNo, @Secured)
	
	declare
		@FIFOLocation varchar(10)
	
	select
		@FIFOLocation = Location
	from
		@Objects
	where
		ID = 1
	
	return
		@FIFOLocation
end
GO
