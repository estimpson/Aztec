SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view
  [dbo].[cs_quotes_vw]
  as select quote_number,
    quote_date,
    contact,
    status,
    amount,
    notes,
    expire_date,
    customer,
    destination
    from quote
GO
