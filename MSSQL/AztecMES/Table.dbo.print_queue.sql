/*
(column=(type=long updatewhereclause=no key=yes name=entry_id dbname="entry_id" )
 column=(type=long updatewhereclause=no name=serial_number dbname="serial_number" )
 column=(type=char(255) updatewhereclause=no name=label_format dbname="label_format" )
 column=(type=char(1) updatewhereclause=no name=type dbname="type" )
 column=(type=number updatewhereclause=no name=copies dbname="copies" )
 column=(type=long update=yes updatewhereclause=no name=printed dbname="printed" )
*/

/*
Create table fx21st.dbo.print_queue
*/

--use fx21st
--go

--drop table dbo.print_queue
if	objectproperty(object_id('dbo.print_queue'), 'IsTable') is null begin

	create table dbo.print_queue
	(	printed int not null default(0)
	,	type char(1)
	,	copies int
	,	serial_number int
	,	label_format varchar(255)
	,	server_name varchar(255)
	,	entry_id int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	)
end
go



select
	pq.entry_id
,	pq.serial_number
,	rl.object_name
,	rl.type
,	rl.copies
,	pq.printed
from
	print_queue pq
	join object o
		on o.serial = pq.serial_number
	left outer join order_detail od
		on od.id =
		(	select
				min(id)
			from
				order_detail od
				join shipper_detail sd
					on sd.order_no = od.order_no
					   and sd.part_original = od.part_number
			where
				sd.shipper = o.shipper
				and od.part_number = o.part
		)
	join part_inventory pi
		on pi.part = o.part
	join report_library rl
		on rl.name = isnull(od.box_label,pi.label_format)
where
	o.type is null
	and pq.printed = 0
	and rl.report = 'Label'
