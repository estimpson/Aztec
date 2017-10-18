
/*
Create table fx21st.custom.MoldingColorLetdown
*/

use fx21st
go

--drop table custom.MoldingColorLetdown
if	objectproperty(object_id('custom.MoldingColorLetdown'), 'IsTable') is null begin

	create table custom.MoldingColorLetdown
	(	MoldApplication varchar(50)
	,	BaseMaterialCode varchar(25)
	,	ColorCode varchar(5)
	,	ColorName varchar(30)
	,	ColorantCode varchar(25)
	,	LetDownRate numeric(4,2)
	,	Status int not null default(0)
	,	Type int not null default(0)
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	,	unique nonclustered
		(	MoldApplication
		,	BaseMaterialCode
		,	ColorCode
		)
	)
end
go

select
	*
from
	custom.MoldingColorLetDown