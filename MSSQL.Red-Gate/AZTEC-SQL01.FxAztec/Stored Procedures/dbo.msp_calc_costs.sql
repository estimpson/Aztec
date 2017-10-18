SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[msp_calc_costs] (@part VARCHAR(25)=NULL, @cost_bucket CHAR(1)='S') AS
--------------------------------------------------------------------------------------------------------------------------
--
--	Procedure 	msp_calc_costs
--	Arguments	part varchar(25)
--			cost bucket char(1) ie S/P/Q/F
--	Purpose		To rollup the cost from it's components for the specified part
--
--	Logic		
--		Declare variables
--		Create Temp tables
--		Initialize
--		Process data in temp table #bom_parts starting from the top part
--			process all component parts
--		processing the costing rollup from the deepest level 
--		process all the rows in the temp table in the reverse order (cost rolls up from inner most to top part)
--			calculate labor & burden
--			update part_standard table with the new values for the current part
--
--	Development	GPH
--------------------------------------------------------------------------------------------------------------------------
BEGIN

BEGIN Transaction
EXECUTE	[dbo].[usp_Scheduling_BuildXRt]

commit
			


IF @Part > '' BEGIN
	SELECT	*
	INTO	#XRt
	FROM	FT.XRt
	WHERE	TopPart IN
		(	SELECT	ChildPart
			FROM	FT.XRt
			WHERE	TopPart = @Part )

	UPDATE	part_standard
	SET	labor = vwPartStandardAccum.Labor,
		burden = vwPartStandardAccum.Burden,
		cost = vwPartStandardAccum.Cost,
		material_cum = vwPartStandardAccum.MaterialAccum,
		labor_cum = vwPartStandardAccum.LaborAccum,
		burden_cum = vwPartStandardAccum.BurdenAccum,
		cost_cum = vwPartStandardAccum.CostAccum
	FROM	part_standard
		JOIN
		(	SELECT	vwPartStandard.Part,
				Cost = vwPartStandard.Material + vwPartStandard.Labor + vwPartStandard.Burden,
				vwPartStandard.Material,
				vwPartStandard.Labor,
				vwPartStandard.Burden,
				CostAccum = SUM ( XRt.XQty * ( Child.Material + Child.Labor + Child.Burden ) ),
				MaterialAccum = SUM ( XRt.XQty * Child.Material ),
				LaborAccum = SUM ( XRt.XQty * Child.Labor ),
				BurdenAccum = SUM ( XRt.XQty * Child.Burden )
			FROM	vwPartStandard
				JOIN #XRt XRt ON vwPartStandard.Part = XRt.TopPart
				JOIN vwPartStandard Child ON XRt.ChildPart = Child.Part
			GROUP BY
				vwPartStandard.Part,
				vwPartStandard.Material,
				vwPartStandard.Burden,
				vwPartStandard.Labor ) vwPartStandardAccum ON part_standard.part = vwPartStandardAccum.Part
END
ELSE BEGIN
	UPDATE	part_standard
	SET	labor = vwPartStandardAccum.Labor,
		burden = vwPartStandardAccum.Burden,
		cost = vwPartStandardAccum.Cost,
		material_cum = vwPartStandardAccum.MaterialAccum,
		labor_cum = vwPartStandardAccum.LaborAccum,
		burden_cum = vwPartStandardAccum.BurdenAccum,
		cost_cum = vwPartStandardAccum.CostAccum
	FROM	part_standard
		JOIN vwPartStandardAccum ON part_standard.part = vwPartStandardAccum.Part
END
END


GO
