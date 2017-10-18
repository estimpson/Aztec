CREATE TABLE [dbo].[MES_StagingLocations]
(
[StagingLocationCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MachineCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PartCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__MES_Stagi__Statu__37BBEBC3] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__MES_Stagin__Type__38B00FFC] DEFAULT ((0)),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__MES_Stagi__RowCr__39A43435] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__MES_Stagi__RowCr__3A98586E] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__MES_Stagi__RowMo__3B8C7CA7] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__MES_Stagi__RowMo__3C80A0E0] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MES_StagingLocations] ADD CONSTRAINT [PK__MES_StagingLocat__32F736A6] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MES_StagingLocations] ADD CONSTRAINT [UQ__MES_StagingLocat__33EB5ADF] UNIQUE NONCLUSTERED  ([StagingLocationCode], [MachineCode], [PartCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MES_StagingLocations] ADD CONSTRAINT [FK__MES_Stagi__Machi__35D3A351] FOREIGN KEY ([MachineCode]) REFERENCES [dbo].[machine] ([machine_no])
GO
ALTER TABLE [dbo].[MES_StagingLocations] ADD CONSTRAINT [FK__MES_Stagi__PartC__36C7C78A] FOREIGN KEY ([PartCode]) REFERENCES [dbo].[part] ([part])
GO
ALTER TABLE [dbo].[MES_StagingLocations] ADD CONSTRAINT [FK__MES_Stagi__Stagi__34DF7F18] FOREIGN KEY ([StagingLocationCode]) REFERENCES [dbo].[location] ([code])
GO
