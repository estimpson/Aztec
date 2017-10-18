CREATE TABLE [dbo].[MES_GroupTechnologyBackflushingPrinciples]
(
[GroupTechnology] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__MES_Group__Statu__12FF6860] DEFAULT ((0)),
[BackflushingPrinciple] [int] NOT NULL CONSTRAINT [DF__MES_Group__Backf__13F38C99] DEFAULT ((0)),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__MES_Group__RowCr__14E7B0D2] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__MES_Group__RowCr__15DBD50B] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__MES_Group__RowMo__16CFF944] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__MES_Group__RowMo__17C41D7D] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MES_GroupTechnologyBackflushingPrinciples] ADD CONSTRAINT [PK__MES_Grou__FFEE74510D468F0A] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MES_GroupTechnologyBackflushingPrinciples] ADD CONSTRAINT [UQ__MES_Grou__A9A9A0521022FBB5] UNIQUE NONCLUSTERED  ([GroupTechnology]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MES_GroupTechnologyBackflushingPrinciples] ADD CONSTRAINT [FK__MES_Group__Group__120B4427] FOREIGN KEY ([GroupTechnology]) REFERENCES [dbo].[group_technology] ([id])
GO
