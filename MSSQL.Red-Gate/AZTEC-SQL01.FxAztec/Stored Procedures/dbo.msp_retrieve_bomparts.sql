SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_retrieve_bomparts] ( @part varchar ( 25 ) ) as
declare @bomlevel integer,
	@sequence integer,
	@childpart varchar(25),
	@bomqty	decimal(20,6),
	@bomq	varchar(20),
	@lseq	integer,
	@count  integer,
	@parentseq integer
	

create table #bomparts (
	parentpart	varchar ( 25) null,
	part 		varchar ( 25) not null,
	bomqty		decimal (20,6) not null,
	bomlevel	integer	not null,
	sequence	integer	not null,
	parentseq	integer not null) 

select  @bomlevel = 1, @sequence = 1, @lseq = 1, @parentseq = 1

insert into #bomparts values ( null, @part , 1 , @bomlevel, @sequence, @parentseq )

select 	@part = min(part),
	@count= count ( * ),
	@bomlevel = min(bomlevel),
	@parentseq= (select sequence from #bomparts where sequence = @lseq)
from 	#bomparts where sequence = @lseq

while @count > 0 
begin

	declare bomparts cursor for 
	select 	part, 
		convert(varchar(20),quantity)
	from 	bill_of_material 
	where	parent_part = @part
	
	open 	bomparts
	fetch 	bomparts into @childpart, @bomq
			
	while @@fetch_status = 0 
	begin
	
		select @sequence = @sequence + 1		
		insert into #bomparts 
		values ( @part , @childpart, convert(numeric ( 20,6), @bomq) , @bomlevel + 1, @sequence, @parentseq )
	
		fetch 	bomparts into @childpart, @bomq
	end 
	
	close bomparts
	
	deallocate bomparts
	
	select @lseq = @lseq + 1

	select 	@part = min(part),
		@count= count ( * ),
		@bomlevel = min(bomlevel),
		@parentseq= (select sequence from #bomparts where sequence = @lseq)
	from 	#bomparts where sequence = @lseq
	
end 	
select * from #bomparts
GO
