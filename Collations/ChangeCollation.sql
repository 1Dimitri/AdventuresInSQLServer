
-- this is the script at:
-- https://gallery.technet.microsoft.com/scriptcenter/Column-Collation-Changer-34321eaa

IF OBJECT_ID('ChangeCollation_SP','P') IS NOT NULL
	DROP PROC ChangeCollation_SP
GO

CREATE PROCEDURE ChangeCollation_SP
 @ToCollation				SYSNAME
,@TableName					SYSNAME			= ''
,@ColumnName				SYSNAME			= ''
,@SchemaName				SYSNAME			= ''
,@FromCollation				SYSNAME			= ''
,@GenerateScriptsOnly		BIT				= 1


AS

/*
Parameters
@ToCollation				- To which collation columns needs to be moved
@Tablename					- TableName for which the collation needs to be changed.
							  Default value is '' and all the tables will be considered for changing the collation.
@ColumnName					- ColumnName for which the collation needs to be changed.
							  Default value is '' and all the columns will be considered for changing the collation.
@SchemaName					- SchemaName for which the collation needs to be changed.
							  Default value is '' and all the columns will be considered for changing the collation.
@FromCollation				- The columns with which collation needs to be changed to the To collation.
							  Default value is '' and all the columns with all collation will be considered for changing the collation.
@GenerateScriptsOnly		- Generates the scripts only for changing the collation.
							  Default value is 1 and generates only script. When changed to 0 the collation change will be applied
							  
*/

	SET NOCOUNT ON


  
  DECLARE @DBName		SYSNAME
  DECLARE @SchemaID	    INT
  DECLARE @TableID	    INT
  DECLARE @IndexID	    INT
  DECLARE @isPrimaryKey BIT
  DECLARE @IndexType	INT
  
  DECLARE @CreateSQL	VARCHAR(MAX)
  DECLARE @IndexColsSQL VARCHAR(MAX)
  DECLARE @WithSQL VARCHAR(MAX)
  DECLARE @IncludeSQL VARCHAR(MAX)
  DECLARE @WhereSQL	  VARCHAR(MAX)
  
  DECLARE @SQL		VARCHAR(MAX)
  DECLARE @DropSQL		VARCHAR(MAX)
  DECLARE @ExistsSQL		VARCHAR(MAX)
  DECLARE @IndexName	SYSNAME
  DECLARE @TblSchemaName SYSNAME


    IF OBJECT_ID('#ChangeCollationTables','U') IS NOT NULL
	BEGIN
		DROP TABLE #ChangeCollationTables
	END
	
	CREATE TABLE #ChangeCollationTables
	(
		 SchemaID		INT
		,SchemaName		SYSNAME
		,TableID		INT
		,TableName		SYSNAME
		,Processed 		BIT
		,RunRank		INT   NULL
	)

	IF OBJECT_ID('#ChangeCollationColumns','U') IS NOT NULL
	BEGIN
		DROP TABLE #ChangeCollationColumns
	END
	
	CREATE TABLE #ChangeCollationColumns
	(
		 SchemaID		INT
		,SchemaName		SYSNAME
		,TableID		INT
		,TableName		SYSNAME
		,ColumnID		INT
		,CoumnName		SYSNAME
		,AlterScript	VARCHAR(MAX)	NULL
	)

	IF OBJECT_ID('#ChangeCollationObjectsBackupTbl','U') IS NOT NULL
	BEGIN
		DROP TABLE #ChangeCollationObjectsBackupTbl
	END
	
	CREATE TABLE #ChangeCollationObjectsBackupTbl
	(
		 BackupID		INT IDENTITY(1,1)
		,SchemaID		INT
		,TableID		INT
		,ObjectName		SYSNAME
		,ObjectType		VARCHAR(50)
		,CreateScript	VARCHAR(MAX)	NULL
		,DropScript		VARCHAR(MAX)	NULL
		,ExistsScript	VARCHAR(MAX)    NULL
		,Processed		BIT				NULL
	)


---------------------------------------------------------------------------------------------------------------------------
-- Get List of columns needs the collation to be changed
---------------------------------------------------------------------------------------------------------------------------

	INSERT INTO #ChangeCollationColumns
	(SchemaID,SchemaName,TableID,TableName,ColumnID,CoumnName,AlterScript)
	SELECT SCH.schema_id
		  ,SCH.name
		  ,ST.Object_id
		  ,ST.name
		  ,SC.column_id
		  ,SC.name
		  ,'ALTER TABLE ' + QUOTENAME(SCH.Name) + '.' + QUOTENAME(ST.name) 
		    + ' ALTER COLUMN ' + QUOTENAME(sc.name) + '  '
			+ STY.name +
			+ CASE 
			  WHEN STY.NAME IN ('char','varchar','nchar','nvarchar') AND SC.max_length = -1 THEN '(max)'
			  WHEN STY.NAME IN ('char','varchar') AND SC.max_length <> -1 THEN  '(' + CONVERT(VARCHAR(5),SC.max_length) + ')'
			  WHEN STY.NAME IN ('nchar','nvarchar') AND SC.max_length <> -1 THEN '(' + CONVERT(VARCHAR(5),SC.max_length/2) + ')'
			  ELSE ''
			  END
			+ ' COLLATE ' + @ToCollation 
			+ CASE SC.is_nullable
			  WHEN 0 THEN ' NOT NULL'
			  ELSE ' NULL'
			  END
      FROM SYS.TABLES  ST
	  JOIN SYS.SCHEMAS SCH
		ON SCH.schema_id = ST.schema_id
	  JOIN SYS.COLUMNS SC
		ON SC.object_id = ST.object_id
	  JOIN SYS.TYPES STY
	    ON STY.system_type_id = SC.system_type_id
	   AND STY.user_type_id	  = SC.user_type_id
	 WHERE SCH.Name = CASE 
					  WHEN @SchemaName = '' THEN SCH.name
					  ELSE @SchemaName
					  END
	   AND ST.Name  = CASE 
					  WHEN @TableName = '' THEN ST.name
					  ELSE @TableName
					  END
	   AND SC.name	= CASE 
					  WHEN @ColumnName = '' THEN SC.name
					  ELSE @ColumnName
					  END
	   AND SC.collation_name = CASE 
							   WHEN @FromCollation = '' THEN SC.collation_name
							   ELSE @FromCollation
							   END
	   AND STY.name in ('char', 'varchar', 'text', 'nchar', 'nvarchar', 'ntext')
	   AND Sc.is_computed = 0
	   
	   
-----------------------------------------------------------------------------------------------------------------------------
-- Get the list of tables need to be processed 
-----------------------------------------------------------------------------------------------------------------------------

	INSERT INTO #ChangeCollationTables
	SELECT  DISTINCT SchemaID
			,SchemaName
			,TableID
			,TableName
			,convert(bit,0) as Processed
			,0 as RunRank
	FROM #ChangeCollationColumns;


----------------------------------------------------------------------------------------------------------------------------
-- Order by foreignkey
-----------------------------------------------------------------------------------------------------------------------------

WITH fkey (ReferencingObjectid,ReferencingSchemaid,ReferencingTablename,PrimarykeyObjectid,PrimarykeySchemaid,PrimarykeyTablename,level)AS
	(
		SELECT 		DISTINCT		 
							   convert(int,null)
							  ,convert(INT,null)
							  ,convert(sysname,null)
							  ,ST.object_id
							  ,ST.schema_id
							  ,ST.name
							  ,0 as level
							  
		FROM SYS.TABLES ST
   LEFT JOIN sys.foreign_keys SF
		  ON SF.parent_object_id = ST.object_id
	   WHERE SF.object_id IS NULL
	   UNION ALL
	  SELECT 				  STP.object_id
							 ,STP.schema_id
							 ,STP.name
							 ,STC.object_id
							 ,STC.schema_id
							 ,STC.name
							  ,f.level+1 as level
							  
		FROM SYS.foreign_keys SFK
		JOIN fkey f
		  ON SFK.referenced_object_id = ISNULL(F.ReferencingObjectid,  f.PrimarykeyObjectid)
		JOIN SYS.tables STP
		  ON STP.object_id  = SFK.parent_object_id
		JOIN SYS.tables STC
		  ON STC.object_id  = SFK.referenced_object_id
		  
	  )

	  
	  UPDATE CT
	     SET RunRank = F.Lvl 
	    FROM #ChangeCollationTables CT
		JOIN
		(
		  SELECT TableId = ISNULL(ReferencingObjectid,PrimarykeyObjectid)
				 , Lvl = MAX(Level)
			FROM fkey
			GROUP BY ISNULL(ReferencingObjectid,PrimarykeyObjectid)
		) F
		ON F.TableId = CT.TableID


---------------------------------------------------------------------------------------------------------------------------
-- Backup Views
---------------------------------------------------------------------------------------------------------------------------
	INSERT INTO #ChangeCollationObjectsBackupTbl
	(SchemaID, TableID, ObjectName, ObjectType, CreateScript, DropScript, ExistsScript, Processed)
	SELECT SchemaID, TableID, ObjectName, ObjectType, CreateScript, DropScript, ExistsScript, Processed
	 FROM
	(
		SELECT SchemaID=SV.Schema_ID
			  ,TableID= X.referenced_major_id 
			  ,ObjectName=SV.Name
			  ,ObjectType='View'
			  ,CreateScript=definition
			  ,DropScript='DROP VIEW ' + QUOTENAME(SCH.Name) + '.' + QUOTENAME(SV.Name)
			  ,ExistsScript=' EXISTS (SELECT 1 
						   FROM SYS.Views SV
						   JOIN SYS.Schemas SCH
							 ON SV.Schema_id = SCH.Schema_ID
						  WHERE SV.Name =''' + SV.Name + '''
							AND SCH.Name =''' + SCH.Name + ''')'
			  ,Processed=0
			  ,Rnk = Rank() Over(Partition by SV.Name order by X.referenced_major_id)
		  FROM sys.views SV
		  JOIN sys.sql_modules SQM
			ON SV.object_id = SQM.object_id
		  JOIN
			(
				SELECT DISTINCT SD.object_id,SD.referenced_major_id
				  FROM sys.sql_dependencies SD
				  JOIN sys.objects SO
					ON SD.referenced_major_id = so.object_id
				  JOIN sys.columns SC
					ON SC.object_id = so.object_id
				   AND SC.column_id = sd.referenced_minor_id
				  JOIN #ChangeCollationColumns CCC
					ON SC.column_id = CCC.ColumnID
				   AND SO.object_id  = CCC.TableID
				   AND SO.schema_id	 = CCC.SchemaID

			) x
			ON X.object_id = SV.object_id
		  JOIN sys.Schemas SCH
			ON SCH.Schema_id = SV.Schema_id
		) Vie
		WHERE Vie.Rnk = 1

	
	

---------------------------------------------------------------------------------------------------------------------------
-- Backup Computed Columns
---------------------------------------------------------------------------------------------------------------------------
	
	INSERT INTO #ChangeCollationObjectsBackupTbl
	(SchemaID, TableID, ObjectName, ObjectType, CreateScript, DropScript, ExistsScript, Processed)
	SELECT CCC.SchemaID 
		  ,CCC.TableID
		  ,SCC.Name
		  ,'ComputedColumn'
		  ,'ALTER TABLE ' + QUOTENAME(CCC.SchemaName) + '.' + QUOTENAME(CCC.TableName) + 
		   ' ADD  ' + QUOTENAME(SCC.Name) + ' as ' + scc.definition
		  ,'ALTER TABLE ' + QUOTENAME(CCC.SchemaName) + '.' + QUOTENAME(CCC.TableName) + 
		   ' DROP COLUMN  ' + QUOTENAME(SCC.Name) 
		  ,'EXISTS (SELECT 1 
					  FROM SYS.computed_columns SCC
					  JOIN SYS.tables ST
						ON ST.object_id = SCC.object_id
					  JOIN SYS.Schemas SCH
					    ON ST.schema_id = SCH.schema_id
					  WHERE SCC.NAME =''' + SCC.NAME  + '''
					    AND ST.NAME  =''' + CCC.TableName + '''
						AND SCH.NAME =''' + CCC.SchemaName + ''')'
		  ,0
	  FROM SYS.computed_columns SCC
	  JOIN #ChangeCollationTables CCC
	    ON SCC.object_id = CCC.TableID
	  JOIN SYS.tables ST
	    ON ST.object_id = CCC.TableID
	   AND ST.schema_id = CCC.SchemaID

	   


-----------------------------------------------------------------------------------------------------------------------------
-- Backup Statistics
-----------------------------------------------------------------------------------------------------------------------------

	INSERT INTO #ChangeCollationObjectsBackupTbl
		(SchemaID, TableID, ObjectName, ObjectType, CreateScript, DropScript, ExistsScript, Processed)
	SELECT CCC.SchemaID
		  ,CCC.TableID
		  ,STA.name
		  ,'Statistics'
		  ,NULL
		  ,'DROP STATISTICS' + QUOTENAME(CCC.SchemaName) + '.' + QUOTENAME(CCC.TableName) + '.' + QUOTENAME(STA.Name)
		  ,' EXISTS ( SELECT * FROM SYS.STATS WHERE NAME = ''' + STA.name + ''' AND OBJECT_ID = ' + CONVERT(VARCHAR(50),STA.object_id) + ')'
		  , 0
	  FROM sys.stats_columns STAC
	  JOIN #ChangeCollationColumns CCC
		ON STAC.object_id = CCC.TableID 
	   AND STAC.column_id = CCC.ColumnID
	  JOIN SYS.stats STA
		ON STA.stats_id    = STAC.stats_id
	   AND STA.object_id	  = STAC.object_id


---------------------------------------------------------------------------------------------------------------------------
-- Backup Indexes
---------------------------------------------------------------------------------------------------------------------------
	IF OBJECT_ID('#CollationIDXTable','U') IS NOT NULL
	BEGIN

		DROP TABLE #CollationIDXTable
	END

		CREATE TABLE #CollationIDXTable 
		(
			 Schema_ID		INT
			,Object_ID		INT
			,Index_ID		INT
			,SchemaName		SYSNAME
			,TableName		SYSNAME
			,IndexName		SYSNAME
			,IsPrimaryKey   BIT
			,IndexType		INT
			,CreateScript	VARCHAR(MAX)	NULL
			,DropScript		VARCHAR(MAX)	NULL
			,ExistsScript	VARCHAR(MAX)    NULL
			,Processed		BIT				NULL
		)
	
	INSERT INTO [dbo].[#CollationIDXTable]
		(
		 Schema_ID		
		,Object_ID		
		,Index_ID		
		,SchemaName		
		,TableName		
		,IndexName		
		,IsPrimaryKey  
		,IndexType 
		)
	SELECT DISTINCT ST.Schema_id
		  ,ST.Object_id
		  ,SI.Index_id
		  ,SCH.Name
		  ,ST.Name
		  ,SI.Name
		  ,SI.is_primary_key
		  ,SI.Type
      FROM SYS.INDEXES SI
	  JOIN SYS.TABLES  ST
		ON SI.Object_ID = ST.Object_ID
	  JOIN SYS.SCHEMAS SCH
		ON SCH.schema_id = ST.schema_id
	  JOIN SYS.INDEX_COLUMNS SIC
  	    ON SIC.OBJECT_ID = SI.Object_ID
	   AND SIC.Index_ID  = SI.Index_ID
	   --AND SIC.is_included_column = 0
	  JOIN #ChangeCollationColumns CCC
	    ON SIC.column_id = CCC.ColumnID
	   AND ST.object_id  = CCC.TableID
	   AND ST.schema_id	 = CCC.SchemaID
	  WHERE SI.Type IN (1,2)
	  
	UNION
	SELECT DISTINCT ST.Schema_id
		  ,ST.Object_id
		  ,SI.Index_id
		  ,SCH.Name
		  ,ST.Name
		  ,SI.Name
		  ,SI.is_primary_key
		  ,SI.Type
      FROM SYS.INDEXES SI
	  JOIN SYS.TABLES  ST
		ON SI.Object_ID = ST.Object_ID
	  JOIN SYS.SCHEMAS SCH
		ON SCH.schema_id = ST.schema_id
	  JOIN SYS.INDEX_COLUMNS SIC
  	    ON SIC.OBJECT_ID = SI.Object_ID
	   AND SIC.Index_ID  = SI.Index_ID
	   --AND SIC.is_included_column = 0
	  JOIN #ChangeCollationTables CCC
	    ON ST.object_id  = CCC.TableID
	   AND ST.schema_id	 = CCC.SchemaID
	  JOIN SYS.columns   SC
	    ON SC.object_id  = CCC.TableID
	   AND SC.column_id  = SIC.column_id
	   AND SC.is_computed = 1
	  WHERE SI.Type IN (1,2)
  
  
  
  SELECT @CreateSQL = '' 
  SELECT @IndexColsSQL = '' 
  SELECT @WithSQL = '' 
  SELECT @IncludeSQL = '' 
  SELECT @WhereSQL = '' 
  
  
    WHILE EXISTS(SELECT 1
				   FROM [dbo].[#CollationIDXTable]
				  WHERE CreateScript IS NULL)
	BEGIN
	
		SELECT TOP 1 @SchemaID = Schema_ID
			  ,@TableID  = Object_ID
			  ,@IndexID  = Index_ID
			  ,@isPrimaryKey = IsPrimaryKey
			  ,@IndexName	 = IndexName
			  ,@IndexType	 = IndexType
			  ,@SchemaName	 = SchemaName
			  ,@TableName	 = TableName
		  FROM [dbo].[#CollationIDXTable]
		 WHERE CreateScript IS NULL
		   --AND SchemaName = @SchemaName
		   --AND TableName  = @TableName
		 ORDER BY Index_ID
	
		SELECT @TblSchemaName = QUOTENAME(@Schemaname) + '.' + QUOTENAME(@TableName)
		 
		IF @isPrimaryKey = 1
		BEGIN
		
		    SELECT @ExistsSQL = ' EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N''' + @TblSchemaName + ''') AND name = N''' + @IndexName + ''')' 
			
			SELECT @DropSQL =   ' ALTER TABLE '+ @TblSchemaName + ' DROP CONSTRAINT [' + @IndexName + ']'
		END
		ELSE
		BEGIN

		    SELECT @ExistsSQL = ' EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N''' + @TblSchemaName + ''') AND name = N''' + @IndexName + ''')' 
			SELECT @DropSQL =  ' DROP INDEX [' + @IndexName  + '] ON ' + @TblSchemaName + 
							  CASE 
							  WHEN @IndexType IN (1,2) THEN ' WITH ( ONLINE = OFF )'
							  ELSE ''
							  END
		END
		
		IF @IndexType IN (1,2)
		BEGIN
				SELECT @CreateSQL = CASE 
									WHEN SI.is_Primary_Key = 1 THEN 
										'ALTER TABLE ' + @TblSchemaName + ' ADD  CONSTRAINT [' + @IndexName + '] PRIMARY KEY ' + SI.type_desc
									WHEN SI.Type IN (1,2) THEN 
										' CREATE ' + CASE SI.is_Unique WHEN 1 THEN ' UNIQUE ' ELSE '' END + SI.type_desc + ' INDEX ' + QUOTENAME(SI.Name) + ' ON ' + @TblSchemaName
									END
					  ,@IndexColsSQL =  ( SELECT SC.Name + ' ' 
								 + CASE SIC.is_descending_key
								   WHEN 0 THEN ' ASC ' 
								   ELSE 'DESC'
								   END +  ','
							FROM SYS.INDEX_COLUMNS SIC
							JOIN SYS.COLUMNS SC
							  ON SIC.Object_ID = SC.Object_ID
							 AND SIC.Column_ID = SC.Column_ID
						  WHERE SIC.OBJECT_ID = SI.Object_ID
							AND SIC.Index_ID  = SI.Index_ID
							AND SIC.is_included_column = 0
						  ORDER BY SIC.Key_Ordinal
						   FOR XML PATH('')
						) 
						,@WithSQL =' WITH (PAD_INDEX  = ' + CASE SI.is_padded WHEN 1 THEN 'ON' ELSE 'OFF' END + ',' + CHAR(13) +
								   ' IGNORE_DUP_KEY = ' + CASE SI.ignore_dup_key WHEN 1 THEN 'ON' ELSE 'OFF' END + ',' + CHAR(13) +
								   ' ALLOW_ROW_LOCKS = ' + CASE SI.Allow_Row_Locks WHEN 1 THEN 'ON' ELSE 'OFF' END + ',' + CHAR(13) +
								   ' ALLOW_PAGE_LOCKS = ' + CASE SI.Allow_Page_Locks WHEN 1 THEN 'ON' ELSE 'OFF' END + ',' + CHAR(13) +
								   CASE SI.Type WHEN 2 THEN 'SORT_IN_TEMPDB = OFF,DROP_EXISTING = OFF,' ELSE '' END + 
								   CASE WHEN SI.Fill_Factor > 0 THEN ' FILLFACTOR = ' + CONVERT(VARCHAR(3),SI.Fill_Factor) + ',' ELSE '' END +
								   ' STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, ONLINE = OFF) ON ' + QUOTENAME(SFG.Name)
						,@IncludeSQL =  ( SELECT QUOTENAME(SC.Name) +  ','
											FROM SYS.INDEX_COLUMNS SIC
											JOIN SYS.COLUMNS SC
											  ON SIC.Object_ID = SC.Object_ID
											 AND SIC.Column_ID = SC.Column_ID
										  WHERE SIC.OBJECT_ID = SI.Object_ID
											AND SIC.Index_ID  = SI.Index_ID
											AND SIC.is_included_column = 1
										  ORDER BY SIC.Key_Ordinal
										   FOR XML PATH('')
										) 
						,@WhereSQL  = SI.Filter_Definition
				  FROM SYS.Indexes SI
				  JOIN SYS.FileGroups SFG
					ON SI.Data_Space_ID =SFG.Data_Space_ID
				 WHERE Object_ID = @TableID
				   AND Index_ID  = @IndexID
				   
				   SELECT @IndexColsSQL = '(' + SUBSTRING(@IndexColsSQL,1,LEN(@IndexColsSQL)-1) + ')'
				   
				   IF LTRIM(RTRIM(@IncludeSQL)) <> ''
						SELECT @IncludeSQL   = ' INCLUDE (' + SUBSTRING(@IncludeSQL,1,LEN(@IncludeSQL)-1) + ')'
				
				   IF LTRIM(RTRIM(@WhereSQL)) <> ''
					   SELECT @WhereSQL		= ' WHERE (' + @WhereSQL + ')'
		
		END
		
		
		   SELECT @CreateSQL = @CreateSQL 
							   + @IndexColsSQL + CASE WHEN @IndexColsSQL <> '' THEN CHAR(13) ELSE '' END
							   + ISNULL(@IncludeSQL,'') + CASE WHEN @IncludeSQL <> '' THEN CHAR(13) ELSE '' END
							   + ISNULL(@WhereSQL,'') + CASE WHEN @WhereSQL <> '' THEN CHAR(13) ELSE '' END 
							   + @WithSQL 

	
			UPDATE [dbo].[#CollationIDXTable]
			   SET CreateScript = @CreateSQL
			      ,DropScript   = @DropSQL
			      ,ExistsScript = @ExistsSQL
			 WHERE Schema_ID = @SchemaID
			   AND Object_ID = @TableID
			   AND Index_ID  = @IndexID
			   
	 END   


	 INSERT INTO #ChangeCollationObjectsBackupTbl
	(SchemaID, TableID, ObjectName, ObjectType, CreateScript, DropScript, ExistsScript, Processed)
	 SELECT Schema_ID,Object_ID,IndexName,'Index-' 
			+ CASE IndexType 
			  WHEN 1 THEN 'Clustered'
			  WHEN 2 THEN 'NonClustered'
			  ELSE ''
			  END
		   ,CreateScript, DropScript, ExistsScript, 0 
	   FROM [#CollationIDXTable]
	
	

-----------------------------------------------------------------------------------------------------------------------------
-- Backup Check Constraints
-----------------------------------------------------------------------------------------------------------------------------

INSERT INTO #ChangeCollationObjectsBackupTbl
	(SchemaID, TableID, ObjectName, ObjectType, CreateScript, DropScript, ExistsScript, Processed)
	SELECT CCC.SchemaID 
		  ,CCC.TableID
		  ,SCC.Name
		  ,'ComputedColumn'
		  ,'ALTER TABLE ' + QUOTENAME(CCC.SchemaName) + '.' + QUOTENAME(CCC.TableName) + 
		   ' ADD  CONSTRAINT  ' + QUOTENAME(SCC.Name) + ' CHECK ' + scc.definition
		  ,'ALTER TABLE ' + QUOTENAME(CCC.SchemaName) + '.' + QUOTENAME(CCC.TableName) + 
		   ' DROP CONSTRAINT  ' + QUOTENAME(SCC.Name) 
		  ,'EXISTS (SELECT 1 
					  FROM SYS.check_constraints SCC
					  JOIN SYS.tables ST
						ON ST.object_id = SCC.Parent_object_id
					  JOIN SYS.Schemas SCH
					    ON ST.schema_id = SCH.schema_id
					  WHERE SCC.NAME =''' + SCC.NAME  + '''
					    AND ST.NAME  =''' + CCC.TableName + '''
						AND SCH.NAME =''' + CCC.SchemaName + ''')'
		  ,0
	  FROM SYS.check_constraints SCC
	  JOIN #ChangeCollationTables CCC
	    ON SCC.Parent_object_id = CCC.TableID
	  JOIN SYS.tables ST
	    ON ST.object_id = CCC.TableID
	   AND ST.schema_id = CCC.SchemaID



-----------------------------------------------------------------------------------------------------------------------------
-- Backup Foreignkey Constraints
-----------------------------------------------------------------------------------------------------------------------------
	INSERT INTO #ChangeCollationObjectsBackupTbl
		(SchemaID, TableID, ObjectName, ObjectType, CreateScript, DropScript, ExistsScript, Processed)
	SELECT STP.schema_id
		  ,STP.object_id
		  ,SF.name
		  ,'Foreign Key'
		  ,' ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(STP.schema_id)) + '.' + QUOTENAME(STP.Name) 
		  +'  WITH CHECK ADD  CONSTRAINT ' + QUOTENAME(SF.Name) + ' FOREIGN KEY(' + 
		  STUFF
			(
			(
			SELECT ',' + QUOTENAME(sc.name)
			  FROM SYS.foreign_key_columns SFC
			  JOIN SYS.columns SC
				ON SC.object_id = SFC.parent_object_id
			   AND SC.column_id = SFC.parent_column_id
			 WHERE SFC.constraint_object_id = SF.object_id
			 ORDER BY SC.column_id
			 FOR XML PATH ('')
			 ),1,1,'') 
			 + ') REFERENCES ' + QUOTENAME(SCHEMA_NAME(STC.schema_id)) + '.' + QUOTENAME(STC.Name) 
			 + ' (' +
			 + STUFF
				(
				(
				SELECT ',' + QUOTENAME(sc.name)
				  FROM SYS.foreign_key_columns SFC
				  JOIN SYS.columns SC
					ON SC.object_id = SFC.referenced_object_id
				   AND SC.column_id = SFC.referenced_column_id
				 WHERE SFC.constraint_object_id = SF.object_id
				 ORDER BY SC.column_id
				 FOR XML PATH ('')
				 ),1,1,'')
			 + ')'

			 ,'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(STP.schema_id)) + '.' + QUOTENAME(STP.Name)  + ' DROP CONSTRAINT [' + SF.Name + ']'
			 ,' EXISTS ( SELECT 1 FROM SYS.FOREIGN_KEYS WHERE Name =''' + sf.name + ''' and parent_object_id = ' + CONVERT(varchar(50),SF.parent_object_id) + ')'
			 ,0
	  FROM SYS.foreign_keys SF
	  JOIN SYS.tables STP
		ON STP.object_id = SF.parent_object_id
	  JOIN SYS.tables STC
		ON STC.object_id = SF.referenced_object_id
	 WHERE EXISTS (
				   SELECT 1 
	                 FROM SYS.foreign_key_columns SFCIn
					 JOIN #ChangeCollationColumns CCC
					   ON SFCIn.parent_object_id = CCC.TableID
					  AND SFCIn.parent_column_id = CCC.ColumnID
					WHERE SFCIn.constraint_object_id = SF.object_id
				  )	

	UNION
	
	SELECT STP.schema_id
			  ,STP.object_id
			  ,SF.name
			  ,'Foreign Key'
			  ,' ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(STC.schema_id)) + '.' + QUOTENAME(STC.Name) 
			  +'  WITH CHECK ADD  CONSTRAINT ' + QUOTENAME(SF.Name) + ' FOREIGN KEY(' + 
			  STUFF
				(
				(
				SELECT ',' + QUOTENAME(sc.name)
				  FROM SYS.foreign_key_columns SFC
				  JOIN SYS.columns SC
					ON SC.object_id = SFC.parent_object_id
				   AND SC.column_id = SFC.parent_column_id
				 WHERE SFC.constraint_object_id = SF.object_id
				 ORDER BY SC.column_id
				 FOR XML PATH ('')
				 ),1,1,'') 
				 + ') REFERENCES ' + QUOTENAME(SCHEMA_NAME(STP.schema_id)) + '.' + QUOTENAME(STP.Name) 
				 + ' (' +
				 + STUFF
					(
					(
					SELECT ',' + QUOTENAME(sc.name)
					  FROM SYS.foreign_key_columns SFC
					  JOIN SYS.columns SC
						ON SC.object_id = SFC.referenced_object_id
					   AND SC.column_id = SFC.referenced_column_id
					 WHERE SFC.constraint_object_id = SF.object_id
					 ORDER BY SC.column_id
					 FOR XML PATH ('')
					 ),1,1,'')
				 + ')'

				 ,'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(STC.schema_id)) + '.' + QUOTENAME(STC.Name)  + ' DROP CONSTRAINT [' + SF.Name + ']'
				 ,' EXISTS ( SELECT 1 FROM SYS.FOREIGN_KEYS WHERE Name =''' + sf.name + ''' and parent_object_id = ' + CONVERT(varchar(50),SF.parent_object_id) + ')'
				 ,0
			  FROM SYS.foreign_keys SF
		  JOIN SYS.tables STP
			ON STP.object_id = SF.referenced_object_id
		  JOIN SYS.tables STC
			ON STC.object_id = SF.parent_object_id 
		 WHERE EXISTS (
					   SELECT 1 
						 FROM SYS.foreign_key_columns SFCIn
						 JOIN #ChangeCollationColumns CCC
						   ON SFCIn.referenced_object_id = CCC.TableID
						  AND SFCIn.referenced_column_id = CCC.ColumnID
						WHERE SFCIn.constraint_object_id = SF.object_id
					  )	


-----------------------------------------------------------------------------------------------------------------------------
-- Loop  through Tables to change Collation
-----------------------------------------------------------------------------------------------------------------------------
	DECLARE @BackupID int
	DECLARE @ObjectType VARCHAR(50)
	DECLARE @ObjectName SYSNAME


-----------------------------------------------------------------------------------------------------------------------------
-- Inner Loop  -- Drop the objects
-----------------------------------------------------------------------------------------------------------------------------


	UPDATE [dbo].[#ChangeCollationTables]
 	   SET Processed = 0
	 
	WHILE EXISTS(SELECT 1
				   FROM #ChangeCollationTables
				  WHERE ISNULL(Processed,0) = 0 
  		  		  )
	BEGIN
	
		SELECT @SQL = ''
	
		SELECT TOP 1 @SchemaID = SchemaID
			  ,@TableID		   = TableID
			  ,@TableName	   = TableName
			  ,@SchemaName	   = SchemaName
			  --,@SQL = 'IF ' + ExistsScript + CHAR(13) + DropScript + CHAR(13)
		  FROM [dbo].[#ChangeCollationTables]
		 WHERE ISNULL(Processed,0) = 0
		 ORDER BY Runrank DESC, SchemaID ASC,TableID ASC

		 

				UPDATE #ChangeCollationObjectsBackupTbl
				   SET Processed = 0 
				 WHERE SchemaID  = @SchemaID
				   AND TableID   = @TableID

		 
				WHILE EXISTS(SELECT 1
								FROM #ChangeCollationObjectsBackupTbl
								WHERE ISNULL(Processed,0) = 0 
								  AND SchemaID = @SchemaID
								  AND TableID  = @TableID
  		  						)
				BEGIN
	
					SELECT @SQL = ''
	
					SELECT TOP 1 @BackupID = BackupID
							,@ObjectName   = ObjectName
							,@ObjectType   = ObjectType
							,@SQL = 'IF ' + ExistsScript + CHAR(13) + DropScript + CHAR(13)
						FROM #ChangeCollationObjectsBackupTbl
						WHERE ISNULL(Processed,0) = 0
						  AND SchemaID = @SchemaID
						  AND TableID  = @TableID
						ORDER BY BackupID DESC
		 
						IF @GenerateScriptsOnly = 1
						BEGIN
							PRINT @sql
						END
						ELSE
						BEGIN
							
								PRINT @sql
							EXEC (@sql)
						END
		 
		
		 
						UPDATE #ChangeCollationObjectsBackupTbl
 						SET Processed = 1
						WHERE SchemaID	= @SchemaID
						AND TableID		= @TableID
						AND BackupID	= @BackupID
		    
				END

		 UPDATE [dbo].[#ChangeCollationTables]
 		    SET Processed = 1
		  WHERE SchemaID = @SchemaID
		    AND TableID = @TableID
	
	END 

	
 -----------------------------------------------------------------------------------------------------------------------------
-- Apply the collation changes
-----------------------------------------------------------------------------------------------------------------------------
	
	UPDATE [dbo].[#ChangeCollationTables]
 	   SET Processed = 0
	 
	WHILE EXISTS(SELECT 1
				   FROM #ChangeCollationTables
				  WHERE ISNULL(Processed,0) = 0 
  		  		  )
	BEGIN
	
		SELECT @SQL = ''
	
		SELECT TOP 1 @SchemaID = SchemaID
			  ,@TableID		   = TableID
			  ,@TableName	   = TableName
			  ,@SchemaName	   = SchemaName
			  --,@SQL = 'IF ' + ExistsScript + CHAR(13) + DropScript + CHAR(13)
		  FROM [dbo].[#ChangeCollationTables]
		 WHERE ISNULL(Processed,0) = 0
		 ORDER BY Runrank DESC, SchemaID ASC,TableID ASC


		SELECT @sQL = ''

		 SELECT @sQL = @sQL + AlterScript + CHAR(13)
		   FROM #ChangeCollationColumns
		  WHERE SchemaID = @SchemaID
		    AND TableID = @TableID
		 
		IF @GenerateScriptsOnly = 1
		BEGIN
			PRINT @sql
		END
		ELSE
		BEGIN
			PRINT @sql
							
			EXEC (@sql)
		END 
		

		 UPDATE [dbo].[#ChangeCollationTables]
 		    SET Processed = 1
		  WHERE SchemaID = @SchemaID
		    AND TableID = @TableID
	
	END 
		
		
-----------------------------------------------------------------------------------------------------------------------------
-- Inner Loop  -- ReApply the objects
-----------------------------------------------------------------------------------------------------------------------------

	UPDATE [dbo].[#ChangeCollationTables]
 	   SET Processed = 0
	 
	WHILE EXISTS(SELECT 1
				   FROM #ChangeCollationTables
				  WHERE ISNULL(Processed,0) = 0 
  		  		  )
	BEGIN
	
		SELECT @SQL = ''
	
		SELECT TOP 1 @SchemaID = SchemaID
			  ,@TableID		   = TableID
			  ,@TableName	   = TableName
			  ,@SchemaName	   = SchemaName
			  --,@SQL = 'IF ' + ExistsScript + CHAR(13) + DropScript + CHAR(13)
		  FROM [dbo].[#ChangeCollationTables]
		 WHERE ISNULL(Processed,0) = 0
		 ORDER BY Runrank asc, SchemaID ASC,TableID ASC

		 

				UPDATE #ChangeCollationObjectsBackupTbl
				   SET Processed = 0 
				 WHERE SchemaID  = @SchemaID
				   AND TableID   = @TableID

		 
		 
				WHILE EXISTS(SELECT 1
								FROM #ChangeCollationObjectsBackupTbl
								WHERE ISNULL(Processed,0) = 0 
								  AND SchemaID = @SchemaID
								  AND TableID  = @TableID
								  AND CreateScript IS NOT NULL
  		  						)
				BEGIN
	
					SELECT @SQL = ''
	
					SELECT TOP 1 @BackupID = BackupID
							,@ObjectName   = ObjectName
							,@ObjectType   = ObjectType
							,@SQL = CASE ObjectType
									WHEN 'View' THEN CreateScript + CHAR(13)
									ELSE 'IF NOT ' + ExistsScript + CHAR(13) + CreateScript + CHAR(13)
									END
						FROM #ChangeCollationObjectsBackupTbl
						WHERE ISNULL(Processed,0) = 0
						  AND SchemaID = @SchemaID
						  AND TableID  = @TableID
						  AND CreateScript IS NOT NULL
						ORDER BY BackupID ASC
		 
						IF @GenerateScriptsOnly = 1
						BEGIN
							PRINT @sql
						END
						ELSE
						BEGIN
							PRINT @sql
							EXEC (@sql)
						END
		 
		
		 
						UPDATE #ChangeCollationObjectsBackupTbl
 						SET Processed = 1
						WHERE SchemaID	= @SchemaID
						AND TableID		= @TableID
						AND BackupID	= @BackupID
		    
				END

			 UPDATE [dbo].[#ChangeCollationTables]
 				SET Processed = 1
			  WHERE SchemaID = @SchemaID
				AND TableID = @TableID
	
		END 
 
GO


						


