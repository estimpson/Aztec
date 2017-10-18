SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create procedure

[EDI].[sp_Ford830Exceptions]
as
Begin
SET TRANSACTION ISOLATION LEVEL
read uncommitted
SELECT [ShipToCode]
      ,[CustomerPart]
      ,[CustomerPO]
      ,[ShipFromCode]
      ,[ICCode]
      ,[ReleaseNo]
      ,[ReleaseQty]
      ,[ReleaseDT]
      ,RowCreateDT as ProcessedDT
  FROM [fxAztec].[EDI].[Ford_830_Releases]
Where	RowCreateDT >= DATEADD(dd, -30, getdate()) and
		ShipFromCode like 'K856%' and  not exists (select 1 from order_header where left(destination,5) = ShipToCode and customer_part = CustomerPart)
End
GO
