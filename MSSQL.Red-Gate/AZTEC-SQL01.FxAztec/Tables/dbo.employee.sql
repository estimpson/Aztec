CREATE TABLE [dbo].[employee]
(
[name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[operator_code] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[password] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[serial_number] [int] NULL,
[epassword] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[operatorlevel] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[tr_employee] on [dbo].[employee] after insert, update, delete
as
set nocount on

delete
	u
from
	FT.Users u
	left join dbo.employee e
		on e.operator_code = u.OperatorCode
where
	e.operator_code is null

insert
	FT.Users
(	OperatorCode
)
select
	OperatorCode = e.operator_code
from
	dbo.employee e
	left join FT.Users u
		on u.OperatorCode = e.operator_code
where
	u.OperatorCode is null
GO
ALTER TABLE [dbo].[employee] ADD CONSTRAINT [PK__employee__2FB4F8432180FB33] PRIMARY KEY CLUSTERED  ([operator_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_employee_operator_code] ON [dbo].[employee] ([operator_code]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[employee] ADD CONSTRAINT [UQ__employee__6E2DBEDE245D67DE] UNIQUE NONCLUSTERED  ([password]) ON [PRIMARY]
GO
