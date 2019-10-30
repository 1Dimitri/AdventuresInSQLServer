Use AdventureWorks;
GO
 
-- define Python script
DECLARE @pyscript NVARCHAR(MAX);

-- Let's  name our parameters
SET @pyscript = N'
df = SqlInputData
PythonOutput = df';
 
DECLARE @sqlscript NVARCHAR(MAX);
SET @sqlscript = N'
  SELECT t.Name AS Territories, CAST(h.Subtotal AS FLOAT) AS Sales
  FROM Sales.SalesOrderHeader h INNER JOIN Sales.SalesTerritory t
      ON h.TerritoryID = t.TerritoryID;';
 
-- run procedure, it's Python, we passing the Python script and 
-- saying the input comes from the SQLscript
EXEC sp_execute_external_script
  @language = N'Python',
  @script = @pyscript,
  @input_data_1_name = N'SqlInputData',
  @output_data_1_name = N'PythonOutput',
  @input_data_1 = @sqlscript
   WITH RESULT SETS(
    ([Geographical Area] NVARCHAR(50), [Sales Revenue] MONEY)); 
GO

-- @nput_data_1_name names the 1st input parameter you'll get in the Python Script
-- With Result sets name the column in SQL Server, use [Name with space] syntax
