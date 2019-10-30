Use AdventureWorks;
GO
 
DROP PROCEDURE IF EXISTS dbo.CalcSalesPerformance;
GO


-- you can call your  python script from within a stored procedure 
-- and interact with your colleagues who don't use Python or its packages ;-)

CREATE PROCEDURE dbo.CalcSalesPerformance
AS
  SET NOCOUNT ON;
  
DECLARE @pyscript NVARCHAR(MAX);

SET @pyscript = N'
df = SqlInputData
newdf = df.groupby("Territories", as_index=False).sum()
newdf[''Target'']="In line"
newdf[''Target''][newdf[''Sales''] < 6500000]="Below target"
newdf[''Target''][newdf[''Sales''] > 10000000]="Above all expectations"
PythonOutput = newdf ';

DECLARE @sqlscript NVARCHAR(MAX);
SET @sqlscript = N'
  SELECT t.Name AS Territories, CAST(h.Subtotal AS FLOAT) AS Sales
  FROM Sales.SalesOrderHeader h INNER JOIN Sales.SalesTerritory t
      ON h.TerritoryID = t.TerritoryID;';
 
-- unleash the python, the pandas, the full zoo
EXEC sp_execute_external_script
  @language = N'Python',
  @script = @pyscript,
  @input_data_1_name = N'SqlInputData',
  @output_data_1_name = N'PythonOutput',
  @input_data_1 = @sqlscript
   WITH RESULT SETS(
    ([Geographical Area] NVARCHAR(50), [Sales Revenue] MONEY, [Target] NVARCHAR(25) )); 
GO

exec dbo.CalcSalesPerformance;
GO

