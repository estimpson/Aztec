SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*	One will fail, the other will be loaded.  */

create function [monitor].[udf_ReplaceWords]
(	@Value varchar (8000),
	@ReplaceList varchar (8000))
returns varchar (8000)
begin
	set	@ReplaceList = monitor.udf_Trim (@ReplaceList)

	declare	@ReturnValue varchar (8000); set @ReturnValue = @Value
	declare @ReplaceExp varchar (8000),
		@NextReplaceLength int,
		@Find varchar (8000),
		@Replace varchar (8000),
		@NextEquals int
	
	set	@NextReplaceLength =
		case	Patindex ('%,%', @ReplaceList) when 0 then len (@ReplaceList)
			else Patindex ('%,%', @ReplaceList) - 1
		end
	
	while	@NextReplaceLength > 0 begin

		select	@ReplaceExp = left (@ReplaceList, @NextReplaceLength),
			@ReplaceList = monitor.udf_Trim (substring (@ReplaceList, @NextReplaceLength + 2, 8000))
		
		set	@NextEquals =
			case	when Patindex ('%=%', @ReplaceExp) = 0 then Len (@ReplaceExp)
				else Patindex ('%=%', @ReplaceExp) - 1
			end
		
		set	@Find = rtrim (left (@ReplaceExp, @NextEquals))
		set	@Replace = ltrim (substring (@ReplaceExp, @NextEquals + 2, 8000))
		
		set	@ReturnValue = Replace (@ReturnValue, ' ' + @Find, ' ' + @Replace)
		set	@ReturnValue = Replace (@ReturnValue, @Find + ' ', @Replace + ' ')
		if	@ReturnValue = @Find begin
			set	@ReturnValue = @Replace
		end

		set	@NextReplaceLength =
			case	Patindex ('%,%', @ReplaceList) when 0 then len (@ReplaceList)
				else Patindex ('%,%', @ReplaceList) - 1
			end
	end

	return	@ReturnValue
end
GO
