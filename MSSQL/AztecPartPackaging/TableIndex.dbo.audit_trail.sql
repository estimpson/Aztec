create index ix_AuditTrail_TypeSerialDateStampPart on dbo.audit_trail (type, serial, date_stamp, part)
create index ix_AuditTrail_TypeSerialDateStampFromLoc on dbo.audit_trail (type, serial, date_stamp, from_loc) include (std_quantity)
create index ix_AuditTrail_SerialDateStamp on dbo.audit_trail (serial, date_stamp) include (remarks, lot, shipper)
