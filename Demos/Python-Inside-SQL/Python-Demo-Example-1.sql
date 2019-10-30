Use AdventureWorks;
GO
 
-- define Python script
DECLARE @pyscript NVARCHAR(MAX);

-- InputDataSet is the default name of the input parameter
-- OutputDataSet is the default name of the output parameter
-- we just copy the data without doing anything
SET @pyscript = N'
df = InputDataSet
OutputDataSet = df';
 
-- THe query which will be put in  'InputDataSet'
-- (T-SQL) --> python
-- NVARCHAR -->  str
-- MONEY --> does not exist, hence the FLOAT cast
-- FLOAT --> float64

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
  @input_data_1 = @sqlscript;    
GO

-- note that we used SELECT .. AS to name the columns but they are not
-- transferred to Python

