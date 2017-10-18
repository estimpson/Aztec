SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_checkshipper] (@shipper integer, @returnvalue integer OUTPUT) as
begin -- (1b)
  declare @bol_number  integer,
          @customerstatus char(1),
          @shipperstatus  char(1),
          @packlistprinted char(1),
          @bolprinted char(1)
  SELECT @returnvalue=0 -- successful status
  -- check for customer status, shipper status, packlist printed
  SELECT @customerstatus=status_type, 
         @shipperstatus=status, 
         @packlistprinted=printed, 
         @bol_number=bill_of_lading_number
    FROM customer_service_status as a, shipper as b
   WHERE (a.status_name = b.cs_status and b.id = @shipper)
  if (@@rowcount > 0)
   if (@customerstatus='A')  -- Check customer status type
    begin -- (3b)
      if (@shipperstatus='S') -- check shipper status 
       begin -- (3.1b) 
         if (@packlistprinted='Y') -- check pack list printed
          begin -- (3.2b) 
            if (@bol_number > 0) -- check the bol number
             begin -- (3.3b)
               SELECT @bolprinted=bill_of_lading.printed  
                 FROM bill_of_lading  
                WHERE (bill_of_lading.bol_number = @bol_number)
               if (@bolprinted<>'Y')   -- check bol printed 
                  SELECT @returnvalue=-5 -- bol not printed
             end -- (3.3e) 
          end -- (3.2e)
         else
           SELECT @returnvalue=-4  -- pack list not printed
       end -- (3.1e) 
      else
       begin -- (3.1.1b)
         if (@shipperstatus in ('C','Z')) -- check whether the shipper is closed
            SELECT @returnvalue=-2 -- shipper is closed by another user
         else 
            SELECT @returnvalue=-3 -- shipper not staged
       end -- (3.1.1e)       
    end -- (3e)
   else
     SELECT @returnvalue = -1 -- customer status is not approved	
  else
    SELECT @returnvalue = 100 -- shipper not found
  select @returnvalue -- return value 
end -- (1e)
GO
