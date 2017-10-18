
--drop table FT.XRt
if	object_id ('FT.XRt') is null begin

	create table FT.XRt
	(
		ID int not null identity(1,1) primary key
	,	TopPart varchar (25) null
	,	ChildPart varchar (25) null
	,	BOMID int null
	,	Sequence smallint null
	,	BOMLevel smallint not null default (0)
	,	XQty float null default (1)
	,	XScrap float null default (1)
	,	XBufferTime float not null default (0)
	,	XRunRate float not null default (0)
	,	Hierarchy varchar(500)
	,	Infinite smallint not null default (0)
	,	unique
		(	TopPart
		,	Sequence
		)
	)

	create index XRt_1 on FT.XRt
	(
		TopPart
	,	ChildPart
	,	Sequence
	,	XQty
	,	XScrap
	,	XBufferTime
	,	ID
	)

	create index XRt_2 on FT.XRt
	(
		ChildPart
	,	BOMLevel
	)
end
go

if not exists ( select
                    *
                from
                    dbo.sysindexes
                where
                    id = object_id(N'FT.XRt')
                    and name = N'idx_XRt_1' ) 
    create nonclustered index idx_XRt_1 on FT.XRt 
    (
    BOMLevel asc,
    ChildPart asc,
    ID asc
    )
go
if not exists ( select
                    *
                from
                    dbo.sysindexes
                where
                    id = object_id(N'FT.XRt')
                    and name = N'idx_XRt_2' ) 
    create nonclustered index idx_XRt_2 on FT.XRt 
    (
    TopPart asc,
    Hierarchy asc,
    ID asc
    )
go
if not exists ( select
                    *
                from
                    dbo.sysindexes
                where
                    id = object_id(N'FT.XRt')
                    and name = N'idx_XRt_3' ) 
    create nonclustered index idx_XRt_3 on FT.XRt 
    (
    ChildPart asc,
    BOMLevel asc,
    ID asc
    )
go
if not exists ( select
                    *
                from
                    dbo.sysindexes
                where
                    id = object_id(N'FT.XRt')
                    and name = N'idx_XRt_4' ) 
    create nonclustered index idx_XRt_4 on FT.XRt 
    (
    ChildPart asc,
    TopPart asc,
    ID asc
    )
go
if not exists ( select
                    *
                from
                    dbo.sysindexes
                where
                    id = object_id(N'FT.XRt')
                    and name = N'idx_XRt_5' ) 
    create nonclustered index idx_XRt_5 on FT.XRt 
    (
    TopPart asc,
    ChildPart asc,
    XQty asc,
    ID asc
    )
go

select
	*
from
	FT.XRt xr
