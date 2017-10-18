SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_fp_list_main] (@childpart varchar(25)) as
begin -- (1b)
  begin transaction -- (2b)
  delete 
    from partlist
  exec msp_fp_list_sub @childpart
  commit transaction -- (2e)
  set rowcount 0 	
  select part from partlist
end -- (1e)
GO
