CREATE TABLE [dbo].[WorkOrderDetailBillOfMaterials]
(
[WorkOrderNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[WorkOrderDetailLine] [float] NOT NULL CONSTRAINT [DF__WorkOrder__WorkO__05257EFE] DEFAULT ((0)),
[Line] [float] NOT NULL CONSTRAINT [DF__WorkOrderD__Line__0619A337] DEFAULT ((0)),
[Status] [int] NOT NULL CONSTRAINT [DF__WorkOrder__Statu__070DC770] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__WorkOrderD__Type__0801EBA9] DEFAULT ((0)),
[ChildPart] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ChildPartSequence] [int] NOT NULL,
[ChildPartBOMLevel] [int] NOT NULL,
[BillOfMaterialID] [int] NULL,
[Suffix] [int] NULL,
[QtyPer] [numeric] (20, 6) NULL,
[XQty] [numeric] (20, 6) NOT NULL,
[XScrap] [numeric] (20, 6) NOT NULL CONSTRAINT [DF__WorkOrder__XScra__09EA341B] DEFAULT ((0)),
[SubForRowID] [int] NULL,
[SubPercentage] [numeric] (20, 6) NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__WorkOrder__RowCr__0BD27C8D] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__WorkOrder__RowCr__0CC6A0C6] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__WorkOrder__RowMo__0DBAC4FF] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__WorkOrder__RowMo__0EAEE938] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[trWorkOrderDetailBillOfMaterials_d] on [dbo].[WorkOrderDetailBillOfMaterials] instead of delete
as
/*	Don't allow deletes.  */
update
	dbo.WorkOrderDetailBillOfMaterials
set
	Status = dbo.udf_StatusValue('dbo.WorkOrderDetailBillOfMaterials', 'Deleted')
,	RowModifiedDT = getdate()
,	RowModifiedUser = suser_name()
from
	dbo.WorkOrderDetailBillOfMaterials wodbom
	join deleted d on
		wodbom.RowID = d.RowID
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[trWorkOrderDetailBillOfMaterials_u] on [dbo].[WorkOrderDetailBillOfMaterials] for update
as
/*	Record modification user and date.  */
if	not update(RowModifiedDT)
	and
		not update(RowModifiedUser) begin
	update
		dbo.WorkOrderDetailBillOfMaterials
	set
		RowModifiedDT = getdate()
	,	RowModifiedUser = suser_name()
	from
		dbo.WorkOrderDetailBillOfMaterials wodbom
		join inserted i on
			wodbom.RowID = i.RowID
end
GO
ALTER TABLE [dbo].[WorkOrderDetailBillOfMaterials] ADD CONSTRAINT [PK__WorkOrde__FFEE74510060C9E1] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[WorkOrderDetailBillOfMaterials] ADD CONSTRAINT [UQ__WorkOrde__96B35E23033D368C] UNIQUE NONCLUSTERED  ([WorkOrderNumber], [WorkOrderDetailLine], [Line]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[WorkOrderDetailBillOfMaterials] ADD CONSTRAINT [FK__WorkOrder__BillO__08F60FE2] FOREIGN KEY ([BillOfMaterialID]) REFERENCES [dbo].[bill_of_material_ec] ([ID])
GO
ALTER TABLE [dbo].[WorkOrderDetailBillOfMaterials] ADD CONSTRAINT [FK__WorkOrder__SubFo__0ADE5854] FOREIGN KEY ([SubForRowID]) REFERENCES [dbo].[WorkOrderDetailBillOfMaterials] ([RowID])
GO
ALTER TABLE [dbo].[WorkOrderDetailBillOfMaterials] ADD CONSTRAINT [FK__WorkOrderDetailB__22CFB488] FOREIGN KEY ([WorkOrderNumber], [WorkOrderDetailLine]) REFERENCES [dbo].[WorkOrderDetails] ([WorkOrderNumber], [Line])
GO
