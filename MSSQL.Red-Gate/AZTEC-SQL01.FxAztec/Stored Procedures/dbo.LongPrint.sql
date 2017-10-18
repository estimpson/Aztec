SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 

CREATE procedure [dbo].[LongPrint] @String nvarchar(max)
as /*
Example:

exec LongPrint @string =
'This String
Exists to test
the system.'

print
'This String
Exists to test
the system.'


*/

/* This procedure is designed to overcome the limitation
in the SQL print command that causes it to truncate strings
longer than 8000 characters (4000 for nvarchar).

It will print the text passed to it in substrings smaller than 4000
characters.  If there are carriage returns (CRs) or new lines (NLs in the text),
it will break up the substrings at the carriage returns and the
printed version will exactly reflect the string passed.

If there are insufficient line breaks in the text, it will
print it out in blocks of 4000 characters with an extra carriage
return at that point.

If it is passed a null value, it will do virtually nothing.

NOTE: This is substantially slower than a simple print, so should only be used
when actually needed.
 */

declare
    @CurrentEnd bigint
, /* track the length of the next substring */
    @offset tinyint /*tracks the amount of offset needed */

set @string = replace(replace(@string,char(13) + char(10),char(10)),char(13),char(10))

while
	len(@String) > 1 begin

    if	charindex(char(10),@String) between 1 and 4000
		and len(@String) > 4000 begin

        set @CurrentEnd = (len(reverse(substring(@String, 1, 4000))) - charindex(char(10),reverse(substring(@String, 1, 4000))))
        set @offset = 2
    end
    else begin
        set @CurrentEnd = 4000
        set @offset = 1
    end

    print substring(@String,1,@CurrentEnd)

    set
		@string = substring(@String, @CurrentEnd + @offset, 1073741822)

end /*End While loop*/
GO
