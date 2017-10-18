CREATE TABLE [dbo].[Calendars]
(
[CalendarName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Status] [int] NOT NULL,
[Type] [int] NOT NULL,
[CalendarDescription] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreatedDT] [datetime] NOT NULL CONSTRAINT [DF__Calendars__RowCr__7128A7F2] DEFAULT (getdate()),
[RowCreatedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Calendars__RowCr__721CCC2B] DEFAULT (suser_sname())
) ON [PRIMARY]
GO
