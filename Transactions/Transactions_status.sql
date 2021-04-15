select transaction_id, name, transaction_begin_time
,transaction_type
 ,case transaction_type 
    when 1 then 'Read/write transaction'
    when 2 then 'Read-only transaction'
    when 3 then 'System transaction'
    when 4 then 'Distributed transaction'
end as transaction_type_desc
,transaction_state
,case transaction_state 
    when 0 then 'transaction has not been completely initialized yet'
    when 1 then 'transaction has been initialized but has not started'
    when 2 then 'transaction is active'
    when 3 then 'transaction has ended. This is used for read-only transactions'
    when 4 then 'commit process has been initiated on the distributed transaction'
    when 5 then 'transaction is in a prepared state and waiting resolution'
    when 6 then 'transaction has been committed'
    when 7 then 'transaction is being rolled back'
    when 8 then 'transaction has been rolled back'
end as transaction_state_desc
,dtc_state
,case dtc_state 
    when 1 then '1 = ACTIVE'
    when 2 then '2 = PREPARED'
    when 3 then '3 = COMMITTED'
    when 4 then '4 = ABORTED'
    when 5 then '5 = RECOVERED'
end as dtc_state_desc
,transaction_status, transaction_status2,dtc_status, dtc_isolation_level, filestream_transaction_id
from sys.dm_tran_active_transactions
