SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[cdisp_jobcomplnrepo] (@stdate datetime, @eddate datetime)
as
begin
	declare	@sstdate varchar(20),
		@seddate varchar(20)
		
	select	@sstdate = convert(varchar(10), @stdate, 101) + ' 00:00:00',
		@seddate = convert(varchar(10), @eddate, 101) + ' 23:59:59'
		
	select	@stdate = convert(datetime, @sstdate),
		@eddate = convert(datetime, @seddate)
		
	select	audit_trail.std_quantity,
		audit_trail.part,
		part.cross_ref,
		parameters.company_name,
		part.product_line,
		parameters.company_logo  
	from	audit_trail
		join part on part.part = audit_trail.part
		cross join parameters  
	where	( audit_trail.date_stamp >= @stdate ) AND  
		( audit_trail.date_stamp <= @eddate) AND  
		( audit_trail.type = 'J' ) AND  
		( part.type = 'F' ) 
end
GO
