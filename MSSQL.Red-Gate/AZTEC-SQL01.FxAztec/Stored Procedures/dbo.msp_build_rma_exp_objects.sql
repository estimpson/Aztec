SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_build_rma_exp_objects]
	( @shipper integer )
as
----------------------------------------------------------------------
--
--
--
--
--
--
--
----------------------------------------------------------------------
begin -- ( 1B)

	select	audit_trail.serial,   
		audit_trail.part,   
		audit_trail.quantity,   
		audit_trail.status,   
		audit_trail.engineering_level,   
		audit_trail.date_stamp,
		audit_trail.object_type,
		audit_trail.type
	from	audit_trail
			join shipper_detail on shipper_detail.shipper = @shipper and audit_trail.part = shipper_detail.part_original
	where	audit_trail.shipper = convert(varchar,shipper_detail.old_shipper)
		and audit_trail.serial not in ( select	serial 
						from	audit_trail 
						where	type = 'U' ) 
		and audit_trail.type = 'S' 

end -- ( 1E)
GO
