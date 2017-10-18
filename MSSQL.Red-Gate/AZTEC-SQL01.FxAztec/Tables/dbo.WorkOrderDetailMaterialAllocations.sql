CREATE TABLE [dbo].[WorkOrderDetailMaterialAllocations]
(
[WorkOrderNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[WorkOrderDetailLine] [float] NOT NULL CONSTRAINT [DF__WorkOrder__WorkO__33C07256] DEFAULT ((0)),
[WorkOrderDetailBillOfMaterialLine] [float] NOT NULL CONSTRAINT [DF__WorkOrder__WorkO__34B4968F] DEFAULT ((0)),
[AllocationDT] [datetime] NOT NULL CONSTRAINT [DF__WorkOrder__Alloc__35A8BAC8] DEFAULT (getdate()),
[AllocationEndDT] [datetime] NULL,
[Serial] [int] NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__WorkOrder__Statu__369CDF01] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__WorkOrderD__Type__3791033A] DEFAULT ((0)),
[QtyOriginal] [numeric] (20, 6) NOT NULL,
[QtyBegin] [numeric] (20, 6) NOT NULL,
[QtyIssued] [numeric] (20, 6) NULL,
[QtyEnd] [numeric] (20, 6) NULL,
[QtyEstimatedEnd] [numeric] (20, 6) NULL,
[QtyOverage] [numeric] (20, 6) NULL,
[QtyPer] [numeric] (20, 6) NULL,
[ChangeReason] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AllowablePercentOverage] [numeric] (10, 6) NULL CONSTRAINT [DF__WorkOrder__Allow__38852773] DEFAULT ((0)),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__WorkOrder__RowCr__39794BAC] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__WorkOrder__RowCr__3A6D6FE5] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__WorkOrder__RowMo__3B61941E] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__WorkOrder__RowMo__3C55B857] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create trigger [dbo].[trWorkOrderDetailMaterialAllocations_d] on [dbo].[WorkOrderDetailMaterialAllocations] instead of delete
as
/*	Don't allow deletes.  */
update
	dbo.WorkOrderDetailMaterialAllocations
set
	Status = dbo.udf_StatusValue('dbo.WorkOrderDetailMaterialAllocations', 'Deleted')
,	RowModifiedDT = getdate()
,	RowModifiedUser = suser_name()
from
	dbo.WorkOrderDetailMaterialAllocations wodma
	join deleted d on
		wodma.RowID = d.RowID
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[trWorkOrderDetailMaterialAllocations_u] on [dbo].[WorkOrderDetailMaterialAllocations] for update
as
/*	Record modification user and date.  */
if	not update(RowModifiedDT)
	and
		not update(RowModifiedUser) begin
	update
		dbo.WorkOrderDetailMaterialAllocations
	set
		RowModifiedDT = getdate()
	,	RowModifiedUser = suser_name()
	from
		dbo.WorkOrderDetailMaterialAllocations wodma
		join inserted i on
			wodma.RowID = i.RowID
end
GO
ALTER TABLE [dbo].[WorkOrderDetailMaterialAllocations] ADD CONSTRAINT [PK__WorkOrde__FFEE74512EFBBD39] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[WorkOrderDetailMaterialAllocations] ADD CONSTRAINT [UQ__WorkOrde__28DD15A031D829E4] UNIQUE NONCLUSTERED  ([WorkOrderNumber], [WorkOrderDetailLine], [WorkOrderDetailBillOfMaterialLine], [AllocationDT], [Serial]) ON [PRIMARY]
GO
