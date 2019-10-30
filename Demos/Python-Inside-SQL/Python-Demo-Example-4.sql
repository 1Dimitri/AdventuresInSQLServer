Use AdventureWorks;
GO
 
DECLARE @pyscript NVARCHAR(MAX);

-- let's show how to create data within pandas and get it back in SQL Server

-- within the pandas frame, you use the column names defined in the T-SQL Script
-- Sales, Territories, etc.

-- this is noticeable in the pandas syntax
-- newdf['New Column Name'][Pandas_Criteria] = Value_For_the_New_column_and_that_panda_row
SET @pyscript = N'
df = SqlInputData
newdf = df.groupby("Territories", as_index=False).sum()
newdf[''Target'']="In line"
newdf[''Target''][newdf[''Sales''] < 6500000]="Below target"
newdf[''Target''][newdf[''Sales''] > 10000000]="Above all expectations"
PythonOutput = newdf ';

DECLARE @sqlscript NVARCHAR(MAX);
SET @sqlscript = N'
  SELECT t.Name AS Territories, CAST(h.Subtotal AS INT) AS Sales
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
    ([Geographical Area] NVARCHAR(50), [Sales Revenue] INT, [Target] NVARCHAR(25) )); 
GO

-- We had to modify the RESULT SETS for the new  column created within the Pandas Frame