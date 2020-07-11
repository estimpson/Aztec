SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[FormatDT]
(	@Format varchar(12)
,	@DateTime datetime
)
returns varchar(50)
as
begin
--- <Body>
	declare
		@Result varchar(50)
	
	set	@Result =
		case @Format
			when 'YYMMDD' then
				rtrim(convert(char(6), @DateTime, 12))
			when 'CCYYMMDD' then
				rtrim(convert(char(8), @DateTime, 112))
			when 'CCYYMMDDHHMM' then
				dbo.FormatDT('CCYYMMDD', @DateTime) + dbo.FormatDT('HHMM', @DateTime)
			when 'HHMM' then
				rtrim(substring(convert(char(5), @DateTime, 14), 1, 2) + substring(convert(char(5), @DateTime, 14), 4, 2))
		end
--- </Body>

---	<Return>
	return
		@Result
end
GO
