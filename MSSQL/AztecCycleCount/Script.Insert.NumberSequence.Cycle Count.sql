
insert
	FT.NumberSequence
(	Name
,	HelpText
,	NumberMask
,	NextValue
)
select
	Name = 'Cycle Count'
,	HelpText = 'Number sequence for cycle counts.'
,	NumberMask = 'CC_000000000'
,	NextValue = 0
where
	not exists
	(	select
			*
		from
			FT.NumberSequence ns
		where
			Name = 'Cycle Count'
	)

if	@@ROWCOUNT = 1 begin
	declare
		@numberSequenceID int
	
	set @numberSequenceID = scope_identity()
	
	insert
		FT.NumberSequenceKeys
	(	KeyName
	,	NumberSequenceID
	)
	select
		KeyName = 'dbo.InventoryControl_CycleCountHeaders.CycleCountNumber'
	,	NumberSequenceID = @numberSequenceID
	where
		not exists
			(	select
					*
				from
					FT.NumberSequenceKeys nsk
				where
					nsk.KeyName =  'dbo.InventoryControl_CycleCountHeaders.CycleCountNumber'
			)
end
go

select
	*
from
	FT.NumberSequence ns

select
	*
from
	FT.NumberSequenceKeys nsk