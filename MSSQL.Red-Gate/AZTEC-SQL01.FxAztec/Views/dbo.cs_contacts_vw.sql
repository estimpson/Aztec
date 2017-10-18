SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cs_contacts_vw]
as 
	select	contact.name,
		contact.phone,
		contact.fax_number,
		contact.email1,
		contact.email2,
		contact.title,
		contact.notes,
		contact.customer,
		contact.destination
	from	contact
GO
