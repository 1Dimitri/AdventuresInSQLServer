-- This is the script at:
-- https://gallery.technet.microsoft.com/determining-the-version-dbc1c53a

--------------------------------------------------------------------------------- 
-- The sample scripts are not supported under any Microsoft standard support 
-- program or service. The sample scripts are provided AS IS without warranty  
-- of any kind. Microsoft further disclaims all implied warranties including,  
-- without limitation, any implied warranties of merchantability or of fitness for 
-- a particular purpose. The entire risk arising out of the use or performance of  
-- the sample scripts and documentation remains with you. In no event shall 
-- Microsoft, its authors, or anyone else involved in the creation, production, or 
-- delivery of the scripts be liable for any damages whatsoever (including, 
-- without limitation, damages for loss of business profits, business interruption, 
-- loss of business information, or other pecuniary loss) arising out of the use 
-- of or inability to use the sample scripts or documentation, even if Microsoft 
-- has been advised of the possibility of such damages 

-- The script is not compatible with SQL Server 2000 and SQL Server 2005, please upgrade your SQL Server to newer edition.
--------------------------------------------------------------------------------- 

DECLARE @ProductVersion		NVARCHAR(20)
DECLARE @ProductLevel		NVARCHAR(20)
DECLARE @UpdateLevel		NVARCHAR(20)
DECLARE @UpdateRef			NVARCHAR(20)
DECLARE @UpdateRefOutput	NVARCHAR(200) = ''
DECLARE @Edition			NVARCHAR(100)

DECLARE @ProductName		NVARCHAR(30)
DECLARE @TheLastVersion		NVARCHAR(100)
DECLARE @OtherProduct		NVARCHAR(800)
DECLARE @SPInfo				NVARCHAR(400)
DECLARE @CUInfo				NVARCHAR(400)

DECLARE @CumulativeUpdate   NVARCHAR(20)
DECLARE @CumulativeUpdateKB NVARCHAR(100)
DECLARE @EditionID			sql_variant

DECLARE @ExtendedSupport	NVARCHAR(500)
DECLARE @MainSupportNonUpdate	NVARCHAR(500)
DECLARE @MainSupport		NVARCHAR(500)

DECLARE @2017E			NVARCHAR(50) = + CHAR(13) + 'SQL Server 2017 Enterprise'
DECLARE @2017BI			NVARCHAR(50) = + CHAR(13) + 'SQL Server 2017 Business Intelligence'
DECLARE @2017Std		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2017 Standard'
DECLARE @2017Web		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2017 Web'
DECLARE @2017Exp		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2017 Express'
DECLARE @2017Dev		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2017 Developer'																	
DECLARE @2017Eval		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2017 Evaluation'


DECLARE @2016E			NVARCHAR(50) = + CHAR(13) + 'SQL Server 2016 Enterprise'
DECLARE @2016BI			NVARCHAR(50) = + CHAR(13) + 'SQL Server 2016 Business Intelligence'
DECLARE @2016Std		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2016 Standard'
DECLARE @2016Web		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2016 Web'
DECLARE @2016Exp		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2016 Express'
DECLARE @2016Dev		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2016 Developer'																	
DECLARE @2016Eval		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2016 Evaluation'

DECLARE @2014E			NVARCHAR(50) = + CHAR(13) + 'SQL Server 2014 Enterprise'
DECLARE @2014BI			NVARCHAR(50) = + CHAR(13) + 'SQL Server 2014 Business Intelligence'
DECLARE @2014Std		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2014 Standard'
DECLARE @2014Web		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2014 Web'
DECLARE @2014Exp		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2014 Express'
DECLARE @2014Dev		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2014 Developer'																	

DECLARE @2012E			NVARCHAR(50) = + CHAR(13) + 'SQL Server 2012 Enterprise'
DECLARE @2012BI			NVARCHAR(50) = + CHAR(13) + 'SQL Server 2012 Business Intelligence'
DECLARE @2012Std		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2012 Standard'
DECLARE @2012Web		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2012 Web'
DECLARE @2012Exp		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2012 Express'
DECLARE @2012Dev		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2012 Developer'																		

DECLARE @2008R2E		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2008 R2 Enterprise'
DECLARE @2008R2Dat		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2008 R2 Datacenter'
DECLARE @2008R2Std		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2008 R2 Standard'
DECLARE @2008R2Wg		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2008 R2 Workgroup'
DECLARE @2008R2Dev		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2008 R2 Developer'																	
DECLARE @2008R2ExpAdv	NVARCHAR(50) = + CHAR(13) + 'SQL Server 2008 R2 Express with Advanced'

DECLARE @2008E			NVARCHAR(50) = + CHAR(13) + 'SQL Server 2008 Enterprise'
DECLARE @2008Std		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2008 Standard'
DECLARE @2008Wg			NVARCHAR(50) = + CHAR(13) + 'SQL Server 2008 Workgroup'
DECLARE @2008Dev		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2008 Developer'	
DECLARE @2008ExpAdv		NVARCHAR(50) = + CHAR(13) + 'SQL Server 2008 Express with Advanced'
								
SET @ExtendedSupport = 'Support Lifecycle stage: Extended Support Phase. For additional information refer to '
					    + CHAR(13) + 'https://support.microsoft.com/en-us/lifecycle/search?sort=PN&alpha=SQL%20Server&Filter=FilterNO, and Q6, Q18'
					    + CHAR(13) + 'in the FAQ section of Support Lifecycle page at: https://support.microsoft.com/en-us/lifecycle#gp/lifePolicy'

SET @MainSupportNonUpdate	 = 'Support Lifecycle stage: Mainstream Support Phase, however security/non-security updates are not available for' 
						+ CHAR(13) + 'current 2012 baseline. Upgrade to SP2 for security/Non-security updates. For additional information refer to:'
						+ CHAR(13) + 'https://support.microsoft.com/en-us/lifecycle/search?sort=PN&alpha=SQL%20Server&Filter=FilterNO, and Q6, Q18'
					    + CHAR(13) + 'in the FAQ section of Support Lifecycle page at: https://support.microsoft.com/en-us/lifecycle#gp/lifePolicy'

SET @MainSupport	 = 'Support Lifecycle stage: Mainstream Support Phase. For additional information refer to '
						+ CHAR(13) + 'https://support.microsoft.com/en-us/lifecycle/search?sort=PN&alpha=SQL%20Server&Filter=FilterNO, and Q6, Q18'
					    + CHAR(13) + 'in the FAQ section of Support Lifecycle page at: https://support.microsoft.com/en-us/lifecycle#gp/lifePolicy'

SET @EditionID			= SERVERPROPERTY('EditionID')
SET @ProductVersion		= CONVERT(NVARCHAR(20),SERVERPROPERTY('ProductVersion')) 
SET @ProductLevel		= CONVERT(NVARCHAR(20),SERVERPROPERTY('ProductLevel')) 
SET @UpdateLevel		= ISNULL(CONVERT(NVARCHAR(20),SERVERPROPERTY('ProductUpdateLevel')),'')
SET @UpdateRef			= ISNULL(CONVERT(NVARCHAR(20),SERVERPROPERTY('@UpdateRef')),'')
SET @Edition			= CONVERT(NVARCHAR(100),SERVERPROPERTY('Edition'))

SELECT	@ProductName = 
		CASE SUBSTRING(@ProductVersion,1,4)
			WHEN '14.0' THEN 'SQL Server 2017'
		    WHEN '13.0' THEN 'SQL Server 2016' 
			WHEN '12.0' THEN 'SQL Server 2014' 
			WHEN '11.0' THEN 'SQL Server 2012' 
			WHEN '10.5' THEN 'SQL Server 2008 R2' 
			WHEN '10.0' THEN 'SQL Server 2008'  
		END,
		@TheLastVersion = 
		CASE SUBSTRING(@ProductVersion,1,4)
			WHEN '14.0' THEN 'SQL Server 2017 RTM' 
		    WHEN '13.0' THEN 'SQL Server 2016 SP1' 
			WHEN '12.0' THEN 'SQL Server 2014 SP2' 
			WHEN '11.0' THEN 'SQL Server 2012 SP4' 
			WHEN '10.5' THEN 'SQL Server 2008 R2 SP3' 
			WHEN '10.0' THEN 'SQL Server 2008 SP4' 
		END

DECLARE @Temp1 NVARCHAR(100) = 'You have already installed the latest service pack.' 
DECLARE @Temp12 NVARCHAR(100) = 'Install the latest service pack:              '
SELECT  @SPInfo = 
		CASE @ProductName
				WHEN 'SQL Server 2016' THEN 
											CASE @ProductLevel
												WHEN 'SP1' THEN @Temp1 ELSE @Temp12 + 'SP1, <https://support.microsoft.com/en-us/kb/3182545>'
											END
				WHEN 'SQL Server 2014' THEN 
											CASE @ProductLevel
												WHEN 'SP2' THEN @Temp1 ELSE @Temp12 + 'SP2, <https://support.microsoft.com/en-us/kb/3171021>'
											END
				WHEN 'SQL Server 2012' THEN
											CASE @ProductLevel
												WHEN 'SP4' THEN @Temp1 ELSE @Temp12 + 'SP4, <https://support.microsoft.com/en-us/kb/4018073>'
											END
				WHEN 'SQL Server 2008 R2' THEN
											CASE @ProductLevel
												WHEN 'SP3' THEN @Temp1 ELSE @Temp12 + 'SP3, <https://support.microsoft.com/en-us/kb/2979597>'
											END
				WHEN 'SQL Server 2008' THEN
											CASE @ProductLevel
												WHEN 'SP4' THEN @Temp1 ELSE @Temp12 + 'SP4, <https://support.microsoft.com/en-us/kb/2979596>'
											END
		END,
		@CUInfo = 
		CASE @ProductName
				WHEN 'SQL Server 2017' THEN CASE @ProductVersion
												WHEN '14.0.3022.28' THEN 'You have already installed the latest cumulative update.'
												ELSE 'Install the latest Cumulative Update (CU) of RTM:  CU4, <https://support.microsoft.com/en-us/kb/4056498>'
											END
			    WHEN 'SQL Server 2016' THEN 
											CASE @ProductVersion
												WHEN '13.0.4466.4' THEN 'You have already installed the latest cumulative update.' 
												ELSE 'Install the latest Cumulative Update (CU) of SP1:  CU7, <https://support.microsoft.com/en-us/kb/4057119>'
											END
				WHEN 'SQL Server 2014' THEN 
											CASE @ProductVersion
												WHEN '12.0.5571.0' THEN 'You have already installed the latest cumulative update.'
												ELSE 'Install the latest Cumulative Update (CU) of SP2:  CU10, <https://support.microsoft.com/en-us/kb/4052725>'
											END
				WHEN 'SQL Server 2012' THEN
											CASE @ProductVersion
												WHEN '11.0.7001.0' THEN 'You have already installed the latest cumulative update.'
												ELSE 'Install the latest Cumulative Update (CU) of SP4:  RTW/PCU4, <https://support.microsoft.com/en-us/kb/4018073>'
											END

				--WHEN 'SQL Server 2008 R2' THEN
				--WHEN 'SQL Server 2008' THEN
		END

IF (@UpdateRef <> '')
BEGIN
	SET @UpdateRefOutput = @UpdateRef + ' (' + 'https://support.microsoft.com/kb/'+SUBSTRING(@UpdateRef,3,10)+ ')'
END

IF (@ProductName = 'SQL Server 2008')
BEGIN

	IF (@ProductLevel = 'RTM') AND (@ProductVersion < '10.00.1835.00')
	BEGIN
		SET @CumulativeUpdate = 'CU10'; SET @CumulativeUpdateKB = 'https://support.microsoft.com/en-us/kb/979064';
	END
	ELSE IF (@ProductLevel = 'SP1') AND (@ProductVersion < '10.00.2850.0')
	BEGIN
		SET @CumulativeUpdate = 'CU16'; SET @CumulativeUpdateKB = 'https://support.microsoft.com/en-us/kb/2582282';
	END
	ELSE IF (@ProductLevel = 'SP2') AND (@ProductVersion < '10.00.4333.00')
	BEGIN
		SET @CumulativeUpdate = 'CU11'; SET @CumulativeUpdateKB = 'https://support.microsoft.com/en-us/kb/2715951';
	END
	ELSE IF (@ProductLevel = 'SP3') AND (@ProductVersion < '10.00.5861.00')
	BEGIN
		SET @CumulativeUpdate = 'CU17'; SET @CumulativeUpdateKB = 'https://support.microsoft.com/en-us/kb/2958696';
	END

	SELECT  @OtherProduct = 
			CASE 
				WHEN @ProductLevel IN ('RTM','SP1') THEN 
						CASE 
							WHEN @EditionID IN (1804890536,1872460670)	THEN @2008R2E+@2008R2Dat 
							WHEN @EditionID = -1534726760				THEN @2008R2E+@2008R2Dat+@2008R2Std
							WHEN @EditionID = -2117995310               THEN @2008R2Dat+@2008R2Dev
							WHEN @Edition LIKE 'Express%'				THEN @2008R2E+@2008R2Dat+@2008R2Std+@2008R2Wg+@2008R2Dev+@2008R2ExpAdv
						END

				WHEN @ProductLevel = 'SP2' THEN 
						CASE 
							WHEN @EditionID IN (1804890536,1872460670)	THEN @2008R2E+@2008R2Dat + @2012E+@2012BI			 													 	
							WHEN @EditionID = -1534726760             	THEN @2008R2E+@2008R2Dat+@2008R2Std + @2012E+@2012BI+@2012Std
							WHEN @EditionID = -2117995310         		THEN @2008R2Dat+@2008R2Dev + @2012Dev
							WHEN @Edition LIKE 'Express%'				THEN @2008R2E+@2008R2Dat+@2008R2Std+@2008R2Wg+@2008R2Dev+@2008R2ExpAdv 
																		   + @2012E+@2012BI+@2012Std+@2012Web+@2012Exp
						END
	 
				WHEN @ProductLevel IN('SP3','SP4') THEN 
						CASE 
							WHEN @EditionID IN (1804890536,1872460670)	THEN @2008R2E+@2008R2Dat + @2012E+@2012BI + @2014E+@2014BI + @2016E+@2016BI	+ @2017E+@2017BI	 														 	
							WHEN @EditionID = -1534726760             	THEN @2008R2E+@2008R2Dat+@2008R2Std + @2012E+@2012BI+@2012Std 
																		   + @2014E+@2014BI+@2014Std + @2016E+@2016BI+@2016Std + @2017E+@2017BI+@2017Std
							WHEN @EditionID = -2117995310         		THEN @2008R2Dat+@2008R2Dev + @2012Dev + @2014Dev + @2016Dev + @2017Dev
							WHEN @Edition LIKE 'Express%'				THEN @2008R2E+@2008R2Dat+@2008R2Std+@2008R2Wg+@2008R2Dev+@2008R2ExpAdv 
																		   + @2012E+@2012BI+@2012Std+@2012Web+@2012Exp 
																		   + @2014E+@2014BI+@2014Std+@2014Web+@2014Exp
						END
			END				
END

																		  
IF (@ProductName = 'SQL Server 2008 R2')
BEGIN

	IF (@ProductLevel = 'RTM') AND (@ProductVersion < '10.50.1815.00')
	BEGIN
		SET @CumulativeUpdate = 'CU13'; SET @CumulativeUpdateKB = 'https://support.microsoft.com/en-us/kb/2679366';
	END
	ELSE IF (@ProductLevel = 'SP1') AND (@ProductVersion < '10.50.2881.00')
	BEGIN
		SET @CumulativeUpdate = 'CU14'; SET @CumulativeUpdateKB = 'https://support.microsoft.com/en-us/kb/2868244';
	END
	ELSE IF (@ProductLevel = 'SP2') AND (@ProductVersion < '10.50.4319.00')
	BEGIN
		SET @CumulativeUpdate = 'CU13'; SET @CumulativeUpdateKB = 'https://support.microsoft.com/en-us/kb/2967540';
	END

	SELECT  @OtherProduct = 
			CASE 
				WHEN @ProductLevel = 'RTM' THEN ' If you want to upgrade to higher edition, please intall service pack.'
				WHEN @ProductLevel = 'SP1' THEN 
						CASE 
							WHEN @EditionID IN (1804890536,1872460670)	THEN @2012E+@2012BI					 													 	
							WHEN @EditionID = -1534726760             	THEN @2012E+@2012BI+@2012Std
							WHEN @EditionID = -2117995310         		THEN @2012Dev
							WHEN @Edition LIKE 'Express%'				THEN @2012E+@2012BI+@2012Std+@2012Web+@2012Exp
						END
				WHEN @ProductLevel IN('SP2','SP3','SP4') THEN 
						CASE 
							WHEN @EditionID IN (1804890536,1872460670)	THEN @2012E+@2012BI + @2014E+@2014BI + @2016E+@2016BI + @2017E+@2017BI				 														 	
							WHEN @EditionID = -1534726760             	THEN @2012E+@2012BI+@2012Std + @2014E+@2014BI+@2014Std + @2016E+@2016BI+@2016Std + @2017E+@2017BI+@2017Std
							WHEN @EditionID = -2117995310         		THEN @2012Dev + @2014Dev + @2016Dev +@2017Dev
							WHEN @Edition LIKE 'Express%'				THEN @2012E+@2012BI+@2012Std+@2012Web+@2012Exp 
																		   + @2014E+@2014BI+@2014Std+@2014Web+@2014Exp 
																		   + @2016E+@2016BI+@2016Std+@2016Web+@2016Exp
																		   + @2017E+@2017BI+@2017Std+@2017Web+@2017Exp
						END
			END				
END


IF (@ProductName = 'SQL Server 2012')
BEGIN
	
	--2012
	IF (@ProductLevel = 'RTM') AND (@ProductVersion < '11.0.2424.0')
	BEGIN
		SET @CumulativeUpdate = 'CU11'; SET @CumulativeUpdateKB = 'https://support.microsoft.com/en-us/kb/2908007';
	END
	ELSE IF (@ProductLevel = 'SP1') AND (@ProductVersion < '11.0.3487.0')
	BEGIN
		SET @CumulativeUpdate = 'CU16'; SET @CumulativeUpdateKB = 'https://support.microsoft.com/en-us/kb/3052476';
	END
	ELSE IF (@ProductLevel = 'SP2') AND (@ProductVersion < '11.0.5678.0')
	BEGIN
		SET @CumulativeUpdate = 'CU16'; SET @CumulativeUpdateKB = 'https://support.microsoft.com/en-us/kb/3205054';
	END
	ELSE IF (@ProductLevel = 'SP3') AND (@ProductVersion < '11.0.6607.3')
	BEGIN
		SET @CumulativeUpdate = 'CU10'; SET @CumulativeUpdateKB = 'https://support.microsoft.com/en-us/kb/4025925';
	END
	ELSE IF (@ProductLevel = 'SP4') AND (@ProductVersion < '11.0.7001.0')
	BEGIN
		SET @CumulativeUpdate = 'RTW/PCU4'; SET @CumulativeUpdateKB = 'https://support.microsoft.com/en-us/kb/4018073';
	END	
	SELECT  @OtherProduct = 
			CASE 
				WHEN @ProductLevel = 'RTM' THEN ' If you want to upgrade to higher edition, please intall service pack.'
				WHEN @ProductLevel IN('SP1','SP2','SP3','SP4') THEN 
						CASE 
							WHEN @EditionID IN (1804890536,1872460670)	THEN @2014E+@2014BI + @2016E+@2016BI + @2017E+@2017BI						 														 	
							WHEN @EditionID = -1534726760             	THEN @2014E+@2014BI+@2014Std + @2016E+@2016BI+@2016Std + @2017E+@2017BI+@2017Std
							WHEN @EditionID = -2117995310         		THEN @2014Dev + @2016E+@2016BI+@2016Std+@2016Web+@2016Dev + @2017E+@2017BI+@2017Std+@2017Web+@2017Dev
							WHEN @EditionID = -610778273         		THEN @2016E+@2016BI+@2016Std+@2016Web+@2016Dev+@2016Eval + @2017E+@2017BI+@2017Std+@2017Web+@2017Dev+@2017Eval
							WHEN @Edition LIKE 'Express%'				THEN @2014E+@2014BI+@2014Std+@2014Web+@2014Exp 
																		   + @2016E+@2016BI+@2016Std+@2016Web+@2016Exp+@2016Dev
																		   + @2017E+@2017BI+@2017Std+@2017Web+@2017Exp+@2017Dev		
						END
			END				
END

IF (@ProductName = 'SQL Server 2014')
BEGIN

	--2014
	IF (@ProductLevel = 'RTM') AND (@ProductVersion < '12.0.2569.0')
	BEGIN
		SET @CumulativeUpdate = 'CU14'; SET @CumulativeUpdateKB = 'https://support.microsoft.com/en-us/kb/3158271';
	END
	ELSE IF (@ProductLevel = 'SP1') AND (@ProductVersion < '12.0.4520.0')
	BEGIN
		SET @CumulativeUpdate = 'CU13'; SET @CumulativeUpdateKB = 'https://support.microsoft.com/en-us/kb/4019099';
	END
	ELSE IF (@ProductLevel = 'SP2') AND (@ProductVersion < '12.0.5571.0')
	BEGIN
		SET @CumulativeUpdate = 'CU10'; SET @CumulativeUpdateKB = 'https://support.microsoft.com/en-us/kb/4052725';
	END

	SELECT  @OtherProduct = 
			CASE 
				WHEN @ProductLevel IN ('RTM','SP1','SP2') THEN 
						CASE 
							WHEN @EditionID IN (1804890536,1872460670)	THEN @2016E+@2016BI + @2017E+@2017BI			 														 	
							WHEN @EditionID = -1534726760             	THEN @2016E+@2016BI+@2016Std + @2017E+@2017BI+@2017Std
							WHEN @EditionID = -2117995310         		THEN @2016E+@2016BI+@2016Std+@2016Web+@2016Dev + @2017E+@2017BI+@2017Std+@2017Web+@2017Dev
							WHEN @EditionID = -610778273         		THEN @2016E+@2016BI+@2016Std+@2016Web+@2016Dev+@2016Eval + @2017E+@2017BI+@2017Std+@2017Web+@2017Dev+@2017Eval		
							WHEN @Edition LIKE 'Express%'				THEN @2016E+@2016BI+@2016Std+@2016Web+@2016Exp+@2016Dev + @2017E+@2017BI+@2017Std+@2017Web+@2017Exp+@2017Dev									
						END
			END				
END

IF (@ProductName = 'SQL Server 2016')
BEGIN

	--2016
	IF (@ProductLevel = 'RTM') AND (@ProductVersion < '13.0.2216.0')
	BEGIN
		SET @CumulativeUpdate = 'CU9'; SET @CumulativeUpdateKB = 'https://support.microsoft.com/en-us/kb/4037357';
	END
	ELSE IF (@ProductLevel = 'SP1') AND (@ProductVersion < '13.0.4466.4')
	BEGIN
		SET @CumulativeUpdate = 'CU7'; SET @CumulativeUpdateKB = 'https://support.microsoft.com/en-us/kb/4057119';
	END	
	SELECT  @OtherProduct = 
			CASE 
				WHEN @ProductLevel IN ('RTM','SP1') THEN 
						CASE 
							WHEN @EditionID IN (1804890536,1872460670)	THEN @2017E+@2017BI			 														 	
							WHEN @EditionID = -1534726760             	THEN @2017E+@2017BI+@2017Std
							WHEN @EditionID = -2117995310         		THEN @2017E+@2017BI+@2017Std+@2017Web+@2017Dev
							WHEN @EditionID = -610778273         		THEN @2017E+@2017BI+@2017Std+@2017Web+@2017Dev+@2017Eval		
							WHEN @Edition LIKE 'Express%'				THEN @2017E+@2017BI+@2017Std+@2017Web+@2017Exp+@2017Dev									
						END
			END				
			
END


------------------------------------------------------------
--//Begin GDR or QFE ///////////////////////////////////////
------------------------------------------------------------
DECLARE @SecurityUpdate		NVARCHAR(100)
DECLARE @GDR				NVARCHAR(2000) = ''
DECLARE @QFE				NVARCHAR(2000) = ''
DECLARE @GDRorQFE			TINYINT      = 0
DECLARE @Build				NVARCHAR(20) = SUBSTRING(@ProductVersion,1,9)


IF (@ProductName = 'SQL Server 2014')
BEGIN
	
	IF (@Build in ('12.0.2000','12.0.4100'))
		SET @GDRorQFE = 1 
	ELSE IF (@Build in ('12.0.2381','12.0.2548'))
		SET @GDRorQFE = 2
	ELSE IF (@Build in ('12.0.2254','12.0.2269','12.0.4213'))
		SET @GDRorQFE = 3
	ELSE 
		SET @GDRorQFE = 4

	SET @QFE = @QFE
			--+ CHAR(13) + '12.0.2381 (SQL Server 2014 RTM QFE) https://support.microsoft.com/en-us/kb/2977316'
			+ CHAR(13) + '12.0.2548 (SQL Server 2014 RTM QFE) http://support.microsoft.com/en-us/kb/3045323'

	SET @GDR = @GDR
			+ CHAR(13) + '12.0.2254 (SQL Server 2014 RTM GDR) http://support.microsoft.com/kb/2977315/en-us'
			+ CHAR(13) + '12.0.2269 (SQL Server 2014 RTM GDR) http://support.microsoft.com/en-us/kb/3045324'
			+ CHAR(13) + '12.0.4213 (SQL Server 2014 SP1 GDR) https://support.microsoft.com/en-us/kb/3070446'

END


IF (@ProductName = 'SQL Server 2012')
BEGIN
	--1:RTM SP
	--2:QFE
	--3:GDR
	--4:CU
	IF (@Build in ('11.0.2100','11.0.3000','11.0.5058'))
		SET @GDRorQFE = 1 
	ELSE IF (@Build in ('11.0.2376','11.0.3460','11.0.3513','11.0.5613'))
		SET @GDRorQFE = 2
	ELSE IF (@Build in ('11.0.2218','11.0.3153','11.0.3156','11.0.5343'))
		SET @GDRorQFE = 3
	ELSE 
		SET @GDRorQFE = 4

	SET @QFE = @QFE
		+ CHAR(13) + '11.0.2376 (SQL Server 2012 RTM QFE) http://support.microsoft.com/en-us/kb/2716441'
		--+ CHAR(13) + '11.0.3460 (SQL Server 2012 SP1 QFE) http://support.microsoft.com/kb/2977325/en-us'
		+ CHAR(13) + '11.0.3513 (SQL Server 2012 SP1 QFE) https://support.microsoft.com/en-us/kb/3045317'
		+ CHAR(13) + '11.0.5613 (SQL Server 2012 SP2 QFE) https://support.microsoft.com/en-us/kb/3045319'

	SET @GDR = @GDR
		+ CHAR(13) + '11.0.2218 (SQL Server 2012 RTM GDR) https://support.microsoft.com/en-us/kb/2716442'
		+ CHAR(13) + '11.0.3153 (SQL Server 2012 SP1 GDR) http://support.microsoft.com/kb/2977326/en-us'
		+ CHAR(13) + '11.0.3156 (SQL Server 2012 SP1 GDR) https://support.microsoft.com/en-us/kb/3045318'
		+ CHAR(13) + '11.0.5343 (SQL Server 2012 SP2 GDR) https://support.microsoft.com/en-us/kb/3045321'

END


IF (@ProductName = 'SQL Server 2008 R2')
BEGIN

	IF (@Build in ('10.50.1600','10.50.2500','10.50.4000','10.50.6000'))
		SET @GDRorQFE = 1 
	ELSE IF (@Build in ('10.50.1790','10.50.2861','10.50.4321','10.50.4339','10.50.6220','10.50.6529'))
		SET @GDRorQFE = 2
	ELSE IF (@Build in ('10.50.1617','10.50.2550','10.50.4033','10.50.4042'))
		SET @GDRorQFE = 3
	ELSE 
		SET @GDRorQFE = 4

	SET @QFE = @QFE
		+ CHAR(13) + '10.50.1790 (SQL Server 2008 R2 RTM QFE) http://support.microsoft.com/kb/2494086'
		+ CHAR(13) + '10.50.2861 (SQL Server 2008 R2 SP1 QFE) http://support.microsoft.com/kb/2716439'
		+ CHAR(13) + '10.50.4339 (SQL Server 2008 R2 SP2 QFE) http://support.microsoft.com/kb/3045312/en-us'
		+ CHAR(13) + '10.50.6529 (SQL Server 2008 R2 SP3 QFE) http://support.microsoft.com/kb/3045314/en-us'

	SET @GDR = @GDR
		+ CHAR(13) + '10.50.1617 (SQL Server 2008 R2 RTM GDR) http://support.microsoft.com/kb/2494088'
		+ CHAR(13) + '10.50.2550 (SQL Server 2008 R2 SP1 GDR) http://technet.microsoft.com/en-us/security/bulletin/ms12-070'
		+ CHAR(13) + '10.50.4033 (SQL Server 2008 R2 SP2 GDR) http://support.microsoft.com/kb/2977320/en-us'
		+ CHAR(13) + '10.50.4042 (SQL Server 2008 R2 SP2 GDR) http://support.microsoft.com/kb/3045313/en-us'
END

IF (@ProductName = 'SQL Server 2008')
BEGIN

	IF (@Build in ('10.00.1600','10.00.2531','10.00.4000','10.00.5500','10.00.6000'))
		SET @GDRorQFE = 1 
	ELSE IF (@Build in ('10.00.2841','10.00.4311','10.00.4371','10.00.5826','10.00.5869','10.00.5890','10.00.6535'))
		SET @GDRorQFE = 2
	ELSE IF (@Build in ('10.00.2573','10.00.4064','10.00.4067','10.00.5512','10.00.5520','10.00.5538','10.00.6241'))
		SET @GDRorQFE = 3
	ELSE 
		SET @GDRorQFE = 4


	SET @QFE = @QFE
		+ CHAR(13) + '10.00.2841 (SQL Server 2008 SP1 QFE) https://support.microsoft.com/en-us/kb/2494100'
		+ CHAR(13) + '10.00.4371 (SQL Server 2008 SP2 QFE) http://support.microsoft.com/en-us/kb/2716433'
		+ CHAR(13) + '10.00.5890 (SQL Server 2008 SP3 QFE) https://support.microsoft.com/en-us/kb/3045303'
		+ CHAR(13) + '10.00.6535 (SQL Server 2008 SP4 QFE) http://support.microsoft.com/kb/3045308/en-us'
	
	SET @GDR = @GDR
		+ CHAR(13) + '10.00.2573 (SQL Server 2008 SP1 GDR) http://support.microsoft.com/kb/2494096'
		+ CHAR(13) + '10.00.4064 (SQL Server 2008 SP2 GDR) http://support.microsoft.com/kb/2494089'
		+ CHAR(13) + '10.00.4067 (SQL Server 2008 SP2 GDR) http://support.microsoft.com/en-us/kb/2716434'
		+ CHAR(13) + '10.00.5512 (SQL Server 2008 SP3 GDR) http://support.microsoft.com/en-us/kb/2716436'
		+ CHAR(13) + '10.00.5520 (SQL Server 2008 SP3 GDR) http://support.microsoft.com/kb/2977321/en-us'
		+ CHAR(13) + '10.00.5538 (SQL Server 2008 SP3 GDR) https://support.microsoft.com/en-us/kb/3045305'
		+ CHAR(13) + '10.00.6241 (SQL Server 2008 SP4 GDR) https://support.microsoft.com/en-us/kb/3045311'
END

IF @GDRorQFE = 2
	SET @SecurityUpdate = '+ Security update(QFE branch)'
ELSE IF @GDRorQFE = 3
	SET @SecurityUpdate = '+ Security update(GDR)'
ELSE 
	SET @SecurityUpdate = ''

------------------------------------------------------------
--//GDR or QFE end /////////////////////////////////////////
------------------------------------------------------------

--begin output results
--//Your current Microsoft SQL Server information:
PRINT REPLICATE('-',105)
PRINT '--//Your current Microsoft SQL Server information:'
PRINT REPLICATE('-',105)
PRINT 'Product Version:          ' + @ProductVersion
PRINT 'Product Name:             ' + @ProductName
PRINT 'Product Level:            ' + @ProductLevel + ' ' + @SecurityUpdate
PRINT 'Product Edition:          ' + @Edition

IF (@ProductName = 'SQL Server 2014') 
	AND ((@ProductLevel = 'RTM' AND SUBSTRING(@UpdateLevel,3,4) >= 10) 
		  OR (@ProductLevel = 'SP1' AND SUBSTRING(@UpdateLevel,3,4) >= 3)
		  OR (@ProductLevel > 'SP1'))
BEGIN
	PRINT 'Product Update Level:     ' + @UpdateLevel
	PRINT 'Product Update Reference: ' + @UpdateRefOutput
END
ELSE
BEGIN
	IF (@ProductName = 'SQL Server 2014' AND @ProductLevel = 'RTM' AND SUBSTRING(@UpdateLevel,3,4) < 14) 
	BEGIN
		PRINT REPLICATE('-',105)
		PRINT 'Note, if you want to know information about CU, you need to intall' 
			   + CHAR(13) + 'SQL Server 2014 RTM Cumulative Update 14. CU14, <https://support.microsoft.com/en-us/kb/3158271>'
			   + CHAR(13) + REPLICATE(' ',50) + '- see KB3158271 to get the Cumulative Update 14'	
	END

	IF (@ProductName = 'SQL Server 2014' AND @ProductLevel = 'SP1' AND SUBSTRING(@UpdateLevel,3,4) < 13) 
	BEGIN
		PRINT REPLICATE('-',105)
		PRINT 'Note, if you want to know information about CU, you need to intall' 
			   + CHAR(13) + 'SQL Server 2014 SP1 Cumulative Update 13. CU13, <https://support.microsoft.com/en-us/kb/4019099>'
			   + CHAR(13) + REPLICATE(' ',50) + '- see KB4019099 to get the Cumulative Update 13'	
	END

	IF (@ProductName <> 'SQL Server 2014') 
	BEGIN
		PRINT REPLICATE('-',105)
		PRINT 'Note, if you want to know information about CU, please read this KB below.' 
			   + CHAR(13) + 'KB321185,' + ' <https://support.microsoft.com/en-us/kb/321185>'

	END

END


PRINT REPLICATE('-',105)

--//lifecycle Support
IF (@ProductName = 'SQL server 2008' OR @ProductName = 'SQL server 2008 R2')
BEGIN
		PRINT @ExtendedSupport
END

IF (@ProductName = 'SQL server 2012')
BEGIN
	IF @ProductLevel = 'SP2' OR @ProductLevel = 'SP3' OR @ProductLevel = 'SP4'
		PRINT @MainSupport
	ELSE
		PRINT @MainSupportNonUpdate
END

IF (@ProductName = 'SQL server 2014' OR @ProductName = 'SQL server 2016' OR @ProductName = 'SQL server 2017')
BEGIN
		PRINT @MainSupport
END


PRINT REPLICATE('-',105)
PRINT 'Full information:' + CHAR(13) + @@VERSION

--//Recommended Updates:


PRINT REPLICATE('-',105)
PRINT '--//Recommended updates: '--Upgrade to ' + @TheLastVersion
PRINT '--### RTM -> QFE or GDR'
PRINT '--### SP  -> QFE or GDR'
PRINT '--### QFE -> QFE'
PRINT '--### GDR -> GDR or QFE'
PRINT REPLICATE('-',105)
PRINT @SPInfo

IF @CUInfo IS NOT NULL
PRINT @CUInfo
PRINT ''


PRINT REPLICATE('-',105)
PRINT '###### QFE branch updates'
PRINT REPLICATE('-',105)
PRINT SUBSTRING(@QFE,2,2000)

IF (@GDRorQFE in (1,3))
BEGIN
PRINT REPLICATE('-',105)
PRINT '###### GDR branch updates'
PRINT REPLICATE('-',105)
PRINT SUBSTRING(@GDR,2,2000)
END

IF @CumulativeUpdate IS NOT NULL AND (@ProductName <> 'SQL Server 2017')
BEGIN
	PRINT REPLICATE('-',105)
	PRINT 'Note, if you don''t want to upgrade to latest service pack right now, we recommend you install the latest' 
		  + CHAR(13) + 'Cumulative Update ' + @CumulativeUpdate + ' of ' + @ProductName + ' ' + @ProductLevel + '.' 
		  + CHAR(13) + 'Install the latest Cumulative Update (CU) of ' + @ProductLevel + ': ' + @CumulativeUpdate +', <' + @CumulativeUpdateKB + '>' 
END


--//You can upgrade to any of the following product(s):
PRINT CHAR(13)
PRINT REPLICATE('-',105)
PRINT '--//You can upgrade to any of the following product(s):'
PRINT REPLICATE('-',105)
PRINT SUBSTRING(@OtherProduct,2,800)
PRINT CHAR(13)
IF (@ProductName = 'SQL server 2017')
	PRINT 'For additional information about supported version and edition upgrades refer to:' 
		  + CHAR(13) +'https://docs.microsoft.com/en-us/sql/database-engine/install-windows/supported-version-and-edition-upgrades-2017'
ELSE IF(@ProductName = 'SQL server 2016')
	PRINT 'For additional information about supported version and edition upgrades refer to:' 
		  + CHAR(13) +'https://docs.microsoft.com/en-us/sql/database-engine/install-windows/supported-version-and-edition-upgrades'
ELSE
	PRINT 'For additional information about supported version and edition upgrades refer to:' 
		  + CHAR(13) +'https://technet.microsoft.com/en-us/library/ms143393(v=sql.120).aspx'
GO
