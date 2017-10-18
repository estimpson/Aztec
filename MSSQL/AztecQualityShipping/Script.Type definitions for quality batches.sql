--delete td from FT.TypeDefn td where td.TypeTable = 'dbo.InventoryControl_QualityBatchHeaders' and td.TypeColumn = 'Type' and td.TypeCode = 1
insert
	FT.TypeDefn
(	TypeGUID
,	TypeTable
,	TypeColumn
,	TypeCode
,	TypeName
,	HelpText
)
select
	TypeGUID = '12826743-B007-4C29-96FE-2F74F6F4F28D'
,	TypeTable = 'dbo.InventoryControl_QualityBatchHeaders'
,	TypeColumn = 'Type'
,	TypeCode = 1
,	TypeName = 'Manual'
,	HelpText = 'A manual quality batch.'
where
	not exists
		(	select
				*
			from
				FT.TypeDefn td
			where
				td.TypeTable = 'dbo.InventoryControl_QualityBatchHeaders'
				and td.TypeColumn = 'Type'
				and td.TypeCode = 1
		)

--delete td from FT.TypeDefn td where td.TypeTable = 'dbo.InventoryControl_QualityBatchHeaders' and td.TypeColumn = 'Type' and td.TypeCode = 2
insert
	FT.TypeDefn
(	TypeGUID
,	TypeTable
,	TypeColumn
,	TypeCode
,	TypeName
,	HelpText
)
select
	TypeGUID = '62CA6563-406F-418A-AED0-E511A0927578'
,	TypeTable = 'dbo.InventoryControl_QualityBatchHeaders'
,	TypeColumn = 'Type'
,	TypeCode = 2
,	TypeName = 'QSA'
,	HelpText = 'A quality batch associated with inspection of a shipment.'
where
	not exists
		(	select
				*
			from
				FT.TypeDefn td
			where
				td.TypeTable = 'dbo.InventoryControl_QualityBatchHeaders'
				and td.TypeColumn = 'Type'
				and td.TypeCode = 2
		)

select
	*
from
	FT.TypeDefn td
where
	td.TypeTable = 'dbo.InventoryControl_QualityBatchHeaders'