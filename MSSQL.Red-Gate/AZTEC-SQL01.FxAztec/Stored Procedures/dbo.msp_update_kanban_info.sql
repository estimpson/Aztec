SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_update_kanban_info] (@shipper integer) as
begin -- (1b)
   SELECT kanban.kanban_number,   
          kanban.status,   
          object.serial,
          pi.label_format 
     FROM kanban, object
          join part_inventory as pi on pi.part = object.part
    WHERE ( kanban.kanban_number  = isnull ( object.kanban_number, '0' )) and 
          ( object.shipper = @shipper )
end -- (1e)
GO
