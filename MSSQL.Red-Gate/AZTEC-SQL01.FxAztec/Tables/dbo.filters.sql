CREATE TABLE [dbo].[filters]
(
[filtername] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence] [int] NOT NULL,
[module] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[filterdate] [datetime] NOT NULL,
[leftparenthesis] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[column_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[roperator] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[value] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[loperator] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[operator] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rightparenthesis] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[filters] ADD CONSTRAINT [PK_filters] PRIMARY KEY CLUSTERED  ([filtername], [sequence]) ON [PRIMARY]
GO
