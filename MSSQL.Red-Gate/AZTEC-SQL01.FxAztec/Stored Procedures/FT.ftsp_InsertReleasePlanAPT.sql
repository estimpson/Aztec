SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create  procedure [FT].[ftsp_InsertReleasePlanAPT]
as


--Clear API table
TRUNCATE TABLE m_in_release_plan
							
Create table #CumulativereleasePlan (
							lineid			integer identity,
							customerpart	varchar (35),
							destination		varchar (20),
							customerPO		varchar	(20),
							modelYear		varchar	(4),
							ReleaseNumber	varchar(30),
							QtyQual			char(1),
							Qty				numeric(20,6),
							DateType		char(1),
							ReleaseDate		DATETIME,
							Accum			numeric (20,6),
							CustomerAccum	numeric (20,6),
							EmpireAccum		numeric (20,6))
							
Create table #releasePlan (
							lineid	integer identity,
							customerpart	varchar (35),
							destination		varchar (20),
							customerPO		varchar	(20),
							modelYear			varchar	(4),
							ReleaseNumber	varchar(30),
							QtyQual				char(1),
							Qty						numeric(20,6),
							DateType			char(1),
							ReleaseDate		DATETIME,
							CustomerAccum	numeric (20,6))
						

insert #releasePlan(		customerpart	,
							destination		,
							customerPO		,
							modelYear			,
							ReleaseNumber	,
							QtyQual				,
							Qty						,
							DateType			,
							ReleaseDate		,
							customerAccum		)
	
	
	
	select 	rtrim(lin03),
			COALESCE((SELECT		MAX(order_header.destination) 
				FROM	order_header
				JOIN	edi_setups ON order_header.destination = edi_setups.destination
				WHERE	order_header.customer_part = RTRIM(raw_830_release.lin03) AND
						edi_setups.parent_destination = RTRIM(raw_830_release.n104_1)), RTRIM(raw_830_release.n104_1) ),
			rtrim(lin05),
			'',
			rtrim(bfr_rel),
			'N',
			convert(numeric(20,6),fst01),
			'S',		
			dateadd(dd, -1*isNULL ((SELECT		MAX(edi_setups.id_code_type) 
				FROM	order_header
				JOIN	edi_setups ON order_header.destination = edi_setups.destination
				WHERE	order_header.customer_part = RTRIM(raw_830_release.lin03) AND
						edi_setups.parent_destination = RTRIM(raw_830_release.n104_1)),0),convert(datetime,fst04)),
				(SELECT	MAX(CONVERT(numeric(20,6), last_ship_qty))
					FROM 	"raw_830_shp"
					WHERE	RTRIM(raw_830_shp.lin03) = RTRIM(raw_830_release.lin03) AND
							RTRIM(raw_830_shp.n104_1) = RTRIM(raw_830_release.n104_1) AND
							RTRIM(bfr_sched_qty_type)= '02' AND
							RTRIM(N101_1) = 'ST')
	 FROM "raw_830_release" 
	 WHERE	RTRIM(N101_1) = 'ST'
ORDER BY 1,2,9

INSERT #CumulativereleasePlan
        ( customerpart ,
          destination ,
          customerPO ,
          modelYear ,
          ReleaseNumber ,
          QtyQual ,
          Qty ,
          DateType ,
          ReleaseDate ,
          Accum ,
          CustomerAccum ,
          EmpireAccum
        )

	select 	customerpart,
			destination,
			customerPO,
			ModelYear,
			ReleaseNumber,
			QtyQual,
			Qty,
			DateType,
			ReleaseDate,
			(Select sum(Qty) from #releasePlan RP2 
				where RP2.customerPart = #releasePlan.customerPart and 
							RP2.destination = #ReleasePlan.destination  and 
							RP2.lineid <= #releasePlan.lineid),
			(Select sum(Qty) from #releasePlan RP2 
				where RP2.customerPart = #releasePlan.customerPart and 
							RP2.destination = #ReleasePlan.destination  and 
							RP2.lineid <= #releasePlan.lineid)+COALESCE(CustomerAccum,0),
			(Select sum(Qty) from #releasePlan RP2 
				where RP2.customerPart = #releasePlan.customerPart and 
							RP2.destination = #ReleasePlan.destination  and 
							RP2.lineid <= #releasePlan.lineid)+COALESCE((SELECT	MIN(order_header.our_cum )
																FROM	order_header 
																JOIN	part_eecustom ON order_header.blanket_part = part_eecustom.part 
																WHERE	ISNULL(NULLIF(order_header.status,''),'C') = 'A' AND 
																		order_header.customer_part = #releasePlan.CustomerPart AND
																		order_header.destination = #releasePlan.destination), CustomerAccum,0)
	 FROM #releasePlan
	 order by destination, customerpart, ReleaseDate       
DELETE	#CumulativereleasePlan
WHERE	(Accum-(EmpireAccum-CustomerAccum))<=0



UPDATE	#CumulativereleasePlan
SET		#CumulativereleasePlan.Qty = (#CumulativereleasePlan.Accum-(#CumulativereleasePlan.EmpireAccum-#CumulativereleasePlan.CustomerAccum))
FROM	#CumulativereleasePlan
JOIN	(SELECT MIN(lineid)FIRSTLINEID
				 FROM	#CumulativereleasePlan
				 GROUP BY	customerpart,
							destination) FIRSTROWCRP ON #CumulativereleasePlan.Lineid =FIRSTROWCRP.FIRSTLINEID






INSERT	dbo.m_in_release_plan
        ( customer_part ,
          shipto_id ,
          customer_po ,
          model_year ,
          release_no ,
          quantity_qualifier ,
          quantity ,
          release_dt_qualifier ,
          release_dt
        )
SELECT	customerpart,
		destination,
		customerPO,
		modelYear,
		ReleaseNumber,
		'N',
		Qty,
		'S',
		ReleaseDate
FROM	#CumulativereleasePlan

 

Update	order_header
set			custom01 = rtrim(udf9)
FROM 		"raw_830_shp"
	LEFT OUTER JOIN 	"edi_setups"  ON rtrim("raw_830_shp"."n104_1") = "edi_setups"."parent_destination"
	  JOIN	"order_header"   ON edi_setups.destination = order_header.destination
	  WHERE rtrim(raw_830_shp.lin03) = order_header.customer_part

 
	  SELECT	'Inserted m_in_release_plan'
GO
