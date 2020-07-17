SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [SPORTAL].[ExceptionLogInsert]
	@ProcedureName varchar(50)
,	@Exception varchar(1000)
as
begin
set nocount on

	begin try

		insert into SPORTAL.ExceptionLog
		(
			ProcedureName
		,	Exception
		)
		select
			ProcedureName = @ProcedureName
		,	Exception = @Exception;

	end try
	begin catch

	end catch
end

GO
GRANT EXECUTE ON  [SPORTAL].[ExceptionLogInsert] TO [SupplierPortal]
GO
