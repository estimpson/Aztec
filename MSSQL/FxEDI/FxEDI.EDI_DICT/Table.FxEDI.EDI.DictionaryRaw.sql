drop table #TEXTFILE_1

create table #TEXTFILE_1 (FIELD1 varchar(max));

--declare
--	@lf char(1) = char(10)

--print 't' + @lf + 'est'

bulk insert #TEXTFILE_1 from 'C:\Temp\2002FORD.mrg'
with (fieldterminator ='|',rowterminator ='
')

create table EDI_DICT.DictionaryRaw
(	DictionaryVersion varchar(12)
,	Dictionary varchar(max)
,	RowID int not null identity(1, 1) primary key
)

insert	EDI_DICT.DictionaryRaw
(	DictionaryVersion
,	Dictionary
)
select
	'002002FORD'
,	t.FIELD1
from
	#TEXTFILE_1 t

select
	*
from
	EDI_DICT.DictionaryRaw dr
