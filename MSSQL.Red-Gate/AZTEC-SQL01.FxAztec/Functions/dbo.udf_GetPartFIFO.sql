SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[udf_GetPartFIFO]
(
	@Part varchar(25)
)
returns @Objects table
(
	Serial int
,	Location varchar (10)
,	Quantity numeric (20, 6)
,	BreakoutSerial int null
,	FirstDT datetime null
)
as
begin
--- <Body>
	insert
		@Objects
	(
		Serial
	,	Location
	,	Quantity
	,	BreakoutSerial
	)
	select
		Serial = o.serial
	,	Location = min(o.location)
	,	Quantity = min(o.quantity)
	,	BreakoutSerial = min(convert (int, Breakout.from_loc))
	from
		dbo.object o
		left join audit_trail BreakOut on
			o.serial = BreakOut.serial
			and
				Breakout.type = 'B' and
				isnumeric(replace(replace(Breakout.from_loc, 'D', 'X'), 'E', 'Z')) = 1 
	where
		o.part = @Part
		and
			o.Status = 'A'
	group by
		o.serial
	
	while
		@@rowcount > 0 begin
		update
			o
		set
			BreakoutSerial = Breakout.BreakoutSerial
		from
			@Objects o
			join
			(
				select
					Serial
				,	BreakoutSerial = min(convert(int, Breakout.from_loc))
				from
					audit_trail BreakOut
				where
					type = 'B'
					and
						serial in (select BreakoutSerial from @Objects where BreakoutSerial > 0)
					and
						isnumeric(replace(replace(Breakout.from_loc, 'D', 'X'), 'E', 'Z')) = 1 
				group by
					serial
			) Breakout on
			o.BreakoutSerial = Breakout.Serial
	end

	update
		@Objects
	set
		FirstDT = (select min(coalesce(start_date, date_stamp)) from audit_trail where type in ('A', 'R', 'J') and serial = coalesce (o.BreakoutSerial, o.Serial))
	from
		@Objects o
--- </Body>

---	<Return>
	return
end
GO
