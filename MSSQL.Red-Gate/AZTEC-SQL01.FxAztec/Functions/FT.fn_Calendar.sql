SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [FT].[fn_Calendar]
(	@BeginDT datetime = null,
	@EndDT datetime = null,
	@DatePart nvarchar (25) = null,
	@Increment integer = null,
	@Entries integer = null)
returns @Calendar table
	(	EntryDT datetime primary key)
begin
--- <Body>
--	If EndDT, DatePart, Increment, and Entries are specified, determine BeginDT.
	set	@BeginDT = isnull (@BeginDT, FT.fn_DateAdd (@DatePart, -@Increment * (@Entries - 1), @EndDT))
--	If BeginDT, DatePart, Increment, and Entries are specified, determine EndDT.
	set	@EndDT = isnull (@EndDT, FT.fn_DateAdd (@DatePart, @Increment * (@Entries - 1), @BeginDT))
--	If BeginDT and EndDT, DatePart, and Increment are specified, determine entries.
	set	@Entries = isnull (@Entries, 1 + FT.fn_DateDiff (@DatePart, @BeginDT, @EndDT) / @Increment)
--	If BeginDT and EndDT, DatePart, and Entries are specified, determine increment.
	set	@Increment = isnull (@Increment, (1 + FT.fn_DateDiff (@DatePart, @BeginDT, @EndDT)) / @Entries)

	while @BeginDT <= @EndDT and @Increment > 0 begin
		insert	@Calendar
		values	(@BeginDT)

		set @BeginDT = FT.fn_DateAdd (@DatePart, @Increment, @BeginDT)
	end
--- </Body>

---	<Return>
	return
---	</Return>
end
GO
