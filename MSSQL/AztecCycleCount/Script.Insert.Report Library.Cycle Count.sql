
insert
	dbo.report_library
(	name
,	report
,	type
,	object_name
,	library_name
,	preview
,	print_setup
,	printer
,	copies
)
select
	name = 'Cycle Count'
,	report = 'Cycle Count'
,	type = 'C'
,	object_name = 'd_cyclecount_countsheet'
,	library_name = ''
,	preview = 'Y'
,	print_setup = 'N'
,	printer = null
,	copies = 1
where
	not exists
	(	select
			*
		from
			dbo.report_library rl
		where
			rl.name = 'Cycle Count'
	)

select
	*
from
	dbo.report_library rl
where
	name = 'Cycle Count'
