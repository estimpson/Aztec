SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_find_internal_part] (
	@customerpart varchar(35),
	@customer varchar(10),
	@internalpart varchar(25) output )
as
-------------------------------------------------------------------------------------
--	This procedure finds an internal part number from customer part and customer.
--
--	Modifications:	02 JAN 1999, Eric E. Stimpson	Original
--			24 MAY 1999, Eric E. Stimpson	Modified formatting.
--			29 JUN 1999, Eric E. Stimpson	Changed null to empty for error returns.
--
--	Paramters:	@customerpart	mandatory
--			@customer	mandatory
--			@internalpart	output
--
--	Returns:	  0	success
--			 -1	error occurred (more than one internal part found)
--			100	internal part not found
--
--	Process:
--	1. Declarations.
--	2. Initialize all variables.
--	3. Get the number of internal parts.
--	4. If part count is equal to 0, set internal part to empty and return internal part not found.
--	5. If part count is greater than 1, set internal part to empty and return error occurred.
--	6. Part count is equal to 1, set internal part to the part found and return success.
-------------------------------------------------------------------------------------

--	1. Declarations.
declare	@partcount	integer

--	2. Initialize all variables.
select	@partcount = 0

--	3. Get the number of internal parts.
select	@partcount = IsNull ( (
		select	Count ( 1 )
		  from	part_customer
		 where	customer_part = @customerpart and
		 	customer = @customer ), 0 )

--	4. If part count is equal to 0, set internal part to null and return internal part not found.
if @partcount = 0
begin -- (1aB)
	select	@internalpart = ''
	Return 100
end -- (1aB)

--	5. If part count is greater than 1, set internal part to null and return error occurred.
if @partcount > 1
begin -- (1bB)
	select @internalpart = ''
	Return -1
end -- (1bB)

--	6. Part count is equal to 1, set internal part to the part found and return success.
select	@internalpart = part
  from	part_customer
 where	customer_part = @customerpart and
 	customer = @customer
return 0
GO
