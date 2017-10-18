SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[msp_build_bom_timeline] (
	@top_part	char ( 25 ) )
AS
--	Procedure:	msp_build_bom_timeline
--	Date:		June 29 1999 - mb

	SELECT	effective_date,
		'*', 
		engineering_level,
		operator,
		notes
	  FROM	effective_change_notice
	 WHERE	part = @top_part 
	 ORDER BY 1
GO
