SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_update_shipper_cost] 
(@serial integer, 
 @shipper integer,
 @customer varchar(10),
 @vendor   varchar(10),
 @destination varchar(10),
 @shippertype char(1),
 @operator varchar(5),
 @returnvalue integer OUTPUT) as
begin -- (1b)
  declare @part        varchar(25),
          @suffix      integer,
          @std_qty     numeric(20,6),
          @price       numeric(20,6),
          @salesman    varchar(10),
          @note        varchar(254),
          @group_no    varchar(10),
          @order_no    integer,
          @release_no  varchar(30),
          @accountcode varchar(50),
          @cost        numeric(20,6),
          @total_cost  numeric(20,6),
          @onhand      numeric(20,6),
          @remarks     varchar(40)
  SELECT @returnvalue = 0 -- success status
  SET rowcount 0 
  -- get the details about that object
  SELECT @part=o.part,
         @suffix=o.suffix,
         @std_qty=o.std_quantity,
         @cost=o.cost,
         @onhand=p.on_hand
    FROM object as o join part_online as p on p.part = o.part
   WHERE (serial=@serial)
  if (@@rowcount > 0 )
   begin -- (2b)
     -- get price for that part
     SET rowcount 0 
     if (@suffix is not null and @suffix <> 0)
        SELECT @price =price, 
               @salesman=salesman,
               @note =note, 
               @group_no =group_no,
               @order_no=order_no, 
               @release_no =release_no, 
               @accountcode=account_code 
          FROM shipper_detail 
         WHERE (shipper = @shipper and part_original = @part and suffix = @suffix)
     else
         SELECT @price =price, 
                @salesman=salesman,
                @note =note, 
                @group_no =group_no,
                @order_no=order_no, 
                @release_no =release_no, 
                @accountcode=account_code 
           FROM shipper_detail 
          WHERE (shipper = @shipper and part_original = @part)
     if @@rowcount > 0 
      begin -- (3b)
        --  compute the total cost
        SELECT @total_cost = isnull(@std_qty,1.0) * isnull(@cost,1.0)
        set rowcount 0         
        -- update shipper detail 
        if (@suffix is not null and @suffix <> 0)
          UPDATE shipper_detail 
             SET total_cost = @total_cost 
           WHERE (shipper = @shipper and part_original = @part and suffix = @suffix)
        else
          UPDATE shipper_detail 
             SET total_cost = @total_cost 
           WHERE (shipper = @shipper and part_original = @part)
        if @@rowcount > 0 
         begin -- (4b)
           if (@shippertype='S' or @shippertype='Q')
              SELECT @remarks = 'Shipping'
           else if (@shippertype = 'O')
             SELECT @remarks = 'Out Proc' 
           else if (@shippertype = 'V')
             SELECT @remarks = 'Ret Vendor'
           else 
             SELECT @remarks = ''
           set rowcount 0   
           -- create audit_trail info
           INSERT INTO audit_trail  
                 ( serial, date_stamp, type, part, quantity, remarks, price, salesman, customer,   
                   vendor, po_number,  operator, from_loc, to_loc, on_hand, lot, weight, status,   
                   shipper, flag, activity, unit, workorder, std_quantity, cost, control_number,   
                   custom1, custom2, custom3, custom4, custom5, plant, invoice_number,    notes,   
                   gl_account, package_type, suffix, due_date, group_no, sales_order,release_no,   
                   dropship_shipper, std_cost, user_defined_status, engineering_level,   posted,   
                   parent_serial, origin, destination, sequence, object_type, part_name, start_date,
                   field1, field2, show_on_shipper, tare_weight, kanban_number, dimension_qty_string,
                   dim_qty_string_other, varying_dimension_code)  
           SELECT  serial, getdate(), @shippertype, part, quantity, @remarks, @price, @salesman, @customer,
                   @vendor, po_number, @operator, location, @destination, @onhand, lot, weight, status, 
                   convert(varchar,@shipper), null, null, unit_measure, workorder, std_quantity, cost, null,
                   custom1, custom2, custom3, custom4, custom4, plant, null, @note, 
                   @accountcode, package_type, suffix, date_due, @group_no, convert(varchar,@order_no), @release_no, 
                   null, std_cost, user_defined_status, engineering_level, null, 
                   parent_serial, null, @destination, sequence, null, name, start_date,
                   field1, field2, show_on_shipper, tare_weight, kanban_number, dimension_qty_string,
                   dim_qty_string_other, varying_dimension_code
              FROM object
             WHERE (serial=@serial)   
           if (@@rowcount = 0) 
             SELECT @returnvalue= -1
           -- check shipper type
           if (@shippertype = 'O') 
             -- update object info
             UPDATE object SET location=@destination, destination=@destination, status='P'
              WHERE (serial=@serial)
           else
             -- delete row from object table
             DELETE FROM object WHERE (serial=@serial)
         end -- (4e) 
        else
         SELECT @returnvalue= -1 
      end -- (3e)
     else
      SELECT @returnvalue= -1     
   end  -- (2e)
  else
   SELECT @returnvalue= -1 
end -- (1e)
GO
