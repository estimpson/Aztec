SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[msp_get_1050_compl_data]
	(	@a_s_machine	varchar ( 10 ),
		@a_s_part	varchar ( 25 ) = null )
AS
DECLARE	@l_s_wo_number		varchar ( 10 ),
	@l_f_std_pack		float,
	@l_f_parts_per_cycle	float,
	@l_f_cyc_tot		float,
	@l_f_qty_comp		float,
	@l_f_qty_req		float,
	@l_f_defects		float,
	@l_f_box_req		float,
	@l_f_box_per_sqr	float
CREATE TABLE #part_list
(	part		varchar ( 25 ) )
CREATE TABLE #result_out_header
(
	wo_number	varchar (10) null,
	machine_count	integer	null)
CREATE TABLE #result_out_detail
(	part		varchar ( 25 ),
	box_per_square	float,
	required	float,
	cycles		float	null,
	complete	float	null,
	defects		float	null )
/* Get the work order from work_order :: @l_s_wo_number */
SELECT	@l_s_wo_number = work_order
  FROM	work_order
 WHERE	machine_no = @a_s_machine AND
	sequence = 1
/* Get the current counter count from machine_data_1050 :: @l_f_cyc_tot */
SELECT	@l_f_cyc_tot = counter
  FROM	machine_data_1050
 WHERE	machine = @a_s_machine
/* Write header info */
INSERT	#result_out_header
	SELECT	@l_s_wo_number,
		IsNull ( @l_f_cyc_tot, 0 )
/* Build part list */
IF @a_s_part IS NULL
	INSERT	#part_list
		SELECT	part
		  FROM	workorder_detail
		 WHERE	workorder = @l_s_wo_number
ELSE
	INSERT	#part_list
		SELECT	part
		  FROM	workorder_detail
		 WHERE	workorder = @l_s_wo_number AND
			part = @a_s_part
/* Loop through part list */
SELECT	@a_s_part = NULL
SELECT	@a_s_part = Min ( part )
  FROM	#part_list
WHILE @a_s_part > ''
BEGIN
/* Get the total required qty from workorder_detail :: @l_f_qty_req */
	SELECT	@l_f_qty_req = Sum ( qty_required )
	  FROM	workorder_detail
	 WHERE	part = @a_s_part AND
		workorder = @l_s_wo_number
/* Get the total completed qty from workorder_detail :: @l_f_qty_comp */
	SELECT	@l_f_qty_comp = Sum ( qty_completed )
	  FROM	workorder_detail
	 WHERE	part = @a_s_part AND
		workorder = @l_s_wo_number
/* Get the total number of defects from defects :: @l_f_defects */
	SELECT	@l_f_defects = IsNull ( Sum ( defects.quantity ), 0 )
	  FROM	defects
	 WHERE	part = @a_s_part AND
		work_order = @l_s_wo_number
/* Get the number of parts per cycle from part_mfg :: @l_f_parts_per_cycle */
	SELECT	@l_f_parts_per_cycle = parts_per_cycle
	  FROM	part_mfg
	 WHERE	part = @a_s_part
	IF IsNull ( @l_f_parts_per_cycle, 0 ) = 0
		SELECT @l_f_parts_per_cycle = 1
/* Get the standard pack (parts per box) from part_packaging :: @l_f_std_pack */
	SELECT	@l_f_std_pack = Min ( quantity )
	  FROM	part_packaging
	 WHERE	part = @a_s_part
	IF IsNull ( @l_f_std_pack, 0 ) = 0
		SELECT @l_f_std_pack = 1
/* Calculate the number of boxes required by dividing @l_f_qty_req by @l_f_std_pack and rounding up :: @l_f_box_req */
	SELECT	@l_f_box_req = @l_f_qty_req / @l_f_std_pack
/* Calculate the boxes per square from @l_f_box_req and @l_f_defects :: @l_f_box_per_sqr */
	SELECT	@l_f_box_per_sqr = Power ( Convert ( float, 10 ), Ceiling ( LOG10 ( @l_f_box_req + ( @l_f_defects / @l_f_std_pack ) ) ) )
/*	SELECT	@l_s_wo_number wo_number,
		@l_f_std_pack std_pack,
		@l_f_parts_per_cycle ppc,
		@l_f_cyc_tot cyc_tot,
		@l_f_qty_comp qty_comp,
		@l_f_qty_req qty_req,
		@l_f_defects def,
		@l_f_box_req box_req,
		@l_f_box_per_sqr box_per_sqr*/
	INSERT #result_out_detail
	(	part,
		box_per_square,
		required,
		cycles,
		complete,
		defects )
		SELECT	@a_s_part,
			IsNull ( @l_f_box_per_sqr / 10, 0 ),
			IsNull ( @l_f_box_req / @l_f_box_per_sqr, 0 ),
			IsNull ( @l_f_cyc_tot * @l_f_parts_per_cycle / ( @l_f_std_pack * @l_f_box_per_sqr ), 0 ),
			IsNull ( @l_f_qty_comp / ( @l_f_std_pack * @l_f_box_per_sqr ), 0 ),
			IsNull ( @l_f_defects / ( @l_f_std_pack * @l_f_box_per_sqr ), 0 )
	DELETE	#part_list
	 WHERE	part = @a_s_part
	SELECT	@a_s_part = NULL
	SELECT	@a_s_part = Min ( part )
	  FROM	#part_list
END
SELECT	*
  FROM	#result_out_header,
	#result_out_detail
GO
