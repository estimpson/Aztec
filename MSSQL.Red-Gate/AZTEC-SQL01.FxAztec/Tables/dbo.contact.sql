CREATE TABLE [dbo].[contact]
(
[name] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[title] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company_id] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fax_number] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[destination] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_contact_d] on [dbo].[contact] for delete
as
begin
	declare	@contact varchar(35)
	declare deleted_contacts cursor for
		select	name
		from	deleted
		
	open deleted_contacts
	fetch deleted_contacts into @contact
	while ( @@fetch_status = 0 )
	begin
		delete from contact_call_log where contact = @contact
		fetch deleted_contacts into @contact
	end
	close deleted_contacts
	deallocate deleted_contacts
end
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_contact_u] on [dbo].[contact] for update
as
begin
	declare	@inserted_contact varchar(35),
		@deleted_contact varchar(35)
		
	declare inserted_contacts cursor for
		select	name
		from	inserted
	declare deleted_contacts cursor for
		select	name
		from	deleted
		
	open inserted_contacts
	open deleted_contacts
	fetch inserted_contacts into @inserted_contact
	fetch deleted_contacts into @deleted_contact
	while ( @@fetch_status = 0 )
	begin
		if @inserted_contact <> @deleted_contact
			update 	contact_call_log
			set	contact = @inserted_contact
			where	contact = @deleted_contact
			
		fetch inserted_contacts into @inserted_contact
		fetch deleted_contacts into @deleted_contact
	end
	close inserted_contacts
	deallocate inserted_contacts
	close deleted_contacts
	deallocate deleted_contacts
end
GO
ALTER TABLE [dbo].[contact] ADD CONSTRAINT [PK__contact__00D4FFD6] PRIMARY KEY CLUSTERED  ([name]) ON [PRIMARY]
GO
