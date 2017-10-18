SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cs_issues_vw]
as 
	select  issues.issue_number issue_number,
		issues.issue issue,
		issues.status status,
		issues.solution solution,
		issues.start_date start_date,
		issues.stop_date stop_date,
		issues.category category,
		issues.sub_category sub_category,
		issues.priority_level priority_level,
		issues.product_line product_line,
		issues.product_code product_code,
		issues.origin_type origin_type,
		issues.origin origin,
		issues.assigned_to assigned_to,
		issues.authorized_by authorized_by,
		issues.documentation_change documentation_change,
		issues.fax_sheet,   
		issues.environment environment,
		issues.entered_by entered_by,
		issues.product_component product_component, 
		issues_status.type type
	from  issues
		left outer join issues_status on issues_status.status = issues.status
GO
