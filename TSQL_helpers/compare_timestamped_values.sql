-- Having a table with columns
-- id: a unique field IDing an object
-- name a friendly named linked to the ID (optional)
-- data_value: the data value your recording for the unique_object_id over time
-- recorded_at_utc : your date time field (optionally in UTC) acting as timestamp
-- e.g.
-- ID       Name    recorded_at_utc   data_value
-- 5       Tagada   2019-10-01 11:03         50
-- 5       Tagada   2019-10-02 00:04         15
-- 5       Tagada   2019-10-02 00:17         25
-- 5       Tagada   2019-10-03 01:03         17
-- 5       Tagada   2019-10-03 14:03         28
-- 4       Ours     2019-10-01 11:03         89
-- 4       Ours     2019-10-02 00:04         7
-- 4       Ours     2019-10-02 00:17         5
-- 4       Ours     2019-10-03 01:03         7
-- 4       Ours     2019-10-03 14:03         89


-- get the earliest and latest values for each object ID
SELECT DISTINCT id,name,
first_value(data_value) OVER (PARTITION BY id ORDER BY recorded_at_utc DESC) as latest_value,
max(recorded_at_utc) over (partition by id) AS latest_timestamp,
first_value(data_value) OVER (PARTITION BY job_id ORDER BY recorded_at_utc ASC) as earliest_value,
min(recorded_at_utc) over (partition by id) AS earliest_timestamp,
CASE 
 WHEN first_value(data_value) OVER (PARTITION BY id ORDER BY recorded_at_utc DESC) <> first_value(data_value) OVER (PARTITION BY id ORDER BY recorded_at_utc ASC)
     THEN 1
 ELSE 
 0
END AS Has_Changed
FROM table_foobar
