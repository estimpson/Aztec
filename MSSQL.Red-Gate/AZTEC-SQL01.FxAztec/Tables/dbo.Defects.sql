CREATE TABLE [dbo].[Defects]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[TransactionDT] [datetime] NOT NULL,
[Machine] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DefectCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[QtyScrapped] [numeric] (20, 6) NULL,
[Operator] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Shift] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WODID] [int] NULL,
[DefectSerial] [int] NULL,
[Comments] [varchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AuditTrailID] [int] NULL,
[AreaToCharge] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Defects] ADD CONSTRAINT [PK__Defects__3214EC270A4A26CE] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_Defects_1] ON [dbo].[Defects] ([DefectSerial], [ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_Defects_2] ON [dbo].[Defects] ([TransactionDT], [DefectCode], [Part], [DefectSerial]) ON [PRIMARY]
GO
