SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure
[dbo].[msp_chrys_asn_end](@shipper integer) as
begin
  declare @status char(1),
  @destination varchar(20)
  select @status=status,
    @destination=destination
    from shipper
    where id=@shipper
  /* Update Cums if not previously sent to EDI*/
  if @status<>'Z'
    begin
      /* temp table for updating package cums*/
      create table #work_pack_cum(
        package_type varchar(20) null,
        quantity integer null,
        )
    end
  begin transaction
  select distinct 'RC',
    a.package_type,
   count(a.serial),
    0,'NONE',
    shipper.id,
    shipper.bill_of_lading_number,
    shipper.destination,
    edi_setups.parent_destination,
    type_sort=2
    from audit_trail as a
    ,shipper
    ,package_materials
    ,edi_setups
    where a.type='S'
    and a.shipper=convert(varchar(35),@shipper)
    and shipper.id=@shipper
    and coalesce(package_materials.returnable,'N') in ('Y','N' )
    and a.package_type=package_materials.code
    and edi_setups.destination=shipper.destination
    and a.part<>'PALLET'
    group by a.package_type,shipper.id,shipper.bill_of_lading_number,
    shipper.destination,edi_setups.parent_destination
  commit transaction
end
GO
