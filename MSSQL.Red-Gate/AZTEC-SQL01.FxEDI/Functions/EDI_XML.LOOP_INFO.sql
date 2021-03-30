SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[LOOP_INFO]
(	@loopCode varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
	/*	CE */
		(	select
				name = @loopCode + ' Loop'
			for xml raw ('LOOP-INFO'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
