SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create function [monitor].[udf_StripWords]
(	@Value varchar (8000),
	@WordList varchar (8000))
returns varchar (8000)
begin
	declare	@ReturnValue varchar (8000); set @ReturnValue = @Value
	declare @Word varchar (8000),
		@NextWordLength int
	
	set	@NextWordLength =
		case	Patindex ('% %', @WordList) when 0 then len (@WordList)
			else Patindex ('% %', @WordList) - 1
		end
	
	while	@NextWordLength > 0 begin

		select	@Word = left (@WordList, @NextWordLength),
			@WordList = substring (@WordList, @NextWordLength + 2, 8000)
		
		set	@ReturnValue = Replace (@ReturnValue, ' ' + @Word, '')
		set	@ReturnValue = Replace (@ReturnValue, @Word + ' ', '')

		set	@NextWordLength =
			case	Patindex ('% %', @WordList) when 0 then len (@WordList)
				else Patindex ('% %', @WordList) - 1
			end
	end

	return	@ReturnValue
end
GO
