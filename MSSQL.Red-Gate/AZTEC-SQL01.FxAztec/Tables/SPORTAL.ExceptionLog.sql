CREATE TABLE [SPORTAL].[ExceptionLog]
(
[Exception] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__Exception__Statu__0221BABA] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__ExceptionL__Type__0315DEF3] DEFAULT ((0)),
[ProcedureName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime2] NOT NULL CONSTRAINT [DF__Exception__RowCr__040A032C] DEFAULT (sysdatetime()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Exception__RowCr__04FE2765] DEFAULT (suser_name()),
[RowModifiedDT] [datetime2] NOT NULL CONSTRAINT [DF__Exception__RowMo__05F24B9E] DEFAULT (sysdatetime()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Exception__RowMo__06E66FD7] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [SPORTAL].[ExceptionLog] ADD CONSTRAINT [PK__Exceptio__FFEE74510DE8A6A0] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
