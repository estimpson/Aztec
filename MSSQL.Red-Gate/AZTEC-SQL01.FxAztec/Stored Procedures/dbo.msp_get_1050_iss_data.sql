SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[msp_get_1050_iss_data]
	(	@a_s_machine	varchar ( 10 ),
		@a_s_parent	varchar ( 25 ) = null,
		@a_s_part	varchar ( 25 ) = null )
AS
DECLARE	@l_s_wo_number		varchar ( 10 ),
	@l_f_std_pack		float,
	@l_f_parts_per_cycle	float,
	@l_f_cyc_tot		float,
	@l_f_qty_iss		float,
	@l_f_qty_req		float,
	@l_f_qty_avail		float,
	@l_f_qty_plant		float,
	@l_f_qty_unavail	float,
	@l_f_box_req		float,
	@l_f_box_per_sqr	float,
	@l_f_factor		float
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
	issue		float	null,
	available	float	null,
	avail_plant	float	null,
	unavailable	float	null )
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
IF @a_s_parent IS NULL
	SELECT	@a_s_parent = Min ( part )
	  FROM	workorder_detail
	 WHERE	workorder = @l_s_wo_number
IF @a_s_part IS NULL
	INSERT	#part_list
		SELECT	part
		  FROM	bill_of_material
		 WHERE	parent_part = @a_s_parent
ELSE
	INSERT	#part_list
		SELECT	part
		  FROM	bill_of_material
		 WHERE	parent_part = @a_s_parent AND
			part = @a_s_part
/* Loop through part list */
SELECT	@a_s_part = NULL
SELECT	@a_s_part = Min ( part )
  FROM	#part_list
WHILE @a_s_part > ''
BEGIN
/* Get the bill factor from bill_of_material :: @l_f_factor */
	SELECT	@l_f_factor = IsNull ( quantity, 0 )
	  FROM	bill_of_material
	 WHERE	parent_part = @a_s_parent AND
		part = @a_s_part
/* Get the total required qty from workorder_detail :: @l_f_qty_req */
	SELECT	@l_f_qty_req = Sum ( qty_required ) * @l_f_factor
	  FROM	workorder_detail
	 WHERE	part = @a_s_parent AND
		workorder = @l_s_wo_number
/* Get the total issued qty from audit_trail :: @l_f_qty_iss */
	SELECT	@l_f_qty_iss = IsNull ( Sum ( std_quantity ), 0 )
	  FROM	audit_trail
	 WHERE	part = @a_s_part AND
		workorder = @l_s_wo_number AND
		type = 'M'
/* Get the total available quantity at current location :: @l_f_qty_avail */
	SELECT	@l_f_qty_avail = IsNull ( Sum ( std_quantity ), 0 )
	  FROM	object
	 WHERE	part = @a_s_part AND
		location = @a_s_machine AND
		status = 'A'
/* Get the total available quantity in plant :: @l_f_qty_plant */
	SELECT	@l_f_qty_plant = IsNull ( Sum ( std_quantity ), 0 )
	  FROM	object
	 WHERE	part = @a_s_part AND
		location <> @a_s_machine AND
		status = 'A'
/* Get the total unavailable quantity in plant :: @l_f_qty_unavail */
	SELECT	@l_f_qty_unavail = IsNull ( Sum ( std_quantity ), 0 )
	  FROM	object
	 WHERE	part = @a_s_part AND
		status <> 'A'
/* Get the number of parts per cycle from part_mfg :: @l_f_parts_per_cycle */
	SELECT	@l_f_parts_per_cycle = parts_per_cycle
	  FROM	part_mfg
	 WHERE	part = @a_s_parent
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
	SELECT	@l_f_box_per_sqr = Power ( Convert ( float, 10 ), Ceiling ( LOG10 ( @l_f_box_req ) ) )
/*	SELECT	@l_s_wo_number wo_number,
		@l_f_std_pack std_pack,
		@l_f_parts_per_cycle ppc,
		@l_f_cyc_tot cyc_tot,
		@l_f_qty_iss qty_iss,
		@l_f_qty_req qty_req,
		@l_f_qty_avail available,
		@l_f_qty_plant avail_plant,
		@l_f_qty_unavail unavailable,
		@l_f_box_req box_req,
		@l_f_box_per_sqr box_per_sqr,
		@l_f_factor factor*/
	INSERT #result_out_detail
	(	part,
		box_per_square,
		required,
		cycles,
		issue,
		available,
		avail_plant,
		unavailable )
		SELECT	@a_s_part,
			IsNull ( @l_f_box_per_sqr / 10, 0 ),
			IsNull ( @l_f_box_req / @l_f_box_per_sqr, 0 ),
			IsNull ( @l_f_cyc_tot * @l_f_parts_per_cycle / ( @l_f_std_pack * @l_f_box_per_sqr ), 0 ),
			IsNull ( @l_f_qty_iss / ( @l_f_std_pack * @l_f_box_per_sqr ), 0 ),
			IsNull ( @l_f_qty_avail / ( @l_f_std_pack * @l_f_box_per_sqr ), 0 ),
			IsNull ( @l_f_qty_plant / ( @l_f_std_pack * @l_f_box_per_sqr ), 0 ),
			IsNull ( @l_f_qty_unavail / ( @l_f_std_pack * @l_f_box_per_sqr ), 0 )
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
