
insert
	FT.NumberSequence
(	Name
,	HelpText
,	NumberMask
,	NextValue
)
select
	Name = 'Quality Batch'
,	HelpText = 'Number sequence for quality batches.'
,	NumberMask = 'QB_000000000'
,	NextValue = 0
where
	not exists
	(	select
			*
		from
			FT.NumberSequence ns
		where
			Name = 'Quality Batch'
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
		KeyName = 'dbo.InventoryControl_QualityBatchHeaders.QualityBatchNumber'
	,	NumberSequenceID = @numberSequenceID
	where
		not exists
			(	select
					*
				from
					FT.NumberSequenceKeys nsk
				where
					nsk.KeyName =  'dbo.InventoryControl_QualityBatchHeaders.QualityBatchNumber'
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