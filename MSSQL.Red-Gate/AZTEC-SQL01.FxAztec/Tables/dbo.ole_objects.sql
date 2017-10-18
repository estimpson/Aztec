CREATE TABLE [dbo].[ole_objects]
(
[id] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ole_object] [image] NULL,
[parent_id] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_stamp] [datetime] NULL,
[serial] [int] NOT NULL,
[parent_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[mtr_ole_objects_i] on [dbo].[ole_objects] for insert
as
begin
	-- declare local variables
	declare @serial integer
	
	-- if trying to update more than 1 row exit
	if @@rowcount > 1
		raiserror ('Multi-row insert on table ole_objects not allowed!', 16, 1)
		
	-- get inserted serial
	select	@serial = serial 
	from 	inserted
	
	if @serial = 0
	begin
		update 	ole_objects
		set	serial = isnull ( (	select	max(serial)
						from	ole_objects ), 0 ) + 1
		where	serial = 0
	end
end

GO
ALTER TABLE [dbo].[ole_objects] ADD CONSTRAINT [PK__ole_obje__6178722802C769E9] PRIMARY KEY CLUSTERED  ([serial]) ON [PRIMARY]
GO
