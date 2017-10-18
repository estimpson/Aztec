delete
	sd
from
	FT.StatusDefn sd
where
	StatusTable = 'dbo.InventoryControl_CycleCountHeaders'
go

insert
	FT.StatusDefn
(	StatusGUID
,	StatusTable
,	StatusColumn
,	StatusCode
,	StatusName
,	HelpText
)
select
	StatusGUID = '5C5A9A0A-800D-4424-87D2-3269B9884E31'
,	StatusTable = 'dbo.InventoryControl_CycleCountHeaders'
,	StatusColumn = 'Status'
,	StatusCode = 0
,	StatusName = 'New'
,	HelpText = 'New cycle count.'
where
	not exists
		(	select
				*
			from
				FT.StatusDefn sd
			where
				sd.StatusGUID = '5C5A9A0A-800D-4424-87D2-3269B9884E31'
		)  
go

insert
	FT.StatusDefn
(	StatusGUID
,	StatusTable
,	StatusColumn
,	StatusCode
,	StatusName
,	HelpText
)
select
	StatusGUID = 'E129FBB2-C974-47A8-9FCB-AD64EAE609FD'
,	StatusTable = 'dbo.InventoryControl_CycleCountHeaders'
,	StatusColumn = 'Status'
,	StatusCode = 1
,	StatusName = 'Started'
,	HelpText = 'Cycle count started.'
where
	not exists
		(	select
				*
			from
				FT.StatusDefn sd
			where
				sd.StatusGUID = 'E129FBB2-C974-47A8-9FCB-AD64EAE609FD'
		)  
go

insert
	FT.StatusDefn
(	StatusGUID
,	StatusTable
,	StatusColumn
,	StatusCode
,	StatusName
,	HelpText
)
select
	StatusGUID = '75A39488-993A-4F92-950E-9D42368CECFD'
,	StatusTable = 'dbo.InventoryControl_CycleCountHeaders'
,	StatusColumn = 'Status'
,	StatusCode = 2
,	StatusName = 'Ended'
,	HelpText = 'Cycle count ended.'
where
	not exists
		(	select
				*
			from
				FT.StatusDefn sd
			where
				sd.StatusGUID = '75A39488-993A-4F92-950E-9D42368CECFD'
		)  
go

select
	*
from
	FT.StatusDefn sd
where
	StatusTable = 'dbo.InventoryControl_CycleCountHeaders'
go

