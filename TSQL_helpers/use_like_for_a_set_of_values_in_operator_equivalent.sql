--table people w/ field:
-- firstname  lastname
--  don  osborne
--  donald duck
-- fred osborne
-- frederic kludge
-- freda kahlo
-- abraham lincoln
-- ronald reagan
-- ..
DECLARE  @Names TABLE (name varchar(40))

INSERT  
INTO @Names(name)
SELECT firstname
  FROM people
WHERE lastname = 'osborne' 

SELECT [a].[firstname]
	, LASTNAME
 FROM  people as p
 JOIN @Names as n on p.firstname like n.NAME+'%'
 ORDER BY [a].[firstname]
