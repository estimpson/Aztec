SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[usp_test_price_admin]
(	@UserCode varchar(5) = null,
	@UserName varchar(40) = 'SQL Manager')
as

select * 
from part_customer
where part = '1216-20'
GO
