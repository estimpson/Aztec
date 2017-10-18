SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[msp_generate_kanban]
(	@orderno	decimal (8) )
AS
---------------------------------------------------------------------------------------
-- 	This procedure generates kanban table information from data stored in order header
--	Modified:	12 Mar 1999, Eric E. Stimpson
--	Paramters:	@orderno		mandatory
--	Returns:	0				success
--				-1				error, invalid begin or end kanban number for order
---------------------------------------------------------------------------------------

--	Declarations.
DECLARE	@beginkanban	varchar (6),
		@endkanban	varchar (6),
		@rootindex	integer,
		@root		varchar (5),
		@suffix1	char (6),
		@suffix2	char (6),
		@begin		integer,
		@end		integer,
		@count		integer


--	Get beginning and ending kanban numbers from order.
SELECT	@beginkanban = begin_kanban_number,
		@endkanban = end_kanban_number
  FROM	order_header
 WHERE	order_no = @orderno

--	Find the common alpha numeric root index (position) between beginning and ending kanban numbers.
SELECT	@rootindex =
		( CASE	
			WHEN	Substring ( @beginkanban, 1, 1 ) = Substring ( @endkanban, 1, 1 ) THEN
			( CASE
				WHEN	Substring ( @beginkanban, 2, 1 ) = Substring ( @endkanban, 2, 1 ) THEN
				( CASE
					WHEN	Substring ( @beginkanban, 3, 1 ) = Substring ( @endkanban, 3, 1 ) THEN
					( CASE
						WHEN	Substring ( @beginkanban, 4, 1 ) = Substring ( @endkanban, 4, 1 ) THEN
						( CASE
							WHEN	Substring ( @beginkanban, 5, 1 ) = Substring ( @endkanban, 5, 1 ) THEN 5
							ELSE	4
						END )
						ELSE	3
					END )
					ELSE	2
				END )
				ELSE	1
			END )
			ELSE	0
		END )

--	Calculate the root and suffixes from the root index.
SELECT	@root = Substring ( @beginkanban, 1, @rootindex ),
		@suffix1 = Right ( '000000' + Substring ( @beginkanban, @rootindex + 1, 6 ), 6 ),
		@suffix2 = Right ( '000000' + Substring ( @endkanban, @rootindex + 1, 6 ), 6 )

--	If suffixes are numeric, calculate the beginning and ending counters.
IF	@suffix1 LIKE '[0-9][0-9][0-9][0-9][0-9][0-9]' AND
	@suffix2 LIKE '[0-9][0-9][0-9][0-9][0-9][0-9]' AND
	@root IS NOT NULL
	SELECT	@begin = Convert ( integer, @suffix1 ),
			@end = Convert ( integer, @suffix2 ),
			@count = Convert ( integer, @suffix1 )

--	If kanban numbers are valid, generate kanban table data.
IF	@end >= @begin
	WHILE @count <= @end
	BEGIN
		BEGIN TRANSACTION
		INSERT	kanban
		SELECT	Substring ( @root + Right ( '00000' + Convert ( varchar (6), @count ), DataLength ( @beginkanban ) - DataLength ( @root ) ), 1, DataLength ( @beginkanban ) ) kanban,
				@orderno,
				line11,
				line12,
				line13,
				line14,
				line15,
				line16,
				line17,
				'A' status,
				standard_pack
		  FROM	order_header
		 WHERE	order_no = @orderno AND
				Substring ( @root + Right ( '00000' + Convert ( varchar (6), @count ), DataLength ( @beginkanban ) - DataLength ( @root ) ), 1, DataLength ( @beginkanban ) ) NOT IN
				(	SELECT	kanban_number
					  FROM	kanban
					 where	order_no = @orderno )
		SELECT	@count = @count + 1
		COMMIT TRANSACTION
	END

--	Otherwise return error code.
ELSE
	Return -1

--	Indicate success.
Return 0
GO
