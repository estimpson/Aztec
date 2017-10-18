SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[cdisp_ovproc] (@order_no integer ) as
begin	
	SELECT	oh.order_no,
		oh.destination,
		oh.customer_part,
		oh.our_cum,
		ohi.the_cum their_cum,
		sd.date_shipped our_shipped_date,
		ohi.shipped_date their_shipped_date,
		sd.qty_packed our_shipped,
		ohi.shipped their_shipped,
		ohi.order_date,
		odi.part_number,
		odi.type,
		odi.due_date,
		odi.sequence,
		IsNull ( ( select Max ( od.quantity ) from order_detail od where od.order_no = odi.order_no and od.due_date = odi.due_date and od.notes = odi.notes), 0 ) old_quantity,
		IsNull ( quantity, 0 ) quantity,
		' ' checked,
		odi.status,
		Left ( odi.notes, 3 ) notes,
		ohi.review_date,
		ohi.reviewed_by
	FROM	order_detail_inserted  odi
		JOIN order_header oh ON odi.order_no = oh.order_no
		JOIN order_header_inserted ohi ON odi.order_no = ohi.order_no AND
			ohi.order_date = (
				SELECT	Max ( ohi2.order_date )
				  FROM	order_header_inserted ohi2
				 WHERE	ohi2.order_no = odi.order_no )
		LEFT OUTER JOIN shipper_detail sd ON sd.order_no = oh.order_no AND
			sd.shipper = oh.shipper AND
			sd.part_original = oh.blanket_part AND
			sd.date_shipped =
			(	SELECT	Max ( date_shipped )
				FROM	shipper_detail sd1
				WHERE	sd1.order_no = oh.order_no AND
					sd1.shipper = oh.shipper AND
					sd1.part_original = oh.blanket_part )
	WHERE	oh.order_no = @order_no
	UNION 
	SELECT	oh.order_no,
		oh.destination,
		oh.customer_part,
		oh.our_cum,
		ohi.the_cum their_cum,
		sd.date_shipped our_shipped_date,
		ohi.shipped_date their_shipped_date,
		sd.qty_packed our_shipped,
		ohi.shipped their_shipped,
		ohi.order_date,
		od.part_number,
		od.type,
		od.due_date,
		( select Max ( odi.sequence ) from order_detail_inserted odi where odi.order_no = od.order_no and odi.due_date = od.due_date and odi.notes = od.notes),
		IsNull ( quantity, 0 ),
		IsNull ( ( select Max ( odi.quantity ) from order_detail_inserted odi where odi.order_no = od.order_no and odi.due_date = od.due_date and odi.notes = od.notes), 0 ),
		' ',
		( select Max ( odi.status ) from order_detail_inserted odi where odi.order_no = od.order_no and odi.due_date = od.due_date and odi.notes = od.notes),
		Left ( od.notes, 3 ),
		ohi.review_date,
		ohi.reviewed_by
	FROM	order_detail od
		JOIN order_header oh ON od.order_no = oh.order_no
		JOIN order_header_inserted ohi ON od.order_no = ohi.order_no AND
			ohi.order_date = (
				SELECT	Max ( ohi2.order_date )
				  FROM	order_header_inserted ohi2
				 WHERE	ohi2.order_no = od.order_no )
		LEFT OUTER JOIN shipper_detail sd ON sd.order_no = oh.order_no AND
			sd.shipper = oh.shipper AND
			sd.part_original = oh.blanket_part AND
			sd.date_shipped =
			(	SELECT	Max ( date_shipped )
				FROM	shipper_detail sd1
				WHERE	sd1.order_no = oh.order_no AND
					sd1.shipper = oh.shipper AND
					sd1.part_original = oh.blanket_part )
	WHERE	oh.order_no = @order_no
	ORDER BY 1, 13, 16 desc
end
GO
