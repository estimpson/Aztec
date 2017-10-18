CREATE TABLE [dbo].[XMLShipNotice_ASNDataRootFunction]
(
[ASNOverlayGroup] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__XMLShipNo__Statu__4A68A496] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__XMLShipNot__Type__4B5CC8CF] DEFAULT ((0)),
[FunctionName] [sys].[sysname] NOT NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__XMLShipNo__RowCr__4C50ED08] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__XMLShipNo__RowCr__4D451141] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__XMLShipNo__RowMo__4E39357A] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__XMLShipNo__RowMo__4F2D59B3] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[XMLShipNotice_ASNDataRootFunction] ADD CONSTRAINT [PK__XMLShipN__FFEE74518DDB37DB] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[XMLShipNotice_ASNDataRootFunction] ADD CONSTRAINT [UQ__XMLShipN__43FF458021119A3A] UNIQUE NONCLUSTERED  ([ASNOverlayGroup]) ON [PRIMARY]
GO
