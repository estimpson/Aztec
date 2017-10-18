SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure
[dbo].[msp_chrys_asn_detail](@shipper integer) as
begin
---exec msp_chrys_asn_end 63365
  begin transaction
  select 'BP',
    shipper_detail.customer_part,
    qty_packed,
    accum_shipped,
    order_header.engineering_level,
    order_header.dock_code,
    shipper.destination,
    shipper.bill_of_lading_number,
    /* both package types */
    (case when exists(select 1
      from audit_trail join
      package_materials on audit_trail.package_type=package_materials.code
      and package_materials.returnable='Y'
      where audit_trail.shipper=convert(varchar(20),@shipper)
      and audit_trail.part=shipper_detail.part_original)
    and exists(select 1
      from audit_trail join
      package_materials on audit_trail.package_type=package_materials.code
      and package_materials.returnable='N'
      where audit_trail.shipper=convert(varchar(20),@shipper)
      and audit_trail.part=shipper_detail.part_original) then '0000EXPM'
    /* only expendable */
    when exists(select 1
      from audit_trail join
      package_materials on audit_trail.package_type=package_materials.code
      and package_materials.returnable='N'
      where audit_trail.shipper=convert(varchar(20),@shipper)
      and audit_trail.part=shipper_detail.part_original) then '00000EXP'
    /* only returnable */
    when exists(select 1
      from audit_trail join
      package_materials on audit_trail.package_type=package_materials.code
      and package_materials.returnable='Y'
      where audit_trail.shipper=convert(varchar(20),@shipper)
      and audit_trail.part=shipper_detail.part_original) then (select max(package_type) from audit_trail join      package_materials on audit_trail.package_type=package_materials.code        where audit_trail.shipper=convert(varchar(20),@shipper)        and audit_trail.part=shipper_detail.part_original)+''   else '00000EXP' end),((select SUM(audit_trail.std_quantity) from audit_trail join
      package_materials on audit_trail.package_type=package_materials.code
      and package_materials.returnable='N'
      where audit_trail.shipper=convert(varchar(20),@shipper)
      and audit_trail.part=shipper_detail.part_original)
    *case when order_header.notes='1' then
      convert(decimal(20,6),order_header.notes)
    else null
    end),
    shipper_detail.customer_po,
    shipper_detail.shipper,
    edi_setups.parent_destination
    from shipper_detail join
    shipper on shipper_detail.shipper=shipper.id join
    order_header on shipper_detail.order_no=order_header.order_no join
    edi_setups on edi_setups.destination=shipper.destination
    where shipper_detail.shipper=@shipper
  commit transaction
end
GO
