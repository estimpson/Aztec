CREATE TABLE [FT].[NumberSequence]
(
[NumberSequenceID] [int] NOT NULL IDENTITY(1, 1),
[Name] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HelpText] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NumberMask] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NextValue] [bigint] NOT NULL CONSTRAINT [DF__NumberSeq__NextV__60C757A0] DEFAULT ((1)),
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__NumberSeq__LastU__61BB7BD9] DEFAULT (suser_sname()),
[LastDT] [datetime] NULL CONSTRAINT [DF__NumberSeq__LastD__62AFA012] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [FT].[NumberSequence] ADD CONSTRAINT [PK__NumberSe__CF5634B15C02A283] PRIMARY KEY CLUSTERED  ([NumberSequenceID]) ON [PRIMARY]
GO
ALTER TABLE [FT].[NumberSequence] ADD CONSTRAINT [UQ__NumberSe__737584F65EDF0F2E] UNIQUE NONCLUSTERED  ([Name]) ON [PRIMARY]
GO
