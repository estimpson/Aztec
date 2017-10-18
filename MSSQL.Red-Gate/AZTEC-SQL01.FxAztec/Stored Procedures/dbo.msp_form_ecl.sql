SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[msp_form_ecl](@part varchar(50),@date datetime)
as
BEGIN

SELECT  max(Convert(varchar(30),effective_date,102) +'  '+ '/' +'   ' + engineering_level)      
FROM
        effective_change_notice
WHERE
        (part = @part) and
        (@date >= effective_date)

END
GO
