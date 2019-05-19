SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [custom].[vw_receipt_history]
AS
Select 
From_loc, 
vendor.name vendorname, 
audit_trail.part, 
part.name partName,
SUM(quantity) Qty, 
CONVERT(CHAR(4), DATEPART(yyyy,audit_trail.date_stamp))+'/'+CONVERT(CHAR(1), DATEPART(qq,audit_trail.date_stamp)) AS RecvdDateQtr,
CONVERT(CHAR(4), DATEPART(yyyy,audit_trail.date_stamp)) +'/'+ CONVERT(CHAR(2), DATEPART(mm,audit_trail.date_stamp)) AS rcvdDateMonth,
CONVERT(CHAR(4), DATEPART(yyyy,audit_trail.date_stamp)) AS recvdDateYear,
part.type as partType

from Audit_trail WITH (NOLOCK)
 Join vendor WITH (NOLOCK) on vendor.code = audit_trail.from_loc and audit_trail.type = 'R'
 left Join part WITH (NOLOCK) on part.part = audit_trail.part
 Group by 
 From_loc, 
	vendor.name, 
	audit_trail.part,
	part.name, 
 CONVERT(CHAR(4), DATEPART(yyyy,audit_trail.date_stamp))+'/'+CONVERT(CHAR(1), DATEPART(qq,audit_trail.date_stamp)) ,
CONVERT(CHAR(4), DATEPART(yyyy,audit_trail.date_stamp)) +'/'+ CONVERT(CHAR(2), DATEPART(mm,audit_trail.date_stamp)),
CONVERT(CHAR(4), DATEPART(yyyy,audit_trail.date_stamp)) ,
part.type

	
GO
