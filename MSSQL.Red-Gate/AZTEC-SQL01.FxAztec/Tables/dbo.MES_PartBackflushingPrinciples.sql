CREATE TABLE [dbo].[MES_PartBackflushingPrinciples]
(
[Part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__MES_PartB__Statu__05A56D42] DEFAULT ((0)),
[BackflushingPrinciple] [int] NOT NULL CONSTRAINT [DF__MES_PartB__Backf__0699917B] DEFAULT ((0)),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__MES_PartB__RowCr__078DB5B4] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__MES_PartB__RowCr__0881D9ED] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__MES_PartB__RowMo__0975FE26] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__MES_PartB__RowMo__0A6A225F] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MES_PartBackflushingPrinciples] ADD CONSTRAINT [PK__MES_Part__FFEE74517FEC93EC] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MES_PartBackflushingPrinciples] ADD CONSTRAINT [UQ__MES_Part__A15FB69502C90097] UNIQUE NONCLUSTERED  ([Part]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MES_PartBackflushingPrinciples] ADD CONSTRAINT [FK__MES_PartBa__Part__04B14909] FOREIGN KEY ([Part]) REFERENCES [dbo].[part] ([part])
GO
