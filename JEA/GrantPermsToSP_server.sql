-- This is the script found at: 
-- http://www.sommarskog.se/grantperm/GrantPermsToSP_server.sql


-- This script takes it base in the master database.
-- It permits you sign a procedure to bestow it with
-- server-level permissions. If the database is in an
-- AG, the certificate and login is created on all servers
-- in the AG.
-- This version requires SQL 2012 or later. For a version
-- that runs on SQL 2008, see GrantPermsToSP_server_2008.sql.
USE master
go
-- Set up parameters: the procedure to sign and the database it belongs to.
DECLARE @database nvarchar(260) = 'Playground',
        @procname nvarchar(520) = 'Management.ShowSessions'

-- The permissions to grant through the certificate. Leave table empty
-- to only remove current permissions.
DECLARE @perms TABLE (perm nvarchar(400) NOT NULL PRIMARY KEY)
INSERT @perms VALUES
   ('VIEW SERVER STATE')

-- Run with debug or not?
DECLARE @debug bit = 1

--============================ END OF SETUP ==========================
-- More local variables.
DECLARE @db_replica_id   uniqueidentifier,
        @sp_executesql   nvarchar(350),
        @certname        sysname,
        @username        sysname,
        @subject         nvarchar(4000),
        @pwd             char(39),
        @public_key      varchar(MAX),
        @sql             nvarchar(MAX),
        @grant_sql       nvarchar(MAX),
        @server          sysname,
        @nl              char(2) = char(13) + char(10),
        @pvt             char(2),
        -- These are comments that we attach to the dynamic SQL to
        -- understand the output better.
        @mastercomment  nvarchar(200),
        @servercomment  nvarchar(200),
        @dbstart        nvarchar(200),
        @dbend          nvarchar(200)


SET XACT_ABORT ON

-- A big TRY-CATCH block around everything to abort on first error.
BEGIN TRY

-- First verify that the database exists.
IF db_id(@database) IS NULL
   RAISERROR('Database %s does not exist.', 16, 1, @database)

-- Make sure that database name is quoted and appears exactly as in
-- sys.databases. Also get id for any AG.
SELECT @database = quotename(name), @db_replica_id = replica_id
FROM   sys.databases
WHERE  name = @database

-- We will call sp_executesql a number of times in the target database.
SELECT @sp_executesql = @database + '.sys.sp_executesql'

-- Set up comments for local and the database. For the database, we also
-- an impersonation of dbo. This is a protection against a malicious power
-- user who have added a DDL trigger which is trying exploit the permission
-- of a sysadmin user who is running. By impersonating a database user, we
-- are sandboxed things in the database, and cannot perform things outside
-- of it. (Unless the database is TRUSTWORTHY and owned by sysadmin, but that
-- is a security issue in itself.)
SELECT @mastercomment = @nl + '-- In master' + @nl,
       @dbstart       = @nl + '-- In database ' + @database + @nl +
                             'EXECUTE AS USER = ''dbo''' + @nl,
       @dbend         = @nl + 'REVERT'

-- Next we verify that the procedure exists and make sure that we have a
-- normalised quoted name. We need to run a query in the target database.
-- The point with MIN is that we get NULL if the procedure is does not exist.
SELECT @sql = @dbstart +
    'SELECT @procname = MIN(quotename(s.name) + ''.'' + quotename(o.name))
     FROM   sys.objects o
     JOIN   sys.schemas s ON o.schema_id = s.schema_id
     WHERE  o.object_id = object_id(@procname)' + 
   @dbend
IF @debug = 1 PRINT @sql
EXEC @sp_executesql @sql, N'@procname nvarchar(260) OUTPUT', @procname OUTPUT

IF @procname IS NULL
   RAISERROR('No procedure with the given name in database %s.', 16, 1, @database)

-- Construct name and password for the certificate.
SELECT @certname = 'SIGN ' + @database + '.' + @procname,
       @pwd      = convert(char(36), newid()) + 'Aa0'

-- And construct the subject from the permissions.
SELECT @subject = 'GRANT ' +
      (SELECT CASE row_number() OVER (ORDER BY (SELECT NULL))
                  WHEN 1 THEN ''
                  ELSE ' - '
            END + replace(perm, ',', ' ')
      FROM   @perms
      FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)')

-- If a login exists for the cerficiate, we drop it.
IF EXISTS (SELECT *
           FROM   sys.server_principals
           WHERE  name = @certname
             AND  type = 'C')
BEGIN
   SELECT @sql = @mastercomment + 'DROP LOGIN ' + quotename(@certname, '"')
   IF @debug = 1 PRINT @sql
   EXEC (@sql)
END

-- And drop the certificate itself.
IF EXISTS (SELECT * FROM sys.certificates WHERE name = @certname)
BEGIN
   SELECT @sql = @mastercomment + 'DROP CERTIFICATE ' + quotename(@certname, '"')
   IF @debug = 1 PRINT @sql
   EXEC(@sql)
END

-- In the target database, we must remove the signature from the procedure,
-- so that we can drop the certificate.
SELECT @sql = @dbstart +
   'IF EXISTS (SELECT *
               FROM   sys.crypt_properties cp
               JOIN   sys.certificates c ON cp.thumbprint = c.thumbprint
               WHERE  cp.major_id = object_id(@procname)
                 AND  c.name = @certname)
        DROP SIGNATURE FROM ' + @procname +
           ' BY CERTIFICATE ' + quotename(@certname, '"') + 
   @dbend
IF @debug = 1 PRINT @sql
EXEC @sp_executesql @sql, N'@certname sysname, @procname nvarchar(260)',
                    @certname, @procname

-- No user should have been created from the cert, but if so, we drop it.
-- Since this may have been performed by some else, we cannot trust the
-- username to be the same as the certificate name.
SELECT @sql = @dbstart +
   'SELECT @username = NULL
    SELECT @username = dp.name
    FROM   sys.database_principals dp
    JOIN   sys.certificates c ON dp.sid = c.sid
    WHERE  c.name = @certname' + 
    @dbend
IF @debug = 1 PRINT @sql
EXEC @sp_executesql @sql, N'@certname  sysname, @username sysname OUTPUT',
                          @certname, @username OUTPUT

IF @username IS NOT NULL
BEGIN
   SELECT @sql = @dbstart + 'DROP USER ' + quotename(@username, '"') + @dbend
   IF @debug = 1 PRINT @sql
   EXEC @sp_executesql @sql
END

-- And here goes the old cert.
SELECT @sql = @dbstart +
   'IF EXISTS (SELECT * FROM sys.certificates WHERE name = @certname)
       DROP CERTIFICATE ' + quotename(@certname, '"') + 
   @dbend
IF @debug = 1 PRINT @sql
EXEC @sp_executesql @sql, N'@certname  sysname', @certname

IF EXISTS (SELECT * FROM @perms)
BEGIN
   -- Now we start to (re)create things. First create the certificate in
   -- in the target database.
   SELECT @sql = @dbstart +
      'CREATE CERTIFICATE ' + quotename(@certname, '"') + '
       ENCRYPTION BY PASSWORD = ' + quotename(@pwd, '''') + '
       WITH SUBJECT = ' + quotename(@subject, '''') +
      @dbend
   IF @debug = 1 PRINT @sql
   EXEC @sp_executesql @sql

   -- Sign the procedure.
   SELECT @sql = @dbstart +
       'ADD SIGNATURE TO ' + @procname + ' BY CERTIFICATE ' + quotename(@certname, '"') + '
         WITH PASSWORD = ' + quotename(@pwd, '''') +
       @dbend
   IF @debug = 1 PRINT @sql
   EXEC @sp_executesql @sql

   -- Drop the private key.
   SELECT @sql = @dbstart + 
                 'ALTER CERTIFICATE ' + quotename(@certname, '"') + ' REMOVE PRIVATE KEY' + 
                 @dbend
   IF @debug = 1 PRINT @sql
   EXEC @sp_executesql @sql

   -- Make sure that the private key is really gone.
   SELECT @sql = @dbstart + 
       'SELECT @pvt = pvt_key_encryption_type FROM sys.certificates WHERE name = @certname' + 
       @dbend
   PRINT @sql
   EXEC @sp_executesql @sql, N'@certname sysname, @pvt char(2) OUTPUT', @certname, @pvt OUTPUT
   IF isnull(@pvt, '') <> 'NA'
      RAISERROR('Private key for %s not dropped as expected.', 16, 1, @certname)

   -- Retrieve the public key for the certificate as hex-string.
   SELECT @sql = @dbstart +
      'SELECT @public_key  = convert(varchar(MAX),
                            certencoded(cert_id(quotename(@certname))), 1)' +
       @dbend
   IF @debug = 1 PRINT @sql
   EXEC @sp_executesql @sql, N'@certname sysname, @public_key varchar(MAX) OUTPUT',
                               @certname, @public_key OUTPUT

   -- Create the certificate to master.
   SELECT @sql = @mastercomment +
      'CREATE CERTIFICATE ' + quotename(@certname, '"') + '
       FROM BINARY = ' + @public_key
   IF @debug = 1 PRINT convert(varchar(MAX), @sql)
   EXEC (@sql)

   -- Create a login for the certificate.
   SELECT @sql = @mastercomment +
                 'CREATE LOGIN ' + quotename(@certname, '"') +
                    ' FROM CERTIFICATE ' + quotename(@certname, '"')
   IF @debug = 1 PRINT @sql
   EXEC(@sql)

   -- Create commands to grant permissions or add membership. This may
   -- also have to be executed on other notes in the AG, why save it in
   -- a separate variable for reuse.
   SELECT @grant_sql =
      (SELECT CASE WHEN EXISTS (SELECT *
                                FROM   sys.server_principals dp
                                WHERE  dp.name = p.perm
                                  AND  dp.type = 'R')
                   THEN 'ALTER SERVER ROLE ' + quotename(p.perm) +
                             ' ADD MEMBER ' + quotename(@certname, '"')
                   ELSE 'GRANT ' + p.perm + ' TO ' + quotename(@certname, '"')
              END + @nl
       FROM   @perms p
       FOR    XML PATH(''), TYPE).value('.', 'nvarchar(MAX)')

   SELECT @sql = @mastercomment + @grant_sql
   IF @debug = 1 PRINT @sql
   EXEC(@sql)
END

-- If the database is part of an availability group, the certificate needs to be propagated
-- to the master databases on the other nodes as well.
IF @db_replica_id IS NOT NULL
BEGIN
   -- Set up a cursor over all the other nodes.
   DECLARE ag_cur CURSOR STATIC LOCAL FOR
      SELECT replica_server_name
      FROM   sys.availability_replicas ar
      WHERE  ar.replica_server_name <> convert(sysname, serverproperty('ServerName'))
        AND  EXISTS (SELECT *
                     FROM   sys.availability_replicas ar2
                     WHERE  ar2.replica_id = @db_replica_id
                       AND  ar.group_id = ar2.group_id)
   OPEN ag_cur

   WHILE 1 = 1
   BEGIN
      FETCH ag_cur INTO @server
      IF @@fetch_status <> 0
         BREAK

      -- This is a string that we put above the debug output of all SQL commands we run on the
      -- remote server.
      SELECT @servercomment = @nl + '-- On server ' + @server + @nl

      -- Set up a temporary linked server to this node. As we will use sp_executesql,
      -- we need RPC out to be enabled.
      EXEC sp_addlinkedserver 'TEMP$SERVER', '', 'SQLOLEDB', @server
      EXEC sp_serveroption 'TEMP$SERVER', 'RPC out', 'true'

      -- If a login exists for the cerficiate on the other node, we drop it
      SELECT @sql = @servercomment +
         'IF EXISTS (SELECT *
                     FROM   sys.server_principals
                     WHERE  name = @certname
                       AND  type = ''C'')
             DROP LOGIN ' + quotename(@certname, '"')
      IF @debug = 1 PRINT @sql
      EXEC TEMP$SERVER.master.sys.sp_executesql @sql, N'@certname sysname', @certname

      -- And drop the certificate itself.
      SELECT @sql = @servercomment +
         'IF EXISTS (SELECT * FROM sys.certificates WHERE name = @certname)
             DROP CERTIFICATE ' + quotename(@certname, '"')
      IF @debug = 1 PRINT @sql
      EXEC TEMP$SERVER.master.sys.sp_executesql @sql, N'@certname sysname', @certname

      -- Only create new certs etc, if there are any permissions to grant. This is
      -- all done by recreating previously created SQL strings.
      IF EXISTS (SELECT * FROM @perms)
      BEGIN

         -- Create the certificate on this server. Note that we only need the public key,
         -- because we will sign nothing here.
         SELECT @sql = @nl + @servercomment +
               'CREATE CERTIFICATE ' + quotename(@certname, '"') + '
                FROM BINARY = ' + @public_key
         IF @debug = 1 PRINT @sql
         EXEC TEMP$SERVER.master.sys.sp_executesql @sql

         -- The login.
         SELECT @sql = @servercomment +
                       'CREATE LOGIN ' + quotename(@certname, '"') +
                       ' FROM CERTIFICATE ' + quotename(@certname, '"')
         IF @debug = 1 PRINT @sql
         EXEC TEMP$SERVER.master.sys.sp_executesql @sql

         -- Grant the permissions.
         SELECT @sql = @servercomment + @grant_sql
         IF @debug = 1 PRINT @sql
         EXEC TEMP$SERVER.master.sys.sp_executesql @sql
      END

      -- Now that alls is done, drop the temporary server.
      EXEC sp_dropserver 'TEMP$SERVER'
   END

   -- Get rid of the cursor.
   DEALLOCATE ag_cur
END
END TRY
BEGIN CATCH
   IF @@trancount > 0 ROLLBACK TRANSACTION
   -- In cases there is an error while we are impersonating dbo, we need
   -- revert back, which must be done in the user database.
   IF EXISTS (SELECT * FROM sys.login_token WHERE usage = 'DENY ONLY')
      EXEC @sp_executesql N'REVERT'
   ; THROW
END CATCH


