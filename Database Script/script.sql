USE [CRDB-NEW]
GO
/****** Object:  UserDefinedFunction [dbo].[ConvertTimeToHHMMSS]    Script Date: 01-07-2020 15:09:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Himanshu Manjarawala
-- Create date: 01-07-2020
-- Description:	
-- =============================================
CREATE FUNCTION [dbo].[ConvertTimeToHHMMSS] 
(
	-- Add the parameters for the function here
	@time decimal(28,3)
)
RETURNS varchar(20)
AS
BEGIN
	-- Declare the return variable here
	declare @seconds decimal(18,3), @minutes int, @hours int;

    set @hours = convert(int, @time /60 / 60);
    set @minutes = convert(int, (@time / 60) - (@hours * 60 ));
    set @seconds = @time % 60;

    return 
        convert(varchar(9), convert(int, @hours)) + ':' +
        right('00' + convert(varchar(2), convert(int, @minutes)), 2) + ':' +
        right('00' + convert(varchar(6), @seconds), 6)

END
GO
/****** Object:  UserDefinedFunction [dbo].[GetBotName]    Script Date: 01-07-2020 15:09:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Himanshu Manjarawala
-- Create date: 30-06-2020
-- Description:	
-- =============================================
CREATE FUNCTION [dbo].[GetBotName] 
(
	-- Add the parameters for the function here
	@Bot_ID uniqueidentifier
)
RETURNS varchar(50)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result varchar(50)

	-- Add the T-SQL statements to compute the return value here
	SELECT @Result = Bot_Name FROM Bot_Master WHERE Bot_ID = @Bot_ID

	-- Return the result of the function
	RETURN @Result

END
GO
/****** Object:  UserDefinedFunction [dbo].[GetMachineName]    Script Date: 01-07-2020 15:09:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Himanshu Manjarawala
-- Create date: 30-06-2020
-- Description:	
-- =============================================
CREATE FUNCTION [dbo].[GetMachineName] 
(
	-- Add the parameters for the function here
	@Machine_ID uniqueidentifier
)
RETURNS varchar(50)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result varchar(50)

	-- Add the T-SQL statements to compute the return value here
	SELECT @Result = Machine_Name FROM Bot_Machine_Master WHERE Machine_ID = @Machine_ID

	-- Return the result of the function
	RETURN @Result

END
GO
/****** Object:  Table [dbo].[Bot_Execution_Master]    Script Date: 01-07-2020 15:09:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Bot_Execution_Master](
	[Bot_ID] [uniqueidentifier] NOT NULL,
	[Bot_Machine_ID] [uniqueidentifier] NOT NULL,
	[Bot_Execution_ID] [uniqueidentifier] NOT NULL,
	[Bot_Execution_Date] [date] NOT NULL,
	[Bot_User_Name] [nvarchar](50) NOT NULL,
	[Bot_Start_Time] [datetime] NOT NULL,
	[Bot_End_Time] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Bot_Machine_Master]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Bot_Machine_Master](
	[Machine_ID] [uniqueidentifier] NOT NULL,
	[Machine_Name] [varchar](50) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Bot_Master]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Bot_Master](
	[Bot_ID] [uniqueidentifier] NOT NULL,
	[Bot_Name] [nvarchar](50) NOT NULL,
	[Creation_Date] [datetime] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Bot_Transaction_Master]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Bot_Transaction_Master](
	[Bot_ID] [uniqueidentifier] NOT NULL,
	[Bot_Machine_ID] [uniqueidentifier] NOT NULL,
	[Bot_Execution_ID] [uniqueidentifier] NOT NULL,
	[Bot_Transaction_ID] [uniqueidentifier] NOT NULL,
	[Bot_Parent_Transaction_ID] [uniqueidentifier] NULL,
	[Transaction_Start_Time] [datetime] NOT NULL,
	[Transaction_End_Time] [datetime] NULL,
	[Transaction_Status] [int] NULL,
	[Transaction_Comment] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [dbo].[VIEW_BOT_PERFORMANCE]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VIEW_BOT_PERFORMANCE]
AS
SELECT        dbo.GetBotName(dbo.Bot_Transaction_Master.Bot_ID) AS Bot_Name, 
			dbo.GetMachineName(dbo.Bot_Transaction_Master.Bot_Machine_ID) AS Machine_Name, 
			dbo.Bot_Execution_Master.Bot_User_Name, 
			dbo.Bot_Execution_Master.Bot_Execution_Date, 
            dbo.Bot_Transaction_Master.Bot_Transaction_ID, 
			CASE 
				WHEN dbo.Bot_Transaction_Master.Transaction_Status=1 THEN 1
				ELSE 0
			END AS Success,
			CASE 
				WHEN dbo.Bot_Transaction_Master.Transaction_Status=2 THEN 1
				ELSE 0
			END AS Failed,
			CASE 
				WHEN dbo.Bot_Transaction_Master.Transaction_Status=0 THEN 1
				ELSE 0
			END AS InProgress
FROM            dbo.Bot_Transaction_Master INNER JOIN
                         dbo.Bot_Execution_Master ON dbo.Bot_Execution_Master.Bot_ID = dbo.Bot_Transaction_Master.Bot_ID AND dbo.Bot_Execution_Master.Bot_Machine_ID = dbo.Bot_Transaction_Master.Bot_Machine_ID AND 
                         dbo.Bot_Execution_Master.Bot_Execution_ID = dbo.Bot_Transaction_Master.Bot_Execution_ID
WHERE        (dbo.Bot_Transaction_Master.Bot_Parent_Transaction_ID IS NULL)

GO
/****** Object:  View [dbo].[VIEW_BOT_WISE_MACHINE_UTILIZATION]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VIEW_BOT_WISE_MACHINE_UTILIZATION]
AS
SELECT        Bot_ID, 
				dbo.GetBotName(Bot_ID) AS Bot_Name, 
				Bot_Machine_ID, 
				dbo.GetMachineName(Bot_Machine_ID) AS Machine_Name, 
				Bot_Execution_ID, 
				Bot_Execution_Date, 
				Bot_User_Name, 
				CASE WHEN EXISTS
                             (SELECT        1
                               FROM            Bot_Transaction_Master btm
                               WHERE        btm.Bot_ID = bem.Bot_ID AND btm.Bot_Machine_ID = bem.Bot_Machine_ID AND btm.Bot_Execution_ID = bem.Bot_Execution_ID) THEN DATEDIFF(SECOND, bem.Bot_Start_Time, ISNULL(bem.Bot_End_Time, 
                         bem.Bot_Start_Time)) 
				ELSE 0 
				END AS Running_Time, 
				CASE WHEN NOT EXISTS
                             (SELECT        1
                               FROM            Bot_Transaction_Master btm
                               WHERE        btm.Bot_ID = bem.Bot_ID AND btm.Bot_Machine_ID = bem.Bot_Machine_ID AND btm.Bot_Execution_ID = bem.Bot_Execution_ID) THEN DATEDIFF(SECOND, bem.Bot_Start_Time, ISNULL(bem.Bot_End_Time, 
                         bem.Bot_Start_Time)) 
				ELSE 0 
				END AS Idle_Time, 
				LEFT(CONVERT(VARCHAR, Bot_Execution_Date, 112), 6) AS YearMonth
FROM            dbo.Bot_Execution_Master AS bem
GO
/****** Object:  Table [dbo].[Bot_Parameter_Master]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Bot_Parameter_Master](
	[Bot_ID] [uniqueidentifier] NOT NULL,
	[Bot_Param_ID] [numeric](5, 0) IDENTITY(1,1) NOT NULL,
	[Bot_Param_Name] [varchar](50) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Bot_Parameter_Value_Details]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Bot_Parameter_Value_Details](
	[Bot_ID] [uniqueidentifier] NOT NULL,
	[Bot_Machine_ID] [uniqueidentifier] NOT NULL,
	[Bot_Execution_ID] [uniqueidentifier] NOT NULL,
	[Bot_Transaction_ID] [uniqueidentifier] NOT NULL,
	[Bot_Parent_Transaction_ID] [uniqueidentifier] NULL,
	[Bot_Param_ID] [numeric](5, 0) NOT NULL,
	[Bot_Param_Value] [varchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Bot_Transaction_Log_Details]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Bot_Transaction_Log_Details](
	[Bot_ID] [uniqueidentifier] NOT NULL,
	[Bot_Machine_ID] [uniqueidentifier] NOT NULL,
	[Bot_Execution_ID] [uniqueidentifier] NOT NULL,
	[Bot_Transaction_ID] [uniqueidentifier] NULL,
	[Bot_Parent_Transaction_ID] [uniqueidentifier] NULL,
	[Log_Timestamp] [datetime] NOT NULL,
	[Log_TaskName] [varchar](50) NOT NULL,
	[Log_Type] [varchar](10) NOT NULL,
	[Log_Message] [varchar](max) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[BOT_MACHINE_MASTER_INSERT]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Himanshu Manjarawala
-- Create date: 
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[BOT_MACHINE_MASTER_INSERT] 
	-- Add the parameters for the stored procedure here
	@Bot_ID uniqueidentifier,
	@Bot_Machine_Name varchar(50),
	@Bot_User_Name varchar(50),
	@Bot_Machine_ID uniqueidentifier output,
	@Bot_Execution_ID uniqueidentifier output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF NOT EXISTS ( SELECT * FROM dbo.Bot_Machine_Master WHERE Machine_Name = @Bot_Machine_Name)
		BEGIN
			SET @Bot_Machine_ID = NEWID()
			INSERT INTO Bot_Machine_Master(Machine_ID,Machine_Name) Values(@Bot_Machine_ID, @Bot_Machine_Name)
		END
	ELSE
		BEGIN
			SELECT @Bot_Machine_ID = Machine_ID FROM dbo.Bot_Machine_Master WHERE Machine_Name = @Bot_Machine_Name
		END
	SET @Bot_Execution_ID = NEWID()
	INSERT INTO Bot_Execution_Master(Bot_ID, Bot_Machine_ID, Bot_Execution_ID, Bot_Execution_Date, Bot_User_Name, Bot_Start_Time) values(@Bot_ID, @Bot_Machine_ID,@Bot_Execution_ID,GETDATE(), @Bot_User_Name, GETDATE())
END

GO
/****** Object:  StoredProcedure [dbo].[BOT_MACHINE_MASTER_UPDATE]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Himanshu Manjarawala
-- Create date: 
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[BOT_MACHINE_MASTER_UPDATE] 
	-- Add the parameters for the stored procedure here
	@Bot_ID uniqueidentifier, 
	@Bot_Machine_ID uniqueidentifier,
	@Bot_Execution_ID uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Update dbo.Bot_Execution_Master Set Bot_End_Time = getdate()
		Where Bot_ID = @Bot_ID
		And   Bot_Machine_ID = @Bot_Machine_ID
		And   Bot_Execution_ID = @Bot_Execution_ID
END

GO
/****** Object:  StoredProcedure [dbo].[BOT_MASTER_DELETE]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Himanshu Manjarawala
-- Create date: 
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[BOT_MASTER_DELETE] 
	-- Add the parameters for the stored procedure here
	@Bot_Name varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF @Bot_Name IS NULL OR RTRIM(LTRIM(@Bot_Name)) = ''
	BEGIN
		DELETE FROM Bot_Transaction_Log_Details

		DELETE FROM Bot_Parameter_Value_Details

		DELETE FROM Bot_Parameter_Master

		DELETE FROM Bot_Transaction_Master

		DELETE FROM Bot_Execution_Master

		DELETE FROM Bot_Master
	END
	ELSE
	BEGIN
		DECLARE @Bot_ID as uniqueidentifier

		SELECT @Bot_ID = Bot_ID FROM dbo.Bot_Master WHERE Bot_Name = @Bot_Name

		DELETE FROM Bot_Transaction_Log_Details WHERE Bot_ID = @Bot_ID

		DELETE FROM Bot_Parameter_Value_Details WHERE Bot_ID = @Bot_ID

		DELETE FROM Bot_Parameter_Master WHERE Bot_ID = @Bot_ID

		DELETE FROM Bot_Transaction_Master WHERE Bot_ID = @Bot_ID

		DELETE FROM Bot_Execution_Master WHERE Bot_ID = @Bot_ID

		DELETE FROM Bot_Master WHERE Bot_ID = @Bot_ID
	END

END

GO
/****** Object:  StoredProcedure [dbo].[BOT_MASTER_INSERT]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Himanshu Manjarawala
-- Create date: 
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[BOT_MASTER_INSERT] 
	-- Add the parameters for the stored procedure here
	@Bot_Name nvarchar(50),
	@Bot_ID uniqueidentifier output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF NOT Exists(SELECT Bot_ID  FROM dbo.Bot_Master WHERE Bot_Name = @Bot_Name)
	Begin
		set @Bot_ID = NEWID()
		INSERT INTO Bot_Master(Bot_ID, Bot_Name, Creation_Date) VAlues(@Bot_ID, @Bot_Name,GETDATE())
	End
	ELSE
	Begin
		SELECT @Bot_ID = Bot_ID From dbo.Bot_Master Where Bot_Name = @Bot_Name
	End
END

GO
/****** Object:  StoredProcedure [dbo].[BOT_PARAMETER_INSERT]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Himanshu Manjarawala
-- Create date: 
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[BOT_PARAMETER_INSERT] 
	-- Add the parameters for the stored procedure here
	@Bot_ID uniqueidentifier, 
	@Bot_Machine_ID uniqueidentifier,
	@Bot_Execution_ID uniqueidentifier,
	@Bot_Transaction_ID uniqueidentifier,
	@Bot_Param_Name varchar(50),
	@Bot_Param_Value varchar(50),
	@Bot_Parent_Transaction_ID uniqueidentifier=null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Bot_Param_ID numeric(5,0)

    -- Insert statements for procedure here
	IF NOT EXISTS(SELECT Bot_Param_ID FROM Bot_Parameter_Master WHERE Bot_Param_Name = @Bot_Param_Name AND Bot_ID = @Bot_ID)
	BEGIN
		INSERT INTO Bot_Parameter_Master(Bot_ID,Bot_Param_Name) VALUES(@Bot_ID,@Bot_Param_Name)
		Set @Bot_Param_ID = @@IDENTITY
	END
	ELSE
	BEGIN
		SELECT @Bot_Param_ID = Bot_Param_ID FROM Bot_Parameter_Master WHERE Bot_Param_Name = @Bot_Param_Name AND Bot_ID = @Bot_ID
	END
	INSERT INTO Bot_Parameter_Value_Details(Bot_ID,Bot_Machine_ID,Bot_Execution_ID,Bot_Transaction_ID,Bot_Parent_Transaction_ID,Bot_Param_ID,Bot_Param_Value)
	VALUES(@Bot_ID,@Bot_Machine_ID,@Bot_Execution_ID,@Bot_Transaction_ID,@Bot_Parent_Transaction_ID,@Bot_Param_ID,@Bot_Param_Value)
END

GO
/****** Object:  StoredProcedure [dbo].[BOT_TRANSACTION_LOG_DETAILS_INSERT]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Himanshu Manjarawala
-- Create date: 
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[BOT_TRANSACTION_LOG_DETAILS_INSERT] 
	-- Add the parameters for the stored procedure here
	@Bot_ID uniqueidentifier, 
	@Bot_Machine_ID uniqueidentifier,
	@Bot_Execution_ID uniqueidentifier,
	@Log_TaskName varchar(50),
	@Log_Type varchar(10),
	@Log_Message varchar(max),
	@Bot_Transaction_ID uniqueidentifier=null,
	@Bot_Parent_Transaction_ID uniqueidentifier=null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	INSERT INTO dbo.Bot_Transaction_Log_Details(Bot_ID,Bot_Machine_ID,Bot_Transaction_ID,Log_Timestamp,Log_TaskName,Log_Type,Log_Message,Bot_Execution_ID,Bot_Parent_Transaction_ID)
	 VALUES(@Bot_ID,@Bot_Machine_ID,@Bot_Transaction_ID,CURRENT_TIMESTAMP,@Log_TaskName,@Log_Type,@Log_Message,@Bot_Execution_ID,@Bot_Parent_Transaction_ID)
END

GO
/****** Object:  StoredProcedure [dbo].[BOT_TRANSACTION_MASTER_INSERT]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Himanshu Manjarawala
-- Create date: 
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[BOT_TRANSACTION_MASTER_INSERT] 
	-- Add the parameters for the stored procedure here
	@Bot_ID uniqueidentifier, 
	@Bot_Machine_ID uniqueidentifier,
	@Bot_Execution_ID uniqueidentifier,
	@Bot_Transaction_ID uniqueidentifier output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	SET @Bot_Transaction_ID = NEWID()
	INSERT INTO dbo.Bot_Transaction_Master(Bot_ID, Bot_Machine_ID, Bot_Transaction_ID, Transaction_Start_Time, Transaction_Status, Bot_Execution_ID)
		Values(@Bot_ID, @Bot_Machine_ID, @Bot_Transaction_ID, GETDATE(),0,@Bot_Execution_ID)
END

GO
/****** Object:  StoredProcedure [dbo].[BOT_TRANSACTION_MASTER_INSERT_CHILD]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Himanshu Manjarawala
-- Create date: 
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[BOT_TRANSACTION_MASTER_INSERT_CHILD] 
	-- Add the parameters for the stored procedure here
	@Bot_ID uniqueidentifier, 
	@Bot_Machine_ID uniqueidentifier,
	@Bot_Execution_ID uniqueidentifier,
	@Bot_Parent_Transaction_ID uniqueidentifier,
	@Bot_Transaction_ID uniqueidentifier output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SET @Bot_Transaction_ID = NEWID()
	INSERT INTO dbo.Bot_Transaction_Master(Bot_ID, Bot_Machine_ID, Bot_Transaction_ID, Transaction_Start_Time, Transaction_Status, Bot_Parent_Transaction_ID,Bot_Execution_ID)
		Values(@Bot_ID, @Bot_Machine_ID, @Bot_Transaction_ID, GETDATE(),0,@Bot_Parent_Transaction_ID,@Bot_Execution_ID)
END

GO
/****** Object:  StoredProcedure [dbo].[BOT_TRANSACTION_MASTER_UPDATE]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Himanshu Manjarawala
-- Create date: 21-11-2019
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[BOT_TRANSACTION_MASTER_UPDATE] 
	-- Add the parameters for the stored procedure here
	@Bot_ID uniqueidentifier, 
	@Bot_Machine_ID uniqueidentifier,
	@Bot_Execution_ID uniqueidentifier,
	@Bot_Transaction_ID uniqueidentifier,
	@Transaction_Status int,
	@Transaction_Comments varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE dbo.Bot_Transaction_Master
	Set Transaction_End_Time = GETDATE(),
		Transaction_Status = @Transaction_Status,
		Transaction_Comment = @Transaction_Comments
	WHERE Bot_Transaction_ID = @Bot_Transaction_ID
	AND   Bot_Execution_ID = @Bot_Execution_ID
	AND	  Bot_Machine_ID = @Bot_Machine_ID
	AND	  Bot_ID = @Bot_ID
END

GO
/****** Object:  StoredProcedure [dbo].[BOT_TRANSACTION_MASTER_UPDATE_CHILD]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Himanshu Manjarawala
-- Create date: 21-11-2019
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[BOT_TRANSACTION_MASTER_UPDATE_CHILD] 
	-- Add the parameters for the stored procedure here
	@Bot_ID uniqueidentifier, 
	@Bot_Machine_ID uniqueidentifier,
	@Bot_Execution_ID uniqueidentifier,
	@Bot_Transaction_ID uniqueidentifier,
	@Bot_Parent_Transaction_ID uniqueidentifier,
	@Transaction_Status int,
	@Transaction_Comments varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE dbo.Bot_Transaction_Master
	Set Transaction_End_Time = GETDATE(),
		Transaction_Status = @Transaction_Status,
		Transaction_Comment = @Transaction_Comments
	WHERE Bot_Transaction_ID = @Bot_Transaction_ID
	AND   Bot_Execution_ID = @Bot_Execution_ID
	AND   Bot_Parent_Transaction_ID = @Bot_Parent_Transaction_ID
	AND	  Bot_Machine_ID = @Bot_Machine_ID
	AND	  Bot_ID = @Bot_ID
END

GO
/****** Object:  StoredProcedure [dbo].[CREATE_VIEW_FOR_BOT]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Himanshu Manjarawala
-- Create date: 
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[CREATE_VIEW_FOR_BOT] 
	-- Add the parameters for the stored procedure here
	@View_Name varchar(50), 
	@Bot_Name varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @cols AS NVARCHAR(MAX), @colsRollup AS NVARCHAR(MAX), @query  AS NVARCHAR(MAX),@Bot_ID as uniqueidentifier,@Condition as varchar(100), @temp as varchar(max)

	IF @Bot_Name IS NULL OR RTRIM(LTRIM(@Bot_Name)) = ''
	BEGIN
		PRINT('Bot Name should''t be NULL or Empty!')
	END
	ELSE IF @View_Name IS NULL OR RTRIM(LTRIM(@View_Name)) = ''
	BEGIN
		PRINT('View Name should''t be NULL or Empty!')
	END
	ELSE IF NOT EXISTS(SELECT 1 FROM sys.views s WHERE s.name=@View_Name)
	BEGIN	

		-- Insert statements for procedure here
		select @Bot_ID = Bot_ID from Bot_Master where Bot_Name = @Bot_Name

		SET @Condition = 'WHERE tr.Transaction_Status = 1'

		SET @temp = CASE WHEN @Bot_Name IS NULL THEN '' ELSE ' AND  b.Bot_ID = ''' + convert(nvarchar(50), @Bot_ID) + ''''  END

		Set @Condition = @Condition + @temp

		select @cols = STUFF((SELECT ',' + QUOTENAME(Bot_Param_Name) FROM BOT_PARAMETER_MASTER WHERE Bot_ID = @Bot_ID FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'')

		select @colsRollup = STUFF((SELECT ',Min(' + QUOTENAME(Bot_Param_Name) + ') AS ' + QUOTENAME(Bot_Param_Name) FROM BOT_PARAMETER_MASTER WHERE Bot_ID = @Bot_ID  FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'')

		set @query = 'SELECT Bot_Name,Machine_Name,Param_Date,Bot_Execution_ID,Bot_Transaction_ID,Bot_Parent_Transaction_ID,transaction_status,' + @cols + ' from 
				 (
					select  tr.Bot_ID,
							b.Bot_Name,
							tr.Bot_Machine_ID,
							m.Machine_Name,
							convert(date, tr.Transaction_Start_Time) as Param_Date,
							tr.Bot_Execution_ID,
							tr.Bot_Transaction_ID,
							tr.Bot_Parent_Transaction_ID,
							tr.transaction_status,
							r.Bot_Param_ID,
							r.Bot_Param_Name,
							c.Bot_Param_Value
					from Bot_Transaction_Master tr
					left join Bot_Master b
						on tr.Bot_ID = b.Bot_ID
					left join Bot_Machine_Master m
						on tr.Bot_Machine_ID = m.Machine_ID
					left join Bot_Parameter_Master r
						on tr.Bot_ID = r.Bot_ID
					left outer join Bot_Parameter_Value_Details c
						on tr.Bot_ID = c.Bot_ID
						and tr.Bot_Machine_ID = c.Bot_Machine_ID
						and tr.Bot_Execution_ID = c.Bot_Execution_ID
						and tr.Bot_Transaction_ID = c.Bot_Transaction_ID
						and r.Bot_Param_ID = c.Bot_Param_ID '
				 + @Condition + '
				) x
				pivot 
				(
					MIN(Bot_Param_Value)
					for Bot_Param_Name in (' + @cols + ')
				) p '

		set @query = 'SELECT Bot_Name,Machine_Name,Param_Date,Bot_Execution_ID,Bot_Transaction_ID,Bot_Parent_Transaction_ID,transaction_status,' + @colsRollup + ' from 
					(' + @query + ') x1 GROUP BY Bot_Name,Machine_Name,Param_Date,Bot_Execution_ID,Bot_Transaction_ID,Bot_Parent_Transaction_ID,transaction_status'

		set @query = 'CREATE VIEW ' + @View_Name + ' AS ' + @query

		PRINT(@Condition)
		execute(@query)
	END
END
GO
/****** Object:  StoredProcedure [dbo].[GET_BOT_PERFORMANCE]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Himanshu Manjarawala
-- Create date: 
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[GET_BOT_PERFORMANCE] 
	-- Add the parameters for the stored procedure here
	@Bot_Name varchar(50), 
	@Machine_Name varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Condition as varchar(max), @SQLQuery as varchar(max), @temp as varchar(max)

	SET @Condition = ''

	SET @temp = CASE WHEN @Bot_Name IS NULL OR rtrim(lTrim(@Bot_Name)) = '' THEN '' ELSE ' AND Bot_Name = ''' + @Bot_Name + '''' END

	SET @Condition = @Condition + @temp

	SET @temp = CASE WHEN @Machine_Name IS NULL OR rtrim(lTrim(@Machine_Name)) = '' THEN '' ELSE ' AND Machine_Name = ''' + @Machine_Name + '''' END

	SET @Condition = @Condition + @temp

    -- Insert statements for procedure here
	SET @SQLQuery = '
	SELECT [Bot_Name], [Machine_Name], [Bot_User_Name], [Bot_Execution_Date], SUM(SUCCESS) AS SUCCESS, SUM(FAILED) as FAILED, SUM(INPROGRESS) as INPROGRESS
	From (
		SELECT [Bot_Name]
			  ,[Machine_Name]
			  ,[Bot_User_Name]
			  ,[Bot_Execution_Date]
			  ,[Bot_Transaction_ID]
			  ,[SUCCESS]
			  ,[FAILED]
			  ,[INPROGRESS]
		  FROM [CRDB-NEW].[dbo].[VIEW_BOT_PERFORMANCE]
		  WHERE 1 = 1' + @Condition + '
	) x
	GROUP BY [Bot_Name], [Machine_Name], [Bot_User_Name], [Bot_Execution_Date] 
	ORDER BY [Bot_Execution_Date] DESC'

	exec(@SQLQuery)
END

GO
/****** Object:  StoredProcedure [dbo].[GET_MACHINE_UTILIZATION]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Himanshu Manjarawala
-- Create date: 
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[GET_MACHINE_UTILIZATION] 
	-- Add the parameters for the stored procedure here
	@Bot_Name varchar(50), 
	@Machine_Name varchar(50) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Condition as varchar(max), @SQLQuery as varchar(max), @temp as varchar(50)

	SET @Condition = 'WHERE 1 = 1'

	SET @temp = CASE WHEN @Bot_Name IS NULL OR rtrim(lTrim(@Bot_Name)) = '' THEN '' ELSE ' AND Bot_Name = ''' + @Bot_Name + '''' END

	SET @Condition = @Condition + @temp

	SET @temp = CASE WHEN @Machine_Name IS NULL OR rtrim(lTrim(@Machine_Name)) = '' THEN '' ELSE ' AND Machine_Name = ''' + @Machine_Name + '''' END

	SET @Condition = @Condition + @temp

    -- Insert statements for procedure here
	SET @SQLQuery = '
	SELECT [Machine_Name]
      ,[Bot_Name]
      ,[Bot_Execution_Date]
	  ,[Bot_User_Name]
      ,dbo.ConvertTimeToHHMMSS(sum([Running_Time])) as Running_Time
	  ,dbo.ConvertTimeToHHMMSS(sum([Idle_Time])) as Idle_Time
	  ,dbo.ConvertTimeToHHMMSS(sum([Running_Time]) + sum([Idle_Time])) as Total_Elapsed_Time
  FROM [CRDB-NEW].[dbo].[VIEW_BOT_WISE_MACHINE_UTILIZATION]'
  + @Condition + '
  group by Machine_Name,Bot_Name,Bot_Execution_Date,Bot_User_Name'

	exec(@SQLQuery)
END

GO
/****** Object:  StoredProcedure [dbo].[GET_TRANSACTION_PARAMETER_DETAILS]    Script Date: 01-07-2020 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Himanshu Manjarawala
-- Create date: 
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[GET_TRANSACTION_PARAMETER_DETAILS] 
	-- Add the parameters for the stored procedure here
	@Bot_Name varchar(50), 
	@Machine_Name varchar(50) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @cols AS NVARCHAR(MAX), @colsRollup AS NVARCHAR(MAX), @query  AS NVARCHAR(MAX),@Bot_ID as uniqueidentifier,@Condition as varchar(100), @temp as varchar(max)

	SET @Condition = 'WHERE tr.Transaction_Status <> 0'

	IF @Bot_Name IS NULL OR RTRIM(LTRIM(@Bot_Name)) = ''
	BEGIN
		PRINT('Bot Name should''t be NULL or Empty!')
	END

	SET @temp = CASE WHEN @Bot_Name IS NULL OR rtrim(lTrim(@Bot_Name)) = '' THEN '' ELSE ' AND  b.Bot_Name = ''' + @Bot_Name + ''''  END

	Set @Condition = @Condition + @temp 

	SET @temp = CASE WHEN @Machine_Name IS NULL OR rtrim(lTrim(@Machine_Name)) = '' THEN '' ELSE ' AND  m.Machine_Name = ''' + @Machine_Name + ''''  END

	Set @Condition = @Condition + @temp

    -- Insert statements for procedure here
	select @Bot_ID = Bot_ID from Bot_Master where Bot_Name = @Bot_Name

	select @cols = STUFF((SELECT ',' + QUOTENAME(Bot_Param_Name) FROM BOT_PARAMETER_MASTER WHERE Bot_ID = @Bot_ID FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'')

	select @colsRollup = STUFF((SELECT ',Min(' + QUOTENAME(Bot_Param_Name) + ') AS ' + QUOTENAME(Bot_Param_Name) FROM BOT_PARAMETER_MASTER WHERE Bot_ID = @Bot_ID  FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'')

	set @query = 'SELECT Bot_Name,Machine_Name,Param_Date,Bot_Execution_ID,Bot_Transaction_ID,Bot_Parent_Transaction_ID,' + @cols + ' from 
             (
                select c.Bot_ID,
				  b.Bot_Name,
                  c.Bot_Machine_ID,
				  m.Machine_Name,
				  convert(date, tr.Transaction_Start_Time) as Param_Date,
				  c.Bot_Execution_ID,
				  c.Bot_Transaction_ID,
				  c.Bot_Parent_Transaction_ID,
				  r.Bot_Param_ID,
                  r.Bot_Param_Name,
				  c.Bot_Param_Value
                from Bot_Parameter_Value_Details c
                left join Bot_Parameter_Master r
                  on c.Bot_ID = r.Bot_ID
				  and c.Bot_Param_ID = r.Bot_Param_ID
				left join Bot_Machine_Master m
				  on c.Bot_Machine_ID = m.Machine_ID
				left join Bot_Master b
				  on c.Bot_ID = b.Bot_ID
				left join Bot_Transaction_Master tr
				  on c.Bot_transaction_ID = tr.Bot_Transaction_ID '
			 + @Condition + '
            ) x
            pivot 
            (
                MIN(Bot_Param_Value)
                for Bot_Param_Name in (' + @cols + ')
            ) p '

set @query = 'SELECT Bot_Name,Machine_Name,Param_Date,Bot_Execution_ID,Bot_Transaction_ID,Bot_Parent_Transaction_ID,' + @colsRollup + ' from 
				(' + @query + ') x1 GROUP BY Bot_Name,Machine_Name,Param_Date,Bot_Execution_ID,Bot_Transaction_ID,Bot_Parent_Transaction_ID'

execute(@query)
END

GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Bot_Execution_Master"
            Begin Extent = 
               Top = 98
               Left = 222
               Bottom = 228
               Right = 414
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "Bot_Transaction_Master"
            Begin Extent = 
               Top = 103
               Left = 522
               Bottom = 233
               Right = 751
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Bot_Master"
            Begin Extent = 
               Top = 0
               Left = 449
               Bottom = 113
               Right = 619
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Bot_Machine_Master"
            Begin Extent = 
               Top = 0
               Left = 12
               Bottom = 96
               Right = 184
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1800
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VIEW_BOT_PERFORMANCE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VIEW_BOT_PERFORMANCE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Bot_Execution_Master"
            Begin Extent = 
               Top = 117
               Left = 245
               Bottom = 247
               Right = 437
            End
            DisplayFlags = 280
            TopColumn = 2
         End
         Begin Table = "Bot_Machine_Master"
            Begin Extent = 
               Top = 16
               Left = 30
               Bottom = 112
               Right = 202
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Bot_Master"
            Begin Extent = 
               Top = 6
               Left = 478
               Bottom = 119
               Right = 648
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 3090
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VIEW_BOT_WISE_MACHINE_UTILIZATION'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VIEW_BOT_WISE_MACHINE_UTILIZATION'
GO
