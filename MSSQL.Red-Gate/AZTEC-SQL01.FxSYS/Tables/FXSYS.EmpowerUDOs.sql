CREATE TABLE [FXSYS].[EmpowerUDOs]
(
[ObjectName] [sys].[sysname] NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__EmpowerUD__Statu__117F9D94] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__EmpowerUDO__Type__1273C1CD] DEFAULT ((0)),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__EmpowerUD__RowCr__1367E606] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__EmpowerUD__RowCr__145C0A3F] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__EmpowerUD__RowMo__15502E78] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__EmpowerUD__RowMo__164452B1] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [FXSYS].[EmpowerUDOs] ADD CONSTRAINT [PK__EmpowerU__FFEE7451518C592E] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [FXSYS].[EmpowerUDOs] ADD CONSTRAINT [UQ__EmpowerU__5B8F1484CC394FF8] UNIQUE NONCLUSTERED  ([ObjectName]) ON [PRIMARY]
GO
