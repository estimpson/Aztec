CREATE TABLE [EDI].[TradingPartners]
(
[TradingPartnerCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[EDIMapCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[TradingPartners] ADD CONSTRAINT [PK__TradingP__077E86293CDDBD05] PRIMARY KEY CLUSTERED  ([TradingPartnerCode]) ON [PRIMARY]
GO
