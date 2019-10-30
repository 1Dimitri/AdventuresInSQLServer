Use AdventureWorks;
GO
 
DECLARE @pyscript NVARCHAR(MAX);

-- Let's demonstrate you're really have pandas available

SET @pyscript = N'
df = SqlInputData
PythonOutput = df.groupby("Territories", as_index=False).sum()';
 
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
    ([Geographical Area] NVARCHAR(50), [Sales Revenue] MONEY)); 
GO
