
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
	StatusGUID = '03D5BF9B-2C1C-44EC-BE8A-E87DAF338CD7'
,	StatusTable = 'dbo.InventoryControl_CycleCountObjects'
,	StatusColumn = 'Status'
,	StatusCode = 0
,	StatusName = 'Unknown'
,	HelpText = 'Object status unknown'
where
	not exists
		(	select
				*
			from
				FT.StatusDefn sd
			where
				sd.StatusGUID = '03D5BF9B-2C1C-44EC-BE8A-E87DAF338CD7'
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
	StatusGUID = '450E4185-FD0E-4C6B-ACC8-A0D964858DCB'
,	StatusTable = 'dbo.InventoryControl_CycleCountObjects'
,	StatusColumn = 'Status'
,	StatusCode = 1
,	StatusName = 'Found'
,	HelpText = 'Object found'
where
	not exists
		(	select
				*
			from
				FT.StatusDefn sd
			where
				sd.StatusGUID = '450E4185-FD0E-4C6B-ACC8-A0D964858DCB'
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
	StatusGUID = '91D4C08A-D1EC-4C18-8834-18161F67ABBD'
,	StatusTable = 'dbo.InventoryControl_CycleCountObjects'
,	StatusColumn = 'Status'
,	StatusCode = 2
,	StatusName = 'Found (adj)'
,	HelpText = 'Object found with quantity adjustment'
where
	not exists
		(	select
				*
			from
				FT.StatusDefn sd
			where
				sd.StatusGUID = '91D4C08A-D1EC-4C18-8834-18161F67ABBD'
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
	StatusGUID = '91C0F18E-9932-48FD-8C9F-C21EE2188AA7'
,	StatusTable = 'dbo.InventoryControl_CycleCountObjects'
,	StatusColumn = 'Status'
,	StatusCode = 3
,	StatusName = 'Found (relocated)'
,	HelpText = 'Object found with relocation'
where
	not exists
		(	select
				*
			from
				FT.StatusDefn sd
			where
				sd.StatusGUID = '91C0F18E-9932-48FD-8C9F-C21EE2188AA7'
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
	StatusGUID = '447CD07A-7E6E-404E-9625-9BCF58B1E09E'
,	StatusTable = 'dbo.InventoryControl_CycleCountObjects'
,	StatusColumn = 'Status'
,	StatusCode = 4
,	StatusName = 'Found (adj/reloc)'
,	HelpText = 'Object found with quantity adjustment and relocation'
where
	not exists
		(	select
				*
			from
				FT.StatusDefn sd
			where
				sd.StatusGUID = '447CD07A-7E6E-404E-9625-9BCF58B1E09E'
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
	StatusGUID = 'D1BFBA16-8B7D-436C-A321-B0D7B5A01E38'
,	StatusTable = 'dbo.InventoryControl_CycleCountObjects'
,	StatusColumn = 'Status'
,	StatusCode = 5
,	StatusName = 'Recover'
,	HelpText = 'Object found'
where
	not exists
		(	select
				*
			from
				FT.StatusDefn sd
			where
				sd.StatusGUID = 'D1BFBA16-8B7D-436C-A321-B0D7B5A01E38'
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
	StatusGUID = 'B00C8E6F-71C3-4B43-BDDC-2B584E8DBE9F'
,	StatusTable = 'dbo.InventoryControl_CycleCountObjects'
,	StatusColumn = 'Status'
,	StatusCode = -1
,	StatusName = 'Lost'
,	HelpText = 'Object lost'
where
	not exists
		(	select
				*
			from
				FT.StatusDefn sd
			where
				sd.StatusGUID = 'B00C8E6F-71C3-4B43-BDDC-2B584E8DBE9F'
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
	StatusGUID = '7DE0371F-B28E-41DF-9B9D-0AE07DBEB07A'
,	StatusTable = 'dbo.InventoryControl_CycleCountObjects'
,	StatusColumn = 'Status'
,	StatusCode = -2
,	StatusName = 'Ignore'
,	HelpText = 'Object ignored'
where
	not exists
		(	select
				*
			from
				FT.StatusDefn sd
			where
				sd.StatusGUID = '7DE0371F-B28E-41DF-9B9D-0AE07DBEB07A'
		)  
go

select
	*
from
	FT.StatusDefn sd
where
	StatusTable = 'dbo.InventoryControl_CycleCountObjects'
