SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[TRN_INFO]
(	@dictionaryVersion varchar(25)
,	@transactionType varchar(25)
,	@tradingPartner varchar(50)
,	@iConnectID varchar(50)
,	@documentNumber varchar(50)
,	@completeFlag bit = 1
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set
		@xmlOutput =
			(	select
					name = dt.TransactionDescription
				,	trading_partner = @TradingPartner
				,	ICN = @iConnectID
				,	version = @DictionaryVersion
				,	type = @TransactionType
				,	doc_number = @DocumentNumber
				,	folder = case when @completeFlag = 0 then '3' else '4' end
				from
					FxEDI.EDI_DICT.DictionaryTransactions dt
				where
					dt.DictionaryVersion = @DictionaryVersion
					and dt.TransactionType = @TransactionType
				for xml raw ('TRN-INFO'), type
			)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
