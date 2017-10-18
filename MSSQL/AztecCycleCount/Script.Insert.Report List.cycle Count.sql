insert
	dbo.report_list
(	report
,	description
)
select
	'Cycle Count'
,	'Cycle Count Object List'
where
	not exists
	(	select
			*
		from
			dbo.report_list rl
		where
			rl.report = 'Cycle Count'
	)
	
