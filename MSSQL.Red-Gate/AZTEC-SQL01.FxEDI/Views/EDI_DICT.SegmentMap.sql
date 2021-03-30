SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [EDI_DICT].[SegmentMap]
as
select distinct
	dsc.DictionaryVersion
,	dsc.ContentType
,	dsc.Segment
,	dsc.ElementOrdinal
,	dsc.ElementUsage
,	de.ElementCode
,	de.ElementName
,	de.ElementDataType
,	de.ElementLengthMin
,	de.ElementLengthMax
,	ChildElementOrdinal = dsc2.ElementOrdinal
,	ChildElementUsage= dsc2.ElementUsage
,	ChildElementCode = de2.ElementCode
,	ChildElementName = de2.ElementName
,	ChildElementDataType = de2.ElementDataType
,	ChildElementLengthMin = de2.ElementLengthMin
,	ChildElementLengthMax = de2.ElementLengthMax
from
	EDI_DICT.DictionaryTransactionSegments dts
	join EDI_DICT.DictionarySegmentContents dsc
		on dsc.DictionaryVersion = dts.DictionaryVersion
		and dsc.Segment = dts.SegmentCode
	join EDI_DICT.DictionaryElements de
		on de.DictionaryVersion = dts.DictionaryVersion
		and de.ElementCode = dsc.ElementCode
	left join EDI_DICT.DictionarySegmentContents dsc2
		on dsc2.DictionaryVersion = dts.DictionaryVersion
		and dsc2.Segment = de.ElementCode
	left join EDI_DICT.DictionaryElements de2
		on de2.DictionaryVersion = dts.DictionaryVersion
		and de2.ElementCode = dsc2.ElementCode
GO
