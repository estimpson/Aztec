SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[msp_reconcile_rma_shipper]
(	@rma integer )
AS
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--      This procedure reconciles the qnty and standard quantity staged to a shipper,
--      sets boxes and pallets staged fields in shipper detail and
--      shipper header, and sets the status of the shipper to
--      (S)taged or (O)pen as appropriate
--
--      Modifications:
--	MB 07/12/99	Original
--	MB 09/26/99	Modified
--			Included code to update shipper detail table from object table depending on the origin,
--			suffix, shipper.
--	EES 28 APR 2000	Modified to use audit trail information.
--
--      Agruments:      @rma not null : shipper to be reconciled
--
--      Returns:        0       success
--                      -1      shipper not found
--                      -2      error, shipper was already closed
--                      -3      error, invalid part was staged to this shipper
--
--	Process:
--	I.	Declarations.
--	II.	Initialize all variables.
--	III.	Ensure shipper is valid.
--	IV.	Calculate received quantity, standard quantity, and boxes staged.
--	V.	Set boxes, pallets staged and status fields in shipper header.
--	VI.	Return.
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--	I.	Declarations.
DECLARE	@status		char (1),
	@invalidpart	varchar (25),
	@boxstage	integer,
	@rma_type	varchar (1)

--	II.	Initialize all variables.
SELECT	@status = NULL,
	@invalidpart = NULL

--	III.	Ensure shipper is valid.
IF NOT Exists
(	SELECT	1
	FROM	shipper
	WHERE	id = @rma )
	Return -1

IF Exists
(	SELECT	1
	FROM 	shipper
	WHERE	id = @rma AND
		status in ( 'C', 'Z' ) )
	Return -2

--	IV.	Calculate received quantity, standard quantity, and boxes staged.
UPDATE	shipper_detail
SET	qty_packed = -
	(	SELECT	Sum ( box.quantity )
		FROM	audit_trail box
		WHERE	box.shipper = Convert ( varchar , shipper_detail.shipper ) AND
			box.type = 'U' AND
			box.origin = Convert ( varchar, shipper_detail.old_shipper ) AND
			IsNull ( box.suffix, 0 ) = IsNull ( shipper_detail.old_suffix, 0 ) AND
			box.part = shipper_Detail.part_original AND
                        box.shipper = convert(varchar,@rma) ),
	alternative_qty = -
	(	SELECT	Sum ( box.std_quantity )
		FROM	audit_trail box
		WHERE	box.shipper = Convert ( varchar , shipper_detail.shipper ) AND
			box.type = 'U' AND
			box.origin = Convert ( varchar, shipper_detail.old_shipper ) AND
			IsNull ( box.suffix, 0 ) = IsNull ( shipper_detail.old_suffix, 0 ) AND
			box.part = shipper_Detail.part_original AND
                        box.shipper = convert(varchar,@rma) ),
	boxes_staged =
	(	SELECT	Count ( 1 )
		FROM	audit_trail box
		WHERE	box.shipper = Convert ( varchar , shipper_detail.shipper ) AND
			box.type = 'U' AND
			box.origin = Convert ( varchar, shipper_detail.old_shipper ) AND
			IsNull ( box.suffix, 0 ) = IsNull ( shipper_detail.old_suffix, 0 ) AND
			box.part = shipper_Detail.part_original AND
                        box.shipper = convert(varchar,@rma) )
WHERE	shipper = @rma

--	V.	Set boxes, pallets staged and status fields in shipper header.
UPDATE	shipper
SET	staged_objs =
	(	SELECT	Count ( 1 )
		FROM	audit_trail box
		WHERE	box.type = 'U' AND
			box.object_type IS NULL AND
			box.shipper = Convert ( varchar, @rma ) ),
	staged_pallets =
	(	SELECT	Count ( 1 )
		FROM	audit_trail box
		WHERE	box.type = 'U' AND
			box.object_type = 'S' AND
			box.shipper = Convert ( varchar, @rma ) ),
	status = IsNull (
        (	SELECT	Max ( 'O' )
		FROM	shipper_detail sd
		WHERE	sd.shipper = @rma and
			alternative_qty  = 0 or qty_packed = 0  ) , 'S' )
WHERE	id = @rma

--	VI.	Return.
Return 0
GO
