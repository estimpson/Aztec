CREATE TABLE [dbo].[issue_detail]
(
[issue_number] [int] NOT NULL,
[status_old] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_new] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_stamp] [datetime] NOT NULL,
[notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[origin] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_issue_detail_i] on [dbo].[issue_detail] for insert
as
begin
	declare	@date_stamp datetime,
			@status_type varchar(1),
			@status varchar(25),
			@issue_number integer,
			@today datetime,
			@notes_from varbinary(16),
			@notes_to varbinary(16)

	select	@today = GetDate()

	select 	@issue_number = min(issue_number)
	from 	inserted

	while(isnull(@issue_number,-1)<>-1)
	begin

		select	@date_stamp = min(date_stamp)
		from	inserted
		where	issue_number = @issue_number

		while(isnull(@date_stamp,@today)<>@today)
		begin

			select	@status = status_new
			from	inserted
			where	issue_number = @issue_number and
					date_stamp = @date_stamp

			select	@status_type = type
			from 	issues_status
			where 	status = @status

			if @status_type='C'
			begin

				select	@notes_from = TEXTPTR(notes) 
				from	issue_detail
				where	issue_number = @issue_number and
						date_stamp = @date_stamp
	
				READTEXT issue_detail.notes @notes_from 0 0
	
				update 	issues
				set		solution = ' '
				where	issue_number = @issue_number and
						solution is null

				select	@notes_to = TEXTPTR(solution)
				from	issues
				where	issue_number = @issue_number
	
				UPDATETEXT issues.solution @notes_to 0 NULL issue_detail.notes @notes_from

			end

			select	@date_stamp = min(date_stamp)
			from	inserted
			where	issue_number = @issue_number and
					date_stamp > @date_stamp

		end

		select 	@issue_number = min(issue_number)
		from 	inserted
		where	issue_number > @issue_number

	end

end
GO
ALTER TABLE [dbo].[issue_detail] ADD CONSTRAINT [PK__issue_detail__2CBDA3B5] PRIMARY KEY CLUSTERED  ([issue_number], [date_stamp]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[issue_detail] ADD CONSTRAINT [FK__issue_det__issue__2DB1C7EE] FOREIGN KEY ([issue_number]) REFERENCES [dbo].[issues] ([issue_number])
GO
