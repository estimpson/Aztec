SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [dbo].[usp_CreateHTMLPage_PartMaster]
	@Part varchar(25)
,	@TranDT datetime = null out
,	@Result integer = null out
as
set nocount on
set ansi_warnings on
set	@Result = 999999

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer,
	@FirstNewSerial integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare
	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
else begin
	save tran @ProcName
end
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>


---	<ArgumentValidation>
-- Valid part.
if	not exists
	(	select	1
		from	part
		where	part = @Part) begin

	set	@Result = 60001
	rollback tran @ProcName
	RAISERROR ('Error in procedure %s. Part %s not found.', 16, 1, @ProcName, @Part)
	return	@Result
end
---	</ArgumentValidation>


--- <Body>
declare
	@HtmlOutput nvarchar(max)


--- <Create Html markup>
set @HtmlOutput = 
'
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">  
<http://www.w3.org/1999/xhtml>


<head>
<title>Part Master</title>

<style type="text/css">

body
{
	font-size: 14px;
	font-family: arial;
	background-color:#000000;
	background-image:url(''Opera.jpg'');
	background-size: 100%;
	background-repeat: repeat;
	margin:0 auto 0 auto;
}
#divPageConstraints
{
	min-width: 400px; 
	max-width:800px; 
	margin: auto;
}
#divHeader
{
	font-size: 15px;
	color: #ffffff; 
	padding-left: 5px;
	margin-top: 5px;
	margin-bottom: 5px;
}
#divDetail
{
	padding: 5px;
	margin-bottom: 5px;
	color: #ffffff; 
	min-height: 120px; 
	background-color: #000000; 
	filter:alpha(opacity=85); 
	Opacity: 0.85;
}
#divDetailPartMaster
{
	margin-top: 15px; 
	max-width: 780px; 
	overflow: auto;
}
#divDetailRelatedParts
{
	margin-top: 15px; 
}

a:link {color:#4791DA; text-decoration: none;}     
a:visited {color:#ffffff; text-decoration: none;} 
a:hover {color:#ffffff; text-decoration: none;}  
a:active {color:#ffffff; text-decoration: none;} 

</style>
</head>  



<body>
<div id="divPageConstraints">

	<div id="divHeader">
		<div>[Part]:</div>
		<div>[Description]</div>
	</div>


	<div id="divImage">
		<img src="[Image]" width="100%" />
	</div>


	<div id="divDetail">

		<div id="divDetailPDF">
			<a href="[PDF]">Part Drawing</a>
		</div>

		<div id="divDetailPartMaster">
			[PartMasterTable]
		</div>


		<div id="divDetailRelatedParts">
			[RelatedPartsTable]
		</div>

	</div>

</div>
</body>
</html>
'
--- </Create Html markup>


--- <Populate data variables>
declare
	@Description varchar(100)
,	@Image varchar(100)
,	@PDF varchar(100)	

select
	@Description = Description
,	@Image = ImageFileName
,	@PDF = DrawingFileName
from 
	custom.PartMaster_Setup 
where 
	PartCode = @Part
--- </Populate data variables>


--- <Create html tables for groups of data>
-- Part master table
select 
	ProductLine
,	GroupTechnology
,	StandardPack
,	StandardUnit
,	LabelFormat
,	PartClass
,	PartType 
into
	#PartMaster
from 
	custom.PartMaster_Setup 
where 
	PartCode = @Part

declare		@PartMasterOutput varchar(max)
set			@CallProcName = 'FT.usp_TableToHTML'
execute		FT.usp_TableToHTML
			@tableName = '#PartMaster',
			@html = @PartMasterOutput out,
--			@orderBy = ,
			@includeRowNumber = 0,
			@camelCaseHeaders = 0

set @Error = @@Error
if @Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran @ProcName
	return @Result
end
if @ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran @ProcName
	return	@Result
end

-- Reformat table
set @PartMasterOutput = REPLACE(@PartMasterOutput,'<th>', '<th style="border: 1px solid grey;">')
set @PartMasterOutput = REPLACE(@PartMasterOutput,'<td>', '<td style="border: 1px solid grey;">')




-- Related parts links table
select
	'<a href="' + pms.IntranetURL + '">' + pmxrp.RelatedPart + '</a>' as RelatedPartLink
into
	#RelatedPartsLinks
from
	dbo.PartMaster_XRelatedParts pmxrp
	join custom.PartMaster_Setup pms
		on pms.PartCode = pmxrp.RelatedPart
where
	pmxrp.AnchorPart = @Part	

declare		@RelatedPartsOutput varchar(max)
set			@CallProcName = 'FT.usp_TableToHTML'
execute		FT.usp_TableToHTML
			@tableName = '#RelatedPartsLinks',
			@html = @RelatedPartsOutput out,
--			@orderBy = ,
			@includeRowNumber = 0,
			@camelCaseHeaders = 0

set @Error = @@Error
if @Error != 0 begin
	set	@Result = 900601
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran @ProcName
	return @Result
end
if @ProcResult != 0 begin
	set	@Result = 900602
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran @ProcName
	return	@Result
end

-- Reformat table
set @RelatedPartsOutput = REPLACE(@RelatedPartsOutput,'<th>', '<th style="border: 1px solid grey;">')
set @RelatedPartsOutput = REPLACE(@RelatedPartsOutput,'<td>', '<td style="border: 1px solid grey;">')
--- </Create html tables for groups of data>



--- <Populate markup variables>
set @HtmlOutput = REPLACE(@HtmlOutput, '[Part]', @Part)
set @HtmlOutput = REPLACE(@HtmlOutput, '[Description]', @Description)
set @HtmlOutput = REPLACE(@HtmlOutput, '[Image]', @Image)
set @HtmlOutput = REPLACE(@HtmlOutput, '[PDF]', @PDF)
set @HtmlOutput = REPLACE(@HtmlOutput, '[PartMasterTable]', @PartMasterOutput)
set @HtmlOutput = REPLACE(@HtmlOutput, '[RelatedPartsTable]', @RelatedPartsOutput)
--- </Populate markup variables>



select	@HtmlOutput
--- </Body>


--<CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit transaction @ProcName
end
--</CloseTran Required=Yes AutoCreate=Yes>

--	Success.
set	@Result = 0
return	
	@Result


GO
