CREATE TABLE [dbo].[edi_setups_bak]
(
[destination] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[supplier_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trading_partner_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[release_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[auto_create_asn] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[asn_overlay_group] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[equipment_description] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pool_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pool_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[material_issuer] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[id_code_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[check_model_year] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[check_po] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prev_cum_in_asn] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[parent_destination] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EDIShipToID] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProcessEDI] [bit] NULL,
[TransitDays] [int] NULL,
[EDIOffsetDays] [int] NULL,
[PlanningReleasesFlag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__edi_setup__Plann__40E6F9F8] DEFAULT ('A'),
[ReferenceAccum] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AdjustmentAccum] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CheckCustomerPOFirm] [int] NULL,
[PlanningReleaseHorizonDaysBack] [int] NULL,
[ShipScheduleHorizonDaysBack] [int] NULL,
[ProcessShipSchedule] [int] NULL,
[ProcessPlanningRelease] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[edi_setups_bak] ADD CONSTRAINT [PK__edi_setups_new__1C323631] PRIMARY KEY CLUSTERED  ([destination]) ON [PRIMARY]
GO
