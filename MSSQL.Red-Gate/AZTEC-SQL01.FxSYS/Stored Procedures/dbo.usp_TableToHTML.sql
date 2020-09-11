SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--if	objectproperty(object_id('dbo.usp_TableToHTML'), 'IsProcedure') = 1 begin
--	drop procedure dbo.usp_TableToHTML
--end
--go

--create procedure dbo.usp_TableToHTML
CREATE procedure [dbo].[usp_TableToHTML]
	@tableName sysname = 'dbo.part_packaging'
,	@html nvarchar(max) output
,	@orderBy nvarchar(max) = ''
,	@includeRowNumber bit = 1
,	@camelCaseHeaders bit = 1
,	@colorCodeType bit = 0
as
set ansi_warnings on 

declare
	@getColumnListSyntax nvarchar(max)

select
	@getColumnListSyntax = N'
set	@columnList =
		(	select
				A2.B.value(''.[1]/@name'', ''varchar(128)'')
			from
				(	select
					' +
		case	when @includeRowNumber = 1 then
					'	[Row] = 1
					,'
				else ''
		end +
					'	*
					from
						' + @tableName + '
					for xml AUTO, TYPE, xmlschema
				) as A1(X)
				cross apply X.nodes(
					''declare namespace xsd="http://www.w3.org/2001/XMLSchema";
					/xsd:schema/xsd:element/xsd:complexType/xsd:attribute'') as A2(B)
			for xml path(''th''), type
		)
'

declare
	@columnList xml

execute
	sp_executesql
	@getColumnListSyntax
,	N'@columnList xml output'
,	@columnList = @columnList output

declare
	@dataTableHTML nvarchar(max)
,	@dataSelectSyntax nvarchar(max)

select
	@dataSelectSyntax =
'
select
	@dataTableHTML = convert
	(	varchar(max)
	,	(	select
'

declare
	columnList cursor local for
select
	columnList.columnName.value('.[1]', 'varchar(128)')
from
	@columnList.nodes('/th') as columnList(columnName)
where
	(	columnList.columnName.value('.[1]', 'varchar(128)') != 'Row'
		or @includeRowNumber = 0
	)
	and
	(	columnList.columnName.value('.[1]', 'varchar(128)') != 'Type'
		or @colorCodeType = 0
	)

open
	columnList
	
declare
	@firstColumn int

select
	@firstColumn = 1

while
	1 = 1 begin
	
	declare
		@columnName sysname
	
	fetch
		columnList
	into
		@columnName
	
	if	@@FETCH_STATUS != 0 begin
		break
	end
	
	if	@firstColumn = 1 begin
		set	@dataSelectSyntax = @dataSelectSyntax +
'				[TRRow] = Row_Number() over (order by [' +
			case	when @orderBy > '' then @orderBy
					else @columnName
			end + ']) % 2
' +
			case	when @colorCodeType = 1 then
'			,	[TRType] = case when Type < 0 then -1 else 0 end'
					else ''
			end +
			case	when @includeRowNumber = 1 then
'			,	[td] = Row_Number() over (order by [' +
						case	when @orderBy > '' then @orderBy
								else @columnName
						end + '])'
					else ''
			end

		set	@firstColumn = 0
	end
	
	set	@dataSelectSyntax = @dataSelectSyntax +
	'
			,	[td] = coalesce(convert(nvarchar(max), [' + @columnName + ']), ''(null)'')'
end

close
	columnList
deallocate
	columnList

set	@dataSelectSyntax = @dataSelectSyntax +
'
			from
				' + @tableName +
		case	when @orderBy > '' then '
			order by
				' + @orderBy
				else ''
		end + '
			for xml raw(''tr''), elements
		)
	)
'

set	@dataSelectSyntax = replace(@dataSelectSyntax, '_x0020_', space(1))
set	@dataSelectSyntax = replace(@dataSelectSyntax, '_x003D_', '=')

exec sp_executesql
	@dataSelectSyntax
,	N'@dataTableHTML nvarchar(max) output'
,	@dataTableHTML = @dataTableHTML output

set	@dataTableHTML = coalesce(@dataTableHTML, N'')

select
	@html =
		N'<table border="1">' +
		N'<tr>' +
		case	when @camelCaseHeaders = 1 then dbo.fn_CamelCase(convert(nvarchar(max), @columnList))
				else convert(nvarchar(max), @columnList)
		end + N'</tr>' +
		@dataTableHTML + N'</table>'

set	@html = replace(@html, '_x0020_', space(1))
set	@html = replace(@html, '_x003D_', '=')
set	@html = replace(@html, '<tr><TRRow>1</TRRow>', '<tr bgcolor=#C6CFFF>')
set	@html = replace(@html, '<TRRow>0</TRRow>', '')
if	@colorCodeType = 1 begin
	set @html = replace(@html, '<th>Type</th>', '')
	set @html = replace(@html, '<tr><TRType>-1</TRType>', '<tr bgcolor=#FF0000>')
	set @html = replace(@html, '<tr bgcolor=#C6CFFF><TRType>-1</TRType>', '<tr bgcolor=#FF0000>')
	set	@html = replace(@html, '<TRType>0</TRType>', '')
end

--print
--	@html
GO
GRANT EXECUTE ON  [dbo].[usp_TableToHTML] TO [SupplierPortal]
GO
