
if objectproperty(object_id('dbo.fn_MES_GetPartFIFO'), 'IsTableFunction') = 1 
	begin
		drop function dbo.fn_MES_GetPartFIFO
	end
go

create function dbo.fn_MES_GetPartFIFO
(	@Part varchar(25)
,	@Status varchar(1) = 'A'
,	@Plant varchar(10) = null
,	@Location varchar(10) = null
,	@GroupNo varchar(25) = null 
,	@Secured char(1) = 'N'
)
returns @Objects table
(	Serial int primary key
,	Location varchar(10)
,	Quantity numeric(20, 6)
,	BreakoutSerial int null
,	FirstDT datetime null
,	IsInFifo char(1)
)
as 
begin

	insert
		@Objects
	(	Serial
	,	Location
	,	Quantity
	,	BreakoutSerial
	)
	select
		Serial = object.serial
	,	Location = min(object.location)
	,	Quantity = min(object.quantity)
	,	BreakoutSerial = min(convert (int, Breakout.from_loc))
	from
		object
		join location
			on	location.code = object.location
		left join audit_trail BreakOut
			on	object.serial = BreakOut.serial
				and Breakout.type = 'B'
				and isnumeric(replace(replace(Breakout.from_loc, 'D', 'X'), 'E', 'Z')) = 1 -- I think this is to prevent locations with like X000 or D000 from being incorrectly idefintied as numbers.  Perhaps a not like '%[^0-9]%' would be better?
	where
		object.part = @Part
		and object.status = 'A'
		and coalesce(location.plant, 'X') = coalesce(@Plant, location.plant, 'X')
		and object.location = coalesce(@Location, object.location)
		and coalesce(location.group_no, 'X') = coalesce(@GroupNo, location.group_no, 'X')
		and coalesce(location.secured_location, 'N') = coalesce(@Secured, location.secured_location, 'N')
	group by
		object.serial

	while @@rowcount > 0 begin
		update
			@Objects
		set 
			BreakoutSerial = Breakout.BreakoutSerial
		from
			@Objects Objects
			join
			(	select
					Serial
				,	BreakoutSerial = min(convert (int, Breakout.from_loc))
				from
					audit_trail BreakOut
				where
					type = 'B'
					and serial in
					(	select
							BreakoutSerial
						from
							@Objects
						where
							BreakoutSerial > 0
					)
					and isnumeric(replace(replace(Breakout.from_loc, 'D', 'X'), 'E', 'Z')) = 1
				group by
					serial
			) Breakout
				on Objects.BreakoutSerial = Breakout.Serial
	end
	
	update
		@Objects
	set 
		FirstDT =
		(	select
				coalesce(min(case when type in ('A', 'R', 'J', 'E') then date_stamp end), min(date_stamp))
			from
				audit_trail with (index = audit_trail_serial_datestamp_ix)
			where
				type in ('A', 'R', 'J', 'E')
				and serial = coalesce(Objects.BreakoutSerial, Objects.Serial)
		)
	from
		@Objects Objects
	
	declare @FifoPart datetime
	
	select
		@FifoPart = min(FirstDT)
	from
		@Objects
	
	update
		@Objects
	set 
		IsInFifo = '*'
	where
		abs(datediff(day, FirstDT, @FifoPart)) = 0
	
	return
end
go

select
	*
from
	dbo.fn_MES_GetPartFIFO('K938 828-06', 'A', 'EEA', null, null, 'N')
order by
	FirstDT
go

select
	*
from
	dbo.fn_MES_GetPartFIFO('NAL0159-DSA04', 'A', 'EEA', null, null, 'N')
order by
	FirstDT
go
