SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_build_mps] (@a_order_no numeric(8,0), @a_row_id int) as

declare         @part_number                    varchar(25),
                @std_qty                        numeric(20,6),
                @due_date                       datetime,
                @due                            datetime,
                @order_no                       numeric(8,0),
                @row_id                         int,
                @origin                         numeric(8,0),
                @source                         int,
                @ship_type                      char(1),
                @plant                          varchar(10),
                @qnty                           numeric(20,6),
                @qty_left                       numeric(20,6),
                @assign_qty                     numeric(20,6),
                @assign_qty_wo                  numeric(20,6),
                @id                             numeric(12,0)

        create table #mps_temp (
                part                            varchar(25),
                plant                           varchar(10) null)

        create table #mps_assign (
                part                            varchar(25),
                due                             datetime,
                source                          int,
                origin                          numeric(8,0),
                qnty                            numeric(20,6),
                id                              numeric(12,0))

        set rowcount 1                                          /* setup poor man's cursor */

        select  @part_number = part_number,                     /* get order detail record */
                @std_qty = std_qty,
                @due_date = due_date,
                @order_no = order_no,
                @row_id = row_id,
                @ship_type = ship_type,
                @plant = plant
          from  #order_detail
      order by  part_number

        while @@rowcount > 0                                    /* loop for each order detail */
        begin

                set rowcount 0

                delete from #bom_info
                                                                /* explode the part */
                execute msp_explode_part null, @part_number, @std_qty, @due_date, 0

                begin transaction                               /* begin transaction */

                        delete  from master_prod_sched          /* delete mps for order detail */
                         where  master_prod_sched.origin = @order_no
                           and  master_prod_sched.source = @row_id

                        insert into master_prod_sched           /* create new mps record */
                          (type,   
                           part,   
                           due,   
                           qnty,   
                           source,   
                           source2,   
                           origin,   
                           rel_date,   
                           tool,   
                           workcenter,   
                           machine,   
                           run_time,   
                           run_day,  
                           dead_start,   
                           material,   
                           job,   
                           material_qnty,   
                           setup,   
                           location,   
                           field1,   
                           field2,   
                           field3,   
                           field4,   
                           field5,   
                           status,   
                           sched_method,   
                           qty_completed,   
                           process,   
                           tool_num,   
                           workorder,   
                           qty_assigned,   
                           due_time,   
                           start_time,   
                           id,   
                           parent_id,   
                           begin_date,   
                           begin_time,   
                           end_date,   
                           end_time,   
                           po_number,   
                           po_row_id,   
                           week_no,
                           plant,
                           ship_type)  
                        select
                           class,   
                           part,   
                           due_datetime,   
                           extended_quantity,   
                           @row_id,   
                           null,   
                           @order_no,   
                           null,   
                           null,   
                           null,   
                           machine,   
                           runtime,   
                           null,   
                           dropdead_datetime,   
                           null,   
                           '',   
                           null,   
                           setup_time,   
                           null,   
                           null,               /*changed from group_technology to null as column width was not same and causing problem to run cop*/  
                           null,   
                           null,   
                           null,   
                           null,   
                           'S',   
                           null,   
                           null,   
                           process_id,   
                           null,   
                           null,   
                           0,   
                           due_datetime,   
                           dropdead_datetime,   
                           new_row_id,   
                           0,   
                           null,   
                           null,   
                           null,   
                           null,   
                           null,   
                           null,   
                           week_no,
                           @plant,
                           @ship_type
                        from #bom_info
select part, bom_level from #bom_info
                        update  order_detail                    /* set order detail COP flag */
                           set  flag = 0  
                         where  order_detail.order_no = @order_no  
                           and  order_detail.row_id = @row_id

                commit transaction                              /* commit transaction */

                set rowcount 1

                delete
                  from  #order_detail
                 where  #order_detail.order_no = @order_no
                   and  #order_detail.row_id = @row_id

                select  @part_number = part_number,             /* get next order detail */
                        @std_qty = std_qty,
                        @due_date = due_date,
                        @order_no = order_no,
                        @row_id = row_id,
                        @ship_type = ship_type,
                        @plant = plant
                  from  #order_detail
              order by  part_number

        end

        set rowcount 0                                          /* assign mps quantities */

        begin transaction                                       /* begin transaction */
                if exists (select 1 where @a_order_no is null) 
                        insert  #mps_temp (part, plant)         /* get distinct mps plant,parts */
                        select  distinct part, plant
                          from  master_prod_sched
                      order by  plant, part
                else
                        insert  #mps_temp (part, plant)         /* get distinct mps plant,parts */
                        select  distinct part, @plant
                          from  #bom_info
                      order by  part

                set rowcount 1                                  /* setup poor man's cursor */

                select  @part_number = part,                    /* get distinct mps plant,part */
                        @plant = plant
                  from  #mps_temp
              order by  plant, part

                while @@rowcount > 0                            /* loop for each distinct plant,part */
                begin

                        set rowcount 0
                                                                /* get po and wo qty w/ null plant */
                                update  master_prod_sched       /* zero mps assigned quantities */
                                   set  qty_assigned = 0
                                 where  part = @part_number

                                select  @assign_qty = sum(pod.standard_qty)
                                  from  po_detail pod
                                 where  pod.part_number = @part_number
                                   and  pod.status <> 'C'

                                select  @assign_qty_wo = sum(wod.qty_required)
                                  from  workorder_detail wod
                                 where  wod.part = @part_number
                        
                                                                /* sum quantities */
                        select @assign_qty = isnull(@assign_qty,0) + isnull(@assign_qty_wo,0)

                        /* get mps plant,parts */
			/* modified insert statement to get id also which is a part of pk - mb */

                        insert  #mps_assign (part, due, source, origin, qnty, id)
                        select  part, due, source, origin, qnty, id
                          from  master_prod_sched
                         where  part = @part_number

                        set rowcount 1                          /* setup poor man's cursor */

			/* modified insert statement to get id also which is a part of pk - mb */
                        select  @due = due,                     /* get mps plant,part */
                                @source = source,
                                @origin = origin,
                                @qnty   = qnty,
                                @id     = id
                          from  #mps_assign
                         where  part = @part_number
	                      order by  due

                        select  @qty_left = @assign_qty
                                                                /* loop for each mps plant,part */
                        while (@@rowcount > 0) and (@qty_left > 0)
                        begin
                                set rowcount 0

                                if @qty_left > @qnty    /* assign qty from oldest to newest */
                                begin

					/* included id in where clause which is a part of pk - mb */
                                        update  master_prod_sched
                                           set  qty_assigned = @qnty
                                         where  part = @part_number
                                           and  source = @source
                                           and  origin = @origin
                                           and  due = @due
                                           and  id = @id

                                        select  @qty_left = @qty_left - @qnty
                                end
                                else
                                begin

					/* included id in where clause which is a part of pk - mb */
                                        update  master_prod_sched
                                           set  qty_assigned = @qty_left
                                         where  part = @part_number
                                           and  source = @source
                                           and  origin = @origin
                                           and  due = @due
                                           and  id = @id

                                        select  @qty_left = 0
                                end                             

                                set rowcount 1

                                delete  from #mps_assign
                                 where  part = @part_number
                                   and  source = @source
                                   and  origin = @origin
	              and  due = @due	
	              and id = @id

                                select  @due = due,             /* get next mps plant, part */
                                        @source = source,
                                        @origin = origin,
                                        @qnty = qnty,
                                        @id     = id
                                  from  #mps_assign
                                 where  part = @part_number
                              order by  due
                                
                        end

                        set rowcount 0

                        delete  from #mps_assign

                        select  @assign_qty = 0

                        set rowcount 1

                        delete  from #mps_temp
                         where  part = @part_number

                        select  @part_number = part,            /* get next distinct mps plant,part */
                                @plant = plant
                          from  #mps_temp
                      order by  plant, part

                end

        set rowcount 0

        commit transaction                                      /* commit transaction */


        drop table #mps_temp                                    /* clean-up */

        drop table #mps_assign 
return
GO
