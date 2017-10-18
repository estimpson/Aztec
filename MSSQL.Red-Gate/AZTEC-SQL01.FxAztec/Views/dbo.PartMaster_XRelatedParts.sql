SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PartMaster_XRelatedParts]
as
with
	Siblings
(	AnchorPart
,	SiblingPart
)
as
(	select
		AnchorPart = pmrpgAnchor.PartCode
	,	SiblingPart = pmrpgSiblings.PartCode
	from
		dbo.PartMaster_RelatedPartGroups pmrpgAnchor
			join dbo.PartMaster_RelatedPartGroups pmrpgSiblings
				on pmrpgSiblings.GroupGUID = pmrpgAnchor.GroupGUID
				and pmrpgSiblings.PartCode != pmrpgAnchor.PartCode
)
,	XSiblings
(	AnchorPart
,	Distance
,	RelatedPart
,	Chain
)
as
(	select
 		AnchorPart
	,	Distance = 1
	,	RelatedPart = SiblingPart
	,	Chain = convert(varchar(max), '/' + AnchorPart + '/' + SiblingPart)
 	from
 		Siblings
	union all
	select
 		XSiblings.AnchorPart
	,	Distance = XSiblings.Distance + 1
	,	RelatedPart = Siblings.SiblingPart
	,	Chain = convert(varchar(max), XSiblings.Chain + '/' + Siblings.SiblingPart)
	from
 		XSiblings
		join Siblings
			on Siblings.AnchorPart = XSiblings.RelatedPart
	where
		XSiblings.Chain not like '%/' + Siblings.SiblingPart + ''
		and XSiblings.Chain not like '%/' + Siblings.SiblingPart + '/%'
)
,	XSequencedSiblings
(	AnchorPart
,	Distance
,	RelatedPart
,	Chain
,	Sequence
)
as
(	select
		AnchorPart
	,	Distance
	,	RelatedPart
	,	Chain
	,	Sequence = row_number() over (partition by AnchorPart order by Chain)
	from
		XSiblings
)  
select
	xss.AnchorPart
,	xss.Distance
,	xss.RelatedPart
,	xss.Chain
,	xss.Sequence
from
	XSequencedSiblings xss
where
	xss.Distance =
	(	select
			min(Distance)
		from
			XSequencedSiblings
		where
			AnchorPart = xss.AnchorPart
			and RelatedPart = xss.RelatedPart
	)
	and
	xss.Sequence =
	(	select
			min(Sequence)
		from
			XSequencedSiblings
		where
			AnchorPart = xss.AnchorPart
			and RelatedPart = xss.RelatedPart
			and Distance = xss.Distance
	)
GO
