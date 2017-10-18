SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[Notification_POEmailProfileDetails]
AS
SELECT
	PONumber = ph.po_number
,	VendorCode = ph.vendor_code
,	EmailTo = COALESCE(nepPO.EmailTo, nepVendor.EmailTo)
,	PODefinedEmailTo = CASE WHEN nepPO.EmailTo IS NOT NULL THEN 1 ELSE 0 END
,	VendorDefinedEmailTo = CASE WHEN nepVendor.EmailTo IS NOT NULL OR nepPO.Emailto IS NOT NULL THEN 1 ELSE 0 END
,	EmailCC = COALESCE(nepPO.EmailCC, nepVendor.EmailCC)
,	PODefinedEmailCC = CASE WHEN nepPO.EmailCC IS NOT NULL THEN 1 ELSE 0 END
,	VendorDefinedEmailCC = CASE WHEN nepVendor.EmailCC IS NOT NULL OR nepPO.EmailCC IS NOT NULL THEN 1 ELSE 0 END
,	EmailReplyTo = COALESCE(nepPO.EmailReplyTo, nepVendor.EmailReplyTo)
,	PODefinedEmailReplyTo = CASE WHEN nepPO.EmailReplyTo IS NOT NULL THEN 1 ELSE 0 END
,	VendorDefinedEmailReplyTo = CASE WHEN nepVendor.EmailReplyTo IS NOT NULL OR nepPO.EmailReplyTo IS NOT NULL THEN 1 ELSE 0 END
,	EmailSubject = COALESCE(nepPO.EmailSubject, nepVendor.EmailSubject)
,	PODefinedEmailSubject = CASE WHEN nepPO.EmailSubject IS NOT NULL THEN 1 ELSE 0 END
,	VendorDefinedEmailSubject = CASE WHEN nepVendor.EmailSubject IS NOT NULL OR nepPO.EmailSubject IS NOT NULL THEN 1 ELSE 0 END
,	EmailBody = COALESCE(nepPO.EmailBody, nepVendor.EmailBody)
,	PODefinedEmailBody = CASE WHEN nepPO.EmailBody IS NOT NULL THEN 1 ELSE 0 END
,	VendorDefinedEmailBody = CASE WHEN nepVendor.EmailBody IS NOT NULL OR nepPO.EmailBody IS NOT NULL THEN 1 ELSE 0 END
,	EmailAttachmentNames = '\\Aztec-SQL01\PO_PDF_Attachments\' +UPPER(ph.vendor_code) + '_'+COALESCE(NULLIF(ph.blanket_part, ''), 'NormalPO') +'_'+ CONVERT(NVARCHAR, ph.po_number) + '_' + CONVERT(VARCHAR(16), GETDATE(), 112)+ '.pdf'
,	PODefinedEmailAttachmentNames = 1
,	VendorDefinedEmailAttachmentNames = 1
,	EmailFrom = 'scanner@aztecmfgcorp.com'
,	PODefinedEmailFrom = 1
,	VendorDefinedEmailFrom = 1
FROM
	dbo.po_header ph
	LEFT JOIN dbo.Notification_POEmailProfile npep
		JOIN dbo.Notification_EmailProfiles nepPO
			ON nepPO.RowID = npep.ProfileID
		ON npep.PONumber = ph.po_number
	LEFT JOIN dbo.Notification_VendorEmailProfile nvep
		JOIN dbo.Notification_EmailProfiles nepVendor
			ON nepVendor.RowID = nvep.ProfileID
		ON nvep.VendorCode = ph.vendor_code




GO
