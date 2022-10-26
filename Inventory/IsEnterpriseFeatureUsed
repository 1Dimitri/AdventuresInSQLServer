-- PRINT [cs_helper].[dbo].[IsEnterpriseFeatureUsed]()

CREATE FUNCTION [dbo].[IsEnterpriseFeatureUsed]()
RETURNS bit
AS
BEGIN
     DECLARE @r int
	 DECLARE @b bit

	 SELECT @r=COUNT(*) FROM sys.dm_db_persisted_sku_features
-- could typecast
	 SET @b=CASE @r WHEN
		0 THEN  0
		ELSE 1
		END
   RETURN @b
END
