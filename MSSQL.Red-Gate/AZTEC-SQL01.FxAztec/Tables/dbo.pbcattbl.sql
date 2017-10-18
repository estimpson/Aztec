CREATE TABLE [dbo].[pbcattbl]
(
[pbt_tnam] [varchar] (129) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pbt_tid] [int] NULL,
[pbt_ownr] [varchar] (129) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pbd_fhgt] [smallint] NULL,
[pbd_fwgt] [smallint] NULL,
[pbd_fitl] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pbd_funl] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pbd_fchr] [smallint] NULL,
[pbd_fptc] [smallint] NULL,
[pbd_ffce] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pbh_fhgt] [smallint] NULL,
[pbh_fwgt] [smallint] NULL,
[pbh_fitl] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pbh_funl] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pbh_fchr] [smallint] NULL,
[pbh_fptc] [smallint] NULL,
[pbh_ffce] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pbl_fhgt] [smallint] NULL,
[pbl_fwgt] [smallint] NULL,
[pbl_fitl] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pbl_funl] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pbl_fchr] [smallint] NULL,
[pbl_fptc] [smallint] NULL,
[pbl_ffce] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pbt_cmnt] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
