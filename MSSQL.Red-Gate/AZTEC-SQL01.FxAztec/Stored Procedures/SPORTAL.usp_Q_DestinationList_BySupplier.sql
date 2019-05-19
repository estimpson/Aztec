SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [SPORTAL].[usp_Q_DestinationList_BySupplier]
	@SupplierCode varchar(10)
as
begin
	set nocount on

	begin try
		begin transaction
		select ' ' as Destination
		union all
		select distinct
			d.destination as Destination
		--,	xrt.TopPart
		--,	xrt.ChildPart
		from
			FT.XRt xrt
			join dbo.part_vendor pv
				on xrt.ChildPart = pv.part
				and pv.vendor = @SupplierCode
			join dbo.po_header ph
				on xrt.TopPart = ph.blanket_part
			join dbo.destination d on
				d.vendor = ph.vendor_code
		where xrt.ChildPart in
			(	select
					ph.blanket_part
				from
					dbo.po_header ph
				where
					ph.vendor_code = @SupplierCode
			)
			and xrt.BOMLevel = 1
		order by
			Destination

		commit transaction
	end try
	begin catch

		if @@trancount > 0 rollback transaction;
		throw;

	end catch
end
GO
