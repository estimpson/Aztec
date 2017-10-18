SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



Create FUNCTION [dbo].[udf_GetSerialFIFO]
(
	@Part VARCHAR(25),
	@Serial int
)
RETURNS @Objects TABLE
(
	Serial INT
,	Location VARCHAR (10)
,	Quantity NUMERIC (20, 6)
,	BreakoutSerial INT NULL
,	FirstDT DATETIME NULL
)
AS
BEGIN
--- <Body>
	INSERT
		@Objects
	(
		Serial
	,	Location
	,	Quantity
	,	BreakoutSerial
	)
	SELECT
		Serial = o.serial
	,	Location = MIN(o.location)
	,	Quantity = MIN(o.quantity)
	,	BreakoutSerial = MIN(CONVERT (INT, Breakout.from_loc))
	FROM
		dbo.object o
		LEFT JOIN audit_trail BreakOut ON
			o.serial = BreakOut.serial
			AND
				Breakout.type = 'B' AND
				ISNUMERIC(REPLACE(REPLACE(Breakout.from_loc, 'D', 'X'), 'E', 'Z')) = 1 
	WHERE
		o.part = @Part
		AND
			o.Status = 'A'
		AND
			o.serial = @serial
	GROUP BY
		o.serial
	
	WHILE
		@@rowcount > 0 BEGIN
		UPDATE
			o
		SET
			BreakoutSerial = Breakout.BreakoutSerial
		FROM
			@Objects o
			JOIN
			(
				SELECT
					Serial
				,	BreakoutSerial = MIN(CONVERT(INT, Breakout.from_loc))
				FROM
					audit_trail BreakOut
				WHERE
					type = 'B'
					AND
						serial IN (SELECT BreakoutSerial FROM @Objects WHERE BreakoutSerial > 0)
					AND
						ISNUMERIC(REPLACE(REPLACE(Breakout.from_loc, 'D', 'X'), 'E', 'Z')) = 1 
				GROUP BY
					serial
			) Breakout ON
			o.BreakoutSerial = Breakout.Serial
	END

	UPDATE
		@Objects
	SET
		FirstDT = (SELECT MIN(COALESCE(start_date, date_stamp)) FROM audit_trail WHERE type IN ('A', 'R', 'J') AND serial = COALESCE (o.BreakoutSerial, o.Serial))
	FROM
		@Objects o
--- </Body>

---	<Return>
	RETURN
END


GO
