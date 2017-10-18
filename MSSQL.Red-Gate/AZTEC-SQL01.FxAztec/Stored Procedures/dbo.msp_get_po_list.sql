SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_get_po_list] (@vendor varchar(10)) as
begin
if isnull(@vendor,'') > '' 
	SELECT	po_number,vendor_code
	FROM	po_header
	WHERE	status = 'A' and vendor_code = @vendor
	GROUP BY vendor_code,po_number
else
	SELECT	po_number,vendor_code
	FROM	po_header
	WHERE	status = 'A'
	GROUP BY vendor_code,po_number
end
GO
