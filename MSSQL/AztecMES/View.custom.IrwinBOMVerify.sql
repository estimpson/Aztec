
/*
Create view fx21st.custom.IrwinBOMVerify
*/

--use fx21st
--go

--drop table custom.IrwinBOMVerify
if	objectproperty(object_id('custom.IrwinBOMVerify'), 'IsView') = 1 begin
	drop view custom.IrwinBOMVerify
end
go

create view custom.IrwinBOMVerify
as
select
	SeatPart = pSeat.part
,   SeatDescription = pSeat.name
,	BucketPart = pBucket.part
,	BucketDescription = pBucket.name
,	BucketSubComponents = (select count(*) from Ft.XRt xr where xr.TopPart = pBucket.part and xr.BOMLevel = 1)
,	BucketBOMLevel = xrBucket.BOMLevel
,	RHBracketPart = pRHBracket.part
,	RHBracketDescription = pRHBracket.name
,	RHBracketSubComponents = (select count(*) from Ft.XRt xr where xr.TopPart = pRHBracket.part and xr.BOMLevel = 1)
,	LHBracketPart = pLHBracket.part
,	LHBracketDescription = pLHBracket.name
,	LHBracketComponents = (select count(*) from Ft.XRt xr where xr.TopPart = pLHBracket.part and xr.BOMLevel = 1)
,	BearingBlockPart = pBearingBlock.part
,	BearingBlockDescription = pBearingBlock.name
,	BearingBlockComponents = (select count(*) from Ft.XRt xr where xr.TopPart = pBearingBlock.part and xr.BOMLevel = 1)
,	TiltMechanismPart = pTiltMechanism.part
,	TiltMechanismDescription = pTiltMechanism.name
,	TiltMechanismSubComponents = (select count(*) from Ft.XRt xr where xr.TopPart = pTiltMechanism.part and xr.BOMLevel = 1)
,	DamperAssyPart = pDamperAssy.part
,	DamperAssyDescription = pDamperAssy.name
,	DamperAssySubComponents = (select count(*) from Ft.XRt xr where xr.TopPart = pDamperAssy.part and xr.BOMLevel = 1)
,	UClipPart = pUClip.part
,	UClipDescription = pUClip.name
,	OtherPart = pOther.part
,	OtherDescription = pOther.name
,	TotalBOMCount = (select count(*) from Ft.XRt xr where xr.TopPart = pSeat.part)
from
	dbo.part pSeat
	left join FT.XRt xrBucket
		join dbo.part pBucket
			on pBucket.part = xrBucket.ChildPart
		on xrBucket.TopPart = pSeat.part
		and xrBucket.ChildPart like '1200[12][019]%'
		and xrBucket.BOMLevel in (1,2)
	left join FT.XRt xrRHBracket
		join dbo.part pRHBracket
			on pRHBracket.part = xrRHBracket.ChildPart
		on xrRHBracket.TopPart = pSeat.part
		and xrRHBracket.ChildPart like '1201%'
		and xrRHBracket.BOMLevel = 1
	left join FT.XRt xrLHBracket
		join dbo.part pLHBracket
			on pLHBracket.part = xrLHBracket.ChildPart
		on xrLHBracket.TopPart = pSeat.part
		and xrLHBracket.ChildPart like '1226%'
		and xrLHBracket.BOMLevel = 1
	left join FT.XRt xrBearingBlock
		join dbo.part pBearingBlock
			on pBearingBlock.part = xrBearingBlock.ChildPart
		on xrBearingBlock.TopPart = pSeat.part
		and xrBearingBlock.ChildPart in
			(	'1222'
			,	'1222QR'
			)
		and xrBearingBlock.BOMLevel = 1
	left join FT.XRt xrTiltMechanism
		join dbo.part pTiltMechanism
			on pTiltMechanism.part = xrTiltMechanism.ChildPart
		on xrTiltMechanism.TopPart = pSeat.part
		and xrTiltMechanism.ChildPart in
			(	'1227'
			,	'1252'
			,	'1232'
			)
		and xrTiltMechanism.BOMLevel = 1
	left join FT.XRt xrDamperAssy
		join dbo.part pDamperAssy
			on pDamperAssy.part = xrDamperAssy.ChildPart
		on xrDamperAssy.TopPart = pSeat.part
		and xrDamperAssy.ChildPart like '442A'
		and xrDamperAssy.BOMLevel = 1
	left join FT.XRt xrUClip
		join dbo.part pUClip
			on pUClip.part = xrUClip.ChildPart
		on xrUClip.TopPart = pSeat.part
		and xrUClip.ChildPart like 'C43978-025-A'
		and xrUClip.BOMLevel >= 1
	left join FT.XRt xrOther
		join dbo.part pOther
			on pOther.part = xrOther.ChildPart
		on xrOther.TopPart = pSeat.part
		and xrOther.ChildPart not in
			(	coalesce(pBucket.part, '')
			,	left(coalesce(pBucket.part, ''), 4) + 'R' + substring(coalesce(pBucket.part, ''), 5, 25)
			,	coalesce(pRHBracket.part, '')
			,	coalesce(pLHBracket.part, '')
			,	coalesce(pBearingBlock.part, '')
			,	coalesce(pTiltMechanism.part, '')
			,	coalesce(pSeat.part, '')
			,	coalesce(pDamperAssy.part, '')
			,	coalesce(pUClip.part, '')
			)
		and xrOther.BOMLevel = 1
where
	pSeat.part like '12[136][12347]%[12][019]%'
	and pSeat.type = 'F'
go

select
	*
from
	custom.IrwinBOMVerify
order by
	1
