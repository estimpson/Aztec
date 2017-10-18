CREATE TABLE [dbo].[part]
(
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cross_ref] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[class] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[commodity] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_technology] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quality_alert] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description_short] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description_long] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[serial_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[product_line] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[configuration] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[standard_cost] [numeric] (20, 6) NULL,
[user_defined_1] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_defined_2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[flag] [int] NULL,
[engineering_level] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[drawing_number] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gl_account_code] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eng_effective_date] [datetime] NULL,
[low_level_code] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[mtr_part_d] ON [dbo].[part]
FOR DELETE
AS
BEGIN
   DELETE part_standard WHERE part IN (SELECT part FROM deleted)
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[mtr_part_i] ON [dbo].[part]
FOR INSERT
AS
BEGIN
   INSERT INTO part_standard (part) (SELECT part FROM inserted)
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[mtr_part_u] ON [dbo].[part]
FOR UPDATE
AS
BEGIN
   Declare @dpart varchar(25),
           @ipart varchar(25)
   SELECT @dpart=part 
     FROM deleted  
   SELECT @ipart=part 
     FROM inserted
   IF (@dpart <> @ipart) 
   BEGIN
     DELETE part_standard WHERE part IN (SELECT part FROM deleted)
     INSERT INTO part_standard (part) (SELECT part FROM inserted)
   END 
END
GO
ALTER TABLE [dbo].[part] ADD CONSTRAINT [PK__part__54CB950F] PRIMARY KEY CLUSTERED  ([part]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [class_index] ON [dbo].[part] ([class]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_part_Type_GroupTechnology_Part] ON [dbo].[part] ([type], [group_technology], [part]) ON [PRIMARY]
GO
