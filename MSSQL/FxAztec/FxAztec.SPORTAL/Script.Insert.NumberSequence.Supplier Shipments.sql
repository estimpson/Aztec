
/*
Script.Insert.NumberSequence.Supplier Shipments.sql
*/

use FxAztec

/*
Create.NumberSequence.SPORTAL.SupplierShipments.ShipperNumber.sql
*/
insert
	FT.NumberSequence
(	Name
,	HelpText
,	NumberMask
,	NextValue
)
select
	Name = 'Supplier Shipments'
,	HelpText = 'Number sequence for SPORTAL.SupplierShipments.ShipperNumber.'
,	NumberMask = 'SS_000000000'
,	NextValue = 0
where
	not exists
	(	select
			*
		from
			FT.NumberSequence ns
		where
			Name = 'Supplier Shipments'
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
		KeyName = 'SPORTAL.SupplierShipments.ShipperNumber'
	,	NumberSequenceID = @numberSequenceID
	where
		not exists
			(	select
					*
				from
					FT.NumberSequenceKeys nsk
				where
					nsk.KeyName = 'Supplier Shipments'
			)
end
go

select
	*
from
	FT.NumberSequence ns
where
	Name = 'Supplier Shipments'

select
	*
from
	FT.NumberSequenceKeys nsk
where
	KeyName = 'SPORTAL.SupplierShipments.ShipperNumber'
go

