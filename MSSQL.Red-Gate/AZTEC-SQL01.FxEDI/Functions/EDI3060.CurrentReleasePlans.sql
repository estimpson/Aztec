SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI3060].[CurrentReleasePlans]
(
--	@Param1 [scalar_data_type] ( = [default_value] ) ...
)
returns @CurrentReleasePlans table
(	RawDocumentGUID uniqueidentifier not null
,	ReleaseNo varchar(50) null
,	ShipToCode varchar(15) null
,	ShipFromCode varchar(15) null
,	ConsigneeCode varchar(15) null
,	CustomerPart varchar(50) null
,	CustomerPO varchar(50) null
,	CustomerModelYear varchar(50) null
,	NewDocument bit
,	SalesOrderNumber int
,	DuplicateBlanketOrders bit
,	MissingBlanketOrder bit
,	TestingOnly bit
,	Exclude bit
)
as
begin
--- <Body>
	insert
		@CurrentReleasePlans
		(	RawDocumentGUID
		,	ReleaseNo
		,	ShipToCode
		,	ShipFromCode
		,	ConsigneeCode
		,	CustomerPart
		,	CustomerPO
		,	CustomerModelYear
		,	NewDocument
		,	SalesOrderNumber
		,	DuplicateBlanketOrders
		,	MissingBlanketOrder
		,	TestingOnly
		,	Exclude
		)
		select
			rpr.RawDocumentGUID
		,	rpr.ReleaseNo
		,	rpr.ShipToCode
		,	rpr.ShipFromCode
		,	rpr.ConsigneeCode
		,	rpr.CustomerPart
		,	rpr.CustomerPO
		,	rpr.CustomerModelYear
		,	NewDocument = case when rpr.Status = 0 then 1 else 0 end
		,	SalesOrderNumber = max(bo.BlanketOrderNo)
		,	DuplicateBlanketOrders =
				case
					when count(distinct	bo.BlanketOrderNo) > 1 then 1
					else 0
				end
		,	MissingBlanketOrder =
				case
					when max(bo.BlanketOrderNo) is null then 1
					else 0
				end
		,	TestingOnly =
				case
					when max(bo.ProcessPlanningRelease) = 0 then 1
					else 0
				end
		,	Exclude =
				case
					when max(bo.ProcessPlanningRelease) < 0 then 1
					else 0
				end
		from
			(	select
					rpr.RawDocumentGUID
				,	rpr.ReleaseNo
				,	rpr.ShipToCode
				,	rpr.ShipFromCode
				,	rpr.ConsigneeCode
				,	rpr.CustomerPart
				,	rpr.CustomerPO
				,	rpr.CustomerModelYear
				,	rph.Status
				,	Precedence = row_number() over
						(	partition by
								rpr.ShipToCode
							,	rpr.ShipFromCode
							,	rpr.ConsigneeCode
							,	rpr.CustomerPart
							,	rpr.CustomerPO
							,	rpr.CustomerModelYear
							order by
								rph.DocumentImportDT desc
							,	rph.DocumentDT desc
							,	rph.RowID desc
						)
				from
					EDI3060.ReleasePlanHeaders rph
					join EDI3060.ReleasePlanReleases rpr
						on rpr.RawDocumentGUID = rph.RawDocumentGUID
				where
					rph.Status in (0, 1)
			) rpr
			left join EDI3060.BlanketOrders bo
				on bo.EDIShipToCode = rpr.ShipToCode
				and bo.CustomerPart = rpr.CustomerPart
				and
				(	bo.CheckCustomerPOPlanning = 0
					or bo.CustomerPO = rpr.CustomerPO
				)
				and
				(	bo.CheckModelYearPlanning = 0
					or bo.ModelYear830 = rpr.CustomerModelYear
				)
		where
			rpr.Precedence = 1
			and coalesce(bo.ProcessReleases, 1) = 1
		group by
			rpr.RawDocumentGUID
		,	rpr.ReleaseNo
		,	rpr.ShipToCode
		,	rpr.ShipFromCode
		,	rpr.ConsigneeCode
		,	rpr.CustomerPart
		,	rpr.CustomerPO
		,	rpr.CustomerModelYear
		,	rpr.Status
--- </Body>

---	<Return>
	return
end
GO
