-- SQL from https://stackoverflow.com/posts/12504496

CREATE TABLE TextFile
    (
    [Line] varchar(500) ,
    [FileName] varchar(100) ,
    [RecordDate] DATETIME DEFAULT GETDATE(),
    [RecordID] INT IDENTITY(1,1) ,
    )

    BULK INSERT TextFile FROM 'C:\FILE.TXT'
    WITH (FORMATFILE = 'C:\FILEFORMAT.XML')
  
--- XML as follows:  
    
<?xml version="1.0"?>
<BCPFORMAT xmlns="http://schemas.microsoft.com/sqlserver/2004/bulkload/format" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
 <RECORD>  
  <FIELD ID="1" xsi:type="CharTerm" TERMINATOR="\r\n" MAX_LENGTH="500" COLLATION="SQL_Latin1_General_CP1_CI_AS"/>
 </RECORD>
 <ROW>
  <COLUMN SOURCE="1" NAME="Line" xsi:type="SQLVARYCHAR"/>
 </ROW>
</BCPFORMAT>
