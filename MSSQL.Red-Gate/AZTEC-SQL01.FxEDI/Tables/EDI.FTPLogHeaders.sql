CREATE TABLE [EDI].[FTPLogHeaders]
(
[Status] [int] NOT NULL CONSTRAINT [DF__FTPLogHea__Statu__6FE99F9F] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__FTPLogHead__Type__70DDC3D8] DEFAULT ((0)),
[Description] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__FTPLogHea__RowCr__71D1E811] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__FTPLogHea__RowCr__72C60C4A] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__FTPLogHea__RowMo__73BA3083] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__FTPLogHea__RowMo__74AE54BC] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[FTPLogHeaders] ADD CONSTRAINT [PK__FTPLogHe__FFEE745181D13AA5] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
