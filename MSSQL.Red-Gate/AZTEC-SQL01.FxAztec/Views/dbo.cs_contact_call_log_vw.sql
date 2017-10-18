SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cs_contact_call_log_vw]
as 
	select	contact_call_log.contact,
		contact_call_log.start_date,
		contact_call_log.stop_date,
		contact_call_log.call_subject,
		contact_call_log.call_content,
		contact.customer as customer,
		contact.destination as destination
	from	contact_call_log,contact
	where	contact_call_log.contact = contact.name
GO
