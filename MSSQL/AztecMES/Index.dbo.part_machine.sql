create index ix_part_machine_1 on dbo.part_machine (part, machine, sequence)
create index ix_part_machine_2 on dbo.part_machine (machine, part, sequence)

create index XRt_3 on FT.XRt (ChildPart, Sequence, TopPart) include (BOMLevel)
create index XRt_4 on FT.XRt (Sequence, TopPart, ChildPart) include (BOMLevel)