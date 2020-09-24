-- PRODUCT_ID
-- 0000786867 -> 786867
-- 0000007898 -> 7898
-- 0000000000 -> 0
-- 1000078979 -> 1000078979
SELECT SUBSTRING([PRODUCT_ID], PATINDEX('%[^0]%',[PRODUCT_ID]+'.'), LEN([PRODUCT_ID])) AS PRODUCT_ID
FROM mytable