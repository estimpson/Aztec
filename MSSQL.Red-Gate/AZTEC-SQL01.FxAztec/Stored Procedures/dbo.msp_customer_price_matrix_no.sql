SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_customer_price_matrix_no] (  @part varchar (25), @customer varchar (25), @display_currency varchar (10) )
as
begin
select  part_customer_price_matrix.part, 
        part_customer_price_matrix.customer, 
        part_customer_price_matrix.qty_break, 
        (       part_customer_price_matrix.alternate_price * isnull(( 
                select  rate 
                from            currency_conversion  
                where   effective_date = (      select  max (effective_date) 
                                                from    currency_conversion cc 
                                                where   effective_date < GetDate ( ) and 
                                        currency_code = customer.default_currency_unit ) and 
                                        currency_code = customer.default_currency_unit ),1) / isnull(( 
                select  rate 
                from            currency_conversion  
                where   effective_date = (      select  max (effective_date) 
                                                from    currency_conversion cc 
                                                where   effective_date < GetDate ( ) and 
                                                        currency_code = @display_currency ) and 
                                                        currency_code = @display_currency ),1)) as price,
        part_inventory.standard_unit,
        customer.default_currency_unit  
        from    part_customer_price_matrix, 
                part_inventory,
                customer 
        where   part_customer_price_matrix.customer = @customer and 
                part_customer_price_matrix.part = @part and 
                part_customer_price_matrix.part = part_inventory.part and
                customer.customer = @customer
end
GO
