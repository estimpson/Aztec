SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[ReceivingDock_ReceiverHeaderStatus]
as
select
	rh.ReceiverID
,	rh.ReceiverNumber
,	rh.Type
,	td.TypeName
,	rh.Status
,	sd.StatusName
,	OriginType =
		case when rh.SupplierASNGuid is null then 1
			else 2
		end
,	OriginTypeName =
		case when rh.SupplierASNGuid is null then 'Manual'
			else 'ASN'
		end
,	SupplierLabelComplianceStatus =
		case
			when alc.VendorCode is null then 0
			when alc.ErrorMessage is not null then -1
			else 1
		end
,	SupplierLabelComplianceStatusName =
		case
			when alc.VendorCode is null then 'Not Verified'
			when alc.ErrorMessage is not null then 'Failed: ' + alc.ErrorMessage
			else 'Verified'
		end
from
	dbo.ReceiverHeaders rh
		join dbo.destination dVend
			on dVend.destination = rh.ShipFrom
	join FT.TypeDefn td
		on td.TypeTable = 'ReceiverHeaders'
		and td.TypeCode = rh.Type
	join FT.StatusDefn sd
		on sd.StatusTable = 'ReceiverHeaders'
		and sd.StatusCode = rh.Status
	outer apply
		(	select VendorCode = dVend.vendor, ErrorMessage = convert(varchar, null)) alc
	--left join dbo.AsnLabelCompliance alc
	--	join
	--	(	select
	--			alc.VendorCode
	--		,	LastScan = max(alc.RowCreateDT)
	--		from
	--			dbo.AsnLabelCompliance alc
	--		group by
	--			alc.VendorCode
	--	) labelVerif
	--		on alc.VendorCode = labelVerif.VendorCode
	--		and alc.RowCreateDT = labelVerif.LastScan
	--	on alc.VendorCode = dVend.vendor
GO
