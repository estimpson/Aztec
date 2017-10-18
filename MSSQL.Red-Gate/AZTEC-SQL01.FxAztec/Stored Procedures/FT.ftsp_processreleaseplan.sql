SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create procedure [FT].[ftsp_processreleaseplan]
as

Begin

Truncate table "log"

exec dbo.msp_process_in_release_plan

TRUNCATE TABLE ft.raw_830_shp
TRUNCATE TABLE ft.raw_830_release
TRUNCATE TABLE dbo.m_in_release_plan

Select	"message"
From 		log
Where		"message" like '%Blanket%'

End
GO
