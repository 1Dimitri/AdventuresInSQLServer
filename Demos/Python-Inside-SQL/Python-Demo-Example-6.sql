Use AdventureWorks;
GO
 
DROP PROCEDURE IF EXISTS dbo.CalcSalesParamPerformance;
GO


-- you can call your  python script from within a PARAMETERIZED stored procedure 
-- and fulfill your boss' wishes

-- note how the parameters are named differently at the T-SQL Stored Procedure
-- and within Python

CREATE PROCEDURE dbo.CalcSalesParamPerformance
 (@lowThreshold FLOAT, @highThreshold FLOAT)
AS
  SET NOCOUNT ON;
  
DECLARE @pyscript NVARCHAR(MAX);

SET @pyscript = N'
df = SqlInputData
newdf = df.groupby("Territories", as_index=False).sum()
newdf[''Target'']="In line"
newdf[''Target''][newdf[''Sales''] < LowerBound]="Below target"
newdf[''Target''][newdf[''Sales''] > UpperBound]="Above all expectations"
PythonOutput = newdf ';

DECLARE @sqlscript NVARCHAR(MAX);
SET @sqlscript = N'
  SELECT t.Name AS Territories, CAST(h.Subtotal AS FLOAT) AS Sales
  FROM Sales.SalesOrderHeader h INNER JOIN Sales.SalesTerritory t
      ON h.TerritoryID = t.TerritoryID;';
 
-- unleash the python
-- parameters are then
-- @params define your names in Python
-- @NameInPython = @NameInSQL

 EXEC sp_execute_external_script
  @language = N'Python',
  @script = @pyscript,
  @input_data_1_name = N'SqlInputData',
  @output_data_1_name = N'PythonOutput',
  @input_data_1 = @sqlscript,
  @params = N'@LowerBound FLOAT, @UpperBound FLOAT',
  @LowerBound = @lowThreshold,
  @UpperBound = @highThreshold

 WITH RESULT SETS(
    ([Geographical Area] NVARCHAR(50), [Sales Revenue] MONEY, [Target] NVARCHAR(25) ));  
GO

exec dbo.CalcSalesParamPerformance @lowThreshold = 6500000, @highThreshold= 10000000;
GO

