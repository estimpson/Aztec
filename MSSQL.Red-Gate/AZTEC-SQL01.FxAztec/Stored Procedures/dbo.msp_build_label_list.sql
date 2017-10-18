SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[msp_build_label_list]
AS
        SELECT  name,
	      null,
	      object_name
          FROM  report_library
         WHERE  report = 'label'
         ORDER BY name
GO
