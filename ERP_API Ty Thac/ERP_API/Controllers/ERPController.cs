using ERP_API.Models;
using Hangfire.Server;
using Hangfire.States;
using Hangfire.Storage;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Reflection;
using System.Reflection.Emit;
using System.Reflection.PortableExecutable;
using System.Runtime.InteropServices.JavaScript;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Xml.Linq;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace ERP_API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ERPController : ControllerBase
    {
        private readonly string TelegramToken = "7569203150:AAF-zwYQRU-GRvvL_eGifd1AWkH1qKS7NgM";
        private readonly HttpClient _httpClient;
        public readonly IConfiguration _configuration;

        public ERPController(HttpClient httpClient, IConfiguration configuration)
        {
            _configuration = configuration;
            _httpClient = httpClient;
        }

        public void CheckCuttingData(string RY)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlCommand SQL = new SqlCommand(
                System.String.Format(
                    "DECLARE @Result BIT; " +
                    "SET @Result = ( " +
                    "  SELECT CASE WHEN (SOP.SOPDate >= ZL.ZLDate OR ZL.ZLDate IS NULL OR ZL.Piece = 0) /*AND SOP.YN <> '5'*/ THEN 1 ELSE 0 END AS Result FROM ( " +
                    "    SELECT DDBH, YN, MAX(UserDate) AS SOPDate FROM ( " +
                    "      SELECT DDZL.DDBH, KT_SOPCut.UserDate, DDZL.YN FROM DDZL " +
                    "      LEFT JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao " +
                    "      WHERE DDZL.DDBH = '{0}' " +
                    "      UNION ALL " +
                    "      SELECT DDZL.DDBH, KT_SOPCutS.UserDate, DDZL.YN FROM DDZL " +
                    "      LEFT JOIN KT_SOPCutS ON KT_SOPCutS.XieXing = DDZL.XieXing AND KT_SOPCutS.SheHao = DDZL.SheHao " +
                    "      WHERE DDZL.DDBH = '{0}' " +
                    "    ) AS SOP " +
                    "    GROUP BY DDBH, YN " +
                    "  ) AS SOP " +
                    "  LEFT JOIN ( " +
                    "    SELECT CutDispatchZL.ZLBH, MIN(CutDispatchZL.UserDate) AS ZLDate, MIN(KT_SOPCut.piece) AS Piece FROM CutDispatchZL " +
                    "    LEFT JOIN DDZL ON DDZL.DDBH = CutDispatchZL.ZLBH " +
                    "    LEFT JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao AND KT_SOPCut.BWBH = CutDispatchZL.BWBH " +
                    "    WHERE CutDispatchZL.ZLBH = '{0}' AND SUBSTRING(CutDispatchZL.CLBH, 1, 1) NOT IN('L', 'N', 'J') " +
                    "    GROUP BY CutDispatchZL.ZLBH " +
                    "  ) AS ZL ON ZL.ZLBH = SOP.DDBH " +
                    "); " +

                    "IF @Result = 1 " +
                    "BEGIN " +
                    "  DELETE FROM CutDispatchZL WHERE ZLBH = '{0}' " +
                    "  INSERT INTO CutDispatchZL (ZLBH, BWBH, CLBH, SIZE, Qty, XXCC, PieceS, CutNum, Piece, Layer, Joinnum, USERID, USERDATE, YN) " +
                    "  SELECT ZLBH, BWBH, CLBH, CC AS SIZE, Qty, XXCC, SUM(Qty) * piece AS PieceS, " +
                    "  CASE WHEN joinnum > 0 THEN CEILING(SUM(Qty) * piece / CONVERT(FLOAT, layer) * joinnum) ELSE 0 END AS CutNum, " +
                    "  Piece, Layer, joinnum, 'app' AS UserID, GetDate() AS UserDate, 1 AS YN FROM ( " +
                    "    SELECT ZLZLS2.ZLBH, ZLZLS2.BWBH, ZLZLS2.CLBH, DDZLS.CC, MAX(DDZLS.Quantity) AS Qty, KT_SOPCutS.XXCC, KT_SOPCut.Piece, KT_SOPCut.Layer, KT_SOPCut.joinnum FROM ZLZLS2 " +
                    "    INNER JOIN DDZL ON DDZL.DDBH = ZLZLS2.ZLBH " +
                    "    INNER JOIN DDZLS ON DDZL.DDBH = DDZLS.DDBH AND (DDZLS.CC = ZLZLS2.SIZE OR 'ZZZZZZ' = ZLZLS2.SIZE) " +
                    "    INNER JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao AND KT_SOPCut.BWBH = ZLZLS2.BWBH " +
                    "    INNER JOIN KT_SOPCutS ON KT_SOPCutS.XieXing = KT_SOPCut.XieXing AND KT_SOPCutS.SheHao = KT_SOPCut.SheHao AND KT_SOPCutS.BWBH = KT_SOPCut.BWBH AND DDZLS.CC = KT_SOPCutS.SIZE " +
                    "    INNER JOIN XXZLS ON XXZLS.XieXing = KT_SOPCut.XieXing AND XXZLS.Shehao = KT_SOPCut.SheHao AND XXZLS.BWBH = KT_SOPCut.BWBH AND XXZLS.CCQQ <= DDZLS.CC AND XXZLS.CCQZ >= DDZLS.CC " +
                    "    WHERE ZLZLS2.MJBH = 'ZZZZZZZZZZ' AND ZLZLS2.ZLBH = '{0}' " +
                    "    GROUP BY ZLZLS2.ZLBH, ZLZLS2.BWBH, ZLZLS2.CLBH, KT_SOPCut.piece, KT_SOPCut.layer, KT_SOPCut.joinnum, DDZLS.CC, KT_SOPCutS.XXCC " +
                    "  ) AS ZLZLCut " +
                    "  WHERE 1 = 1 " +
                    "  GROUP BY ZLBH, BWBH, CLBH, CC, Qty, XXCC, Piece, Layer, joinnum " +
                    "  UNION ALL " +
                    "  SELECT ZLBH, BWBH, CLBH, CC AS SIZE, Qty, XXCC, SUM(Qty) * piece AS PieceS, " +
                    "  CASE WHEN joinnum > 0 THEN CEILING(SUM(Qty) * piece / CONVERT(FLOAT, layer) * joinnum) ELSE 0 END AS CutNum, " +
                    "  Piece, Layer, joinnum, 'app' AS UserID, GetDate() AS UserDate, 1 AS YN FROM ( " +
                    "    SELECT ZLZLS2.ZLBH, ZLZLS2.BWBH, ZLZLS2.CLBH, DDZLS.CC, MAX(DDZLS.Quantity) AS Qty, KT_SOPCutS.XXCC, KT_SOPCut.Piece, KT_SOPCut.Layer, KT_SOPCut.joinnum FROM ZLZLS2 " +
                    "    INNER JOIN DDZL ON DDZL.DDBH = ZLZLS2.ZLBH " +
                    "    INNER JOIN DDZLS ON DDZL.DDBH = DDZLS.DDBH AND (DDZLS.CC = ZLZLS2.SIZE OR 'ZZZZZZ' = ZLZLS2.SIZE) " +
                    "    INNER JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao AND KT_SOPCut.BWBH = ZLZLS2.BWBH " +
                    "    INNER JOIN KT_SOPCutS ON KT_SOPCutS.XieXing = KT_SOPCut.XieXing AND KT_SOPCutS.SheHao = KT_SOPCut.SheHao AND KT_SOPCutS.BWBH = KT_SOPCut.BWBH AND DDZLS.CC = KT_SOPCutS.SIZE " +
                    "    INNER JOIN XXZLS ON XXZLS.XieXing = KT_SOPCut.XieXing AND XXZLS.Shehao = KT_SOPCut.SheHao AND XXZLS.BWBH = KT_SOPCut.BWBH AND ISNULL(XXZLS.CCQQ, '') = '' AND ISNULL(XXZLS.CCQZ, '') = '' " +
                    "    WHERE ZLZLS2.MJBH = 'ZZZZZZZZZZ' AND ZLZLS2.ZLBH = '{0}' " +
                    "    GROUP BY ZLZLS2.ZLBH, ZLZLS2.BWBH, ZLZLS2.CLBH, KT_SOPCut.piece, KT_SOPCut.layer, KT_SOPCut.joinnum, DDZLS.CC, KT_SOPCutS.XXCC " +
                    "  ) AS ZLZLCut " +
                    "  WHERE 1 = 1 " +
                    "  GROUP BY ZLBH, BWBH, CLBH, CC, Qty, XXCC, Piece, Layer, joinnum " +
                    "  UNION ALL " +
                    "  SELECT ZLBH, BWBH, CLBH, CC AS SIZE, Qty, XXCC, SUM(Qty) * piece AS PieceS, " +
                    "  CASE WHEN joinnum > 0 THEN CEILING(SUM(Qty) * piece / CONVERT(FLOAT, layer) * joinnum) ELSE 0 END AS CutNum, " +
                    "  Piece, Layer, joinnum, 'app' AS UserID, GetDate() AS UserDate, 1 AS YN FROM ( " +
                    "    SELECT ZLZLS2.ZLBH, ZLZLS2.BWBH, ZLZLS2.CLBH, DDZLS.CC, MAX(DDZLS.Quantity) AS Qty, KT_SOPCutS.XXCC, KT_SOPCut.Piece, KT_SOPCut.Layer, KT_SOPCut.joinnum FROM ZLZLS2 " +
                    "    INNER JOIN DDZL ON DDZL.DDBH = ZLZLS2.ZLBH " +
                    "    INNER JOIN DDZLS ON DDZL.DDBH = DDZLS.DDBH AND (DDZLS.CC = ZLZLS2.SIZE OR 'ZZZZZZ' = ZLZLS2.SIZE) " +
                    "    INNER JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao AND KT_SOPCut.BWBH = ZLZLS2.BWBH " +
                    "    INNER JOIN KT_SOPCutS ON KT_SOPCutS.XieXing = KT_SOPCut.XieXing AND KT_SOPCutS.SheHao = KT_SOPCut.SheHao AND KT_SOPCutS.BWBH = KT_SOPCut.BWBH AND DDZLS.CC = KT_SOPCutS.SIZE " +
                    "    WHERE ZLZLS2.MJBH = 'ZZZZZZZZZZ' AND ZLZLS2.ZLBH = '{0}' AND NOT EXISTS (SELECT BWBH FROM XXZLS WHERE XXZLS.BWBH = KT_SOPcut.BWBH AND XXZLS.XieXing = KT_SOPcut.XieXing AND XXZLS.SheHao = KT_SOPcut.SheHao) " +
                    "    GROUP BY ZLZLS2.ZLBH, ZLZLS2.BWBH, ZLZLS2.CLBH, KT_SOPCut.piece, KT_SOPCut.layer, KT_SOPCut.joinnum, DDZLS.CC, KT_SOPCutS.XXCC " +
                    "  ) AS ZLZLCut " +
                    "  WHERE 1 = 1 " +
                    "  GROUP BY ZLBH, BWBH, CLBH, CC, Qty, XXCC, Piece, Layer, joinnum " +
                    "END; "
                    , RY
                ), ERP
            );

            ERP.Open();
            SQL.ExecuteNonQuery();
            ERP.Dispose();
        }

        public void CheckProcessingData(string RY)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlCommand SQL = new SqlCommand(
                System.String.Format(
                    "DECLARE @Result BIT; " +
                    "SET @Result = ( " +
                    "  SELECT CASE WHEN SOP.SOPDate > ZL.ZLDate AND SOP.YN <> '5' THEN 1 ELSE 0 END AS Result FROM ( " +
                    "    SELECT DDBH, YN, MAX(UserDate) AS SOPDate FROM ( " +
                    "      SELECT DDZL.DDBH, KT_SOPCutS_GCS.UserDate, DDZL.YN FROM DDZL " +
                    "      LEFT JOIN KT_SOPCutS_GCS ON KT_SOPCutS_GCS.XieXing = DDZL.XieXing AND KT_SOPCutS_GCS.SheHao = DDZL.SheHao " +
                    "      WHERE DDZL.DDBH = '{0}' " +
                    "      UNION ALL " +
                    "      SELECT DDZL.DDBH, KT_SOPCut.UserDate, DDZL.YN FROM DDZL " +
                    "      LEFT JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao " +
                    "      WHERE DDZL.DDBH = '{0}' " +
                    "      UNION ALL " +
                    "      SELECT DDZL.DDBH, KT_SOPCutS.UserDate, DDZL.YN FROM DDZL " +
                    "      LEFT JOIN KT_SOPCutS ON KT_SOPCutS.XieXing = DDZL.XieXing AND KT_SOPCutS.SheHao = DDZL.SheHao " +
                    "      WHERE DDZL.DDBH = '{0}' " +
                    "    ) AS SOP " +
                    "    GROUP BY DDBH, YN " +
                    "  ) AS SOP " +
                    "  LEFT JOIN ( " +
                    "    SELECT ZLBH, MIN(UserDate) AS ZLDate FROM CutDispatchZL_GC " +
                    "    WHERE ZLBH = '{0}' " +
                    "    GROUP BY ZLBH " +
                    "  ) AS ZL ON ZL.ZLBH = SOP.DDBH " +
                    "); " +

                    "IF @Result = 1 " +
                    "BEGIN " +
                    "  DELETE FROM CutDispatchZL_GC WHERE ZLBH = '{0}' " +
                    "  INSERT INTO CutDispatchZL_GC (ZLBH, BWBH, CLBH, SIZE, Qty, Levels, GCBWBH, PDay, EarlyDay, PDays, USERID, USERDATE, YN) " +
                    "  SELECT ZLZLS2_GC.*, NULL AS PDay, NULL AS EaryDay, NULL AS PDays, 'app' AS UserID, GetDate() AS UserDate, '1' AS YN FROM ( " +
                    "    SELECT ZLZLS2.ZLBH, ZLZLS2.BWBH, ZLZLS2.CLBH, DDZLS.CC, SUM(DDZLS.Quantity) AS Qty, KT_SOPCutS_GC.levels, KT_SOPCutS_GC.gcbwdh FROM ZLZLS2 " +
                    "    INNER JOIN DDZL ON DDZL.DDBH = ZLZLS2.ZLBH " +
                    "    INNER JOIN DDZLS ON DDZL.DDBH = DDZLS.DDBH AND (DDZLS.CC = ZLZLS2.SIZE OR 'ZZZZZZ' = ZLZLS2.SIZE) " +
                    "    INNER JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao AND KT_SOPCut.BWBH = ZLZLS2.BWBH " +
                    "    INNER JOIN KT_SOPCutS ON KT_SOPCutS.XieXing = KT_SOPCut.XieXing AND KT_SOPCutS.SheHao = KT_SOPCut.SheHao AND KT_SOPCutS.BWBH = KT_SOPCut.BWBH AND DDZLS.CC = KT_SOPCutS.SIZE " +
                    "    LEFT JOIN( " +
                    "      SELECT KT_SOPCutS_GC.XieXing, KT_SOPCutS_GC.SheHao, KT_SOPCutS_GC.levels, KT_SOPCutS_GCS.gcbwdh, KT_SOPCutS_GCS.bwdh FROM KT_SOPCutS_GCS " +
                    "      LEFT JOIN KT_SOPCutS_GC ON KT_SOPCutS_GC.XieXing = KT_SOPCutS_GCS.XieXing AND KT_SOPCutS_GC.SheHao = KT_SOPCutS_GCS.SheHao AND KT_SOPCutS_GC.gcbwdh = KT_SOPCutS_GCS.gcbwdh " +
                    "      WHERE KT_SOPCutS_GCS.bwdh NOT LIKE '0G%' " +
                    "    ) AS KT_SOPCutS_GC ON KT_SOPCutS_GC.XieXing = DDZL.XieXing AND KT_SOPCutS_GC.SheHao = DDZL.SheHao AND KT_SOPCutS_GC.bwdh = ZLZLS2.BWBH " +
                    "    WHERE ZLZLS2.MJBH = 'ZZZZZZZZZZ' AND ZLZLS2.ZLBH = '{0}' AND KT_SOPCutS_GC.bwdh IS NOT NULL " +
                    "    GROUP BY ZLZLS2.ZLBH, ZLZLS2.BWBH, ZLZLS2.CLBH, DDZLS.CC, KT_SOPCutS_GC.levels, KT_SOPCutS_GC.gcbwdh " +
                    "    UNION ALL " +
                    "    SELECT DDZL.DDBH AS ZLBH, KT_SOPCutS_GCS.bwdh, 'ZZZZZZZZZZ' AS CLBH, DDZLS.CC, SUM(DDZLS.Quantity) AS Qty, KT_SOPCutS_GC.levels, KT_SOPCutS_GC.gcbwdh FROM DDZL " +
                    "    INNER JOIN DDZLS ON DDZL.DDBH = DDZLS.DDBH " +
                    "    INNER JOIN KT_SOPCutS_GC ON KT_SOPCutS_GC.XieXing = DDZL.XieXing AND KT_SOPCutS_GC.SheHao = DDZL.SheHao " +
                    "    INNER JOIN KT_SOPCutS_GCS ON KT_SOPCutS_GC.XieXing = KT_SOPCutS_GCS.XieXing AND KT_SOPCutS_GC.SheHao = KT_SOPCutS_GCS.SheHao AND KT_SOPCutS_GC.gcbwdh = KT_SOPCutS_GCS.gcbwdh " +
                    "    WHERE DDZL.DDBH = '{0}' AND KT_SOPCutS_GCS.bwdh LIKE '0G%' " +
                    "    GROUP BY DDZL.DDBH, KT_SOPCutS_GCS.bwdh, DDZLS.CC, KT_SOPCutS_GC.levels, KT_SOPCutS_GC.gcbwdh " +
                    "  ) AS ZLZLS2_GC; " +
                    "  UPDATE CutDispatchZL_GC SET PDay = ZLDay_GC.PDay, EarlyDay = ZLDay_GC.EarlyDay, PDays = ZLDay_GC.PDays " +
                    "  FROM ( " +
                    "    SELECT ZL_GC.*, ( " +
                    "      SELECT ROUND(SUM(ISNULL(PDay, EarlyDay)) + 0.49, 0) AS PDays FROM ( " +
                    "        SELECT CutDispatchZL_GC.Levels, SUM(ROUND(CutDispatchZL_GC.Qty / KT_SOPCutS_GCBWD.Qty1Day, 2)) AS PDay, MAX(KT_SOPCutS_GCBWD.EarlyDay) AS EarlyDay FROM CutDispatchZL_GC " +
                    "        LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.gcbwdh = CutDispatchZL_GC.GCBWBH " +
                    "        WHERE ZLBH = ZL_GC.ZLBH " +
                    "        GROUP BY CutDispatchZL_GC.Levels " +
                    "      ) AS CutDispatchZL_GC " +
                    "      WHERE 1 = 1 AND ( " +
                    "        Levels = SUBSTRING(ZL_GC.Levels, 1, 1) OR Levels = SUBSTRING(ZL_GC.Levels, 1, 2) OR Levels = SUBSTRING(ZL_GC.Levels, 1, 3) OR Levels = SUBSTRING(ZL_GC.Levels, 1, 4) " +
                    "        OR Levels = SUBSTRING(ZL_GC.Levels, 1, 5) OR Levels = SUBSTRING(ZL_GC.Levels, 1, 6) OR Levels = SUBSTRING(ZL_GC.Levels, 1, 7) OR Levels = SUBSTRING(ZL_GC.Levels, 1, 8) " +
                    "      ) " +
                    "    ) AS PDays FROM( " +
                    "      SELECT ZLBH, Levels, GCBWBH, ROUND(SUM(PDay), 2) AS PDay, MAX(EarlyDay) AS EarlyDay FROM( " +
                    "        SELECT CutDispatchZL_GC.ZLBH, CutDispatchZL_GC.GCBWBH, CutDispatchZL_GC.Levels, ROUND(CutDispatchZL_GC.Qty / KT_SOPCutS_GCBWD.Qty1Day, 2) AS PDay, KT_SOPCutS_GCBWD.EarlyDay FROM CutDispatchZL_GC " +
                    "        LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.gcbwdh = CutDispatchZL_GC.GCBWBH " +
                    "        WHERE ZLBH = '{0}' " +
                    "      ) AS CutDispatchZL_GC " +
                    "      GROUP BY ZLBH, Levels, GCBWBH " +
                    "    ) AS ZL_GC " +
                    "  ) AS ZLDay_GC " +
                    "  WHERE ZLDay_GC.ZLBH = CutDispatchZL_GC.ZLBH AND ZLDay_GC.GCBWBH = CutDispatchZL_GC.GCBWBH AND ZLDay_GC.Levels = CutDispatchZL_GC.Levels " +
                    "END; "
                    , RY
                ), ERP
            );

            ERP.Open();
            SQL.ExecuteNonQuery();
            ERP.Dispose();
        }

        [HttpPost]
        [Route("sendTelegramMessage")]
        public async Task<IActionResult> sendTelegramMessage(TGRequest request)
        {
            string telegramUrl = "https://api.telegram.org/bot" + TelegramToken + "/sendMessage";
            var data = new
            {
                chat_id = request.ChatID,
                parse_mode = request.ParseMode ?? "HTML",
                text = request.Text
            };
            string jsonData = JsonConvert.SerializeObject(data);
            var content = new StringContent(jsonData, Encoding.UTF8, "application/json");
            HttpResponseMessage response = await _httpClient.PostAsync(telegramUrl, content);
            if (response.IsSuccessStatusCode)
            {
                string responseContent = await response.Content.ReadAsStringAsync();
                return Ok(new { Message = "Forwarded successfully" });
            }
            else
            {
                return StatusCode((int)response.StatusCode, response.Content.ReadAsStringAsync());
            }
        }

        [HttpPost]
        [Route("login")]
        public string login(LoginInfo info)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT APP_Users.UserID, APP_Users.UserName, APP_Users.Groups, APP_Users.Factory, " +
                    "CASE WHEN SUBSTRING(APP_Users.Department, 1, 2) IN ('3F', '4F') THEN APP_Users.Department ELSE '3F_LINE 01' END AS Department FROM APP_Users " +
                    "LEFT JOIN BUsers ON BUsers.UserID = APP_Users.UserID " +
                    "WHERE APP_Users.UserID = '{0}' AND BUsers.PWD = '{1}' AND ISNULL(Busers.TYJH, '') <> 'Y' ",
                    info.UserID, info.Password
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            LoginResult ls = new LoginResult();
            if (dt.Rows.Count > 0)
            {
                Task.Run(() => {
                    SqlCommand SQL = new SqlCommand(
                        System.String.Format(
                            "UPDATE APP_Users SET LastActiveTime = GetDate(), FirebaseToken = '{1}', Version = '{2}' WHERE UserID = '{0}';" +
                            "UPDATE Busers SET LASTDATETIME = GetDate(), fromIP = 'Production App', MEMO = 'App User' WHERE UserID = '{0}';",
                            info.UserID, info.FirebaseToken, info.version
                        ), ERP
                    );

                    ERP.Open();
                    int recordCount = SQL.ExecuteNonQuery();
                    ERP.Dispose();
                });
                
                ls.Result = true;
                ls.Status = "Successful";
                ls.UserID = dt.Rows[0]["UserID"].ToString();
                ls.UserName = dt.Rows[0]["UserName"].ToString();
                ls.Group = dt.Rows[0]["Groups"].ToString();
                ls.Department = dt.Rows[0]["Department"].ToString();
                ls.Factory = dt.Rows[0]["Factory"].ToString();
                return JsonConvert.SerializeObject(ls);
            }
            else
            {
                ls.Result = false;
                ls.Status = "Failed";
                ls.UserID = info.UserID;
                ls.UserName = "";
                ls.Group = "";
                ls.Department = "";
                ls.Factory = "";
                return JsonConvert.SerializeObject(ls);
            }
        }

        [HttpPost]
        [Route("updateUserPassword")]
        public string updateUserPassword(LoginInfo info)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlCommand SQL = new SqlCommand(
                System.String.Format(
                    "UPDATE BUsers SET PWD = '{1}', passwordchend = GetDate() WHERE UserID = '{0}';",
                    info.UserID, info.Password.Replace("'", "''")
                ), ERP
            );

            ERP.Open();
            int recordCount = SQL.ExecuteNonQuery();
            ERP.Dispose();

            LoginResult ls = new LoginResult();
            if (recordCount > 0)
            {
                ls.Result = true;
                ls.Status = "Successful";
            }
            else
            {
                ls.Result = false;
                ls.Status = "Failed";
            }
            return JsonConvert.SerializeObject(ls);
        }

        [HttpPost]
        [Route("getScheduleData")]
        public string getScheduleData(ScheduleRequest request)
        {
            DateTime StartDate = DateTime.Parse(request.Month! + "/01");
            DateTime EndDate = new DateTime(StartDate.AddMonths(1).Year, StartDate.AddMonths(1).Month, 1).AddDays(-1);

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#SC') IS NOT NULL " +
                    "BEGIN DROP TABLE #SC END; " +

                    "SET ARITHABORT ON; " +

                    "SELECT SC.lean_no, SC.Date, SC.ry_index, SC.DDBH, SC.bts, SC.DAOMH, SC.chat_lieu, SC.XTMH, SC.buy, SC.Article, SC.sl, SC.ShipDate, SC.country, SC.SubSeq, " +
                    "ISNULL(CASE WHEN ISNUMERIC(SUBSTRING(Cycles, CHARINDEX('-', Cycles)+1, 10)) = 1 AND ISNUMERIC(SUBSTRING(Cycles, 1, CHARINDEX('-', Cycles)-1)) = 1 THEN " +
                    "CAST(SUBSTRING(Cycles, 1, CHARINDEX('-', Cycles)-1) AS INT) END, 1) AS MinCycle, " +
                    "ISNULL(CASE WHEN ISNUMERIC(SUBSTRING(Cycles, CHARINDEX('-', Cycles)+1, 10)) = 1 AND ISNUMERIC(SUBSTRING(Cycles, 1, CHARINDEX('-', Cycles)-1)) = 1 THEN " +
                    "CAST(SUBSTRING(Cycles, CHARINDEX('-', Cycles)+1, 10) AS INT) END, MAX(CASE WHEN SMDD.DDBH = SMDD.YSBH THEN 1 ELSE CAST(RIGHT(SMDD.DDBH, 3) AS INT) END)) AS MaxCycle INTO #SC FROM ( " +
                    "  SELECT lean_no, Date, ry_index, DDBH, bts, DAOMH, chat_lieu, XTMH, buy, Article, sl, ShipDate, country, SubSeq, x.value('.', 'NVARCHAR(50)') AS Cycles FROM ( " +
                    "    SELECT lean_no, Date, ry_index, DDBH, bts, DAOMH, chat_lieu, XTMH, buy, Article, sl, ShipDate, country, SubSeq, CAST('<x>' + REPLACE(Cycles, '+', '</x><x>') + '</x>' AS XML) AS XmlData FROM ( " +
                    "      SELECT SC.building_no + ' LINE ' + RIGHT('00' + CAST(CAST(RIGHT(SC.lean_no, 2) AS INT) AS VARCHAR), 2) AS lean_no, CONVERT(VARCHAR, SC.schedule_date, 111) AS Date, CAST(SC.ry_index AS INT) AS ry_index, DDZL.DDBH, " +
                    "      SC.bts, XXZL.DAOMH, SC.chat_lieu, XXZL.XTMH, SC.buy, DDZL.Article, CAST(SC.sl AS INT) AS sl, CONVERT(VARCHAR, DDZL.ShipDate, 111) AS ShipDate, SC.country, " +
                    "      CASE WHEN RIGHT(SC.ry, 3) LIKE '%-%' THEN SUBSTRING(RIGHT(SC.ry, 3), CHARINDEX('-', RIGHT(SC.ry, 3)) + 1, LEN(RIGHT(SC.ry, 3)) - CHARINDEX('-', RIGHT(SC.ry, 3))) END AS SubSeq, " +
                    "      CASE WHEN REPLACE(SC.stitching, ' ', '') LIKE 'T%' THEN REPLACE(REPLACE(REPLACE(SC.stitching, ' ', ''), '~', '-'), 'T', '') ELSE NULL END AS Cycles FROM schedule_crawler AS SC " +
                    "      LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END " +
                    "      LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "      WHERE SC.building_no = '{1}' AND SUBSTRING(CONVERT(VARCHAR, SC.schedule_date, 111), 1, 7) = '{0}' " +
                    "    ) AS SC " +
                    "  ) AS SC " +
                    "  OUTER APPLY XmlData.nodes('/x') AS B(x) " +
                    ") AS SC " +
                    "LEFT JOIN SMDD ON SMDD.YSBH = SC.DDBH AND SMDD.GXLB = 'A' " +
                    "GROUP BY SC.lean_no, SC.Date, SC.ry_index, SC.DDBH, SC.bts, SC.DAOMH, SC.chat_lieu, SC.XTMH, SC.buy, SC.Article, SC.sl, SC.ShipDate, SC.country, SC.SubSeq, SC.Cycles; " +

                    "WITH TEMPTAB(Date) AS ( " +
                    "  SELECT CONVERT(SmallDateTime, '{2}') " +
                    "  UNION ALL " +
                    "  SELECT DATEADD(D, 1, TEMPTAB.DATE) AS Date FROM TEMPTAB " +
                    "  WHERE DATEADD(D, 1, TEMPTAB.DATE) <= CONVERT(SmallDateTime, '{3}') " +
                    ") " +

                    "SELECT lean_no, CONVERT(VARCHAR, Date, 111) AS Date, ry_index, DDBH, bts, DAOMH, chat_lieu, XTMH, buy, Article, sl, ShipDate, country FROM ( " +
                    "  SELECT SC.lean_no, SC.Date, SC.ry_index, SC.DDBH + ISNULL('-' + SC.SubSeq, '') AS DDBH, SC.bts, SC.DAOMH, SC.chat_lieu, SC.XTMH, SC.buy, SC.Article, SC.sl, SC.ShipDate, SC.country FROM #SC AS SC " +
                    "  UNION ALL " +
                    "  SELECT Lean, Date, -1, '', '', '', '', '', '', '', 0, '', '' FROM ( " +
                    "    SELECT SC.Lean, TEMPTAB.Date FROM ( " +
                    "      SELECT DISTINCT UPPER(building_no + ' LINE ' + RIGHT('00' + CAST(CAST(RIGHT(lean_no, 2) AS INT) AS VARCHAR), 2)) AS Lean FROM schedule_crawler " +
                    "      WHERE building_no = '{1}' AND SUBSTRING(CONVERT(VARCHAR, schedule_date, 111), 1, 7) = '{0}' " +
                    "    ) AS SC " +
                    "    LEFT JOIN TEMPTAB ON 1 = 1 " +
                    "    WHERE DATEPART(DW, TEMPTAB.Date) = 1 " +
                    "    UNION " +
                    "    SELECT TEMPTAB.Lean, TEMPTAB.Date FROM ( " +
                    "      SELECT SC.Lean, TEMPTAB.Date FROM TEMPTAB " +
                    "      LEFT JOIN ( " +
                    "        SELECT DISTINCT lean_no AS Lean FROM #SC " +
                    "      ) AS SC ON 1 = 1 " +
                    "    ) AS TEMPTAB " +
                    "    LEFT JOIN ( " +
                    "      SELECT UPPER(REPLACE(BDepartment.DepName, '_G', '')) AS Lean, CONVERT(SmallDateTime, SCRL.SCYEAR + '/' + SCRL.SCMONTH + '/' + SCRL.SCDay) AS Date FROM SCRL " +
                    "      LEFT JOIN BDepartment ON BDepartment.ID = SCRL.DepNO " +
                    "      WHERE CONVERT(SmallDateTime, SCRL.SCYEAR + '/' + SCRL.SCMONTH + '/' + SCRL.SCDay) BETWEEN '{2}' AND '{3}' " +
                    "      AND BDepartment.DepName LIKE 'DT_G-{1}-%' AND BDepartment.GXLB = 'A' AND ISNULL(SCRL.SCGS, 0) > 0 " +
                    "    ) AS SCRL ON SCRL.Date = TEMPTAB.Date " +
                    "    WHERE SCRL.Date IS NULL " +
                    "  ) AS SCRL " +
                    ") AS SC " +
                    "ORDER BY SC.lean_no, SC.ry_index, CONVERT(VARCHAR, Date, 111) " +
                    "OPTION (MAXRECURSION 0) "
                    , request.Month, request.Building, StartDate.ToString("yyyy/MM/dd"), EndDate.ToString("yyyy/MM/dd")
                ), ERP
            );

            DataTable dt = new DataTable();
            da.Fill(dt);
            List<dynamic> ResultList = new List<dynamic>();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                int index = 1;
                while (Row < dt.Rows.Count)
                {
                    ScheduleLean scheduleLean = new ScheduleLean();
                    scheduleLean.Lean = dt.Rows[Row]["lean_no"].ToString();
                    scheduleLean.Holiday = new List<int>();
                    scheduleLean.Sequence = new List<Sequence>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["lean_no"].ToString() == scheduleLean.Lean)
                    {
                        if ((int)dt.Rows[Row]["ry_index"] > 0)
                        {
                            Sequence Seq = new Sequence();
                            Seq.Index = index;
                            Seq.Schedule = new List<ScheduleResult>();

                            while (Row < dt.Rows.Count && (int)dt.Rows[Row]["ry_index"] == Seq.Index)
                            {
                                ScheduleResult OrderInfo = new ScheduleResult();
                                OrderInfo.Date = dt.Rows[Row]["Date"].ToString();
                                OrderInfo.Order = dt.Rows[Row]["DDBH"].ToString();
                                OrderInfo.SubTitle = dt.Rows[Row]["bts"].ToString();
                                OrderInfo.DieCutMold = dt.Rows[Row]["DAOMH"].ToString();
                                OrderInfo.Material = dt.Rows[Row]["chat_lieu"].ToString();
                                OrderInfo.LastMold = dt.Rows[Row]["XTMH"].ToString();
                                OrderInfo.BuyNo = dt.Rows[Row]["buy"].ToString();
                                OrderInfo.SKU = dt.Rows[Row]["Article"].ToString();
                                OrderInfo.Pairs = (int)dt.Rows[Row]["sl"];
                                OrderInfo.ShipDate = dt.Rows[Row]["ShipDate"].ToString();
                                OrderInfo.Country = dt.Rows[Row]["country"].ToString();

                                Seq.Schedule.Add(OrderInfo);
                                Row++;
                            }

                            scheduleLean.Sequence.Add(Seq);
                            index = Row < dt.Rows.Count ? (int)dt.Rows[Row]["ry_index"] : 0;
                        }
                        else
                        {
                            string HDate = dt.Rows[Row]["Date"].ToString()!;
                            scheduleLean.Holiday.Add(int.Parse(HDate.Substring(HDate.Length - 2)));
                            Row++;
                        }
                    }

                    ResultList.Add(scheduleLean);
                    index = 1;
                }

                return JsonConvert.SerializeObject(ResultList);
            }
            else
            {
                return "{}";
            }
        }

        [HttpPost]
        [Route("getMonthOrder")]
        public string getMonthOrder(MonthOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#PS') IS NOT NULL " +
                    "BEGIN DROP TABLE #PS END; " +

                    "SELECT CAST(ROW_NUMBER() OVER(ORDER BY PS.schedule_date, PS.ry_index) AS INT) AS Seq, " +
                    "CONVERT(VARCHAR, CONVERT(SmallDateTime, PS.schedule_date), 111) AS AssemblyDate, CONVERT(VARCHAR, DDZL.ShipDate, 111) AS ShipDate, " +
                    "CASE WHEN LEN(PS.ry) - LEN(REPLACE(PS.ry, '-', '')) < 2 THEN PS.ry ELSE SUBSTRING(PS.ry, 1, LEN(PS.ry) - CHARINDEX('-', REVERSE(PS.ry))) END AS DDBH, " +
                    "CAST(PS.sl AS INT) AS Pairs, DDZL.Article, XXZL.DAOMH, CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR) + ' BUY' AS BuyNo INTO #PS FROM schedule_crawler AS PS " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(PS.ry) - LEN(REPLACE(PS.ry, '-', '')) < 2 THEN PS.ry ELSE SUBSTRING(PS.ry, 1, LEN(PS.ry) - CHARINDEX('-', REVERSE(PS.ry))) END " +
                    "LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "WHERE PS.building_no + '_' + PS.lean_no = '{0}' AND CAST(YEAR(PS.schedule_date) AS VARCHAR) + '/' + RIGHT('00' + CAST(MONTH(PS.schedule_date) AS VARCHAR), 2) = '{1}' AND DDZL.DDBH LIKE '{2}%' " +

                    "SELECT ZL.Seq, ZL.AssemblyDate, ZL.ShipDate, ZL.DDBH, ZL.Pairs, ZL.Article, ZL.DAOMH, ZL.BuyNo, " +
                    "ISNULL(SUM(ZL.ZLQty), 0) AS ZLQty, ISNULL(SUM(DP.Qty), 0) AS Qty, ISNULL(SUM(DP.ScanQty), 0) AS ScanQty FROM ( " +
                    "  SELECT PS.Seq, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, PS.Article, PS.DAOMH, PS.BuyNo, " +
                    "  CutDispatchZL.BWBH, CutDispatchZL.CLBH, CutDispatchZL.SIZE, " +
                    "  ISNULL(SUM(CutDispatchZL.Qty), 0) AS ZLQty FROM #PS AS PS " +
                    "  LEFT JOIN CutDispatchZL ON CutDispatchZL.ZLBH = PS.DDBH " +
                    "  LEFT JOIN DDZL ON DDZL.DDBH = CutDispatchZL.ZLBH " +
                    "  LEFT JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao AND KT_SOPCut.BWBH = CutDispatchZL.BWBH " +
                    "  WHERE (SUBSTRING(ISNULL(CutDispatchZL.CLBH, ''), 1, 1) NOT IN ('L', 'M', 'J') AND KT_SOPCut.piece > 0) OR CutDispatchZL.BWBH IS NULL " +
                    "  GROUP BY PS.Seq, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, PS.Article, PS.DAOMH, PS.BuyNo, CutDispatchZL.BWBH, CutDispatchZL.CLBH, CutDispatchZL.SIZE " +
                    ") AS ZL " +
                    "LEFT JOIN ( " +
                    "  SELECT PS.Seq, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, PS.Article, PS.DAOMH, PS.BuyNo, " +
                    "  CutDispatchSS.BWBH, CutDispatchSS.CLBH, CutDispatchSS.SIZE, " +
                    "  ISNULL(SUM(CutDispatchSS.Qty), 0) AS Qty, ISNULL(SUM(CutDispatchSS.ScanQty), 0) AS ScanQty FROM #PS AS PS " +
                    "  LEFT JOIN CutDispatchSS ON CutDispatchSS.ZLBH = PS.DDBH " +
                    "  GROUP BY PS.Seq, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, PS.Article, PS.DAOMH, PS.BuyNo, CutDispatchSS.BWBH, CutDispatchSS.CLBH, CutDispatchSS.SIZE " +
                    ") AS DP ON DP.DDBH = ZL.DDBH AND DP.BWBH = ZL.BWBH AND DP.CLBH = ZL.CLBH AND DP.SIZE = ZL.SIZE " +
                    "GROUP BY ZL.Seq, ZL.AssemblyDate, ZL.ShipDate, ZL.DDBH, ZL.Pairs, ZL.Article, ZL.DAOMH, ZL.BuyNo " +
                    (request.Type == "Incomplete" ? "HAVING ISNULL(SUM(DP.Qty), 0) < ISNULL(SUM(ZL.ZLQty), 0) OR ISNULL(SUM(ZL.ZLQty), 0) = 0 " : "") +
                    "ORDER BY ZL.Seq "
                    , request.Lean, request.PlanMonth, request.Order
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<MonthOrderResult> orderList = new List<MonthOrderResult>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    MonthOrderResult order = new MonthOrderResult();
                    order.Seq = (int)dt.Rows[i]["Seq"];
                    order.AssemblyDate = dt.Rows[i]["AssemblyDate"].ToString();
                    order.ShipDate = dt.Rows[i]["ShipDate"].ToString();
                    order.Order = dt.Rows[i]["DDBH"].ToString();
                    order.Pairs = (int)dt.Rows[i]["Pairs"];
                    order.SKU = dt.Rows[i]["Article"].ToString();
                    order.DieCut = dt.Rows[i]["DAOMH"].ToString();
                    order.BuyNo = dt.Rows[i]["BuyNo"].ToString();
                    int ZLQty = (int)dt.Rows[i]["ZLQty"], Qty = (int)dt.Rows[i]["Qty"], ScanQty = (int)dt.Rows[i]["ScanQty"];

                    if (ZLQty > 0)
                    {
                        if (Qty > 0)
                        {
                            if (ScanQty < ZLQty)
                            {
                                order.Status = "InProduction";
                            }
                            else
                            {
                                order.Status = "Completed";
                            }
                        }
                        else
                        {
                            order.Status = "NotDispatch";
                        }
                    }
                    else
                    {
                        order.Status = "NoCuttingData";
                    }

                    orderList.Add(order);
                }

                return JsonConvert.SerializeObject(orderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getMonthProcessingOrder")]
        public string getMonthProcessingOrder(MonthOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#PS') IS NOT NULL " +
                    "BEGIN DROP TABLE #PS END; " +

                    "SELECT CAST(ROW_NUMBER() OVER(ORDER BY PS.schedule_date, PS.ry_index) AS INT) AS Seq, " +
                    "CONVERT(VARCHAR, CONVERT(SmallDateTime, PS.schedule_date), 111) AS AssemblyDate, CONVERT(VARCHAR, DDZL.ShipDate, 111) AS ShipDate, " +
                    "CASE WHEN LEN(PS.ry) - LEN(REPLACE(PS.ry, '-', '')) < 2 THEN PS.ry ELSE SUBSTRING(PS.ry, 1, LEN(PS.ry) - CHARINDEX('-', REVERSE(PS.ry))) END AS DDBH, " +
                    "CAST(PS.sl AS INT) AS Pairs, DDZL.Article, XXZL.DAOMH, CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR) + ' BUY' AS BuyNo INTO #PS FROM schedule_crawler AS PS " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(PS.ry) - LEN(REPLACE(PS.ry, '-', '')) < 2 THEN PS.ry ELSE SUBSTRING(PS.ry, 1, LEN(PS.ry) - CHARINDEX('-', REVERSE(PS.ry))) END " +
                    "LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "WHERE PS.building_no + '_' + PS.lean_no = '{0}' AND CAST(YEAR(PS.schedule_date) AS VARCHAR) + '/' + RIGHT('00' + CAST(MONTH(PS.schedule_date) AS VARCHAR), 2) = '{1}' AND DDZL.DDBH LIKE '{2}%' " +

                    "SELECT ZL.Seq, ZL.AssemblyDate, ZL.ShipDate, ZL.DDBH, ZL.Pairs, ZL.Article, ZL.DAOMH, ZL.BuyNo, " +
                    "ISNULL(SUM(ZL.ZLQty), 0) AS ZLQty, ISNULL(SUM(DP.Qty), 0) AS Qty, ISNULL(SUM(DP.ScanQty), 0) AS ScanQty FROM ( " +
                    "  SELECT PS.Seq, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, PS.Article, PS.DAOMH, PS.BuyNo, " +
                    "  CutDispatchZL_GC.GCBWBH, CutDispatchZL_GC.BWBH, CutDispatchZL_GC.SIZE, " +
                    "  ISNULL(SUM(CutDispatchZL_GC.Qty), 0) AS ZLQty FROM #PS AS PS " +
                    "  LEFT JOIN CutDispatchZL_GC ON CutDispatchZL_GC.ZLBH = PS.DDBH " +
                    "  GROUP BY PS.Seq, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, PS.Article, PS.DAOMH, PS.BuyNo, CutDispatchZL_GC.GCBWBH, CutDispatchZL_GC.BWBH, CutDispatchZL_GC.SIZE " +
                    ") AS ZL " +
                    "LEFT JOIN ( " +
                    "  SELECT PS.Seq, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, PS.Article, PS.DAOMH, PS.BuyNo, " +
                    "  CutDispatchSS_GC.GCBWBH, CutDispatchSS_GC.BWBH, CutDispatchSS_GC.SIZE, " +
                    "  ISNULL(SUM(CutDispatchSS_GC.Qty), 0) AS Qty, ISNULL(SUM(CutDispatchSS_GC.ScanQty), 0) AS ScanQty FROM #PS AS PS " +
                    "  LEFT JOIN CutDispatchSS_GC ON CutDispatchSS_GC.ZLBH = PS.DDBH " +
                    "  GROUP BY PS.Seq, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, PS.Article, PS.DAOMH, PS.BuyNo, CutDispatchSS_GC.GCBWBH, CutDispatchSS_GC.BWBH, CutDispatchSS_GC.SIZE " +
                    ") AS DP ON DP.DDBH = ZL.DDBH AND DP.GCBWBH = ZL.GCBWBH AND DP.BWBH = ZL.BWBH AND DP.SIZE = ZL.SIZE " +
                    "GROUP BY ZL.Seq, ZL.AssemblyDate, ZL.ShipDate, ZL.DDBH, ZL.Pairs, ZL.Article, ZL.DAOMH, ZL.BuyNo " +
                    "HAVING ISNULL(SUM(ZL.ZLQty), 0) > 0 " + (request.Type == "Incomplete" ? "AND ISNULL(SUM(DP.Qty), 0) < ISNULL(SUM(ZL.ZLQty), 0) " : "") +
                    "ORDER BY ZL.Seq "
                    , request.Lean, request.PlanMonth, request.Order
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<MonthOrderResult> orderList = new List<MonthOrderResult>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    MonthOrderResult order = new MonthOrderResult();
                    order.Seq = (int)dt.Rows[i]["Seq"];
                    order.AssemblyDate = dt.Rows[i]["AssemblyDate"].ToString();
                    order.ShipDate = dt.Rows[i]["ShipDate"].ToString();
                    order.Order = dt.Rows[i]["DDBH"].ToString();
                    order.Pairs = (int)dt.Rows[i]["Pairs"];
                    order.SKU = dt.Rows[i]["Article"].ToString();
                    order.DieCut = dt.Rows[i]["DAOMH"].ToString();
                    order.BuyNo = dt.Rows[i]["BuyNo"].ToString();
                    int ZLQty = (int)dt.Rows[i]["ZLQty"], Qty = (int)dt.Rows[i]["Qty"], ScanQty = (int)dt.Rows[i]["ScanQty"];

                    if (ZLQty > 0)
                    {
                        if (Qty > 0)
                        {
                            if (ScanQty < ZLQty)
                            {
                                order.Status = "InProduction";
                            }
                            else
                            {
                                order.Status = "Completed";
                            }
                        }
                        else
                        {
                            order.Status = "NotDispatch";
                        }
                    }
                    else
                    {
                        order.Status = "NoProcessData";
                    }

                    orderList.Add(order);
                }

                return JsonConvert.SerializeObject(orderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getMonthStitchingOrder")]
        public string getMonthStitchingOrder(MonthOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#PS') IS NOT NULL " +
                    "BEGIN DROP TABLE #PS END; " +

                    "SELECT CAST(ROW_NUMBER() OVER(ORDER BY PS.schedule_date, PS.ry_index) AS INT) AS Seq, " +
                    "CONVERT(VARCHAR, CONVERT(SmallDateTime, PS.schedule_date), 111) AS AssemblyDate, CONVERT(VARCHAR, DDZL.ShipDate, 111) AS ShipDate, " +
                    "CASE WHEN LEN(PS.ry) - LEN(REPLACE(PS.ry, '-', '')) < 2 THEN PS.ry ELSE SUBSTRING(PS.ry, 1, LEN(PS.ry) - CHARINDEX('-', REVERSE(PS.ry))) END AS DDBH, " +
                    "CAST(PS.sl AS INT) AS Pairs, DDZL.Article, XXZL.DAOMH, CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR) + ' BUY' AS BuyNo INTO #PS FROM schedule_crawler AS PS " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(PS.ry) - LEN(REPLACE(PS.ry, '-', '')) < 2 THEN PS.ry ELSE SUBSTRING(PS.ry, 1, LEN(PS.ry) - CHARINDEX('-', REVERSE(PS.ry))) END " +
                    "LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "WHERE PS.building_no + '_' + PS.lean_no = '{0}' AND CAST(YEAR(PS.schedule_date) AS VARCHAR) + '/' + RIGHT('00' + CAST(MONTH(PS.schedule_date) AS VARCHAR), 2) = '{1}' AND DDZL.DDBH LIKE '{2}%' " +

                    "SELECT ZL.Seq, ZL.AssemblyDate, ZL.ShipDate, ZL.DDBH, ZL.Pairs, ZL.Article, ZL.DAOMH, ZL.BuyNo, " +
                    "ISNULL(ZL.ZLQty, 0) AS ZLQty, ISNULL(DP.Qty, 0) AS Qty, ISNULL(ZL.ScanQty, 0) AS ScanQty FROM ( " +
                    "  SELECT PS.Seq, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, PS.Article, PS.DAOMH, PS.BuyNo, " +
                    "  ISNULL(SUM(SMDDSS.CTS), 0) AS ZLQty, ISNULL(SUM(SMDDSS.okCTS), 0) AS ScanQty FROM #PS AS PS " +
                    "  LEFT JOIN SMDD ON SMDD.YSBH = PS.DDBH " +
                    "  LEFT JOIN SMDDSS ON SMDDSS.DDBH = SMDD.DDBH AND SMDDSS.GXLB = SMDD.GXLB " +
                    "  WHERE SMDD.GXLB = 'S' " +
                    "  GROUP BY PS.Seq, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, PS.Article, PS.DAOMH, PS.BuyNo " +
                    ") AS ZL " +
                    "LEFT JOIN( " +
                    "  SELECT PS.Seq, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, PS.Article, PS.DAOMH, PS.BuyNo, ISNULL(SUM(SMDDSS.CTS), 0) AS Qty FROM #PS AS PS " +
                    "  LEFT JOIN CycleDispatch ON CycleDispatch.ZLBH = PS.DDBH " +
                    "  LEFT JOIN SMDDSS ON SMDDSS.DDBH = CycleDispatch.DDBH AND SMDDSS.GXLB = CycleDispatch.GXLB " +
                    "  WHERE CycleDispatch.GXLB = 'S' " +
                    "  GROUP BY PS.Seq, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, PS.Article, PS.DAOMH, PS.BuyNo " +
                    ") AS DP ON DP.DDBH = ZL.DDBH " +
                    (request.Type == "Incomplete" ? "WHERE ISNULL(DP.Qty, 0) < ISNULL(ZL.ZLQty, 0) OR ISNULL(ZL.ZLQty, 0) = 0 " : "") +
                    "ORDER BY ZL.Seq "
                    , request.Lean, request.PlanMonth, request.Order
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<MonthOrderResult> orderList = new List<MonthOrderResult>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    MonthOrderResult order = new MonthOrderResult();
                    order.Seq = (int)dt.Rows[i]["Seq"];
                    order.AssemblyDate = dt.Rows[i]["AssemblyDate"].ToString();
                    order.ShipDate = dt.Rows[i]["ShipDate"].ToString();
                    order.Order = dt.Rows[i]["DDBH"].ToString();
                    order.Pairs = (int)dt.Rows[i]["Pairs"];
                    order.SKU = dt.Rows[i]["Article"].ToString();
                    order.DieCut = dt.Rows[i]["DAOMH"].ToString();
                    order.BuyNo = dt.Rows[i]["BuyNo"].ToString();
                    int ZLQty = (int)dt.Rows[i]["ZLQty"], Qty = (int)dt.Rows[i]["Qty"], ScanQty = (int)dt.Rows[i]["ScanQty"];
                    if (ScanQty > Qty)
                    {
                        ScanQty = Qty;
                    }
                    if (ZLQty > 0)
                    {
                        if (Qty > 0)
                        {
                            if (ScanQty < ZLQty)
                            {
                                order.Status = "InProduction";
                            }
                            else
                            {
                                order.Status = "Completed";
                            }
                        }
                        else
                        {
                            order.Status = "NotDispatch";
                        }
                    }
                    else
                    {
                        if (order.Order != "")
                        {
                            order.Status = "NotDispatch";
                        }
                        else
                        {
                            order.Status = "NoCycleData";
                        }
                    }

                    orderList.Add(order);
                }

                return JsonConvert.SerializeObject(orderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getMonthAssemblyOrder")]
        public string getMonthAssemblyOrder(MonthOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#PS') IS NOT NULL " +
                    "BEGIN DROP TABLE #PS END; " +

                    "SELECT DISTINCT CAST(DENSE_RANK() OVER(ORDER BY PS.schedule_date, PS.ry_index) AS INT) AS Seq, " +
                    "CONVERT(VARCHAR, CONVERT(SmallDateTime, PS.schedule_date), 111) AS AssemblyDate, CONVERT(VARCHAR, DDZL.ShipDate, 111) AS ShipDate, " +
                    "CASE WHEN LEN(PS.ry) - LEN(REPLACE(PS.ry, '-', '')) < 2 THEN PS.ry ELSE SUBSTRING(PS.ry, 1, LEN(PS.ry) - CHARINDEX('-', REVERSE(PS.ry))) END AS DDBH, " +
                    "CAST(PS.sl AS INT) AS Pairs, DDZL.Article, XXZL.DAOMH, CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR) + ' BUY' AS BuyNo INTO #PS FROM schedule_crawler AS PS " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(PS.ry) - LEN(REPLACE(PS.ry, '-', '')) < 2 THEN PS.ry ELSE SUBSTRING(PS.ry, 1, LEN(PS.ry) - CHARINDEX('-', REVERSE(PS.ry))) END " +
                    "LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "LEFT JOIN ProductionPlan AS PP ON PP.Building = PS.building_no AND PP.Lean = PS.lean_no AND PP.RY = DDZL.DDBH " +
                    "WHERE PS.building_no + '_' + PS.lean_no = '{0}' AND CAST(YEAR(PS.schedule_date) AS VARCHAR) + '/' + RIGHT('00' + CAST(MONTH(PS.schedule_date) AS VARCHAR), 2) = '{1}' AND DDZL.DDBH LIKE '{2}%' " +
                    (request.Type == "Incomplete" ? "AND PP.PlanType = '1-Day' " : "") +

                    "SELECT ZL.Seq, ZL.AssemblyDate, ZL.ShipDate, ZL.DDBH, ZL.Pairs, ZL.Article, ZL.DAOMH, ZL.BuyNo, " +
                    "ISNULL(ZL.ZLQty, 0) AS ZLQty, ISNULL(DP.Qty, 0) AS Qty, ISNULL(ZL.ScanQty, 0) AS ScanQty FROM ( " +
                    "  SELECT PS.Seq, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, PS.Article, PS.DAOMH, PS.BuyNo, " +
                    "  ISNULL(SUM(SMDDSS.CTS), 0) AS ZLQty, ISNULL(SUM(SMDDSS.okCTS), 0) AS ScanQty FROM #PS AS PS " +
                    "  LEFT JOIN SMDD ON SMDD.YSBH = PS.DDBH " +
                    "  LEFT JOIN SMDDSS ON SMDDSS.DDBH = SMDD.DDBH AND SMDDSS.GXLB = SMDD.GXLB " +
                    "  WHERE SMDD.GXLB = 'A' " +
                    "  GROUP BY PS.Seq, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, PS.Article, PS.DAOMH, PS.BuyNo " +
                    ") AS ZL " +
                    "LEFT JOIN( " +
                    "  SELECT PS.Seq, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, PS.Article, PS.DAOMH, PS.BuyNo, ISNULL(SUM(SMDDSS.CTS), 0) AS Qty FROM #PS AS PS " +
                    "  LEFT JOIN CycleDispatch ON CycleDispatch.ZLBH = PS.DDBH " +
                    "  LEFT JOIN SMDDSS ON SMDDSS.DDBH = CycleDispatch.DDBH AND SMDDSS.GXLB = CycleDispatch.GXLB " +
                    "  WHERE CycleDispatch.GXLB = 'A' " +
                    "  GROUP BY PS.Seq, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, PS.Article, PS.DAOMH, PS.BuyNo " +
                    ") AS DP ON DP.DDBH = ZL.DDBH " +
                    (request.Type == "Incomplete" ? "WHERE ISNULL(DP.Qty, 0) < ISNULL(ZL.ZLQty, 0) OR ISNULL(ZL.ZLQty, 0) = 0 " : "") +
                    "ORDER BY ZL.Seq "
                    , request.Lean, request.PlanMonth, request.Order
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<MonthOrderResult> orderList = new List<MonthOrderResult>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    MonthOrderResult order = new MonthOrderResult();
                    order.Seq = (int)dt.Rows[i]["Seq"];
                    order.AssemblyDate = dt.Rows[i]["AssemblyDate"].ToString();
                    order.ShipDate = dt.Rows[i]["ShipDate"].ToString();
                    order.Order = dt.Rows[i]["DDBH"].ToString();
                    order.Pairs = (int)dt.Rows[i]["Pairs"];
                    order.SKU = dt.Rows[i]["Article"].ToString();
                    order.DieCut = dt.Rows[i]["DAOMH"].ToString();
                    order.BuyNo = dt.Rows[i]["BuyNo"].ToString();
                    int ZLQty = (int)dt.Rows[i]["ZLQty"], Qty = (int)dt.Rows[i]["Qty"], ScanQty = (int)dt.Rows[i]["ScanQty"];
                    if (ScanQty > Qty)
                    {
                        ScanQty = Qty;
                    }
                    if (ZLQty > 0)
                    {
                        if (Qty > 0)
                        {
                            if (ScanQty < ZLQty)
                            {
                                order.Status = "InProduction";
                            }
                            else
                            {
                                order.Status = "Completed";
                            }
                        }
                        else
                        {
                            order.Status = "NotDispatch";
                        }
                    }
                    else
                    {
                        if (order.Order != "")
                        {
                            order.Status = "NotDispatch";
                        }
                        else
                        {
                            order.Status = "NoCycleData";
                        }
                    }

                    orderList.Add(order);
                }

                return JsonConvert.SerializeObject(orderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getDispatchedOrder")]
        public string getDispatchedOrder(MonthOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#PS') IS NOT NULL " +
                    "BEGIN DROP TABLE #PS END; " +

                    "SELECT DISTINCT PS.ry_index, CONVERT(VARCHAR, CONVERT(SmallDateTime, PS.schedule_date), 111) AS AssemblyDate, CONVERT(VARCHAR, DDZL.ShipDate, 111) AS ShipDate, " +
                    "CASE WHEN LEN(PS.ry) - LEN(REPLACE(PS.ry, '-', '')) < 2 THEN PS.ry ELSE SUBSTRING(PS.ry, 1, LEN(PS.ry) - CHARINDEX('-', REVERSE(PS.ry))) END AS DDBH, " +
                    "CAST(PS.sl AS INT) AS Pairs, DDZL.Article, XXZL.DAOMH, CAST(CAST(CASE WHEN ISNUMERIC(SUBSTRING(DDZL.BUYNO, 5, 2)) = 1 THEN SUBSTRING(DDZL.BUYNO, 5, 2) ELSE 0 END AS INT) AS VARCHAR) + ' BUY' AS BuyNo INTO #PS FROM CutDispatch " +
                    "LEFT JOIN CutDispatchSS ON CutDispatchSS.DLNO = CutDispatch.DLNO " +
                    "LEFT JOIN schedule_crawler AS PS ON CASE WHEN LEN(PS.ry) - LEN(REPLACE(PS.ry, '-', '')) < 2 THEN PS.ry ELSE SUBSTRING(PS.ry, 1, LEN(PS.ry) - CHARINDEX('-', REVERSE(PS.ry))) END = CutDispatchSS.ZLBH " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(PS.ry) - LEN(REPLACE(PS.ry, '-', '')) < 2 THEN PS.ry ELSE SUBSTRING(PS.ry, 1, LEN(PS.ry) - CHARINDEX('-', REVERSE(PS.ry))) END " +
                    "LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "WHERE PS.building_no + '_' + PS.lean_no = '{0}' AND PS.ry IS NOT NULL AND DDZL.DDBH LIKE '{1}%' " +

                    "SELECT * FROM ( " +
                    "  SELECT CAST(ROW_NUMBER() OVER(ORDER BY PS.AssemblyDate, PS.ry_index) AS INT) AS Seq, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, " +
                    "  PS.Article, PS.DAOMH, PS.BuyNo, ISNULL(SUM(CutDispatchSS.Qty), 0) AS Qty, ISNULL(SUM(CutDispatchSS.ScanQty), 0) AS ScanQty FROM #PS AS PS " +
                    "  LEFT JOIN CutDispatchSS ON CutDispatchSS.ZLBH = PS.DDBH " +
                    "  GROUP BY PS.ry_index, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, PS.Article, PS.DAOMH, PS.BuyNo " +
                    ") AS PS " +
                    "WHERE Qty > ScanQty " +
                    "ORDER BY Seq "
                    , request.Lean, request.Order
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<MonthOrderResult> orderList = new List<MonthOrderResult>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    MonthOrderResult order = new MonthOrderResult();
                    order.Seq = (int)dt.Rows[i]["Seq"];
                    order.AssemblyDate = dt.Rows[i]["AssemblyDate"].ToString();
                    order.ShipDate = dt.Rows[i]["ShipDate"].ToString();
                    order.Order = dt.Rows[i]["DDBH"].ToString();
                    order.Pairs = (int)dt.Rows[i]["Pairs"];
                    order.SKU = dt.Rows[i]["Article"].ToString();
                    order.DieCut = dt.Rows[i]["DAOMH"].ToString();
                    order.BuyNo = dt.Rows[i]["BuyNo"].ToString();
                    order.Status = "InProduction";
                    orderList.Add(order);
                }

                return JsonConvert.SerializeObject(orderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getOrderCycleDispatchData")]
        public string getOrderCycleDispatchData(ProcessRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT SMDD.YSBH, SMDD.DDBH, CASE WHEN SUM(SMDDSS.CTS) > SUM(SMDDSS.okCTS) OR SUM(SMDDSS.CTS) IS NULL THEN 1 ELSE 2 END AS Dispatched, " +
                    "CASE WHEN CP.DDBH IS NULL THEN 0 ELSE 1 END AS Prepare FROM SMDD " +
                    "LEFT JOIN CycleDispatch ON CycleDispatch.DDBH = SMDD.DDBH AND CycleDispatch.GXLB = SMDD.GXLB " +
                    "LEFT JOIN CycleDispatch AS CP ON CP.DDBH = SMDD.DDBH AND CP.GXLB = 'P' " +
                    "LEFT JOIN SMDDSS ON SMDDSS.DDBH = CycleDispatch.DDBH AND SMDDSS.GXLB = CycleDispatch.GXLB " +
                    "WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = '{1}' " +
                    "GROUP BY SMDD.YSBH, SMDD.DDBH, CycleDispatch.DDBH, CP.DDBH " +
                    "ORDER BY SMDD.YSBH, SMDD.DDBH "
                    , request.Order, request.Section
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            OrderCycleList cycleList = new OrderCycleList();
            if (dt.Rows.Count > 0)
            {
                cycleList.Order = dt.Rows[0]["YSBH"].ToString();
                cycleList.Cycles = new List<CycleResult>();
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    CycleResult cycle = new CycleResult();
                    cycle.Cycle = dt.Rows[i]["DDBH"].ToString();
                    cycle.Dispatched = (int)dt.Rows[i]["Dispatched"];
                    cycle.Prepare = (int)dt.Rows[i]["Prepare"];
                    cycleList.Cycles.Add(cycle);
                }

                return JsonConvert.SerializeObject(cycleList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getProcessingDispatchedOrder")]
        public string getProcessingDispatchedOrder(MonthOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#PS') IS NOT NULL " +
                    "BEGIN DROP TABLE #PS END; " +

                    "SELECT DISTINCT PS.ry_index, CONVERT(VARCHAR, CONVERT(SmallDateTime, PS.schedule_date), 111) AS AssemblyDate, CONVERT(VARCHAR, DDZL.ShipDate, 111) AS ShipDate, " +
                    "CASE WHEN LEN(PS.ry) - LEN(REPLACE(PS.ry, '-', '')) < 2 THEN PS.ry ELSE SUBSTRING(PS.ry, 1, LEN(PS.ry) - CHARINDEX('-', REVERSE(PS.ry))) END AS DDBH, " +
                    "CAST(PS.sl AS INT) AS Pairs, DDZL.Article, XXZL.DAOMH, CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR) + ' BUY' AS BuyNo INTO #PS FROM CutDispatch_GC " +
                    "LEFT JOIN CutDispatchSS_GC ON CutDispatchSS_GC.DLNO = CutDispatch_GC.DLNO " +
                    "LEFT JOIN schedule_crawler AS PS ON CASE WHEN LEN(PS.ry) - LEN(REPLACE(PS.ry, '-', '')) < 2 THEN PS.ry ELSE SUBSTRING(PS.ry, 1, LEN(PS.ry) - CHARINDEX('-', REVERSE(PS.ry))) END = CutDispatchSS_GC.ZLBH " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(PS.ry) - LEN(REPLACE(PS.ry, '-', '')) < 2 THEN PS.ry ELSE SUBSTRING(PS.ry, 1, LEN(PS.ry) - CHARINDEX('-', REVERSE(PS.ry))) END " +
                    "LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "WHERE PS.building_no + '_' + PS.lean_no = '{0}' AND PS.ry IS NOT NULL AND DDZL.DDBH LIKE '{1}%' " +

                    "SELECT * FROM ( " +
                    "  SELECT CAST(ROW_NUMBER() OVER(ORDER BY PS.AssemblyDate, PS.ry_index) AS INT) AS Seq, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, " +
                    "  PS.Article, PS.DAOMH, PS.BuyNo, ISNULL(SUM(CutDispatchSS_GC.Qty), 0) AS Qty, ISNULL(SUM(CutDispatchSS_GC.ScanQty), 0) AS ScanQty FROM #PS AS PS " +
                    "  LEFT JOIN CutDispatchSS_GC ON CutDispatchSS_GC.ZLBH = PS.DDBH " +
                    "  GROUP BY PS.ry_index, PS.AssemblyDate, PS.ShipDate, PS.DDBH, PS.Pairs, PS.Article, PS.DAOMH, PS.BuyNo " +
                    ") AS PS " +
                    "WHERE Qty > ScanQty " +
                    "ORDER BY Seq "
                    , request.Lean, request.Order
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<MonthOrderResult> orderList = new List<MonthOrderResult>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    MonthOrderResult order = new MonthOrderResult();
                    order.Seq = (int)dt.Rows[i]["Seq"];
                    order.AssemblyDate = dt.Rows[i]["AssemblyDate"].ToString();
                    order.ShipDate = dt.Rows[i]["ShipDate"].ToString();
                    order.Order = dt.Rows[i]["DDBH"].ToString();
                    order.Pairs = (int)dt.Rows[i]["Pairs"];
                    order.SKU = dt.Rows[i]["Article"].ToString();
                    order.DieCut = dt.Rows[i]["DAOMH"].ToString();
                    order.BuyNo = dt.Rows[i]["BuyNo"].ToString();
                    order.Status = "InProduction";
                    orderList.Add(order);
                }

                return JsonConvert.SerializeObject(orderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getBuildingMonthlyCapacity")]
        public string getBuildingMonthlyCapacity(CommonRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "DECLARE @SDate VARCHAR(10) = ( " +
                    "  SELECT CONVERT(VARCHAR, CONVERT(SmallDateTime, LEFT('{0}', 8) + '01'), 111) AS SDate " +
                    "); " +

                    "DECLARE @EDate VARCHAR(10) = ( " +
                    "  SELECT CONVERT(VARCHAR, DATEADD(DAY, -1, DATEADD(MONTH, 1, CONVERT(SmallDateTime, LEFT('{0}', 8) + '01'))), 111) AS EDate " +
                    "); " +

                    "SELECT Type, Building AS GroupID, Building, 'LINE ' + RIGHT('00' + CAST(CAST(RIGHT(Lean, 2) AS INT) AS VARCHAR), 2) AS Lean, " +
                    "ISNULL(T_Finished, 0) AS T_Finished, ISNULL(T_Target, 0) AS T_Target, ISNULL(UT_Finished, 0) AS UT_Finished, ISNULL(UT_Target, 0) AS UT_Target, ISNULL(M_Target, 0) AS M_Target FROM ( " +
                    "  SELECT 'MP' AS Type, Target.Building AS GroupID, Target.Building, Target.Lean, Actual.T_Finished, Target.T_Target, Actual.UT_Finished, Target.UT_Target, Target.M_Target FROM ( " +
                    "    SELECT LEFT(REPLACE(DepName, 'DT_G-', ''), 2) AS Building, RIGHT(REPLACE(DepName, 'DT_G-', ''), 6) AS Lean, " +
                    "    SUM(CASE WHEN BZDate = CONVERT(VARCHAR, GETDATE(), 111) THEN SCBZCL.Qty END) AS T_Target, " +
                    "    SUM(CASE WHEN BZDate <= CONVERT(VARCHAR, GETDATE(), 111) THEN SCBZCL.Qty END) AS UT_Target, " +
                    "    SUM(SCBZCL.Qty) AS M_Target FROM SCBZCL " +
                    "    LEFT JOIN BDepartment ON BDepartment.ID = SCBZCL.DepNo " +
                    "    WHERE SCBZCL.BZDate BETWEEN @SDate AND @EDate AND ISNULL(SCBZCL.Qty, 0) > 0 AND (BDepartment.GXLB = 'A' AND BDepartment.DepName LIKE 'DT_G-%F%') " +
                    "    GROUP BY LEFT(REPLACE(DepName, 'DT_G-', ''), 2), RIGHT(REPLACE(DepName, 'DT_G-', ''), 6) " +
                    "  ) AS Target " +
                    "  LEFT JOIN ( " +
                    "    SELECT SC.Building, SC.Lean, SMZL.T_Finished, ISNULL(SMZL.T_Finished, 0) + ISNULL(SCBB.UT_Finished, 0) AS UT_Finished FROM ( " +
                    "      SELECT DISTINCT UPPER(building_no) AS Building, UPPER(lean_no) AS Lean FROM schedule_crawler " +
                    "      WHERE schedule_date BETWEEN @SDate AND @EDate AND GSBH = 'VDH' " +
                    "    ) AS SC " +
                    "    LEFT JOIN ( " +
                    "      SELECT LEFT(REPLACE(DepName, 'DT_G-', ''), 2) AS Building, RIGHT(REPLACE(DepName, 'DT_G-', ''), 6) AS Lean, CAST(SUM(SCBBS.Qty) AS INT) AS UT_Finished FROM SCBB " +
                    "      LEFT JOIN SCBBS ON SCBBS.ProNo = SCBB.ProNo " +
                    "      LEFT JOIN BDepartment ON BDepartment.ID = SCBB.DepNo " +
                    "      WHERE SCBB.SCDate BETWEEN @SDate AND @EDate AND SCBBS.GXLB = 'A' AND BDepartment.DepName LIKE 'DT_G-%F%' " +
                    "      GROUP BY LEFT(REPLACE(DepName, 'DT_G-', ''), 2), RIGHT(REPLACE(DepName, 'DT_G-', ''), 6) " +
                    "    ) AS SCBB ON SCBB.Building = SC.Building AND SCBB.Lean = SC.Lean " +
                    "    LEFT JOIN ( " +
                    "      SELECT LEFT(REPLACE(DepName, 'DT_G-', ''), 2) AS Building, RIGHT(REPLACE(DepName, 'DT_G-', ''), 6) AS Lean, SUM(SMZL.CTS * SMDDSS.Qty) AS T_Finished FROM SMZL " +
                    "      LEFT JOIN BDepartment ON BDepartment.ID = SMZL.DepNo " +
                    "      LEFT JOIN SMDDSS ON SMDDSS.CODEBAR = SMZL.CODEBAR " +
                    "      WHERE SMZL.ScanDate > CONVERT(VARCHAR, GETDATE(), 111) AND SMDDSS.GXLB = 'A' AND BDepartment.DepName LIKE 'DT_G-%' " +
                    "      GROUP BY LEFT(REPLACE(DepName, 'DT_G-', ''), 2), RIGHT(REPLACE(DepName, 'DT_G-', ''), 6) " +
                    "    ) AS SMZL ON SMZL.Building = SC.Building AND SMZL.Lean = SC.Lean " +
                    "  ) AS Actual ON Actual.Building = Target.Building AND Actual.Lean = Target.Lean " +
                    ") AS Capacity " +
                    "ORDER BY Building, CAST(RIGHT(Lean, 2) AS INT), Type DESC "
                    , request.Date
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<BuildingCapacity> buildingList = new List<BuildingCapacity>();
            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    BuildingCapacity building = new BuildingCapacity();
                    building.Group = dt.Rows[Row]["GroupID"].ToString();
                    building.Building = dt.Rows[Row]["Building"].ToString();
                    building.Lean = new List<LeanCapacity>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["Building"].ToString() == building.Building)
                    {
                        LeanCapacity lean = new LeanCapacity();
                        lean.Lean = dt.Rows[Row]["Lean"].ToString();
                        lean.Type = dt.Rows[Row]["Type"].ToString();
                        lean.T_Finished = (int)dt.Rows[Row]["T_Finished"];
                        lean.T_Target = (int)dt.Rows[Row]["T_Target"];
                        lean.UT_Finished = (int)dt.Rows[Row]["UT_Finished"];
                        lean.UT_Target = (int)dt.Rows[Row]["UT_Target"];
                        lean.M_Target = (int)dt.Rows[Row]["M_Target"];
                        building.Lean.Add(lean);

                        Row++;
                    }

                    buildingList.Add(building);
                }

                return JsonConvert.SerializeObject(buildingList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getLeanMonthlyCapacity")]
        public string getLeanMonthlyCapacity(CommonRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "WITH TEMPTAB(Date) AS ( " +
                    "  SELECT CONVERT(SmallDateTime, LEFT(CONVERT(VARCHAR, '{2}', 111), 8) + '01') " +
                    "  UNION ALL " +
                    "  SELECT DATEADD(D, 1, TEMPTAB.DATE) AS Date FROM TEMPTAB " +
                    "  WHERE DATEADD(D, 1, TEMPTAB.DATE) <= DATEADD(DAY ,-1, DATEADD(MONTH, DATEDIFF(MONTH, 0, '{2}') + 1, 0)) " +
                    ") " +

                    "SELECT RIGHT(CONVERT(VARCHAR, TEMPTAB.Date, 111), 5) AS Date, ISNULL(SCBB.Finished, 0) AS Finished, ISNULL(SCBZCL.Target, 0) AS Target FROM TEMPTAB " +
                    "LEFT JOIN ( " +
                    "  SELECT TEMPTAB.Date, SUM(SCBZCL.Qty) AS Target FROM TEMPTAB " +
                    "  LEFT JOIN SCBZCL ON SCBZCL.BZDate = TEMPTAB.Date " +
                    "  LEFT JOIN BDepartment ON BDepartment.ID = SCBZCL.DepNo " +
                    "  WHERE BDepartment.GXLB = 'A' " +
                    (request.Lean != "" ? "  AND BDepartment.DepName = 'DT_G-{0}-LINE ' + CAST(CAST(RIGHT('{1}', 2) AS INT) AS VARCHAR) " : "  AND BDepartment.DepName LIKE 'DT_G-{0}-%' ") +
                    "  GROUP BY TEMPTAB.Date " +
                    ") AS SCBZCL ON SCBZCL.Date = TEMPTAB.Date " +
                    "LEFT JOIN ( " +
                    "  SELECT SCBB.Date, SCBB.Finished FROM ( " +
                    "    SELECT TEMPTAB.Date, CAST(SUM(SCBBS.Qty) AS INT) AS Finished FROM TEMPTAB " +
                    "    LEFT JOIN SCBB ON SCBB.SCDate = TEMPTAB.Date " +
                    "    LEFT JOIN SCBBS ON SCBBS.ProNo = SCBB.ProNo " +
                    "    LEFT JOIN BDepartment ON BDepartment.ID = SCBB.DepNo " +
                    "    WHERE SCBBS.GXLB = 'A' " +
                    (request.Lean != "" ? "  AND BDepartment.DepName = 'DT_G-{0}-LINE ' + CAST(CAST(RIGHT('{1}', 2) AS INT) AS VARCHAR) " : "  AND BDepartment.DepName LIKE 'DT_G-{0}-%' ") +
                    "    GROUP BY TEMPTAB.Date " +
                    "  ) AS SCBB " +
                    "  UNION ALL " +
                    "  SELECT SMZL.Date, SMZL.Finished FROM ( " +
                    "    SELECT CONVERT(SmallDateTime, CONVERT(VARCHAR, GETDATE(), 111)) AS Date, SUM(SMZL.CTS * SMDDSS.Qty) AS Finished FROM SMZL " +
                    "    LEFT JOIN BDepartment ON BDepartment.ID = SMZL.DepNo " +
                    "    LEFT JOIN SMDDSS ON SMDDSS.CODEBAR = SMZL.CODEBAR " +
                    "    WHERE SMZL.ScanDate >= CONVERT(VARCHAR, GETDATE(), 111) AND SMDDSS.GXLB = 'A' " +
                    (request.Lean != "" ? "  AND BDepartment.DepName = 'DT_G-{0}-LINE ' + CAST(CAST(RIGHT('{1}', 2) AS INT) AS VARCHAR) " : "  AND BDepartment.DepName LIKE 'DT_G-%' ") +
                    "  ) AS SMZL " +
                    ") AS SCBB ON SCBB.Date = SCBZCL.Date " +
                    "ORDER BY TEMPTAB.Date "
                    , request.Building, request.Lean, (request.Date != null ? request.Date : DateTime.Now.ToString("yyyy/MM/dd"))
                ), ERP
            );

            DataTable dt = new DataTable();
            da.Fill(dt);

            List<LeanDailyCapacity> LeanList = new List<LeanDailyCapacity>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    LeanDailyCapacity date = new LeanDailyCapacity();
                    date.Date = dt.Rows[i]["Date"].ToString();
                    date.Finished = (int)dt.Rows[i]["Finished"];
                    date.Target = (int)dt.Rows[i]["Target"];

                    LeanList.Add(date);
                }

                return JsonConvert.SerializeObject(LeanList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getCuttingDispatchedOrderProgress")]
        public string getCuttingDispatchedOrderProgress(MonthOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#SC') IS NOT NULL " + 
                    "BEGIN DROP TABLE #SC END; " + 

                    "SELECT SC.ry_index, SC.schedule_date AS AssemblyDate, DDZL.Article, CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR) + ' BUY' AS BuyNo, " + 
                    "DDZL.DDBH, DDZL.Pairs INTO #SC FROM schedule_crawler AS SC " + 
                    "LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END " + 
                    "WHERE SC.schedule_date >= DATEADD(MONTH, -2, GETDATE()) AND SC.building_no + '_' + SC.lean_no LIKE '{0}%' " + 

                    "SELECT Seq, DDBH, Article, Date, BuyNo, Pairs, Progress FROM ( " +
                    "  SELECT DENSE_RANK() OVER(ORDER BY CASE WHEN Progress > 0 THEN 1 ELSE 0 END DESC, Date) AS Seq1, Seq, DDBH, Article, Date, BuyNo, Pairs, Progress FROM ( " +
                    "    SELECT DISTINCT SC.Seq, SC.DDBH, SC.Article, SC.Date, SC.BuyNo, SC.Pairs, " +
                    "    CAST(CASE WHEN Finished_A > Finished_C THEN Finished_A ELSE CASE WHEN Finished_S > Finished_C THEN Finished_S ELSE Finished_C END END * 100.0 / SC.Pairs AS NUMERIC(4, 1)) AS Progress FROM ( " +
                    "      SELECT CAST(ROW_NUMBER() OVER(ORDER BY SC.AssemblyDate, SC.ry_index) AS INT) AS Seq, SC.DDBH, " +
                    "      SC.Article, RIGHT(CONVERT(VARCHAR, SC.AssemblyDate, 111), 5) AS Date, SC.BuyNo, SC.Pairs, " +
                    "      ISNULL(SCBB.Finished_C, 0) + ISNULL(SMZL.Finished_C, 0) AS Finished_C, " +
                    "      ISNULL(SCBB.Finished_S, 0) + ISNULL(SMZL.Finished_S, 0) AS Finished_S, " +
                    "      ISNULL(SCBB.Finished_A, 0) + ISNULL(SMZL.Finished_A, 0) AS Finished_A FROM #SC AS SC " +
                    "      LEFT JOIN ( " +
                    "        SELECT SCBH, " +
                    "        SUM(CASE WHEN GXLB = 'C' THEN Qty END) AS Finished_C, " +
                    "        SUM(CASE WHEN GXLB = 'S' THEN Qty END) AS Finished_S, " +
                    "        SUM(CASE WHEN GXLB = 'A' THEN Qty END) AS Finished_A FROM SCBBS " +
                    "        WHERE SCBH IN (SELECT DDBH FROM #SC) AND GXLB IN ('C', 'S', 'A') " +
                    "        GROUP BY SCBH " +
                    "      ) AS SCBB ON SCBB.SCBH = SC.DDBH " +
                    "      LEFT JOIN ( " +
                    "        SELECT SMDD.YSBH, " +
                    "        SUM(CASE WHEN SMDD.GXLB = 'C' THEN SMDDSS.Qty * SMZL.CTS END) AS Finished_C, " +
                    "        SUM(CASE WHEN SMDD.GXLB = 'S' THEN SMDDSS.Qty * SMZL.CTS END) AS Finished_S, " +
                    "        SUM(CASE WHEN SMDD.GXLB = 'A' THEN SMDDSS.Qty * SMZL.CTS END) AS Finished_A FROM SMZL " +
                    "        LEFT JOIN SMDDSS ON SMDDSS.CODEBAR = SMZL.CODEBAR " +
                    "        LEFT JOIN SMDD ON SMDD.DDBH = SMDDSS.DDBH AND SMDD.GXLB = SMDDSS.GXLB " +
                    "        WHERE SMZL.ScanDate >= CONVERT(VARCHAR, GETDATE(), 111) AND SMDD.YSBH IN (SELECT DDBH FROM #SC) AND SMDD.GXLB IN ('C', 'S', 'A') " +
                    "        GROUP BY SMDD.YSBH " +
                    "      ) AS SMZL ON SMZL.YSBH = SC.DDBH " +
                    "    ) AS SC " +
                    "    LEFT JOIN MRCardS ON MRCardS.RY_Begin = SC.DDBH " +
                    "    LEFT JOIN MRCard ON MRCard.ListNo = MRCardS.ListNo AND MRCard.DeliveryCFMDate IS NOT NULL " +
                    "    WHERE CASE WHEN Finished_A > Finished_C THEN Finished_A ELSE CASE WHEN Finished_S > Finished_C THEN Finished_S ELSE Finished_C END END < SC.Pairs AND MRCard.ListNo IS NOT NULL " +
                    "  ) AS SC " +
                    ") AS Sc " +
                    "WHERE Seq1 = 1 OR Progress > 0 " +
                    "ORDER BY Seq "
                    , request.Lean
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<DispatchedOrderProgress> orderList = new List<DispatchedOrderProgress>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    DispatchedOrderProgress order = new DispatchedOrderProgress();
                    order.Seq = (int)dt.Rows[i]["Seq"];
                    order.Order = dt.Rows[i]["DDBH"].ToString();
                    order.BuyNo = dt.Rows[i]["BuyNo"].ToString();
                    order.Date = dt.Rows[i]["Date"].ToString();
                    order.SKU = dt.Rows[i]["Article"].ToString();
                    order.Pairs = (int)dt.Rows[i]["Pairs"];
                    //order.DProgress = (decimal)dt.Rows[i]["DProgress"];
                    order.Progress = (decimal)dt.Rows[i]["Progress"];
                    orderList.Add(order);
                }

                return JsonConvert.SerializeObject(orderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getProcessingDispatchedOrderProgress")]
        public string getProcessingDispatchedOrderProgress(MonthOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da;

            da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#SC') IS NOT NULL " +
                    "BEGIN DROP TABLE #SC END; " +

                    "SELECT CAST(ROW_NUMBER() OVER(ORDER BY SC.schedule_date, SC.ry_index) AS INT) AS Seq, SC.schedule_date AS AssemblyDate, DDZL.Article, " +
                    "CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR) + ' BUY' AS BuyNo, DDZL.DDBH, DDZL.XieXing, DDZL.SheHao, DDZL.Pairs INTO #SC FROM schedule_crawler AS SC " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END " +
                    "WHERE SC.schedule_date >= DATEADD(MONTH, -2, GETDATE()) AND SC.building_no + '_' + SC.lean_no LIKE '{0}%' " +

                    "IF OBJECT_ID('tempdb..#SC1') IS NOT NULL " +
                    "BEGIN DROP TABLE #SC1 END; " +

                    "SELECT SC.Seq, SC.DDBH, SC.Article, SC.Date, SC.BuyNo, SC.Pairs, MIN(SC.Input) AS Input, MIN(SC.Output) AS Output INTO #SC1 FROM ( " +
                    "  SELECT SC.Seq, SC.DDBH, SC.Article, SC.Date, SC.BuyNo, SC.Pairs, SC.Part, SC.Process, SC.Output, ISNULL(MAX(SC.Input), 0) AS Input FROM ( " +
                    "    SELECT SC.Seq, SC.DDBH, SC.Article, SC.Date, SC.BuyNo, SC.Pairs, SC.Part, SC.Process, SC.Output, SPI.Building, SPI.Lean, SUM(SPI.Pairs) AS Input FROM ( " +
                    "      SELECT SC.Seq, SC.DDBH, SC.Article, SC.Date, SC.BuyNo, SC.Pairs, SC.Part, SC.Process, ISNULL(MAX(SC.Output), 0) AS Output FROM ( " +
                    "        SELECT SC.Seq, SC.DDBH, SC.Article, RIGHT(CONVERT(VARCHAR, SC.AssemblyDate, 111), 5) AS Date, SC.BuyNo, " +
                    "        SC.Pairs, MSP.Part, MSP.Process, SPO.Building, SPO.Lean, SUM(SPO.Pairs) AS Output FROM #SC AS SC " +
                    "        LEFT JOIN ModelSecondProcess AS MSP ON MSP.XieXing = SC.XieXing AND MSP.SheHao = SC.SheHao " +
                    "        LEFT JOIN SecondProcessOutput AS SPO ON SPO.RY = SC.DDBH AND SPO.Part = MSP.Part AND SPO.Process = MSP.Process " +
                    "        WHERE ISNULL(MSP.Part, 'NO PROCESSING') <> 'NO PROCESSING' " +
                    "        GROUP BY SC.Seq, SC.DDBH, SC.Article, SC.AssemblyDate, SC.BuyNo, SC.Pairs, MSP.Part, MSP.Process, SPO.Building, SPO.Lean " +
                    "      ) AS SC " +
                    "      GROUP BY SC.Seq, SC.DDBH, SC.Article, SC.Date, SC.BuyNo, SC.Pairs, SC.Part, SC.Process " +
                    "      HAVING ISNULL(MAX(SC.Output), 0) < SC.Pairs " +
                    "    ) AS SC " +
                    "    LEFT JOIN SecondProcessInput AS SPI ON SPI.RY = SC.DDBH AND SPI.Part = SC.Part AND SPI.Process = SC.Process " +
                    "    GROUP BY SC.Seq, SC.DDBH, SC.Article, SC.Date, SC.BuyNo, SC.Pairs, SC.Part, SC.Process, SC.Output, SPI.Building, SPI.Lean " +
                    "  ) AS SC " +
                    "  GROUP BY SC.Seq, SC.DDBH, SC.Article, SC.Date, SC.BuyNo, SC.Pairs, SC.Part, SC.Process, SC.Output " +
                    "  HAVING ISNULL(MAX(SC.Input), 0) > 0 " +
                    ") AS SC " +
                    "GROUP BY SC.Seq, SC.DDBH, SC.Article, SC.Date, SC.BuyNo, SC.Pairs " +

                    "SELECT Seq, DDBH, Article, Date, BuyNo, Pairs, Progress FROM ( " +
                    "  SELECT DENSE_RANK() OVER(ORDER BY CASE WHEN Progress > 0 THEN 1 ELSE 0 END DESC, Date) AS Seq1, Seq, DDBH, Article, Date, BuyNo, Pairs, Progress FROM ( " +
                    "    SELECT SC.Seq, SC.DDBH, SC.Article, SC.Date, SC.BuyNo, SC.Pairs, " +
                    "    CAST(CASE WHEN Finished_A > SC.Output THEN Finished_A ELSE CASE WHEN Finished_S > SC.Output THEN Finished_S ELSE SC.Output END END * 100.0 / SC.Pairs AS NUMERIC(4, 1)) AS Progress FROM ( " +
                    "      SELECT SC.Seq, SC.DDBH, SC.Article, SC.Date, SC.BuyNo, SC.Pairs, SC.Input, SC.Output, " +
                    "      ISNULL(SCBB.Finished_S, 0) + ISNULL(SMZL.Finished_S, 0) AS Finished_S, " +
                    "      ISNULL(SCBB.Finished_A, 0) + ISNULL(SMZL.Finished_A, 0) AS Finished_A FROM #SC1 AS SC " +
                    "      LEFT JOIN ( " +
                    "        SELECT SCBH, " +
                    "        SUM(CASE WHEN GXLB = 'S' THEN Qty END) AS Finished_S, " +
                    "        SUM(CASE WHEN GXLB = 'A' THEN Qty END) AS Finished_A FROM SCBBS " +
                    "        WHERE SCBH IN(SELECT DDBH FROM #SC1) AND GXLB IN ('S', 'A') " +
                    "        GROUP BY SCBH " +
                    "      ) AS SCBB ON SCBB.SCBH = SC.DDBH " +
                    "      LEFT JOIN ( " +
                    "        SELECT SMDD.YSBH, " +
                    "        SUM(CASE WHEN SMDD.GXLB = 'S' THEN SMDDSS.Qty * SMZL.CTS END) AS Finished_S, " +
                    "        SUM(CASE WHEN SMDD.GXLB = 'A' THEN SMDDSS.Qty * SMZL.CTS END) AS Finished_A FROM SMZL " +
                    "        LEFT JOIN SMDDSS ON SMDDSS.CODEBAR = SMZL.CODEBAR " +
                    "        LEFT JOIN SMDD ON SMDD.DDBH = SMDDSS.DDBH AND SMDD.GXLB = SMDDSS.GXLB " +
                    "        WHERE SMZL.ScanDate >= CONVERT(VARCHAR, GETDATE(), 111) AND SMDD.YSBH IN(SELECT DDBH FROM #SC1) AND SMDD.GXLB IN ('S', 'A') " +
                    "        GROUP BY SMDD.YSBH " +
                    "      ) AS SMZL ON SMZL.YSBH = SC.DDBH " +
                    "    ) AS SC " +
                    "    WHERE CASE WHEN Finished_A > SC.Output THEN Finished_A ELSE CASE WHEN Finished_S > SC.Output THEN Finished_S ELSE SC.Output END END < SC.Pairs " +
                    "  ) AS SC " +
                    ") AS SC " +
                    "WHERE Seq1 = 1 OR Progress > 0 " + 
                    "ORDER BY Seq "
                    , request.Lean
                ), ERP
            );

            DataTable dt = new DataTable();
            da.Fill(dt);

            List<DispatchedOrderProgress> orderList = new List<DispatchedOrderProgress>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    DispatchedOrderProgress order = new DispatchedOrderProgress();
                    order.Seq = (int)dt.Rows[i]["Seq"];
                    order.Order = dt.Rows[i]["DDBH"].ToString();
                    order.BuyNo = dt.Rows[i]["BuyNo"].ToString();
                    order.Date = dt.Rows[i]["Date"].ToString();
                    order.SKU = dt.Rows[i]["Article"].ToString();
                    order.Pairs = (int)dt.Rows[i]["Pairs"];
                    //order.DProgress = (decimal)dt.Rows[i]["DProgress"];
                    order.Progress = (decimal)dt.Rows[i]["Progress"];
                    orderList.Add(order);
                }

                return JsonConvert.SerializeObject(orderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getStitchingDispatchedOrderProgress")]
        public string getStitchingDispatchedOrderProgress(MonthOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#PP') IS NOT NULL " +
                    "BEGIN DROP TABLE #PP END; " +

                    "SELECT AssemblyDate, Article, BuyNo, DDBH, Pairs INTO #PP FROM ( " +
                    "  SELECT ROW_NUMBER() OVER(PARTITION BY DDZL.DDBH ORDER BY SC.version DESC) AS Seq, SC.schedule_date AS AssemblyDate, DDZL.Article, " +
                    "  CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR) + ' BUY' AS BuyNo, DDZL.DDBH, DDZL.Pairs FROM ProductionPlan AS PP " +
                    "  LEFT JOIN DDZL ON DDZL.DDBH = PP.RY " +
                    "  LEFT JOIN schedule_crawler AS SC ON CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END = DDZL.ZLBH " +
                    "  WHERE DDZL.DDBH IS NOT NULL AND PP.Building + '_' + PP.Lean LIKE '{0}%' AND PP.PlanType LIKE '3-Day%' " +
                    "  AND PP.PlanDate >= DATEADD(DAY, -14, GETDATE()) " +
                    ") AS PP " +
                    "WHERE Seq = 1 " +

                    "SELECT CAST(ROW_NUMBER() OVER(ORDER BY Date) AS INT) AS Seq, DDBH, Article, Date, BuyNo, Pairs, Progress FROM ( " +
                    "  SELECT DENSE_RANK() OVER(ORDER BY CASE WHEN Progress > 0 THEN 1 ELSE 0 END DESC, Date) AS Seq, DDBH, Article, Date, BuyNo, Pairs, Progress FROM ( " +
                    "    SELECT DDBH, Article, Date, BuyNo, Pairs, " +
                    "    CAST(CASE WHEN Finished_A > Finished_S THEN Finished_A ELSE Finished_S END * 100.0 / Pairs AS NUMERIC(4, 1)) AS Progress FROM ( " +
                    "      SELECT PP.DDBH, PP.Article, RIGHT(CONVERT(VARCHAR, PP.AssemblyDate, 111), 5) AS Date, PP.BuyNo, PP.Pairs, " +
                    "      ISNULL(SCBB.Finished_S, 0) + ISNULL(SMZL.Finished_S, 0) AS Finished_S, " +
                    "      ISNULL(SCBB.Finished_A, 0) + ISNULL(SMZL.Finished_A, 0) AS Finished_A FROM #PP AS PP " +
                    "      LEFT JOIN ( " +
                    "        SELECT SCBH, " +
                    "        SUM(CASE WHEN GXLB = 'S' THEN Qty END) AS Finished_S, " +
                    "        SUM(CASE WHEN GXLB = 'A' THEN Qty END) AS Finished_A FROM SCBBS " +
                    "        WHERE SCBH IN(SELECT DDBH FROM #PP) AND GXLB IN ('S', 'A') " +
                    "        GROUP BY SCBH " +
                    "      ) AS SCBB ON SCBB.SCBH = PP.DDBH " +
                    "      LEFT JOIN ( " +
                    "        SELECT SMDD.YSBH, " +
                    "        SUM(CASE WHEN SMDD.GXLB = 'S' THEN SMDDSS.Qty * SMZL.CTS END) AS Finished_S, " +
                    "        SUM(CASE WHEN SMDD.GXLB = 'A' THEN SMDDSS.Qty * SMZL.CTS END) AS Finished_A FROM SMZL " +
                    "        LEFT JOIN SMDDSS ON SMDDSS.CODEBAR = SMZL.CODEBAR " +
                    "        LEFT JOIN SMDD ON SMDD.DDBH = SMDDSS.DDBH AND SMDD.GXLB = SMDDSS.GXLB " +
                    "        WHERE SMZL.ScanDate >= CONVERT(VARCHAR, GETDATE(), 111) AND SMDD.YSBH IN(SELECT DDBH FROM #PP) AND SMDD.GXLB IN ('S', 'A') " +
                    "        GROUP BY SMDD.YSBH " +
                    "      ) AS SMZL ON SMZL.YSBH = PP.DDBH " +
                    "    ) AS PP " +
                    "    WHERE CASE WHEN Finished_A > Finished_S THEN Finished_A ELSE Finished_S END < Pairs " +
                    "  ) AS PP " +
                    ") AS PP " +
                    "WHERE Seq = 1 OR Progress > 0 "
                    , request.Lean
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<DispatchedOrderProgress> orderList = new List<DispatchedOrderProgress>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    DispatchedOrderProgress order = new DispatchedOrderProgress();
                    order.Seq = (int)dt.Rows[i]["Seq"];
                    order.Order = dt.Rows[i]["DDBH"].ToString();
                    order.BuyNo = dt.Rows[i]["BuyNo"].ToString();
                    order.Date = dt.Rows[i]["Date"].ToString();
                    order.SKU = dt.Rows[i]["Article"].ToString();
                    order.Pairs = (int)dt.Rows[i]["Pairs"];
                    //order.DProgress = (decimal)dt.Rows[i]["DProgress"];
                    order.Progress = (decimal)dt.Rows[i]["Progress"];
                    orderList.Add(order);
                }

                return JsonConvert.SerializeObject(orderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getAssemblyDispatchedOrderProgress")]
        public string getAssemblyDispatchedOrderProgress(MonthOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#PP') IS NOT NULL " +
                    "BEGIN DROP TABLE #PP END; " +

                    "SELECT AssemblyDate, Article, BuyNo, DDBH, Pairs INTO #PP FROM ( " +
                    "  SELECT ROW_NUMBER() OVER(PARTITION BY DDZL.DDBH ORDER BY SC.version DESC) AS Seq, SC.schedule_date AS AssemblyDate, DDZL.Article, " +
                    "  CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR) + ' BUY' AS BuyNo, DDZL.DDBH, DDZL.Pairs FROM ProductionPlan AS PP " +
                    "  LEFT JOIN DDZL ON DDZL.DDBH = PP.RY " +
                    "  LEFT JOIN schedule_crawler AS SC ON CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END = DDZL.ZLBH " +
                    "  WHERE DDZL.DDBH IS NOT NULL AND PP.Building + '_' + PP.Lean LIKE '{0}%' AND PP.PlanType LIKE '1-Day%' " +
                    "  AND PP.PlanDate BETWEEN DATEADD(DAY, -14, GETDATE()) AND CONVERT(VARCHAR, GETDATE(), 111) " +
                    ") AS PP " +
                    "WHERE Seq = 1 " +

                    "SELECT CAST(ROW_NUMBER() OVER(ORDER BY Date) AS INT) AS Seq, DDBH, Article, Date, BuyNo, Pairs, Progress FROM ( " +
                    "  SELECT DENSE_RANK() OVER(ORDER BY CASE WHEN Progress > 0 THEN 1 ELSE 0 END DESC, Date) AS Seq, DDBH, Article, Date, BuyNo, Pairs, Progress FROM ( " +
                    "    SELECT DDBH, Article, Date, BuyNo, Pairs, " +
                    "    CAST(Finished_A * 100.0 / Pairs AS NUMERIC(4, 1)) AS Progress FROM ( " +
                    "      SELECT PP.DDBH, PP.Article, RIGHT(CONVERT(VARCHAR, PP.AssemblyDate, 111), 5) AS Date, PP.BuyNo, PP.Pairs, " +
                    "      ISNULL(SCBB.Finished_A, 0) + ISNULL(SMZL.Finished_A, 0) AS Finished_A FROM #PP AS PP " +
                    "      LEFT JOIN ( " +
                    "        SELECT SCBH, " +
                    "        SUM(CASE WHEN GXLB = 'A' THEN Qty END) AS Finished_A FROM SCBBS " +
                    "        WHERE SCBH IN(SELECT DDBH FROM #PP) AND GXLB IN ('A') " +
                    "        GROUP BY SCBH " +
                    "      ) AS SCBB ON SCBB.SCBH = PP.DDBH " +
                    "      LEFT JOIN ( " +
                    "        SELECT SMDD.YSBH, " +
                    "        SUM(CASE WHEN SMDD.GXLB = 'A' THEN SMDDSS.Qty * SMZL.CTS END) AS Finished_A FROM SMZL " +
                    "        LEFT JOIN SMDDSS ON SMDDSS.CODEBAR = SMZL.CODEBAR " +
                    "        LEFT JOIN SMDD ON SMDD.DDBH = SMDDSS.DDBH AND SMDD.GXLB = SMDDSS.GXLB " +
                    "        WHERE SMZL.ScanDate >= CONVERT(VARCHAR, GETDATE(), 111) AND SMDD.YSBH IN(SELECT DDBH FROM #PP) AND SMDD.GXLB IN ('A') " +
                    "        GROUP BY SMDD.YSBH " +
                    "      ) AS SMZL ON SMZL.YSBH = PP.DDBH " +
                    "    ) AS PP " +
                    "    WHERE Finished_A < Pairs " +
                    "  ) AS PP " +
                    ") AS PP " +
                    "WHERE Seq = 1 OR Progress > 0 "
                    , request.Lean
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<DispatchedOrderProgress> orderList = new List<DispatchedOrderProgress>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    DispatchedOrderProgress order = new DispatchedOrderProgress();
                    order.Seq = (int)dt.Rows[i]["Seq"];
                    order.Order = dt.Rows[i]["DDBH"].ToString();
                    order.BuyNo = dt.Rows[i]["BuyNo"].ToString();
                    order.Date = dt.Rows[i]["Date"].ToString();
                    order.SKU = dt.Rows[i]["Article"].ToString();
                    order.Pairs = (int)dt.Rows[i]["Pairs"];
                    //order.DProgress = (decimal)dt.Rows[i]["DProgress"];
                    order.Progress = (decimal)dt.Rows[i]["Progress"];
                    orderList.Add(order);
                }

                return JsonConvert.SerializeObject(orderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getFactoryLean")]
        public string getFactoryLean(MonthOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            string SQL = string.Empty;
            if (request.Type == "MachineLean")
            {
                SQL = System.String.Format(
                    "SELECT * FROM ( " +
                    "  SELECT DISTINCT building_no AS Xuong, UPPER(lean_no) AS Lean FROM schedule_crawler " +
                    "  WHERE building_no = '{0}' AND schedule_date >= LEFT(CONVERT(VARCHAR, GETDATE(), 111), 7) + '/01' " +
                    ") AS SC " +
                    "ORDER BY Xuong, Lean "
                    , request.PlanMonth
                );
            }
            else
            {
                SQL = System.String.Format(
                    "SELECT Xuong, Lean FROM ( " +
                    "  SELECT DISTINCT building_no AS Xuong, 'LINE ' + RIGHT('00' + CAST(CAST(RIGHT(lean_no, 2) AS INT) AS VARCHAR), 2) AS Lean FROM schedule_crawler " +
                    "  WHERE SUBSTRING(CONVERT(VARCHAR, CONVERT(SmallDateTime, schedule_date), 111), 1, 7) >= '{0}' " +
                    ") AS SC " +
                    "ORDER BY Xuong, Lean "
                    , request.PlanMonth
                );
            }

            SqlDataAdapter da = new SqlDataAdapter(SQL, ERP);
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<FilterResult> filterList = new List<FilterResult>();
            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    FilterResult filter = new FilterResult();
                    filter.Factory = dt.Rows[Row]["Xuong"].ToString();
                    filter.Lean = new List<string>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["Xuong"].ToString() == filter.Factory)
                    {
                        filter.Lean.Add(dt.Rows[Row]["Lean"].ToString()!);
                        Row++;
                    }

                    filterList.Add(filter);
                }

                return JsonConvert.SerializeObject(filterList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getOrderPart")]
        public string getOrderPart(OrderRequest request)
        {
            CheckCuttingData(request.Order);

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT CutDispatchZL.BWBH, CutDispatchZL.CLBH, BWZL.ZWSM, BWZL.YWSM, ISNULL(KT_SOPCut.Type, 'Manual') AS Type, ISNULL(SUM(CutDispatchZL.Qty), 0) AS ZLQty, ISNULL(CutDispatchSS.Qty, 0) AS Qty FROM CutDispatchZL " +
                    "LEFT JOIN( " +
                    "  SELECT ZLBH, BWBH, SUM(Qty) AS Qty FROM CutDispatchSS " +
                    "  WHERE ZLBH = '{0}' " +
                    "  GROUP BY ZLBH, BWBH " +
                    ") AS CutDispatchSS ON CutDispatchSS.ZLBH = CutDispatchZL.ZLBH AND CutDispatchSS.BWBH = CutDispatchZL.BWBH " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = CutDispatchZL.ZLBH " +
                    "LEFT JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao AND KT_SOPCut.BWBH = CutDispatchZL.BWBH " +
                    "LEFT JOIN BWZL ON BWZL.BWDH = CutDispatchZL.BWBH " +
                    "WHERE CutDispatchZL.ZLBH = '{0}' AND SUBSTRING(CutDispatchZL.CLBH, 1, 1) NOT IN ('L', 'N', 'J') AND CutDispatchZL.Piece > 0 " +
                    "GROUP BY CutDispatchZL.BWBH, CutDispatchZL.CLBH, BWZL.ZWSM, BWZL.YWSM, ISNULL(KT_SOPCut.Type, 'Manual'), CutDispatchSS.Qty " +
                    "ORDER BY ISNULL(KT_SOPCut.Type, 'Manual') DESC, CutDispatchZL.BWBH "
                    , request.Order
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<OrderPartResult> orderList = new List<OrderPartResult>();
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    OrderPartResult part = new OrderPartResult();
                    part.PartID = dt.Rows[i]["BWBH"].ToString();
                    part.MaterialID = dt.Rows[i]["CLBH"].ToString();
                    part.PartName = new List<PartInfo>();

                    PartInfo partInfo = new PartInfo();
                    partInfo.ZH = dt.Rows[i]["ZWSM"].ToString();
                    partInfo.EN = dt.Rows[i]["YWSM"].ToString();
                    partInfo.VI = dt.Rows[i]["YWSM"].ToString();
                    partInfo.Type = dt.Rows[i]["Type"].ToString();
                    if ((int)dt.Rows[i]["ZLQty"] > (int)dt.Rows[i]["Qty"])
                    {
                        if ((int)dt.Rows[i]["Qty"] == 0)
                        {
                            partInfo.Status = 0;
                        }
                        else
                        {
                            partInfo.Status = 1;
                        }
                    }
                    else
                    {
                        partInfo.Status = 2;
                    }
                    part.PartName.Add(partInfo);
                    orderList.Add(part);
                }

                return JsonConvert.SerializeObject(orderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getProcessingDispatchFlow")]
        public string getProcessingDispatchFlow(OrderRequest request)
        {
            string ReCalculateSQL = string.Empty;
            string[] Orders = request.Order.Split(", ");
            for (int i = 0; i < Orders.Length; i++)
            {
                CheckProcessingData(Orders[i]);
            }

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#GC') IS NOT NULL " +
                    "BEGIN DROP TABLE #GC END; " +

                    "SELECT DISTINCT CutDispatchZL_GC.BWBH AS Section, " +
                    "ISNULL(BWZL.ZWSM, GC1.ZWSM) + CASE WHEN CutDispatchZL_GC.BWBH NOT LIKE '0G%' THEN '/n' + CutDispatchZL_GC.CLBH ELSE '' END AS ZWSM, " +
                    "ISNULL(BWZL.YWSM, GC1.YWSM) + CASE WHEN CutDispatchZL_GC.BWBH NOT LIKE '0G%' THEN '/n' + CutDispatchZL_GC.CLBH ELSE '' END AS YWSM, " +
                    "ISNULL(BWZL.YWSM, GC1.VWSM) + CASE WHEN CutDispatchZL_GC.BWBH NOT LIKE '0G%' THEN '/n' + CutDispatchZL_GC.CLBH ELSE '' END AS VWSM, " +
                    "CASE WHEN GC2.Memo = 'Single' THEN CutDispatchZL_GC.BWBH + '@' + CutDispatchZL_GC.GCBWBH ELSE CutDispatchZL_GC.GCBWBH END AS Parent INTO #GC FROM CutDispatchZL_GC " +
                    "LEFT JOIN BWZL ON BWZL.BWDH = CutDispatchZL_GC.BWBH " +
                    "LEFT JOIN KT_SOPCutS_GCBWD AS GC1 ON GC1.GCBWDH = CutDispatchZL_GC.BWBH " +
                    "LEFT JOIN KT_SOPCutS_GCBWD AS GC2 ON GC2.GCBWDH = CutDispatchZL_GC.GCBWBH " +
                    "WHERE CutDispatchZL_GC.ZLBH IN ({0}) " +

                    "IF OBJECT_ID('tempdb..#Section') IS NOT NULL " +
                    "BEGIN DROP TABLE #Section END; " +

                    "SELECT Section, ZWSM, YWSM, VWSM, Parent INTO #Section FROM ( " +
                    "  SELECT Section, ZWSM, YWSM, VWSM, Parent FROM #GC " +
                    "  UNION " +
                    "  SELECT DISTINCT SUBSTRING(GC.Parent, CHARINDEX('@', GC.Parent) + 1, LEN(GC.Parent) - CHARINDEX('@', GC.Parent)) AS Section, " +
                    "  KT_SOPCutS_GCBWD.ZWSM, KT_SOPCutS_GCBWD.YWSM, KT_SOPCutS_GCBWD.VWSM, 'Root' AS Parent FROM #GC AS GC " +
                    "  LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = SUBSTRING(GC.Parent, CHARINDEX('@', GC.Parent) + 1, LEN(GC.Parent) - CHARINDEX('@', GC.Parent)) " +
                    "  LEFT JOIN #GC AS GC2 ON GC2.Section = SUBSTRING(GC.Parent, CHARINDEX('@', GC.Parent) + 1, LEN(GC.Parent) - CHARINDEX('@', GC.Parent)) " +
                    "  WHERE GC2.Section IS NULL " +
                    ") AS Section " +

                    "SELECT DISTINCT Section.Section, Section.ZWSM, Section.YWSM, Section.VWSM, CAST(ISNULL(CutDispatchSS_GC.Qty, 0) AS INT) AS Qty, CAST(ISNULL(CutDispatchZL_GC.ZLQty, 0) AS INT) AS ZLQty, Section.Parent FROM ( " +
                    "  SELECT DISTINCT ISNULL(S2.Parent, S1.Section) AS Section, S1.ZWSM, S1.YWSM, S1.VWSM, S1.Parent FROM #Section AS S1 " +
                    "  LEFT JOIN #Section AS S2 ON REPLACE(S2.Parent, S2.Section + '@', '') = S1.Section " +
                    ") AS Section " +
                    "LEFT JOIN ( " +
                    "  SELECT GCBWBH, BWBH, SUM(ZLQty) AS ZLQty FROM ( " +
                    "    SELECT ZLBH, GCBWBH, BWBH, SUM(Qty) AS ZLQty FROM CutDispatchZL_GC " +
                    "    LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = CutDispatchZL_GC.GCBWBH " +
                    "    WHERE ZLBH IN ({0}) AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') = 'Single' " +
                    "    GROUP BY ZLBH, GCBWBH, BWBH " +
                    "    UNION ALL " +
                    "    SELECT ZLBH, GCBWBH, '' AS BWBH, SUM(Qty) AS ZLQty FROM CutDispatchZL_GC " +
                    "    LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = CutDispatchZL_GC.GCBWBH " +
                    "    WHERE ZLBH IN ({0}) AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') <> 'Single' " +
                    "    GROUP BY ZLBH, GCBWBH " +
                    "  ) AS CutDispatchZL_GC " +
                    "  GROUP BY GCBWBH, BWBH " +
                    ") AS CutDispatchZL_GC ON CutDispatchZL_GC.BWBH + '@' + CutDispatchZL_GC.GCBWBH = Section.Section OR CutDispatchZL_GC.GCBWBH = Section.Section " +
                    "LEFT JOIN ( " +
                    "  SELECT GCBWBH, BWBH, SUM(Qty) AS Qty FROM ( " +
                    "    SELECT ZLBH, GCBWBH, BWBH, SUM(Qty) AS Qty FROM CutDispatchSS_GC " +
                    "    LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = CutDispatchSS_GC.GCBWBH " +
                    "    WHERE ZLBH IN ({0}) AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') = 'Single' " +
                    "    GROUP BY ZLBH, GCBWBH, BWBH " +
                    "    UNION ALL " +
                    "    SELECT ZLBH, GCBWBH, '' AS BWBH, SUM(Qty) AS Qty FROM CutDispatchSS_GC " +
                    "    LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = CutDispatchSS_GC.GCBWBH " +
                    "    WHERE ZLBH IN ({0}) AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') <> 'Single' " +
                    "    GROUP BY ZLBH, GCBWBH " +
                    "  ) AS CutDispatchSS_GC " +
                    "  GROUP BY GCBWBH, BWBH " +
                    ") AS CutDispatchSS_GC ON CutDispatchSS_GC.BWBH + '@' + CutDispatchSS_GC.GCBWBH = Section.Section OR CutDispatchSS_GC.GCBWBH = Section.Section "
                    , "'" + request.Order.Replace(" ", "").Replace(",", "','") + "'"
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<ProcessFlow> flowList = new List<ProcessFlow>();
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    ProcessFlow flow = new ProcessFlow();
                    flow.Section = dt.Rows[i]["Section"].ToString();
                    flow.ZH = dt.Rows[i]["ZWSM"].ToString();
                    flow.EN = dt.Rows[i]["YWSM"].ToString();
                    flow.VI = dt.Rows[i]["VWSM"].ToString();
                    flow.Parent = dt.Rows[i]["Parent"].ToString();
                    if ((int)dt.Rows[i]["Qty"] < (int)dt.Rows[i]["ZLQty"])
                    {
                        if ((int)dt.Rows[i]["Qty"] == 0)
                        {
                            flow.Status = 0;
                        }
                        else
                        {
                            flow.Status = 1;
                        }
                    }
                    else
                    {
                        flow.Status = 2;
                    }
                    flowList.Add(flow);
                }

                return JsonConvert.SerializeObject(flowList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getProcessingReportingFlow")]
        public string getProcessingReportingFlow(OrderRequest request)
        {
            CheckProcessingData(request.Order);

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#GC') IS NOT NULL " +
                    "BEGIN DROP TABLE #GC END; " +

                    "SELECT DISTINCT CutDispatchZL_GC.BWBH AS Section, " +
                    "ISNULL(BWZL.ZWSM, GC1.ZWSM) + CASE WHEN CutDispatchZL_GC.BWBH NOT LIKE '0G%' THEN '/n' + CutDispatchZL_GC.CLBH ELSE '' END AS ZWSM, " +
                    "ISNULL(BWZL.YWSM, GC1.YWSM) + CASE WHEN CutDispatchZL_GC.BWBH NOT LIKE '0G%' THEN '/n' + CutDispatchZL_GC.CLBH ELSE '' END AS YWSM, " +
                    "ISNULL(BWZL.YWSM, GC1.VWSM) + CASE WHEN CutDispatchZL_GC.BWBH NOT LIKE '0G%' THEN '/n' + CutDispatchZL_GC.CLBH ELSE '' END AS VWSM, " +
                    "CASE WHEN GC2.Memo = 'Single' THEN CutDispatchZL_GC.BWBH + '@' + CutDispatchZL_GC.GCBWBH ELSE CutDispatchZL_GC.GCBWBH END AS Parent INTO #GC FROM CutDispatchZL_GC " +
                    "LEFT JOIN BWZL ON BWZL.BWDH = CutDispatchZL_GC.BWBH " +
                    "LEFT JOIN KT_SOPCutS_GCBWD AS GC1 ON GC1.GCBWDH = CutDispatchZL_GC.BWBH " +
                    "LEFT JOIN KT_SOPCutS_GCBWD AS GC2 ON GC2.GCBWDH = CutDispatchZL_GC.GCBWBH " +
                    "WHERE CutDispatchZL_GC.ZLBH = '{0}' " +

                    "IF OBJECT_ID('tempdb..#Section') IS NOT NULL " +
                    "BEGIN DROP TABLE #Section END; " +

                    "SELECT Section, ZWSM, YWSM, VWSM, Parent INTO #Section FROM ( " +
                    "  SELECT Section, ZWSM, YWSM, VWSM, Parent FROM #GC " +
                    "  UNION " +
                    "  SELECT DISTINCT SUBSTRING(GC.Parent, CHARINDEX('@', GC.Parent) + 1, LEN(GC.Parent) - CHARINDEX('@', GC.Parent)) AS Section, " +
                    "  KT_SOPCutS_GCBWD.ZWSM, KT_SOPCutS_GCBWD.YWSM, KT_SOPCutS_GCBWD.VWSM, 'Root' AS Parent FROM #GC AS GC " +
                    "  LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = SUBSTRING(GC.Parent, CHARINDEX('@', GC.Parent) + 1, LEN(GC.Parent) - CHARINDEX('@', GC.Parent)) " +
                    "  LEFT JOIN #GC AS GC2 ON GC2.Section = SUBSTRING(GC.Parent, CHARINDEX('@', GC.Parent) + 1, LEN(GC.Parent) - CHARINDEX('@', GC.Parent)) " +
                    "  WHERE GC2.Section IS NULL " +
                    ") AS Section " +

                    "SELECT DISTINCT Section.Section, Section.ZWSM, Section.YWSM, Section.VWSM, CAST(ISNULL(CutDispatchSS_GC.ScanQty, 0) AS INT) AS ScanQty, CAST(ISNULL(CutDispatchZL_GC.ZLQty, 0) AS INT) AS ZLQty, Section.Parent FROM ( " +
                    "  SELECT DISTINCT ISNULL(S2.Parent, S1.Section) AS Section, S1.ZWSM, S1.YWSM, S1.VWSM, S1.Parent FROM #Section AS S1 " +
                    "  LEFT JOIN #Section AS S2 ON REPLACE(S2.Parent, S2.Section + '@', '') = S1.Section " +
                    ") AS Section " +
                    "LEFT JOIN( " +
                    "  SELECT ZLBH, GCBWBH, BWBH, SUM(Qty) AS ZLQty FROM CutDispatchZL_GC " +
                    "  LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = CutDispatchZL_GC.GCBWBH " +
                    "  WHERE ZLBH = '{0}' AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') = 'Single' " +
                    "  GROUP BY ZLBH, GCBWBH, BWBH " +
                    "  UNION ALL " +
                    "  SELECT ZLBH, GCBWBH, '' AS BWBH, SUM(Qty) AS ZLQty FROM CutDispatchZL_GC " +
                    "  LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = CutDispatchZL_GC.GCBWBH " +
                    "  WHERE ZLBH = '{0}' AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') <> 'Single' " +
                    "  GROUP BY ZLBH, GCBWBH " +
                    ") AS CutDispatchZL_GC ON CutDispatchZL_GC.BWBH + '@' + CutDispatchZL_GC.GCBWBH = Section.Section OR CutDispatchZL_GC.GCBWBH = Section.Section " +
                    "LEFT JOIN( " +
                    "  SELECT ZLBH, GCBWBH, BWBH, SUM(ScanQty) AS ScanQty FROM CutDispatchSS_GC " +
                    "  LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = CutDispatchSS_GC.GCBWBH " +
                    "  WHERE ZLBH = '{0}' AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') = 'Single' " +
                    "  GROUP BY ZLBH, GCBWBH, BWBH " +
                    "  UNION ALL " +
                    "  SELECT ZLBH, GCBWBH, '' AS BWBH, SUM(ScanQty) AS ScanQty FROM CutDispatchSS_GC " +
                    "  LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = CutDispatchSS_GC.GCBWBH " +
                    "  WHERE ZLBH = '{0}' AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') <> 'Single' " +
                    "  GROUP BY ZLBH, GCBWBH " +
                    ") AS CutDispatchSS_GC ON CutDispatchSS_GC.BWBH + '@' + CutDispatchSS_GC.GCBWBH = Section.Section OR CutDispatchSS_GC.GCBWBH = Section.Section "
                    , request.Order
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<ProcessFlow> flowList = new List<ProcessFlow>();
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    ProcessFlow flow = new ProcessFlow();
                    flow.Section = dt.Rows[i]["Section"].ToString();
                    flow.Target = (int)dt.Rows[i]["ZLQty"];
                    flow.Actual = (int)dt.Rows[i]["ScanQty"];
                    flow.ZH = dt.Rows[i]["ZWSM"].ToString();
                    flow.EN = dt.Rows[i]["YWSM"].ToString();
                    flow.VI = dt.Rows[i]["VWSM"].ToString();
                    flow.Parent = dt.Rows[i]["Parent"].ToString();
                    if ((int)dt.Rows[i]["ScanQty"] < (int)dt.Rows[i]["ZLQty"])
                    {
                        if ((int)dt.Rows[i]["ScanQty"] == 0)
                        {
                            flow.Status = 0;
                        }
                        else
                        {
                            flow.Status = 1;
                        }
                    }
                    else
                    {
                        flow.Status = 2;
                    }
                    flowList.Add(flow);
                }

                return JsonConvert.SerializeObject(flowList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getOrderDispatchedPart")]
        public string getOrderDispatchedPart(OrderRequest request)
        {
            CheckCuttingData(request.Order);

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT CutDispatchZL.BWBH, CutDispatchZL.CLBH, BWZL.ZWSM, BWZL.YWSM, ISNULL(KT_SOPCut.Type, 'Manual') AS Type, ISNULL(SUM(CutDispatchZL.Qty), 0) AS ZLQty, ISNULL(CutDispatchSS.ScanQty, 0) AS ScanQty FROM CutDispatchZL " +
                    "LEFT JOIN( " +
                    "  SELECT ZLBH, BWBH, SUM(ScanQty) AS ScanQty FROM CutDispatchSS " +
                    "  WHERE ZLBH = '{0}' " +
                    "  GROUP BY ZLBH, BWBH " +
                    ") AS CutDispatchSS ON CutDispatchSS.ZLBH = CutDispatchZL.ZLBH AND CutDispatchSS.BWBH = CutDispatchZL.BWBH " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = CutDispatchZL.ZLBH " +
                    "LEFT JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao AND KT_SOPCut.BWBH = CutDispatchZL.BWBH " +
                    "LEFT JOIN BWZL ON BWZL.BWDH = CutDispatchZL.BWBH " +
                    "WHERE CutDispatchZL.ZLBH = '{0}' AND SUBSTRING(CutDispatchZL.CLBH, 1, 1) NOT IN ('L', 'N', 'J') AND CutDispatchZL.Piece > 0 " +
                    "GROUP BY CutDispatchZL.BWBH, CutDispatchZL.CLBH, BWZL.ZWSM, BWZL.YWSM, ISNULL(KT_SOPCut.Type, 'Manual'), CutDispatchSS.ScanQty " +
                    "ORDER BY ISNULL(KT_SOPCut.Type, 'Manual') DESC, CutDispatchZL.BWBH "
                    , request.Order
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<OrderPartResult> orderList = new List<OrderPartResult>();
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    OrderPartResult part = new OrderPartResult();
                    part.PartName = new List<PartInfo>();
                    part.PartID = dt.Rows[i]["BWBH"].ToString();
                    part.MaterialID = dt.Rows[i]["CLBH"].ToString();

                    PartInfo partInfo = new PartInfo();
                    partInfo.ZH = dt.Rows[i]["ZWSM"].ToString();
                    partInfo.EN = dt.Rows[i]["YWSM"].ToString();
                    partInfo.VI = dt.Rows[i]["YWSM"].ToString();
                    partInfo.Type = dt.Rows[i]["Type"].ToString();
                    if ((int)dt.Rows[i]["ZLQty"] > (int)dt.Rows[i]["ScanQty"])
                    {
                        if ((int)dt.Rows[i]["ScanQty"] == 0)
                        {
                            partInfo.Status = 0;
                        }
                        else
                        {
                            partInfo.Status = 1;
                        }
                    }
                    else
                    {
                        partInfo.Status = 2;
                    }
                    part.PartName.Add(partInfo);
                    orderList.Add(part);
                }

                return JsonConvert.SerializeObject(orderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getOrderSize")]
        public string getOrderSize(OrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT SMDDS.XXCC, CASE WHEN CutDispatch.Qty = SUM(SMDDS.Qty) THEN 1 ELSE 0 END AS AllDispatched FROM SMDDS " +
                    "LEFT JOIN SMDD ON SMDD.DDBH = SMDDS.DDBH AND SMDD.GXLB = 'A' " +
                    "LEFT JOIN ( " +
                    "  SELECT SIZE, SUM(Qty) AS Qty FROM CutDispatchSS " +
                    "  WHERE ZLBH = '{0}' AND BWBH = '{1}' " +
                    "  GROUP BY Size " +
                    ") AS CutDispatch ON CutDispatch.SIZE = SMDDS.XXCC " +
                    "WHERE SMDD.YSBH = '{0}' " +
                    "GROUP BY SMDDS.XXCC, CutDispatch.Qty " +
                    "ORDER BY SMDDS.XXCC ",
                    request.Order, request.PartID
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);
            List<OrderSize> SizeList = new List<OrderSize>();

            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    OrderSize Size = new OrderSize();
                    Size.Size = dt.Rows[i]["XXCC"].ToString();
                    if ((int)dt.Rows[i]["AllDispatched"] == 0)
                    {
                        Size.AllDispatched = false;
                    }
                    else
                    {
                        Size.AllDispatched = true;
                    }
                    SizeList.Add(Size);
                }

                return JsonConvert.SerializeObject(SizeList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getOrderProcessingSize")]
        public string getOrderProcessingSize(ProcessRequest request)
        {
            string[] requestInfo = request.Section!.Split('@');
            string Process = string.Empty;
            string Part = string.Empty;
            if (requestInfo.Length == 1)
            {
                Process = requestInfo[0];
            }
            else
            {
                Part = requestInfo[0];
                Process = requestInfo[1];
            }

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT SMDDS.XXCC, CASE WHEN CutDispatchSS_GC.Qty = SUM(SMDDS.Qty) THEN 1 ELSE 0 END AS AllDispatched FROM SMDDS " +
                    "LEFT JOIN SMDD ON SMDD.DDBH = SMDDS.DDBH AND SMDD.GXLB = 'A' " +
                    "LEFT JOIN ( " +
                    "  SELECT SIZE, SUM(Qty) AS Qty FROM CutDispatchSS_GC " +
                    "  WHERE ZLBH = '{0}' " + (Part != "" ? "AND BWBH = '" + Part + "' " : "") + (Process != "" ? "AND GCBWBH = '" + Process + "' " : "") +
                    "  GROUP BY Size " +
                    ") AS CutDispatchSS_GC ON CutDispatchSS_GC.SIZE = SMDDS.XXCC " +
                    "WHERE SMDD.YSBH = '{0}' " +
                    "GROUP BY SMDDS.XXCC, CutDispatchSS_GC.Qty " +
                    "ORDER BY SMDDS.XXCC "
                    , request.Order
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);
            List<OrderSize> SizeList = new List<OrderSize>();

            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    OrderSize Size = new OrderSize();
                    Size.Size = dt.Rows[i]["XXCC"].ToString();
                    if ((int)dt.Rows[i]["AllDispatched"] == 0)
                    {
                        Size.AllDispatched = false;
                    }
                    else
                    {
                        Size.AllDispatched = true;
                    }
                    SizeList.Add(Size);
                }

                return JsonConvert.SerializeObject(SizeList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getOrderCycle")]
        public string getOrderCycle(OrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT CASE WHEN LEN(SMDD.DDBH) < 14 AND LEN(SMDD.DDBH) - LEN(REPLACE(SMDD.DDBH, '-', '')) < 2 THEN SMDD.DDBH + '-001' " +
                    "ELSE CASE WHEN LEN(SMDD.DDBH) >= 14 AND LEN(SMDD.DDBH) - LEN(REPLACE(SMDD.DDBH, '-', '')) < 2 THEN SUBSTRING(SMDD.DDBH, 1, LEN(SMDD.DDBH)-3) + '-' + SUBSTRING(SMDD.DDBH, LEN(SMDD.DDBH)-2, 3) " +
                    "ELSE SMDD.DDBH END END AS DDBH, CASE WHEN SMDD.Qty = SUM(CutDispatchSS.Qty) THEN 1 ELSE 0 END AS AllDispatched FROM SMDD " +
                    "LEFT JOIN CutDispatchSS ON CutDispatchSS.DDBH = SMDD.DDBH AND CutDispatchSS.BWBH = '{1}' " +
                    "WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = 'A' " +
                    "GROUP BY SMDD.DDBH, SMDD.Qty " +
                    "ORDER BY SMDD.DDBH ",
                    request.Order, request.PartID
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);
            List<OrderCycle> CycleList = new List<OrderCycle>();

            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    OrderCycle Cycle = new OrderCycle();
                    Cycle.Cycle = dt.Rows[i]["DDBH"].ToString();
                    if ((int)dt.Rows[i]["AllDispatched"] == 0)
                    {
                        Cycle.AllDispatched = false;
                    }
                    else
                    {
                        Cycle.AllDispatched = true;
                    }
                    CycleList.Add(Cycle);
                }

                return JsonConvert.SerializeObject(CycleList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getOrderProcessingCycle")]
        public string getOrderProcessingCycle(ProcessRequest request)
        {
            string[] requestInfo = request.Section!.Split('@');
            string Process = string.Empty;
            string Part = string.Empty;
            if (requestInfo.Length == 1)
            {
                Process = requestInfo[0];
            }
            else
            {
                Part = requestInfo[0];
                Process = requestInfo[1];
            }

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT CASE WHEN LEN(SMDD.DDBH) < 14 AND LEN(SMDD.DDBH) - LEN(REPLACE(SMDD.DDBH, '-', '')) < 2 THEN SMDD.DDBH + '-001' " +
                    "ELSE CASE WHEN LEN(SMDD.DDBH) >= 14 AND LEN(SMDD.DDBH) - LEN(REPLACE(SMDD.DDBH, '-', '')) < 2 THEN SUBSTRING(SMDD.DDBH, 1, LEN(SMDD.DDBH)-3) + '-' + SUBSTRING(SMDD.DDBH, LEN(SMDD.DDBH)-2, 3) " +
                    "ELSE SMDD.DDBH END END AS DDBH, CASE WHEN SMDD.Qty = SUM(CutDispatchSS_GC.Qty) THEN 1 ELSE 0 END AS AllDispatched FROM SMDD " +
                    "LEFT JOIN CutDispatchSS_GC ON CutDispatchSS_GC.DDBH = SMDD.DDBH " + (Part != "" ? "AND CutDispatchSS_GC.BWBH = '" + Part + "' " : "") + (Process != "" ? "AND CutDispatchSS_GC.GCBWBH = '" + Process + "' " : "") +
                    "WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = 'A' " +
                    "GROUP BY SMDD.DDBH, SMDD.Qty " +
                    "ORDER BY SMDD.DDBH "
                    , request.Order
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);
            List<OrderCycle> CycleList = new List<OrderCycle>();

            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    OrderCycle Cycle = new OrderCycle();
                    Cycle.Cycle = dt.Rows[i]["DDBH"].ToString();
                    if ((int)dt.Rows[i]["AllDispatched"] == 0)
                    {
                        Cycle.AllDispatched = false;
                    }
                    else
                    {
                        Cycle.AllDispatched = true;
                    }
                    CycleList.Add(Cycle);
                }

                return JsonConvert.SerializeObject(CycleList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getOrderSizeRun")]
        public string getOrderSizeRun(OrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT SMDD.DDBH, CutDispatchZL.BWBH, CutDispatchZL.YWSM, CutDispatchZL.SIZE, ISNULL(CutDispatchZL.Qty, 0) AS Qty, ISNULL(CutDispatchZL.Dispatched, 0) AS Dispatched FROM ( " +
                    "  SELECT DISTINCT DDBH FROM SMDD " +
                    "  WHERE YSBH = '{0}' AND SMDD.GXLB = 'A' " +
                    ") AS SMDD " +
                    "LEFT JOIN ( " +
                    "  SELECT SMDD.DDBH, CutDispatchZL.BWBH, BWZL.YWSM, CutDispatchZL.SIZE, SMDD.Qty, CASE WHEN CutDispatchSS.Qty IS NOT NULL THEN 1 ELSE 0 END AS Dispatched FROM CutDispatchZL " +
                    "  LEFT JOIN BWZL ON BWZL.BWDH = CutDispatchZL.BWBH " +
                    "  LEFT JOIN( " +
                    "    SELECT SMDD.YSBH, SMDD.DDBH, SMDDS.XXCC, SMDDS.Qty FROM SMDDS " +
                    "    LEFT JOIN SMDD ON SMDD.DDBH = SMDDS.DDBH AND SMDD.GXLB = 'A' " +
                    "    WHERE YSBH = '{0}' " +
                    "  ) AS SMDD ON SMDD.YSBH = CutDispatchZL.ZLBH AND SMDD.XXCC = CutDispatchZL.SIZE " +
                    "  LEFT JOIN CutDispatchSS ON CutDispatchSS.ZLBH = CutDispatchZL.ZLBH AND CutDispatchSS.BWBH = CutDispatchZL.BWBH AND CutDispatchSS.SIZE = CutDispatchZL.SIZE AND CutDispatchSS.DDBH = SMDD.DDBH " +
                    "  WHERE CutDispatchZL.ZLBH = '{0}' AND CutDispatchZL.BWBH = '{1}' " +
                    ") AS CutDispatchZL ON CutDispatchZL.DDBH = SMDD.DDBH " +
                    "ORDER BY SMDD.DDBH, CutDispatchZL.BWBH, CutDispatchZL.SIZE ",
                    request.Order, request.PartID
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);
            List<OrderCycleResult> CycleList = new List<OrderCycleResult>();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    OrderCycleResult Cycles = new OrderCycleResult();
                    Cycles.Cycle = dt.Rows[Row]["DDBH"].ToString();
                    Cycles.Parts = new List<OrderCyclePart>();
                    OrderCyclePart Part = new OrderCyclePart();
                    Part.ID = dt.Rows[Row]["BWBH"].ToString();
                    Part.Name = dt.Rows[Row]["YWSM"].ToString();
                    Part.SizeQty = new List<OrderCyclePartSize>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["DDBH"].ToString() == Cycles.Cycle)
                    {
                        OrderCyclePartSize PartSize = new OrderCyclePartSize();
                        PartSize.Size = dt.Rows[Row]["SIZE"].ToString();
                        PartSize.Qty = (int)dt.Rows[Row]["Qty"];
                        if ((int)dt.Rows[Row]["Dispatched"] == 0)
                        {
                            PartSize.Dispatched = false;
                        }
                        else
                        {
                            PartSize.Dispatched = true;
                        }
                        Part.SizeQty.Add(PartSize);
                        Row++;
                    }
                    Cycles.Parts.Add(Part);
                    CycleList.Add(Cycles);
                }

                return JsonConvert.SerializeObject(CycleList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getOrderProcessingSizeRun")]
        public string getOrderProcessingSizeRun(ProcessRequest request)
        {
            string[] requestInfo = request.Section!.Split('@');
            string Process = string.Empty;
            string sPart = string.Empty;
            if (requestInfo.Length == 1)
            {
                Process = requestInfo[0];
            }
            else
            {
                sPart = requestInfo[0];
                Process = requestInfo[1];
            }

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT SMDD.DDBH, CutDispatchZL_GC.BWBH, BWZL.YWSM, CutDispatchZL_GC.SIZE, SMDD.Qty, CASE WHEN CutDispatchSS_GC.Qty IS NOT NULL THEN 1 ELSE 0 END AS Dispatched FROM CutDispatchZL_GC " +
                    "LEFT JOIN BWZL ON BWZL.BWDH = CutDispatchZL_GC.BWBH " +
                    "LEFT JOIN( " +
                    "  SELECT SMDD.YSBH, SMDD.DDBH, SMDDS.XXCC, SMDDS.Qty FROM SMDDS " +
                    "  LEFT JOIN SMDD ON SMDD.DDBH = SMDDS.DDBH AND SMDD.GXLB = 'A' " +
                    "  WHERE YSBH = '{0}' " +
                    ") AS SMDD ON SMDD.YSBH = CutDispatchZL_GC.ZLBH AND SMDD.XXCC = CutDispatchZL_GC.SIZE " +
                    "LEFT JOIN CutDispatchSS_GC ON CutDispatchSS_GC.ZLBH = CutDispatchZL_GC.ZLBH AND CutDispatchSS_GC.GCBWBH = CutDispatchZL_GC.GCBWBH AND CutDispatchSS_GC.BWBH = CutDispatchZL_GC.BWBH AND CutDispatchSS_GC.SIZE = CutDispatchZL_GC.SIZE AND CutDispatchSS_GC.DDBH = SMDD.DDBH " +
                    "WHERE CutDispatchZL_GC.ZLBH = '{0}' " + (sPart != "" ? "AND CutDispatchZL_GC.BWBH = '" + sPart + "' " : "") + (Process != "" ? "AND CutDispatchZL_GC.GCBWBH = '" + Process + "' " : "") +
                    "ORDER BY SMDD.DDBH, CutDispatchZL_GC.BWBH, CutDispatchZL_GC.SIZE "
                    , request.Order
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);
            List<OrderCycleResult> CycleList = new List<OrderCycleResult>();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    OrderCycleResult Cycles = new OrderCycleResult();
                    Cycles.Cycle = dt.Rows[Row]["DDBH"].ToString();
                    Cycles.Parts = new List<OrderCyclePart>();
                    OrderCyclePart Part = new OrderCyclePart();
                    Part.ID = dt.Rows[Row]["BWBH"].ToString();
                    Part.Name = dt.Rows[Row]["YWSM"].ToString();
                    Part.SizeQty = new List<OrderCyclePartSize>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["DDBH"].ToString() == Cycles.Cycle)
                    {
                        OrderCyclePartSize PartSize = new OrderCyclePartSize();
                        PartSize.Size = dt.Rows[Row]["SIZE"].ToString();
                        PartSize.Qty = (int)dt.Rows[Row]["Qty"];
                        if ((int)dt.Rows[Row]["Dispatched"] == 0)
                        {
                            PartSize.Dispatched = false;
                        }
                        else
                        {
                            PartSize.Dispatched = true;
                        }
                        Part.SizeQty.Add(PartSize);
                        Row++;
                    }
                    Cycles.Parts.Add(Part);
                    CycleList.Add(Cycles);
                }

                return JsonConvert.SerializeObject(CycleList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getOrderDispatchedSizeRun")]
        public string getOrderDispatchedSizeRun(OrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT SMDD.DDBH, CutDispatchZL.BWBH, CutDispatchZL.YWSM, CutDispatchZL.SIZE, ISNULL(CutDispatchZL.Qty, 0) AS Qty, ISNULL(CutDispatchZL.Reported, 0) AS Reported FROM ( " +
                    "  SELECT DISTINCT DDBH FROM SMDD " +
                    "  WHERE YSBH = '{0}' AND SMDD.GXLB = 'A' " +
                    ") AS SMDD " +
                    "LEFT JOIN ( " +
                    "  SELECT SMDD.DDBH, CutDispatchZL.BWBH, BWZL.YWSM, CutDispatchZL.SIZE, ISNULL(CutDispatchSS.Qty, 0) AS Qty, CASE WHEN ISNULL(CutDispatchSS.ScanQty, 0) > 0 THEN 1 ELSE 0 END AS Reported FROM ( " +
                    "    SELECT SMDD.YSBH, SMDD.DDBH, SMDDS.XXCC AS SIZE, SMDDS.Qty FROM SMDDS " +
                    "    LEFT JOIN SMDD ON SMDD.DDBH = SMDDS.DDBH AND SMDD.GXLB = 'A' " +
                    "    WHERE YSBH = '{0}' " +
                    "  ) AS SMDD " +
                    "  LEFT JOIN CutDispatchZL ON CutDispatchZL.ZLBH = SMDD.YSBH AND CutDispatchZL.SIZE = SMDD.SIZE " +
                    "  LEFT JOIN CutDispatchSS ON CutDispatchSS.ZLBH = CutDispatchZL.ZLBH AND CutDispatchSS.DDBH = SMDD.DDBH AND CutDispatchSS.BWBH = CutDispatchZL.BWBH AND CutDispatchSS.SIZE = CutDispatchZL.SIZE " +
                    "  LEFT JOIN BWZL ON BWZL.BWDH = CutDispatchZL.BWBH " +
                    "  WHERE CutDispatchZL.BWBH = '{1}' " +
                    ") AS CutDispatchZL ON CutDispatchZL.DDBH = SMDD.DDBH " +
                    "ORDER BY SMDD.DDBH, CutDispatchZL.BWBH, CutDispatchZL.SIZE "
                    , request.Order, request.PartID
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);
            List<OrderCycleResult> CycleList = new List<OrderCycleResult>();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    OrderCycleResult Cycles = new OrderCycleResult();
                    Cycles.Cycle = dt.Rows[Row]["DDBH"].ToString();

                    Cycles.Parts = new List<OrderCyclePart>();
                    OrderCyclePart Part = new OrderCyclePart();
                    Part.ID = dt.Rows[Row]["BWBH"].ToString();
                    Part.Name = dt.Rows[Row]["YWSM"].ToString();
                    Part.SizeQty = new List<OrderCyclePartSize>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["DDBH"].ToString() == Cycles.Cycle)
                    {
                        OrderCyclePartSize PartSize = new OrderCyclePartSize();
                        PartSize.Size = dt.Rows[Row]["SIZE"].ToString();
                        PartSize.Qty = (int)dt.Rows[Row]["Qty"];
                        if ((int)dt.Rows[Row]["Reported"] == 0)
                        {
                            PartSize.Dispatched = false;
                        }
                        else
                        {
                            PartSize.Dispatched = true;
                        }
                        Part.SizeQty.Add(PartSize);
                        Row++;
                    }

                    Cycles.Parts.Add(Part);
                    CycleList.Add(Cycles);
                }

                return JsonConvert.SerializeObject(CycleList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getOrderProcessingDispatchedSizeRun")]
        public string getOrderProcessingDispatchedSizeRun(ProcessRequest request)
        {
            string[] requestInfo = request.Section!.Split('@');
            string Process = string.Empty;
            string sPart = string.Empty;
            if (requestInfo.Length == 1)
            {
                Process = requestInfo[0];
            }
            else
            {
                sPart = requestInfo[0];
                Process = requestInfo[1];
            }

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT SMDD.DDBH, CutDispatchZL_GC.BWBH, BWZL.YWSM, CutDispatchZL_GC.SIZE, ISNULL(CutDispatchSS_GC.Qty, 0) AS Qty, CASE WHEN ISNULL(CutDispatchSS_GC.ScanQty, 0) > 0 THEN 1 ELSE 0 END AS Reported FROM ( " +
                    "  SELECT SMDD.YSBH, SMDD.DDBH, SMDDS.XXCC AS SIZE, SMDDS.Qty FROM SMDDS " +
                    "  LEFT JOIN SMDD ON SMDD.DDBH = SMDDS.DDBH AND SMDD.GXLB = 'A' " +
                    "  WHERE YSBH = '{0}' " +
                    ") AS SMDD " +
                    "LEFT JOIN CutDispatchZL_GC ON CutDispatchZL_GC.ZLBH = SMDD.YSBH AND CutDispatchZL_GC.SIZE = SMDD.SIZE " +
                    "LEFT JOIN CutDispatchSS_GC ON CutDispatchSS_GC.ZLBH = CutDispatchZL_GC.ZLBH AND CutDispatchSS_GC.DDBH = SMDD.DDBH AND CutDispatchSS_GC.GCBWBH = CutDispatchZL_GC.GCBWBH AND CutDispatchSS_GC.BWBH = CutDispatchZL_GC.BWBH AND CutDispatchSS_GC.SIZE = CutDispatchZL_GC.SIZE " +
                    "LEFT JOIN BWZL ON BWZL.BWDH = CutDispatchZL_GC.BWBH " +
                    "WHERE 1 = 1 " + (sPart != "" ? "AND CutDispatchZL_GC.BWBH = '" + sPart + "' " : "") + (Process != "" ? "AND CutDispatchZL_GC.GCBWBH = '" + Process + "' " : "") +
                    "ORDER BY SMDD.DDBH, CutDispatchZL_GC.BWBH, CutDispatchZL_GC.SIZE "
                    , request.Order
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);
            List<OrderCycleResult> CycleList = new List<OrderCycleResult>();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    OrderCycleResult Cycles = new OrderCycleResult();
                    Cycles.Cycle = dt.Rows[Row]["DDBH"].ToString();
                    if (dt.Rows[Row]["BWBH"] != DBNull.Value)
                    {
                        Cycles.Parts = new List<OrderCyclePart>();
                        OrderCyclePart Part = new OrderCyclePart();
                        Part.ID = dt.Rows[Row]["BWBH"].ToString();
                        Part.Name = dt.Rows[Row]["YWSM"].ToString();
                        Part.SizeQty = new List<OrderCyclePartSize>();

                        while (Row < dt.Rows.Count && dt.Rows[Row]["DDBH"].ToString() == Cycles.Cycle)
                        {
                            OrderCyclePartSize PartSize = new OrderCyclePartSize();
                            PartSize.Size = dt.Rows[Row]["SIZE"].ToString();
                            PartSize.Qty = (int)dt.Rows[Row]["Qty"];
                            if ((int)dt.Rows[Row]["Reported"] == 0)
                            {
                                PartSize.Dispatched = false;
                            }
                            else
                            {
                                PartSize.Dispatched = true;
                            }
                            Part.SizeQty.Add(PartSize);
                            Row++;
                        }

                        Cycles.Parts.Add(Part);
                    }
                    else
                    {
                        Row++;
                    }

                    CycleList.Add(Cycles);
                }

                return JsonConvert.SerializeObject(CycleList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getCuttingWorkOrder")]
        public string getCuttingWorkOrder(GetCuttingWorkOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#RY') IS NOT NULL " +
                    "BEGIN DROP TABLE #RY END; " +

                    "SELECT DISTINCT CutDispatchSS.ZLBH INTO #RY FROM CutDispatchSS " +
                    "LEFT JOIN CutDispatch ON CutDispatch.DLNO = CutDispatchSS.DLNO " +
                    "WHERE CutDispatch.PlanDate = '{0}' AND CutDispatch.UserID = '{1}' AND CutDispatch.DLLB = '{2}' " +

                    (request.Type == "Part" ? "SELECT CutDispatchSS.ZLBH, CutDispatchSS.BWBH, BWZL.YWSM, CutDispatchSS.DDBH, CutDispatchSS.SIZE, SUM(CutDispatchSS.Qty) AS Qty, SUM(CutDispatchSS.ScanQty) AS ScanQty FROM CutDispatchSS " : "SELECT CutDispatchSS.ZLBH, CutDispatchSS.DDBH, CutDispatchSS.BWBH, BWZL.YWSM, CutDispatchSS.SIZE, SUM(CutDispatchSS.Qty) AS Qty, SUM(CutDispatchSS.ScanQty) AS ScanQty FROM CutDispatchSS ") +
                    "LEFT JOIN CutDispatch ON CutDispatch.DLNO = CutDispatchSS.DLNO " +
                    "LEFT JOIN BWZL ON BWZL.BWDH = CutDispatchSS.BWBH " +
                    "WHERE CutDispatchSS.ZLBH IN (SELECT ZLBH FROM #RY) AND CutDispatch.UserID = '{1}' AND CutDispatch.DLLB = '{2}' " +
                    "GROUP BY CutDispatchSS.ZLBH, CutDispatchSS.DDBH, CutDispatchSS.BWBH, BWZL.YWSM, CutDispatchSS.SIZE " +
                    (request.Type == "Part" ? "ORDER BY CutDispatchSS.ZLBH, CutDispatchSS.BWBH, CutDispatchSS.DDBH, CutDispatchSS.SIZE " : "ORDER BY CutDispatchSS.ZLBH, CutDispatchSS.DDBH, CutDispatchSS.BWBH, CutDispatchSS.SIZE "),
                    request.Date, request.UserID, request.Type
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);
            List<dynamic> ResultList = new List<dynamic>();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    if (request.Type == "Part")
                    {
                        GetPartCuttingWorkOrderResult Order = new GetPartCuttingWorkOrderResult();
                        Order.Order = dt.Rows[Row]["ZLBH"].ToString();
                        Order.Items = new List<PartList>();

                        while (Row < dt.Rows.Count && dt.Rows[Row]["ZLBH"].ToString() == Order.Order)
                        {
                            PartList Part = new PartList();
                            Part.ID = dt.Rows[Row]["BWBH"].ToString();
                            Part.Name = dt.Rows[Row]["YWSM"].ToString();
                            Part.Cycle = new List<Cycles>();

                            while (Row < dt.Rows.Count && dt.Rows[Row]["BWBH"].ToString() == Part.ID)
                            {
                                Cycles Cycle = new Cycles();
                                Cycle.Cycle = dt.Rows[Row]["DDBH"].ToString();
                                Cycle.Size = new List<SizeQty>();

                                while (Row < dt.Rows.Count && dt.Rows[Row]["DDBH"].ToString() == Cycle.Cycle)
                                {
                                    SizeQty sizeQty = new SizeQty();
                                    sizeQty.Size = dt.Rows[Row]["SIZE"].ToString();
                                    sizeQty.Qty = (int)dt.Rows[Row]["Qty"];
                                    Cycle.Size.Add(sizeQty);
                                    Row++;
                                }
                                Part.Cycle.Add(Cycle);
                            }
                            Order.Items.Add(Part);
                        }
                        ResultList.Add(Order);
                    }
                    else
                    {
                        GetCycleCuttingWorkOrderResult Order = new GetCycleCuttingWorkOrderResult();
                        Order.Order = dt.Rows[Row]["ZLBH"].ToString();
                        Order.Items = new List<CycleList>();

                        while (Row < dt.Rows.Count && dt.Rows[Row]["ZLBH"].ToString() == Order.Order)
                        {
                            CycleList Cycle = new CycleList();
                            Cycle.Cycle = dt.Rows[Row]["DDBH"].ToString();
                            Cycle.Part = new List<Part>();

                            while (Row < dt.Rows.Count && dt.Rows[Row]["DDBH"].ToString() == Cycle.Cycle)
                            {
                                Part Part = new Part();
                                Part.ID = dt.Rows[Row]["BWBH"].ToString();
                                Part.Name = dt.Rows[Row]["YWSM"].ToString();
                                Part.Size = new List<SizeQty>();

                                while (Row < dt.Rows.Count && dt.Rows[Row]["BWBH"].ToString() == Part.ID)
                                {
                                    SizeQty sizeQty = new SizeQty();
                                    sizeQty.Size = dt.Rows[Row]["SIZE"].ToString();
                                    sizeQty.Qty = (int)dt.Rows[Row]["Qty"];
                                    Part.Size.Add(sizeQty);
                                    Row++;
                                }
                                Cycle.Part.Add(Part);
                            }
                            Order.Items.Add(Cycle);
                        }
                        ResultList.Add(Order);
                    }
                }

                return JsonConvert.SerializeObject(ResultList);
            }
            else
            {
                return "{}";
            }
        }

        [HttpPost]
        [Route("generateCuttingWorkOrder")]
        public string generateCuttingWorkOrder(CuttingWorkOrderRequest request)
        {
            string whereSQL = string.Empty;

            if (request.Cycle != null)
            {
                for (int i = 0; i < request.Cycle.Count; i++)
                {
                    if (i == 0)
                    {
                        whereSQL += System.String.Format("(SMDD.DDBH LIKE '{0}%{1}' AND CutDispatchZL.SIZE IN ({2}))", request.Order, (request.Cycle.Count > 1 ? System.String.Format("{0:000}", i + 1) : ""), "'" + string.Join("', '", request.Cycle[i]) + "'");
                    }
                    else
                    {
                        whereSQL += System.String.Format("OR (SMDD.DDBH LIKE '{0}%{1}' AND CutDispatchZL.SIZE IN ({2}))", request.Order, System.String.Format("{0:000}", i + 1), "'" + string.Join("', '", request.Cycle[i]) + "'");
                    }
                }

                SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
                SqlCommand SQL = new SqlCommand(
                    System.String.Format(
                        "IF OBJECT_ID('tempdb..#CutDispatch') IS NOT NULL " +
                        "BEGIN DROP TABLE #CutDispatch END; " +

                        "DECLARE @Seq AS Int = ( " +
                        "  SELECT ISNULL(MAX(CAST(SUBSTRING(DLNO, 7, 5) AS INT)), 0) AS DLNO FROM CutDispatch " +
                        "  WHERE DLNO LIKE SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + '%' " +
                        "); " +

                        "SELECT SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + RIGHT('0000' + CAST(@Seq + 1 AS VARCHAR), 5) AS DLNO, CutDispatchZL.ZLBH, SMDD.DDBH, CutDispatchZL.BWBH, " +
                        "CutDispatchZL.SIZE, CutDispatchZL.XXCC, CutDispatchZL.CLBH, SMDD.Qty, CASE WHEN ISNULL(CutDispatchZL.CutNum, 0) = 0 THEN SMDD.Qty ELSE CutDispatchZL.CutNum END AS CutNum, " +
                        "0 AS ScanQty, 0 AS QRCode, '' AS Machine, NULL AS MachineDate, NULL AS MachineEndDate, '{2}' AS UserID, GETDATE() AS UserDate, '1' AS YN INTO #CutDispatch FROM CutDispatchZL " +
                        "LEFT JOIN ( " +
                        "  SELECT SMDD.YSBH, SMDD.DDBH, SMDDS.XXCC, SMDDS.Qty FROM SMDD " +
                        "  LEFT JOIN SMDDS ON SMDDS.DDBH = SMDD.DDBH " +
                        "  WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = 'C' " +
                        ") AS SMDD ON SMDD.YSBH = CutDispatchZL.ZLBH AND SMDD.XXCC = CutDispatchZL.SIZE " +
                        "LEFT JOIN CutDispatchSS ON CutDispatchSS.ZLBH = CutDispatchZL.ZLBH AND CutDispatchSS.BWBH = CutDispatchZL.BWBH AND CutDispatchSS.SIZE = CutDispatchZL.SIZE AND CutDispatchSS.DDBH = SMDD.DDBH " +
                        "WHERE CutDispatchZL.ZLBH = '{0}' AND CutDispatchZL.BWBH = '{1}' AND CutDispatchSS.Qty IS NULL AND (" + whereSQL + "); " +

                        "INSERT INTO CutDispatch (DLNO, DLLB, GSBH, DepID, PlanDate, Memo, CustomLayers, USERID, USERDATE, YN) " +
                        "SELECT DISTINCT DLNO, '{5}' AS DLLB, '{3}' AS GSBH, '{4}' AS DepID, CONVERT(SmallDateTime, CONVERT(VARCHAR, UserDate, 111)) AS PlanDate, '' AS Memo, NULL AS CustomLayers, UserID, UserDate, YN FROM #CutDispatch " +
                        "GROUP BY DLNO, ZLBH, BWBH, SIZE, CLBH, XXCC, UserID, UserDate, YN; " +

                        "INSERT INTO CutDispatchS (DLNO, ZLBH, BWBH, SIZE, CLBH, Qty, XXCC, CutNum, okCutNum, USERID, USERDATE, ScanUser, ScanDate, YN) " +
                        "SELECT DLNO, ZLBH, BWBH, SIZE, CLBH, SUM(Qty) AS Qty, XXCC, SUM(CutNum) AS CutNum, 0 AS okCutNum, UserID, UserDate, '' AS ScanUser, NULL AS ScanDate, YN FROM #CutDispatch " +
                        "GROUP BY DLNO, ZLBH, BWBH, SIZE, CLBH, XXCC, UserID, UserDate, YN; " +

                        "INSERT INTO CutDispatchSS (DLNO, ZLBH, DDBH, BWBH, SIZE, CLBH, Qty, ScanQty, QRCode, Machine, MachineDate, MachineEndDate, USERID, USERDATE, YN) " +
                        "SELECT DLNO, ZLBH, DDBH, BWBH, SIZE, CLBH, Qty, ScanQty, QRCode, Machine, MachineDate, MachineEndDate, UserID, UserDate, YN FROM #CutDispatch; ",
                        request.Order, request.PartID, request.UserID, request.Factory, request.Department, request.Type
                    ), ERP
                );

                ERP.Open();
                int recordCount = SQL.ExecuteNonQuery();
                ERP.Dispose();


                if (recordCount > 0)
                {
                    return "{\"statusCode\": 200}";
                }
                else
                {
                    return "{\"statusCode\": 400}";
                }
            }
            else
            {
                return "{\"statusCode\": 404}";
            }
        }

        [HttpPost]
        [Route("generateProcessingWorkOrder")]
        public string generateProcessingWorkOrder(ProcessWorkOrderRequest request)
        {
            string[] requestInfo = request.Section!.Split('@');
            string Process = string.Empty;
            string Part = string.Empty;
            if (requestInfo.Length == 1)
            {
                Process = requestInfo[0];
            }
            else
            {
                Part = requestInfo[0];
                Process = requestInfo[1];
            }
            string whereSQL = string.Empty;

            if (request.Cycle != null)
            {
                for (int i = 0; i < request.Cycle.Count; i++)
                {
                    if (i == 0)
                    {
                        whereSQL += System.String.Format("(SMDD.DDBH LIKE '{0}%{1}' AND CutDispatchZL_GC.SIZE IN ({2}))", request.Order, (request.Cycle.Count > 1 ? System.String.Format("{0:000}", i + 1) : ""), "'" + string.Join("', '", request.Cycle[i]) + "'");
                    }
                    else
                    {
                        whereSQL += System.String.Format("OR (SMDD.DDBH LIKE '{0}%{1}' AND CutDispatchZL_GC.SIZE IN ({2}))", request.Order, System.String.Format("{0:000}", i + 1), "'" + string.Join("', '", request.Cycle[i]) + "'");
                    }
                }

                SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
                SqlCommand SQL = new SqlCommand(
                    System.String.Format(
                        "IF OBJECT_ID('tempdb..#CutDispatch_GC') IS NOT NULL " +
                        "BEGIN DROP TABLE #CutDispatch_GC END; " +

                        "DECLARE @Seq AS Int = ( " +
                        "  SELECT ISNULL(MAX(CAST(SUBSTRING(DLNO, 7, 5) AS INT)), 0) AS DLNO FROM CutDispatch_GC " +
                        "  WHERE DLNO LIKE SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + '%' " +
                        "); " +

                        "SELECT SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + RIGHT('0000' + CAST(@Seq + 1 AS VARCHAR), 5) AS DLNO, CutDispatchZL_GC.ZLBH, " +
                        "SMDD.DDBH, CutDispatchZL_GC.GCBWBH, CutDispatchZL_GC.BWBH, CutDispatchZL_GC.SIZE, CutDispatchZL_GC.CLBH, SMDD.Qty, " +
                        "0 AS ScanQty, '{1}' AS UserID, GETDATE() AS UserDate, '1' AS YN INTO #CutDispatch_GC FROM CutDispatchZL_GC " +
                        "LEFT JOIN( " +
                        "  SELECT SMDD.YSBH, SMDD.DDBH, SMDDS.XXCC, SMDDS.Qty FROM SMDD " +
                        "  LEFT JOIN SMDDS ON SMDDS.DDBH = SMDD.DDBH " +
                        "  WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = 'C' " +
                        ") AS SMDD ON SMDD.YSBH = CutDispatchZL_GC.ZLBH AND SMDD.XXCC = CutDispatchZL_GC.SIZE " +
                        "LEFT JOIN CutDispatchSS_GC ON CutDispatchSS_GC.ZLBH = CutDispatchZL_GC.ZLBH AND CutDispatchSS_GC.GCBWBH = CutDispatchZL_GC.GCBWBH AND CutDispatchSS_GC.BWBH = CutDispatchZL_GC.BWBH AND CutDispatchSS_GC.SIZE = CutDispatchZL_GC.SIZE AND CutDispatchSS_GC.DDBH = SMDD.DDBH " +
                        "WHERE CutDispatchZL_GC.ZLBH = '{0}' " + (Part != "" ? "AND CutDispatchZL_GC.BWBH = '" + Part + "' " : "") + (Process != "" ? "AND CutDispatchZL_GC.GCBWBH = '" + Process + "' " : "") + "AND CutDispatchSS_GC.Qty IS NULL AND (" + whereSQL + "); " +

                        "INSERT INTO CutDispatch_GC (DLNO, GSBH, DepID, PlanDate, Memo, USERID, USERDATE, CFMID, CFMDate, YN) " +
                        "SELECT DISTINCT DLNO, '{2}' AS GSBH, '{3}' AS DepID, CONVERT(SmallDateTime, CONVERT(VARCHAR, UserDate, 111)) AS PlanDate, '' AS Memo, UserID, UserDate, '' AS CFMID, NULL AS CFMDate, YN FROM #CutDispatch_GC " +
                        "GROUP BY DLNO, UserID, UserDate, YN; " +

                        "INSERT INTO CutDispatchS_GC (DLNO, ZLBH, GCBWBH, SIZE, BWBH, TmpQty, Qty, USERDATE, USERID, YN) " +
                        "SELECT DLNO, ZLBH, GCBWBH, SIZE, BWBH, SUM(Qty) AS TemQty, ScanQty AS Qty, UserDate, UserID, YN FROM #CutDispatch_GC " +
                        "GROUP BY DLNO, ZLBH, GCBWBH, SIZE, BWBH, ScanQty, UserID, UserDate, YN; " +

                        "INSERT INTO CutDispatchSS_GC (DLNO, ZLBH, DDBH, GCBWBH, SIZE, BWBH, Qty, ScanQty, ScanDep, ScanUser, ScanDate, USERDATE, USERID, YN) " +
                        "SELECT DLNO, ZLBH, DDBH, GCBWBH, SIZE, BWBH, Qty, ScanQty, '' AS ScanDep, '' AS ScanUser, NULL AS ScanDate, UserDate, UserID, YN FROM #CutDispatch_GC; "
                        , request.Order, request.UserID, request.Factory, request.Department, request.Type
                    ), ERP
                );

                ERP.Open();
                int recordCount = SQL.ExecuteNonQuery();
                ERP.Dispose();


                if (recordCount > 0)
                {
                    return "{\"statusCode\": 200}";
                }
                else
                {
                    return "{\"statusCode\": 400}";
                }
            }
            else
            {
                return "{\"statusCode\": 404}";
            }
        }

        [HttpPost]
        [Route("generateProcessingMergeWorkOrder")]
        public string generateProcessingMergeWorkOrder(ProcessWorkOrderRequest request)
        {
            string[] orderList = request.Order!.Replace(" ", "").Split(',');
            string[] requestInfo = request.Section!.Split('@');
            string Process = string.Empty;
            string Part = string.Empty;
            if (requestInfo.Length == 1)
            {
                Process = requestInfo[0];
            }
            else
            {
                Part = requestInfo[0];
                Process = requestInfo[1];
            }
            string whereSQL = string.Empty;

            if (orderList.Length > 0)
            {
                int totalRecordCount = 0;
                for (int i = 0; i < orderList.Length; i++)
                {
                    SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
                    SqlCommand SQL = new SqlCommand(
                        System.String.Format(
                            "IF OBJECT_ID('tempdb..#CutDispatch_GC') IS NOT NULL " +
                            "BEGIN DROP TABLE #CutDispatch_GC END; " +

                            "DECLARE @Seq AS Int = ( " +
                            "  SELECT ISNULL(MAX(CAST(SUBSTRING(DLNO, 7, 5) AS INT)), 0) AS DLNO FROM CutDispatch_GC " +
                            "  WHERE DLNO LIKE SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + '%' " +
                            "); " +

                            "SELECT SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + RIGHT('0000' + CAST(@Seq + 1 AS VARCHAR), 5) AS DLNO, CutDispatchZL_GC.ZLBH, " +
                            "SMDD.DDBH, CutDispatchZL_GC.GCBWBH, CutDispatchZL_GC.BWBH, CutDispatchZL_GC.SIZE, CutDispatchZL_GC.CLBH, SMDD.Qty, " +
                            "0 AS ScanQty, '{1}' AS UserID, GETDATE() AS UserDate, '1' AS YN INTO #CutDispatch_GC FROM CutDispatchZL_GC " +
                            "LEFT JOIN( " +
                            "  SELECT SMDD.YSBH, SMDD.DDBH, SMDDS.XXCC, SMDDS.Qty FROM SMDD " +
                            "  LEFT JOIN SMDDS ON SMDDS.DDBH = SMDD.DDBH " +
                            "  WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = 'C' " +
                            ") AS SMDD ON SMDD.YSBH = CutDispatchZL_GC.ZLBH AND SMDD.XXCC = CutDispatchZL_GC.SIZE " +
                            "LEFT JOIN CutDispatchSS_GC ON CutDispatchSS_GC.ZLBH = CutDispatchZL_GC.ZLBH AND CutDispatchSS_GC.GCBWBH = CutDispatchZL_GC.GCBWBH AND CutDispatchSS_GC.BWBH = CutDispatchZL_GC.BWBH AND CutDispatchSS_GC.SIZE = CutDispatchZL_GC.SIZE AND CutDispatchSS_GC.DDBH = SMDD.DDBH " +
                            "WHERE CutDispatchZL_GC.ZLBH = '{0}' " + (Part != "" ? "AND CutDispatchZL_GC.BWBH = '" + Part + "' " : "") + (Process != "" ? "AND CutDispatchZL_GC.GCBWBH = '" + Process + "' " : "") + "AND CutDispatchSS_GC.Qty IS NULL; " +

                            "INSERT INTO CutDispatch_GC (DLNO, GSBH, DepID, PlanDate, Memo, USERID, USERDATE, CFMID, CFMDate, YN) " +
                            "SELECT DISTINCT DLNO, '{2}' AS GSBH, '{3}' AS DepID, CONVERT(SmallDateTime, CONVERT(VARCHAR, UserDate, 111)) AS PlanDate, '' AS Memo, UserID, UserDate, '' AS CFMID, NULL AS CFMDate, YN FROM #CutDispatch_GC " +
                            "GROUP BY DLNO, UserID, UserDate, YN; " +

                            "INSERT INTO CutDispatchS_GC (DLNO, ZLBH, GCBWBH, SIZE, BWBH, TmpQty, Qty, USERDATE, USERID, YN) " +
                            "SELECT DLNO, ZLBH, GCBWBH, SIZE, BWBH, SUM(Qty) AS TemQty, ScanQty AS Qty, UserDate, UserID, YN FROM #CutDispatch_GC " +
                            "GROUP BY DLNO, ZLBH, GCBWBH, SIZE, BWBH, ScanQty, UserID, UserDate, YN; " +

                            "INSERT INTO CutDispatchSS_GC (DLNO, ZLBH, DDBH, GCBWBH, SIZE, BWBH, Qty, ScanQty, ScanDep, ScanUser, ScanDate, USERDATE, USERID, YN) " +
                            "SELECT DLNO, ZLBH, DDBH, GCBWBH, SIZE, BWBH, Qty, ScanQty, '' AS ScanDep, '' AS ScanUser, NULL AS ScanDate, UserDate, UserID, YN FROM #CutDispatch_GC; "
                            , orderList[i], request.UserID, request.Factory, request.Department
                        ), ERP
                    );

                    ERP.Open();
                    totalRecordCount += SQL.ExecuteNonQuery();
                    ERP.Dispose();
                }

                if (totalRecordCount > 0)
                {
                    return "{\"statusCode\": 200}";
                }
                else
                {
                    return "{\"statusCode\": 400}";
                }
            }
            else
            {
                return "{\"statusCode\": 404}";
            }
        }

        [HttpPost]
        [Route("generateOrderCycleDispatchData")]
        public string generateOrderCycleDispatchData(CuttingWorkOrderRequest request)
        {
            if (request.SelectedCycle != null)
            {
                string ListSQL = "";
                SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
                SqlCommand SQL;
                if (request.Section!.Length == 1)
                {
                    if (request.Date != "")
                    {
                        SqlDataAdapter da = new SqlDataAdapter(
                            string.Format(
                                "SELECT CASE WHEN RIGHT('{0}', 5) = '09:30' THEN DATEDIFF(SS, GETDATE(), LEFT('{0}', 10) + ' 08:30') " +
                                "ELSE CASE WHEN RIGHT('{0}', 5) = '13:30' THEN DATEDIFF(SS, GETDATE(), LEFT('{0}', 10) + ' 12:30') " +
                                "ELSE DATEDIFF(SS, GETDATE(), LEFT('{0}', 10) + ' 15:30') END END AS Time ",
                                request.Date
                            ), ERP
                        );
                        DataTable dt = new DataTable();
                        da.Fill(dt);

                        if ((int)dt.Rows[0]["Time"] < 0)
                        {
                            return "{\"statusCode\": 401}";
                        }
                    }

                    if (request.Section == "C")
                    {
                        ListSQL = System.String.Format(
                            "DECLARE @Seq AS Int = ( " +
                            "  SELECT ISNULL(MAX(CAST(SUBSTRING(ListNo, 7, 5) AS INT)), 0) AS ListNo FROM CycleDispatchList " +
                            "  WHERE ListNo LIKE SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + '%' " +
                            "); " +

                            "SET @ListNo = (SELECT SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + RIGHT('0000' + CAST(@Seq + 1 AS VARCHAR), 5)); " +

                            "INSERT INTO CycleDispatchList (ListNo, Type, Building, Lean, Date, Pairs, Remark, UserID, UserDate) " +
                            "SELECT @ListNo AS ListNo, '{0}' AS Type, '{1}' AS Building, '{2}' AS Lean, '{3}' AS Date, {4} AS Pairs, N'{5}' AS Remark, '{6}' AS UserID, GetDate() AS UserDate; ",
                            request.Type, request.Department!.Split('_')[0], request.Department!.Split('_')[1], request.Date, request.Pairs, request.Remark!.Replace("'", "''"), request.UserID
                        );
                    }

                    if (request.Type == "Others")
                    {
                        if (request.SelectedCycle != "''")
                        {
                            SQL = new SqlCommand(
                                System.String.Format(
                                    "DECLARE @ListNo AS VARCHAR(11) = ''; " +
                                    ListSQL +
                                    "INSERT INTO CycleDispatchOthers (ListNo, ZLBH, DDBH) " +
                                    "SELECT @ListNo AS ListNo, YSBH, DDBH FROM SMDD " +
                                    "WHERE YSBH = '{0}' AND GXLB = '{1}' AND SMDD.DDBH IN ({2}) ",
                                    request.Order, request.Section, request.SelectedCycle
                                ), ERP
                            );
                        }
                        else
                        {
                            SQL = new SqlCommand(
                                System.String.Format(
                                    "DECLARE @ListNo AS VARCHAR(11) = ''; " +
                                    ListSQL +
                                    "INSERT INTO CycleDispatchOthers (ListNo, ZLBH, DDBH) " +
                                    "SELECT @ListNo AS ListNo, '{0}' AS ZLBH, '' AS DDBH ",
                                    request.Order
                                ), ERP
                            );
                        }
                    }
                    else
                    {
                        SQL = new SqlCommand(
                            System.String.Format(
                                "DECLARE @ListNo AS VARCHAR(11) = ''; " +
                                ListSQL +
                                "INSERT INTO CycleDispatch (ZLBH, GXLB, DDBH, ListNo, GSBH, DepID, UserID, UserDate, YN) " +
                                "SELECT SMDD.YSBH, SMDD.GXLB, SMDD.DDBH, @ListNo AS ListNo, '{3}' AS GSBH, '{4}' AS DepID, '{2}' AS UserID, GETDATE() AS UserDate, '1' AS YN FROM SMDD " +
                                "LEFT JOIN CycleDispatch ON CycleDispatch.ZLBH = SMDD.YSBH AND CycleDispatch.DDBH = SMDD.DDBH AND CycleDispatch.GXLB = SMDD.GXLB " +
                                "WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = '{1}' AND CycleDispatch.DDBH IS NULL " +
                                "AND SMDD.DDBH IN ({5}) ",
                                request.Order, request.Section, request.UserID, request.Factory, request.Department, request.SelectedCycle
                            ), ERP
                        );
                    }
                }
                else
                {
                    string Section = request.Section[0].ToString();
                    string GXLB = request.Section.Substring(1);

                    SQL = new SqlCommand(
                        System.String.Format(
                            "DECLARE @ListNo AS VARCHAR(11) = ''; " +

                            "INSERT INTO CycleDispatch (ZLBH, GXLB, DDBH, ListNo, GSBH, DepID, UserID, UserDate, YN) " +
                            "SELECT SMDD.YSBH, '{2}' AS GXLB, SMDD.DDBH, @ListNo AS ListNo, '{4}' AS GSBH, '{5}' AS DepID, '{3}' AS UserID, GETDATE() AS UserDate, '1' AS YN FROM SMDD " +
                            "LEFT JOIN CycleDispatch ON CycleDispatch.ZLBH = SMDD.YSBH AND CycleDispatch.DDBH = SMDD.DDBH AND CycleDispatch.GXLB = '{2}' " +
                            "WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = '{1}' AND CycleDispatch.DDBH IS NULL " +
                            "AND SMDD.DDBH IN ({6}) ",
                            request.Order, Section, GXLB, request.UserID, request.Factory, request.Department, request.SelectedCycle
                        ), ERP
                    );
                }

                ERP.Open();
                int recordCount = SQL.ExecuteNonQuery();
                ERP.Dispose();


                if (recordCount > 0)
                {
                    return "{\"statusCode\": 200}";
                }
                else
                {
                    return "{\"statusCode\": 400}";
                }
            }
            else
            {
                return "{\"statusCode\": 404}";
            }
        }

        [HttpPost]
        [Route("submitCuttingProgress")]
        public string submitCuttingProgress(CuttingWorkOrderRequest request)
        {
            string whereSQL = string.Empty;

            if (request.Cycle != null)
            {
                for (int i = 0; i < request.Cycle.Count; i++)
                {
                    if (i == 0)
                    {
                        whereSQL += System.String.Format("(DDBH LIKE '{0}%{1}' AND SIZE IN ({2}))", request.Order, (request.Cycle.Count > 1 ? System.String.Format("{0:000}", i + 1) : ""), "'" + string.Join("', '", request.Cycle[i]) + "'");
                    }
                    else
                    {
                        whereSQL += System.String.Format("OR (DDBH LIKE '{0}%{1}' AND SIZE IN ({2}))", request.Order, System.String.Format("{0:000}", i + 1), "'" + string.Join("', '", request.Cycle[i]) + "'");
                    }
                }

                SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
                SqlCommand SQL = new SqlCommand(
                    System.String.Format(
                        "UPDATE CutDispatchSS SET ScanQty = Qty, Machine = '{3}', MachineDate = GETDATE() " +
                        "WHERE ZLBH = '{0}' AND BWBH = '{1}' AND (" + whereSQL + "); " +

                        "UPDATE CutDispatchS SET okCutNum = FLOOR(CutNum * CutDispatchSS.ScanQty / CutDispatchSS.Qty), ScanUser = '{2}', " +
                        "ScanDate = CASE WHEN okCutNum <> FLOOR(CutNum * CutDispatchSS.ScanQty / CutDispatchSS.Qty) THEN GETDATE() ELSE NULL END " +
                        "FROM ( " +
                        "  SELECT CutDispatchSS.* FROM CutDispatchS " +
                        "  LEFT JOIN ( " +
                        "    SELECT ZLBH, BWBH, SIZE, SUM(Qty) AS Qty, SUM(ScanQty) AS ScanQty FROM CutDispatchSS " +
                        "    WHERE ZLBH = '{0}' AND BWBH = '{1}' " +
                        "    GROUP BY ZLBH, BWBH, SIZE " +
                        "  ) AS CutDispatchSS ON CutDispatchSS.ZLBH = CutDispatchS.ZLBH AND CutDispatchSS.BWBH = CutDispatchS.BWBH AND CutDispatchSS.SIZE = CutDispatchS.SIZE " +
                        "  WHERE CutDispatchS.ZLBH = '{0}' AND CutDispatchS.BWBH = '{1}' " +
                        ") AS CutDispatchSS " +
                        "WHERE CutDispatchS.ZLBH = CutDispatchSS.ZLBH AND CutDispatchS.BWBH = CutDispatchSS.BWBH AND CutDispatchS.SIZE = CutDispatchSS.SIZE; "
                        , request.Order, request.PartID, request.UserID, request.Department
                    ), ERP
                );

                ERP.Open();
                int recordCount = SQL.ExecuteNonQuery();
                ERP.Dispose();

                if (recordCount > 0)
                {
                    return "{\"statusCode\": 200}";
                }
                else
                {
                    return "{\"statusCode\": 400}";
                }
            }
            else
            {
                return "{\"statusCode\": 404}";
            }
        }

        [HttpPost]
        [Route("submitProcessingProgress")]
        public string submitProcessingProgress(ProcessWorkOrderRequest request)
        {
            string[] requestInfo = request.Section!.Split('@');
            string Process = string.Empty;
            string Part = string.Empty;
            if (requestInfo.Length == 1)
            {
                Process = requestInfo[0];
            }
            else
            {
                Part = requestInfo[0];
                Process = requestInfo[1];
            }
            string whereSQL = string.Empty;

            if (request.Cycle != null)
            {
                for (int i = 0; i < request.Cycle.Count; i++)
                {
                    if (i == 0)
                    {
                        whereSQL += System.String.Format("(DDBH LIKE '{0}%{1}' AND SIZE IN ({2}))", request.Order, (request.Cycle.Count > 1 ? System.String.Format("{0:000}", i + 1) : ""), "'" + string.Join("', '", request.Cycle[i]) + "'");
                    }
                    else
                    {
                        whereSQL += System.String.Format("OR (DDBH LIKE '{0}%{1}' AND SIZE IN ({2}))", request.Order, System.String.Format("{0:000}", i + 1), "'" + string.Join("', '", request.Cycle[i]) + "'");
                    }
                }

                SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
                SqlCommand SQL = new SqlCommand(
                    System.String.Format(
                        "UPDATE CutDispatchSS_GC SET ScanQty = Qty, ScanDep = '{2}', ScanUser = '{1}', ScanDate = GETDATE() " +
                        "WHERE ZLBH = '{0}' " + (Part != "" ? "AND BWBH = '" + Part + "' " : "") + (Process != "" ? "AND GCBWBH = '" + Process + "' " : "") + "AND (" + whereSQL + "); " +

                        "UPDATE CutDispatchS_GC SET Qty = FLOOR(TmpQty * CutDispatchSS_GC.ScanQty / CutDispatchSS_GC.Qty) " +
                        "FROM ( " +
                        "  SELECT CutDispatchSS_GC.* FROM CutDispatchS_GC " +
                        "  LEFT JOIN ( " +
                        "    SELECT ZLBH, GCBWBH, BWBH, SIZE, SUM(Qty) AS Qty, SUM(ScanQty) AS ScanQty FROM CutDispatchSS_GC " +
                        "    WHERE ZLBH = '{0}' " + (Part != "" ? "AND BWBH = '" + Part + "' " : "") + (Process != "" ? "AND GCBWBH = '" + Process + "' " : "") + 
                        "    GROUP BY ZLBH, GCBWBH, BWBH, SIZE " +
                        "  ) AS CutDispatchSS_GC ON CutDispatchSS_GC.ZLBH = CutDispatchS_GC.ZLBH AND CutDispatchSS_GC.GCBWBH = CutDispatchS_GC.GCBWBH AND CutDispatchSS_GC.BWBH = CutDispatchS_GC.BWBH AND CutDispatchSS_GC.SIZE = CutDispatchS_GC.SIZE " +
                        "  WHERE CutDispatchS_GC.ZLBH = '{0}' " + (Part != "" ? "AND CutDispatchS_GC.BWBH = '" + Part + "' " : "") + (Process != "" ? "AND CutDispatchS_GC.GCBWBH = '" + Process + "' " : "") +
                        ") AS CutDispatchSS_GC " +
                        "WHERE CutDispatchS_GC.ZLBH = CutDispatchSS_GC.ZLBH AND CutDispatchS_GC.GCBWBH = CutDispatchSS_GC.GCBWBH AND CutDispatchS_GC.BWBH = CutDispatchSS_GC.BWBH AND CutDispatchS_GC.SIZE = CutDispatchSS_GC.SIZE; "
                        , request.Order, request.UserID, request.Department
                    ), ERP
                );

                ERP.Open();
                int recordCount = SQL.ExecuteNonQuery();
                ERP.Dispose();

                if (recordCount > 0)
                {
                    return "{\"statusCode\": 200}";
                }
                else
                {
                    return "{\"statusCode\": 400}";
                }
            }
            else
            {
                return "{\"statusCode\": 404}";
            }
        }

        [HttpPost]
        [Route("getOrderCuttingTrackingData")]
        public string getOrderCuttingTrackingData(CuttingWorkOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da;

            if (request.Type == "Demo")
            {
                da = new SqlDataAdapter(
                    System.String.Format(
                        "IF OBJECT_ID('tempdb..#ZL') IS NOT NULL " +
                        "BEGIN DROP TABLE #ZL END; " +

                        "SELECT CutDispatchZL.ZLBH, SMDD.DDBH, CutDispatchZL.BWBH, CutDispatchZL.CLBH, CutDispatchZL.SIZE, SUM(ISNULL(SMDDS.Qty, 0)) AS Pairs INTO #ZL FROM CutDispatchZL " +
                        "LEFT JOIN SMDD ON SMDD.YSBH = CutDispatchZL.ZLBH AND SMDD.GXLB = 'C' " +
                        "LEFT JOIN SMDDS ON SMDDS.DDBH = SMDD.DDBH AND SMDDS.XXCC = CutDispatchZL.SIZE " +
                        "WHERE CutDispatchZL.ZLBH = '{0}' AND SUBSTRING(CutDispatchZL.CLBH, 1, 1) NOT IN('L', 'N', 'J') AND CutDispatchZL.Piece > 0 AND ISNULL(SMDDS.Qty, 0) > 0 " +
                        "GROUP BY CutDispatchZL.ZLBH, SMDD.DDBH, CutDispatchZL.BWBH, CutDispatchZL.CLBH, CutDispatchZL.SIZE " +

                        "SELECT CASE WHEN SS.DDBH <> SS.ZLBH THEN CAST(RIGHT(SS.DDBH, 3) AS INT) ELSE 1 END AS Cycle, SS.BWBH, SS.CLBH, BWZL.ZWSM, BWZL.YWSM, " +
                        "SS.ZLPairs AS TargetPairs, SS.DPairs AS DispatchedPairs, SS.CPairs AS ScanPairs, ISNULL(KT_SOPCut.Type, 'Manual') AS DLLB FROM ( " +
                        "  SELECT ZL.ZLBH, ZL.DDBH, ZL.BWBH, ZL.CLBH, SUM(ZL.ZLPairs) AS ZLPairs, " +
                        "  SUM(CASE WHEN CS.DDBH IS NOT NULL OR CA.DDBH IS NOT NULL THEN ZL.ZLPairs ELSE SS.Pairs END) AS DPairs, " +
                        "  SUM(CASE WHEN CS.DDBH IS NOT NULL OR CA.DDBH IS NOT NULL THEN ZL.ZLPairs ELSE SS.ScanPairs END) AS CPairs FROM ( " +
                        "    SELECT ZLBH, DDBH, BWBH, CLBH, SUM(Pairs) AS ZLPairs FROM #ZL " +
                        "    GROUP BY ZLBH, DDBH, BWBH, CLBH " +
                        "  ) AS ZL " +
                        "  LEFT JOIN ( " +
                        "    SELECT Dispatched.ZLBH, Dispatched.DDBH, Dispatched.BWBH, ISNULL(SUM(Dispatched.Pairs), 0) AS Pairs, ISNULL(SUM(CutDispatchSS.ScanQty), 0) AS ScanPairs FROM ( " +
                        "      SELECT DISTINCT #ZL.ZLBH, #ZL.DDBH, #ZL.BWBH, #ZL.CLBH, #ZL.SIZE, SMDDS.Qty AS Pairs FROM #ZL " +
                        "      LEFT JOIN MRCardS ON MRCardS.RY_Begin = #ZL.ZLBH AND MRCardS.MaterialID = #ZL.CLBH " +
                        "      LEFT JOIN MRCard ON MRCard.ListNo = MRCardS.ListNo " +
                        "      LEFT JOIN SMDDS ON SMDDS.DDBH = #ZL.DDBH AND SMDDS.XXCC = #ZL.SIZE " +
                        "      WHERE MRCard.Section = 'C' AND MRCard.DeliveryCFMDate IS NOT NULL AND MRCardS.IssuanceUsage > 0 " +
                        "      UNION " +
                        "      SELECT #ZL.ZLBH, #ZL.DDBH, #ZL.BWBH, #ZL.CLBH, #ZL.SIZE, SMDDS.Qty AS Pairs FROM #ZL " +
                        "      LEFT JOIN CutDispatchSS ON CutDispatchSS.DDBH = #ZL.DDBH AND CutDispatchSS.BWBH = #ZL.BWBH AND CutDispatchSS.SIZE = #ZL.SIZE " +
                        "      LEFT JOIN SMDDS ON SMDDS.DDBH = CutDispatchSS.DDBH AND SMDDS.XXCC = CutDispatchSS.SIZE " +
                        "      WHERE SMDDS.Qty > 0 " +
                        "    ) AS Dispatched " +
                        "    LEFT JOIN CutDispatchSS ON CutDispatchSS.DDBH = Dispatched.DDBH AND CutDispatchSS.BWBH = Dispatched.BWBH AND CutDispatchSS.SIZE = Dispatched.SIZE " +
                        "    GROUP BY Dispatched.ZLBH, Dispatched.DDBH, Dispatched.BWBH " +
                        "  ) AS SS ON SS.ZLBH = ZL.ZLBH AND SS.DDBH = ZL.DDBH " +
                        "  LEFT JOIN CycleDispatch AS CS ON CS.DDBH = ZL.DDBH AND CS.GXLB = 'S' " +
                        "  LEFT JOIN CycleDispatch AS CA ON CA.DDBH = ZL.DDBH AND CA.GXLB = 'A' " +
                        "  GROUP BY ZL.ZLBH, ZL.DDBH, ZL.BWBH, ZL.CLBH " +
                        ") AS SS " +
                        "LEFT JOIN BWZL ON BWZL.BWDH = SS.BWBH " +
                        "LEFT JOIN DDZL ON DDZL.DDBH = SS.ZLBH " +
                        "LEFT JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao AND KT_SOPCut.BWBH = SS.BWBH " +
                        "ORDER BY SS.DDBH, ISNULL(KT_SOPCut.Type, 'Manual') DESC, SS.BWBH "
                        , request.Order
                    ), ERP
                );
            }
            else
            {
                da = new SqlDataAdapter(
                    System.String.Format(
                        "SELECT CASE WHEN SMDD.DDBH <> SMDD.YSBH THEN CAST(RIGHT(SMDD.DDBH, 3) AS INT) ELSE 1 END AS Cycle, CutDispatchZL.BWBH, CutDispatchZL.CLBH, BWZL.ZWSM, BWZL.YWSM, " +
                        "ISNULL(SUM(SMDDS.Qty), 0) AS TargetPairs, ISNULL(CutDispatchSS.DispatchedQty, 0) AS DispatchedPairs, ISNULL(CutDispatchSS.ScanQty, 0) AS ScanPairs, ISNULL(KT_SOPCut.Type, 'Manual') AS DLLB FROM CutDispatchZL " +
                        "LEFT JOIN SMDD ON SMDD.YSBH = CutDispatchZL.ZLBH AND SMDD.GXLB = 'C' " +
                        "LEFT JOIN SMDDS ON SMDDS.DDBH = SMDD.DDBH AND SMDDS.XXCC = CutDispatchZL.SIZE " +
                        "LEFT JOIN( " +
                        "  SELECT CutDispatchSS.DDBH, CutDispatchSS.BWBH, SUM(CutDispatchSS.Qty) AS DispatchedQty, SUM(CutDispatchSS.ScanQty) AS ScanQty FROM CutDispatchSS " +
                        "  LEFT JOIN CutDispatch ON CutDispatch.DLNO = CutDispatchSS.DLNO " +
                        "  WHERE CutDispatchSS.ZLBH = '{0}' " +
                        "  GROUP BY CutDispatchSS.DDBH, CutDispatchSS.BWBH " +
                        ") AS CutDispatchSS ON CutDispatchSS.DDBH = SMDD.DDBH AND CutDispatchSS.BWBH = CutDispatchZL.BWBH " +
                        "LEFT JOIN BWZL ON BWZL.BWDH = CutDispatchZL.BWBH " +
                        "LEFT JOIN DDZL ON DDZL.DDBH = CutDispatchZL.ZLBH " +
                        "LEFT JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao AND KT_SOPCut.BWBH = CutDispatchZL.BWBH " +
                        "WHERE CutDispatchZL.ZLBH = '{0}' AND SUBSTRING(CutDispatchZL.CLBH, 1, 1) NOT IN ('L', 'N', 'J') AND CutDispatchZL.Piece > 0 " +
                        "GROUP BY SMDD.DDBH, SMDD.YSBH, CutDispatchZL.BWBH, CutDispatchZL.CLBH, BWZL.ZWSM, BWZL.YWSM, CutDispatchSS.DispatchedQty, CutDispatchSS.ScanQty, KT_SOPCut.Type " +
                        "ORDER BY SMDD.DDBH, ISNULL(KT_SOPCut.Type, 'Manual') DESC, CutDispatchZL.BWBH "
                        , request.Order
                    ), ERP
                );
            }
            DataTable dt = new DataTable();
            da.Fill(dt);
            List<dynamic> ResultList = new List<dynamic>();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    OrderCycles OrderCycle = new OrderCycles();
                    OrderCycle.Cycle = dt.Rows[Row]["Cycle"].ToString();
                    OrderCycle.Part = new List<CycleParts>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["Cycle"].ToString() == OrderCycle.Cycle)
                    {
                        CycleParts Part = new CycleParts();
                        Part.ID = dt.Rows[Row]["BWBH"].ToString();
                        Part.Material = dt.Rows[Row]["CLBH"].ToString();
                        Part.ZH = dt.Rows[Row]["ZWSM"].ToString();
                        Part.EN = dt.Rows[Row]["YWSM"].ToString();
                        Part.VI = dt.Rows[Row]["YWSM"].ToString();
                        Part.TargetPairs = (int)dt.Rows[Row]["TargetPairs"];
                        Part.DispatchedPairs = (int)dt.Rows[Row]["DispatchedPairs"];
                        Part.ScanPairs = (int)dt.Rows[Row]["ScanPairs"];
                        Part.CuttingType = dt.Rows[Row]["DLLB"].ToString() == "Manual" ? "Manual" : "Auto";

                        OrderCycle.Part.Add(Part);
                        Row++;
                    }
                    ResultList.Add(OrderCycle);
                }

                return JsonConvert.SerializeObject(ResultList);
            }
            else
            {
                return "{}";
            }
        }

        [HttpPost]
        [Route("getOrderProcessingTrackingData")]
        public string getOrderProcessingTrackingData(ProcessWorkOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da;
            if (request.Type == "Demo")
            {
                da = new SqlDataAdapter(
                    System.String.Format(
                        "IF OBJECT_ID('tempdb..#GC') IS NOT NULL " +
                        "BEGIN DROP TABLE #GC END; " +

                        "SELECT DISTINCT CutDispatchZL_GC.BWBH AS Section, ISNULL(BWZL.ZWSM, GC1.ZWSM) AS ZWSM, ISNULL(BWZL.YWSM, GC1.YWSM) AS YWSM, " +
                        "CASE WHEN GC2.Memo = 'Single' THEN CutDispatchZL_GC.BWBH + '@' + CutDispatchZL_GC.GCBWBH ELSE CutDispatchZL_GC.GCBWBH END AS Parent INTO #GC FROM CutDispatchZL_GC " +
                        "LEFT JOIN BWZL ON BWZL.BWDH = CutDispatchZL_GC.BWBH " +
                        "LEFT JOIN KT_SOPCutS_GCBWD AS GC1 ON GC1.GCBWDH = CutDispatchZL_GC.BWBH " +
                        "LEFT JOIN KT_SOPCutS_GCBWD AS GC2 ON GC2.GCBWDH = CutDispatchZL_GC.GCBWBH " +
                        "WHERE CutDispatchZL_GC.ZLBH = '{0}' " +

                        "IF OBJECT_ID('tempdb..#Section') IS NOT NULL " +
                        "BEGIN DROP TABLE #Section END; " +

                        "SELECT Section, ZWSM, YWSM, Parent INTO #Section FROM ( " +
                        "  SELECT Section, ZWSM, YWSM, Parent FROM #GC " +
                        "  UNION " +
                        "  SELECT DISTINCT SUBSTRING(GC.Parent, CHARINDEX('@', GC.Parent) + 1, LEN(GC.Parent) - CHARINDEX('@', GC.Parent)) AS Section, " +
                        "  KT_SOPCutS_GCBWD.ZWSM, KT_SOPCutS_GCBWD.YWSM, 'Root' AS Parent FROM #GC AS GC " +
                        "  LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = SUBSTRING(GC.Parent, CHARINDEX('@', GC.Parent) + 1, LEN(GC.Parent) - CHARINDEX('@', GC.Parent)) " +
                        "  LEFT JOIN #GC AS GC2 ON GC2.Section = SUBSTRING(GC.Parent, CHARINDEX('@', GC.Parent) + 1, LEN(GC.Parent) - CHARINDEX('@', GC.Parent)) " +
                        "  WHERE GC2.Section IS NULL " +
                        ") AS Section " +

                        "SELECT CutDispatchZL_GC.DDBH, CutDispatchZL_GC.Cycle, Section.OSestion AS BWBH, Section.ZWSM, Section.YWSM, CAST(ISNULL(CutDispatchZL_GC.ZLQty, 0) AS INT) AS TargetPairs, " +
                        "CAST(CASE WHEN CS.DDBH IS NOT NULL OR CA.DDBH IS NOT NULL THEN ISNULL(CutDispatchZL_GC.ZLQty, 0) ELSE ISNULL(CutDispatchSS_GC.Qty, 0) END AS INT) AS DispatchedPairs, " +
                        "CAST(CASE WHEN CS.DDBH IS NOT NULL OR CA.DDBH IS NOT NULL THEN ISNULL(CutDispatchZL_GC.ZLQty, 0) ELSE ISNULL(CutDispatchSS_GC.ScanQty, 0) END AS INT) AS ScanPairs FROM ( " +
                        "  SELECT DISTINCT ISNULL(S2.Parent, S1.Section) AS Section, S1.Section AS OSestion, S2.ZWSM + '@' + S1.ZWSM AS ZWSM, S2.YWSM + '@' + S1.YWSM AS YWSM, S1.Parent FROM #Section AS S1 " +
                        "  LEFT JOIN #Section AS S2 ON REPLACE(S2.Parent, S2.Section + '@', '') = S1.Section " +
                        "  LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = S1.Section " +
                        "  WHERE S1.Section LIKE '%0G%' AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') = 'Single' " +
                        "  UNION ALL " +
                        "  SELECT DISTINCT ISNULL(S2.Parent, S1.Section) AS Section, S1.Section AS OSestion, S1.ZWSM, S1.YWSM, S1.Parent FROM #Section AS S1 " +
                        "  LEFT JOIN #Section AS S2 ON REPLACE(S2.Parent, S2.Section + '@', '') = S1.Section " +
                        "  LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = S1.Section " +
                        "  WHERE S1.Section LIKE '%0G%' AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') <> 'Single' " +
                        ") AS Section " +
                        "LEFT JOIN ( " +
                        "  SELECT CutDispatchZL_GC.ZLBH, SMDDS.DDBH, CutDispatchZL_GC.GCBWBH, CutDispatchZL_GC.BWBH, SUM(SMDDS.Qty) AS ZLQty, " +
                        "  CASE WHEN SMDDS.DDBH <> CutDispatchZL_GC.ZLBH THEN CAST(RIGHT(SMDDS.DDBH, 3) AS INT) ELSE 1 END AS Cycle FROM ( " +
                        "    SELECT ZLBH, GCBWBH, BWBH, SUM(Qty) AS ZLQty FROM CutDispatchZL_GC " +
                        "    LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = CutDispatchZL_GC.GCBWBH " +
                        "    WHERE ZLBH = '{0}' AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') = 'Single' " +
                        "    GROUP BY ZLBH, GCBWBH, BWBH " +
                        "    UNION ALL " +
                        "    SELECT ZLBH, GCBWBH, '' AS BWBH, SUM(Qty) AS ZLQty FROM CutDispatchZL_GC " +
                        "    LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = CutDispatchZL_GC.GCBWBH " +
                        "    WHERE ZLBH = '{0}' AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') <> 'Single' " +
                        "    GROUP BY ZLBH, GCBWBH " +
                        "  ) AS CutDispatchZL_GC " +
                        "  LEFT JOIN SMDD ON SMDD.YSBH = CutDispatchZL_GC.ZLBH AND SMDD.GXLB = 'C' " +
                        "  LEFT JOIN SMDDS ON SMDDS.DDBH = SMDD.DDBH " +
                        "  GROUP BY CutDispatchZL_GC.ZLBH, SMDDS.DDBH, CutDispatchZL_GC.GCBWBH, CutDispatchZL_GC.BWBH " +
                        ") AS CutDispatchZL_GC ON CutDispatchZL_GC.BWBH + '@' + CutDispatchZL_GC.GCBWBH = Section.Section OR CutDispatchZL_GC.GCBWBH = Section.Section " +
                        "LEFT JOIN ( " +
                        "  SELECT CutDispatchSS_GC.ZLBH, CutDispatchSS_GC.DDBH, CutDispatchSS_GC.GCBWBH, CutDispatchSS_GC.BWBH, SUM(SMDDS.Qty) AS Qty, " +
                        "  SUM(CASE WHEN CutDispatchSS_GC.ScanQty = CutDispatchSS_GC.Qty THEN SMDDS.Qty ELSE 0 END) AS ScanQty FROM CutDispatchSS_GC " +
                        "  LEFT JOIN SMDDS ON SMDDS.DDBH = CutDispatchSS_GC.DDBH AND SMDDS.XXCC = CutDispatchSS_GC.SIZE " +
                        "  LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = CutDispatchSS_GC.GCBWBH " +
                        "  WHERE CutDispatchSS_GC.ZLBH = '{0}' AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') = 'Single' " +
                        "  GROUP BY CutDispatchSS_GC.ZLBH, CutDispatchSS_GC.DDBH, CutDispatchSS_GC.GCBWBH, CutDispatchSS_GC.BWBH " +
                        "  UNION ALL " +
                        "  SELECT CutDispatchSS_GC.ZLBH, CutDispatchSS_GC.DDBH, CutDispatchSS_GC.GCBWBH, '' AS BWBH, SUM(SMDDS.Qty) AS Qty, " +
                        "  SUM(CASE WHEN CutDispatchSS_GC.ScanQty = CutDispatchSS_GC.Qty THEN SMDDS.Qty ELSE 0 END) AS ScanQty FROM CutDispatchSS_GC " +
                        "  LEFT JOIN SMDDS ON SMDDS.DDBH = CutDispatchSS_GC.DDBH AND SMDDS.XXCC = CutDispatchSS_GC.SIZE " +
                        "  LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = CutDispatchSS_GC.GCBWBH " +
                        "  WHERE CutDispatchSS_GC.ZLBH = '{0}' AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') <> 'Single' " +
                        "  GROUP BY CutDispatchSS_GC.ZLBH, CutDispatchSS_GC.DDBH, CutDispatchSS_GC.GCBWBH " +
                        ") AS CutDispatchSS_GC ON CutDispatchSS_GC.DDBH = CutDispatchZL_GC.DDBH AND (CutDispatchSS_GC.BWBH + '@' + CutDispatchSS_GC.GCBWBH = Section.Section OR CutDispatchSS_GC.GCBWBH = Section.Section) " +
                        "LEFT JOIN CycleDispatch AS CS ON CS.DDBH = CutDispatchZL_GC.DDBH AND CS.GXLB = 'S' " +
                        "LEFT JOIN CycleDispatch AS CA ON CA.DDBH = CutDispatchZL_GC.DDBH AND CA.GXLB = 'A' " +
                        "WHERE CutDispatchZL_GC.Cycle IS NOT NULL " +
                        "ORDER BY CutDispatchZL_GC.Cycle, CutDispatchZL_GC.BWBH "
                        , request.Order
                    ), ERP
                );
            }
            else
            {
                da = new SqlDataAdapter(
                    System.String.Format(
                        "IF OBJECT_ID('tempdb..#GC') IS NOT NULL " +
                        "BEGIN DROP TABLE #GC END; " +

                        "SELECT DISTINCT CutDispatchZL_GC.BWBH AS Section, ISNULL(BWZL.ZWSM, GC1.ZWSM) AS ZWSM, ISNULL(BWZL.YWSM, GC1.YWSM) AS YWSM, " +
                        "CASE WHEN GC2.Memo = 'Single' THEN CutDispatchZL_GC.BWBH + '@' + CutDispatchZL_GC.GCBWBH ELSE CutDispatchZL_GC.GCBWBH END AS Parent INTO #GC FROM CutDispatchZL_GC " +
                        "LEFT JOIN BWZL ON BWZL.BWDH = CutDispatchZL_GC.BWBH " +
                        "LEFT JOIN KT_SOPCutS_GCBWD AS GC1 ON GC1.GCBWDH = CutDispatchZL_GC.BWBH " +
                        "LEFT JOIN KT_SOPCutS_GCBWD AS GC2 ON GC2.GCBWDH = CutDispatchZL_GC.GCBWBH " +
                        "WHERE CutDispatchZL_GC.ZLBH = '{0}' " +

                        "IF OBJECT_ID('tempdb..#Section') IS NOT NULL " +
                        "BEGIN DROP TABLE #Section END; " +

                        "SELECT Section, ZWSM, YWSM, Parent INTO #Section FROM ( " +
                        "  SELECT Section, ZWSM, YWSM, Parent FROM #GC " +
                        "  UNION " +
                        "  SELECT DISTINCT SUBSTRING(GC.Parent, CHARINDEX('@', GC.Parent) + 1, LEN(GC.Parent) - CHARINDEX('@', GC.Parent)) AS Section, " +
                        "  KT_SOPCutS_GCBWD.ZWSM, KT_SOPCutS_GCBWD.YWSM, 'Root' AS Parent FROM #GC AS GC " +
                        "  LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = SUBSTRING(GC.Parent, CHARINDEX('@', GC.Parent) + 1, LEN(GC.Parent) - CHARINDEX('@', GC.Parent)) " +
                        "  LEFT JOIN #GC AS GC2 ON GC2.Section = SUBSTRING(GC.Parent, CHARINDEX('@', GC.Parent) + 1, LEN(GC.Parent) - CHARINDEX('@', GC.Parent)) " +
                        "  WHERE GC2.Section IS NULL " +
                        ") AS Section " +

                        "SELECT DISTINCT CutDispatchZL_GC.DDBH, CutDispatchZL_GC.Cycle, Section.OSestion AS BWBH, Section.ZWSM, Section.YWSM, CAST(ISNULL(CutDispatchZL_GC.ZLQty, 0) AS INT) AS TargetPairs, " +
                        "CAST(ISNULL(CutDispatchSS_GC.Qty, 0) AS INT) AS DispatchedPairs, CAST(ISNULL(CutDispatchSS_GC.ScanQty, 0) AS INT) AS ScanPairs FROM ( " +
                        "  SELECT DISTINCT ISNULL(S2.Parent, S1.Section) AS Section, S1.Section AS OSestion, S2.ZWSM + '@' + S1.ZWSM AS ZWSM, S2.YWSM + '@' + S1.YWSM AS YWSM, S1.Parent FROM #Section AS S1 " +
                        "  LEFT JOIN #Section AS S2 ON REPLACE(S2.Parent, S2.Section + '@', '') = S1.Section " +
                        "  LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = S1.Section " +
                        "  WHERE S1.Section LIKE '%0G%' AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') = 'Single' " +
                        "  UNION ALL " +
                        "  SELECT DISTINCT ISNULL(S2.Parent, S1.Section) AS Section, S1.Section AS OSestion, S1.ZWSM, S1.YWSM, S1.Parent FROM #Section AS S1 " +
                        "  LEFT JOIN #Section AS S2 ON REPLACE(S2.Parent, S2.Section + '@', '') = S1.Section " +
                        "  LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = S1.Section " +
                        "  WHERE S1.Section LIKE '%0G%' AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') <> 'Single' " +
                        ") AS Section " +
                        "LEFT JOIN( " +
                        "  SELECT CutDispatchZL_GC.ZLBH, SMDDS.DDBH, CutDispatchZL_GC.GCBWBH, CutDispatchZL_GC.BWBH, SUM(SMDDS.Qty) AS ZLQty, " +
                        "  CASE WHEN SMDDS.DDBH <> CutDispatchZL_GC.ZLBH THEN CAST(RIGHT(SMDDS.DDBH, 3) AS INT) ELSE 1 END AS Cycle FROM ( " +
                        "    SELECT ZLBH, GCBWBH, BWBH, SUM(Qty) AS ZLQty FROM CutDispatchZL_GC " +
                        "    LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = CutDispatchZL_GC.GCBWBH " +
                        "    WHERE ZLBH = '{0}' AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') = 'Single' " +
                        "    GROUP BY ZLBH, GCBWBH, BWBH " +
                        "    UNION ALL " +
                        "    SELECT ZLBH, GCBWBH, '' AS BWBH, SUM(Qty) AS ZLQty FROM CutDispatchZL_GC " +
                        "    LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = CutDispatchZL_GC.GCBWBH " +
                        "    WHERE ZLBH = '{0}' AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') <> 'Single' " +
                        "    GROUP BY ZLBH, GCBWBH " +
                        "  ) AS CutDispatchZL_GC " +
                        "  LEFT JOIN SMDD ON SMDD.YSBH = CutDispatchZL_GC.ZLBH AND SMDD.GXLB = 'C' " +
                        "  LEFT JOIN SMDDS ON SMDDS.DDBH = SMDD.DDBH " +
                        "  GROUP BY CutDispatchZL_GC.ZLBH, SMDDS.DDBH, CutDispatchZL_GC.GCBWBH, CutDispatchZL_GC.BWBH " +
                        ") AS CutDispatchZL_GC ON CutDispatchZL_GC.BWBH + '@' + CutDispatchZL_GC.GCBWBH = Section.Section OR CutDispatchZL_GC.GCBWBH = Section.Section " +
                        "LEFT JOIN( " +
                        "  SELECT ZLBH, DDBH, GCBWBH, BWBH, SUM(Qty) AS Qty, SUM(ScanQty) AS ScanQty FROM CutDispatchSS_GC " +
                        "  LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = CutDispatchSS_GC.GCBWBH " +
                        "  WHERE ZLBH = '{0}' AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') = 'Single' " +
                        "  GROUP BY ZLBH, DDBH, GCBWBH, BWBH " +
                        "  UNION ALL " +
                        "  SELECT ZLBH, DDBH, GCBWBH, '' AS BWBH, SUM(Qty) AS Qty, SUM(ScanQty) AS ScanQty FROM( " +
                        "    SELECT DISTINCT ZLBH, DDBH, GCBWBH, Qty, ScanQty FROM CutDispatchSS_GC " +
                        "    LEFT JOIN KT_SOPCutS_GCBWD ON KT_SOPCutS_GCBWD.GCBWDH = CutDispatchSS_GC.GCBWBH " +
                        "    WHERE ZLBH = '{0}' AND ISNULL(KT_SOPCutS_GCBWD.Memo, '') <> 'Single' " +
                        "  ) AS CutDispatchSS_GC " +
                        "  GROUP BY ZLBH, DDBH, GCBWBH " +
                        ") AS CutDispatchSS_GC ON CutDispatchSS_GC.DDBH = CutDispatchZL_GC.DDBH AND (CutDispatchSS_GC.BWBH + '@' + CutDispatchSS_GC.GCBWBH = Section.Section OR CutDispatchSS_GC.GCBWBH = Section.Section) " +
                        "WHERE CutDispatchZL_GC.Cycle IS NOT NULL " +
                        "ORDER BY CutDispatchZL_GC.Cycle, CutDispatchZL_GC.BWBH "
                        , request.Order
                    ), ERP
                );
            }

            DataTable dt = new DataTable();
            da.Fill(dt);
            List<dynamic> ResultList = new List<dynamic>();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    OrderCycles OrderCycle = new OrderCycles();
                    OrderCycle.Cycle = dt.Rows[Row]["Cycle"].ToString();
                    OrderCycle.Part = new List<CycleParts>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["Cycle"].ToString() == OrderCycle.Cycle)
                    {
                        CycleParts Part = new CycleParts();
                        Part.ID = dt.Rows[Row]["BWBH"].ToString();
                        Part.ZH = dt.Rows[Row]["ZWSM"].ToString();
                        Part.EN = dt.Rows[Row]["YWSM"].ToString();
                        Part.VI = dt.Rows[Row]["YWSM"].ToString();
                        Part.TargetPairs = (int)dt.Rows[Row]["TargetPairs"];
                        Part.DispatchedPairs = (int)dt.Rows[Row]["DispatchedPairs"];
                        Part.ScanPairs = (int)dt.Rows[Row]["ScanPairs"];

                        OrderCycle.Part.Add(Part);
                        Row++;
                    }
                    ResultList.Add(OrderCycle);
                }

                return JsonConvert.SerializeObject(ResultList);
            }
            else
            {
                return "{}";
            }
        }

        [HttpPost]
        [Route("getMaterialRequisitionCard")]
        public string getMaterialRequisitionCard(MaterialRequisitionRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT LeanList.Lean, MRCard.ListNo, MRCard.Section, TimeSlot.Time AS DemandTime, MRCard.Source, MRCard.Remark, " +
                    "MRCard.ConfirmDate, MRCard.DeliveryCFMDate, MRCard.ReceiverConfirmDate, MRCard.RY_Begin, MRCard.RY_End, DDZL.Article, DDZL.BUYNO, " +
                    "MRCard.Date, MRCard.MaterialID, MRCard.Usage, MRCard.Confirmed,MRCard.IssuanceUsage, MRCard.MatRemark, MRCard.DWBH FROM ( " +
                    "  SELECT DISTINCT 'LINE ' + RIGHT('00' + CAST(CAST(RIGHT(lean_no, 2) AS INT) AS VARCHAR), 2) AS Lean FROM schedule_crawler " +
                    "  WHERE building_no = '{1}' AND schedule_date >= LEFT('{0}', 7) + '/01' " +
                    ") AS LeanList " +
                    "LEFT JOIN ( " +
                    "  SELECT '07:30 - 09:30' AS Time UNION ALL " +
                    "  SELECT '09:30 - 11:30' AS Time UNION ALL " +
                    "  SELECT '12:30 - 14:30' AS Time UNION ALL " +
                    "  SELECT '14:30 - 16:30' AS Time UNION ALL " +
                    "  SELECT '16:30 - 18:00' AS Time " +
                    ") AS TimeSlot ON 1 = 1 " +
                    "LEFT JOIN ( " +
                    "  SELECT MRCard.Lean, MRCard.ListNo, SectionData.Seq, MRCard.Section, MRCard.DemandTime, MRCard.Source, MRCard.Remark, CONVERT(VARCHAR, MRCard.ConfirmDate, 111) AS ConfirmDate, " +
                    "  CONVERT(VARCHAR, MRCard.DeliveryCFMDate, 111) AS DeliveryCFMDate, CONVERT(VARCHAR, MRCard.ReceiverConfirmDate, 111) AS ReceiverConfirmDate, MRCardS.RY_Begin, MRCardS.RY_End, " +
                    "  CAST(MONTH(MAX(SC.schedule_date)) AS VARCHAR) + '/' + CAST(DAY(MAX(SC.schedule_date)) AS VARCHAR) AS Date, MRCardS.MaterialID, " +
                    "  MRCardS.Usage, CASE WHEN MRCard.DeliveryCFMDate IS NULL THEN 0 ELSE 1 END AS Confirmed, MRCardS.IssuanceUsage, MRCardS.Remark AS MatRemark, CLZL.DWBH FROM MRCard " +
                    "  LEFT JOIN MRCardS ON MRCardS.ListNo = MRCard.ListNo " +
                    "  LEFT JOIN schedule_crawler AS SC ON CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END = MRCardS.RY_Begin AND SC.building_no = MRCard.Building AND SC.lean_no = MRCard.Lean " +
                    "  LEFT JOIN ( " +
                    "    SELECT 1 AS Seq, 'C' AS Section UNION ALL " +
                    "    SELECT 2 AS Seq, 'S' AS Section UNION ALL " +
                    "    SELECT 3 AS Seq, 'A' AS Section " +
                    "  ) AS SectionData ON SectionData.Section = MRCard.Section " +
                    "  LEFT JOIN CLZL ON CLZL.CLDH = MRCardS.MaterialID " +
                    "  WHERE MRCard.Building = '{1}' AND MRCard.DemandDate = '{0}' " +
                    "  GROUP BY MRCard.Lean, MRCard.ListNo, SectionData.Seq, MRCard.Section, MRCard.DemandTime, MRCard.Source, MRCard.Remark, CONVERT(VARCHAR, MRCard.ConfirmDate, 111), " +
                    "  CONVERT(VARCHAR, MRCard.DeliveryCFMDate, 111), CONVERT(VARCHAR, MRCard.ReceiverConfirmDate, 111), MRCardS.RY_Begin, MRCardS.RY_End, MRCardS.MaterialID, " +
                    "  MRCardS.Usage, CASE WHEN MRCard.DeliveryCFMDate IS NULL THEN 0 ELSE 1 END, MRCardS.IssuanceUsage, MRCardS.Remark, CLZL.DWBH " +
                    ") AS MRCard ON MRCard.DemandTime = TimeSlot.Time AND MRCard.Lean = LeanList.Lean " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = MRCard.RY_Begin " +
                    "ORDER BY LeanList.Lean, TimeSlot.Time, MRCard.Seq, MRCard.ListNo, MRCard.RY_Begin, MRCard.RY_End, MRCard.MaterialID "
                    , request.Date, request.Building
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);
            List<dynamic> ResultList = new List<dynamic>();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    LeanList leanList = new LeanList();
                    leanList.Lean = dt.Rows[Row]["Lean"].ToString();
                    leanList.TimeSlots = new List<TimeSlot>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["Lean"].ToString() == leanList.Lean)
                    {
                        TimeSlot timeSlot = new TimeSlot();
                        timeSlot.Time = dt.Rows[Row]["DemandTime"].ToString();
                        timeSlot.Section = new List<Models.Section>();

                        if (dt.Rows[Row]["ListNo"] != DBNull.Value)
                        {
                            while (Row < dt.Rows.Count && dt.Rows[Row]["DemandTime"].ToString() == timeSlot.Time)
                            {
                                Section Sections = new Section();
                                Sections.ID = dt.Rows[Row]["Section"].ToString();
                                Sections.MRCard = new List<MRCard>();

                                while (Row < dt.Rows.Count && dt.Rows[Row]["DemandTime"].ToString() == timeSlot.Time && dt.Rows[Row]["Section"].ToString() == Sections.ID)
                                {
                                    MRCard MRCards = new MRCard();
                                    MRCards.ListNo = dt.Rows[Row]["ListNo"].ToString();
                                    MRCards.Source = dt.Rows[Row]["Source"].ToString();
                                    MRCards.Remark = dt.Rows[Row]["Remark"].ToString();
                                    MRCards.ConfirmDate = dt.Rows[Row]["ConfirmDate"].ToString();
                                    MRCards.DeliveryCFMDate = dt.Rows[Row]["DeliveryCFMDate"].ToString();
                                    MRCards.ReceiverConfirmDate = dt.Rows[Row]["ReceiverConfirmDate"].ToString();
                                    MRCards.MRCardInfo = new List<MRCardInfo>();

                                    while (Row < dt.Rows.Count && dt.Rows[Row]["DemandTime"].ToString() == timeSlot.Time && dt.Rows[Row]["ListNo"].ToString() == MRCards.ListNo)
                                    {
                                        MRCardInfo MRCardInfos = new MRCardInfo();
                                        MRCardInfos.RY_Begin = dt.Rows[Row]["RY_Begin"].ToString();
                                        MRCardInfos.RY_End = dt.Rows[Row]["RY_End"].ToString();
                                        MRCardInfos.SKU = dt.Rows[Row]["Article"].ToString();
                                        MRCardInfos.BUY = dt.Rows[Row]["BUYNO"].ToString();
                                        MRCardInfos.Date = dt.Rows[Row]["Date"].ToString();
                                        MRCardInfos.Materials = new List<Material>();
                                         
                                        while (Row < dt.Rows.Count && dt.Rows[Row]["DemandTime"].ToString() == timeSlot.Time && dt.Rows[Row]["ListNo"].ToString() == MRCards.ListNo && dt.Rows[Row]["RY_Begin"].ToString() == MRCardInfos.RY_Begin && dt.Rows[Row]["RY_End"].ToString() == MRCardInfos.RY_End)
                                        {
                                            Material materials = new Material();
                                            materials.ID = dt.Rows[Row]["MaterialID"].ToString();
                                            if (dt.Rows[Row]["Usage"] != DBNull.Value)
                                            {
                                                materials.Usage = (double)dt.Rows[Row]["Usage"];
                                            }
                                            else
                                            {
                                                materials.Usage = 0;
                                            }
                                            if ((int)dt.Rows[Row]["Confirmed"] == 1)
                                            {
                                                materials.Confirmed = true;
                                            }
                                            else
                                            {
                                                materials.Confirmed = false;
                                            }
                                            if (dt.Rows[Row]["IssuanceUsage"] != DBNull.Value)
                                            {
                                                materials.IssuanceUsage = (double)dt.Rows[Row]["IssuanceUsage"];
                                            }
                                            else
                                            {
                                                materials.IssuanceUsage = 0;
                                            }
                                            materials.Unit = dt.Rows[Row]["DWBH"].ToString();
                                            materials.Remark = dt.Rows[Row]["MatRemark"].ToString();

                                            MRCardInfos.Materials.Add(materials);
                                            Row++;
                                        }

                                        MRCards.MRCardInfo.Add(MRCardInfos);
                                    }

                                    Sections.MRCard.Add(MRCards);
                                }

                                timeSlot.Section.Add(Sections);
                            }
                        }
                        else
                        {
                            Row++;
                        }

                        leanList.TimeSlots.Add(timeSlot);
                    }

                    ResultList.Add(leanList);
                }
                return JsonConvert.SerializeObject(ResultList);
            }
            else
            {
                return "{}";
            }
        }

        [HttpPost]
        [Route("getLeanScheduleRY")]
        public string getLeanScheduleRY(MaterialRequisitionRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT Seq, DDBH, XieXing, SheHao, ARTICLE, Date, BuyNo FROM ( " +
                    "  SELECT ROW_NUMBER() OVER(ORDER BY SC.schedule_date, SC.ry_index) AS Seq, DDZL.DDBH, DDZL.XieXing, DDZL.SheHao, " +
                    "  DDZL.ARTICLE, SUBSTRING(CONVERT(VARCHAR, CONVERT(SmallDateTime, SC.schedule_date), 111), 6, 5) AS Date, DDZL.BUYNO FROM schedule_crawler AS SC " +
                    "  LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END " +
                    "  LEFT JOIN YWCP ON YWCP.DDBH = DDZL.DDBH AND YWCP.InDate IS NOT NULL " +
                    "  WHERE SC.building_no = '{1}' AND 'LINE ' + RIGHT('00' + CAST(CAST(RIGHT(SC.lean_no, 2) AS INT) AS VARCHAR), 2) = '{2}' AND SC.schedule_date >= DATEADD(DD, -120, CONVERT(SmallDateTime, '{0}')) " +
                    "  GROUP BY SC.schedule_date, SC.ry_index, DDZL.DDBH, DDZL.XieXing, DDZL.SheHao, DDZL.ARTICLE, DDZL.BUYNO, DDZL.Pairs " +
                    "  HAVING DDZL.Pairs > ISNULL(SUM(YWCP.Qty), 0) " +
                    "  UNION " +
                    "  SELECT 0 AS Seq, DDZL.DDBH, DDZL.XieXing, DDZL.SheHao, DDZL.ARTICLE, 'Temp' AS Date, DDZL.BUYNO FROM MRCard_Unlock " +
                    "  LEFT JOIN DDZL ON DDZL.DDBH = MRCard_Unlock.RY " +
                    "  WHERE MRCard_Unlock.Building = '{1}' AND MRCard_Unlock.Lean = '{2}' " +
                    "  GROUP BY DDZL.DDBH, DDZL.XieXing, DDZL.SheHao, DDZL.ARTICLE, DDZL.BUYNO " +
                    ") AS SC " +
                    "ORDER BY Seq "
                    , request.Date, request.Building, request.Lean
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);
            List<dynamic> ResultList = new List<dynamic>();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;

                while (Row < dt.Rows.Count)
                {
                    SKUGroup skuGroup = new SKUGroup();
                    skuGroup.XieXing = dt.Rows[Row]["XieXing"].ToString();
                    skuGroup.SheHao = dt.Rows[Row]["SheHao"].ToString();
                    skuGroup.SKU = dt.Rows[Row]["ARTICLE"].ToString();
                    skuGroup.BuyNo = dt.Rows[Row]["BUYNO"].ToString();
                    skuGroup.RY = dt.Rows[Row]["DDBH"].ToString();
                    skuGroup.Date = dt.Rows[Row]["Date"].ToString();
                    ResultList.Add(skuGroup);
                    Row++;
                }

                return JsonConvert.SerializeObject(ResultList);
            }
            else
            {
                return "{}";
            }
        }

        [HttpPost]
        [Route("getRYMaterials")]
        public string getRYMaterials(MaterialRequisitionRequest request)
        {
            string MatTypeCode = string.Empty;
            string MatCategoryCode = string.Empty;
            string MatECategoryCode = string.Empty;
            string MatCode = string.Empty;
            string MatECode = string.Empty;
            string ExtraSQL = string.Empty;

            if (request.Section == "C")
            {
                MatTypeCode = "'A', 'B', 'C', 'D', 'E', 'F', 'G', 'J', 'K', 'O', 'P', 'V'";
                MatCategoryCode = "''";
                MatCode = "'H160000952'";
                MatECategoryCode = "'D01', 'D11'";
                MatECode = "'A010000637', 'C120006045', 'E100000436'";
                ExtraSQL = ""; /*System.String.Format(
                    "  WHERE CLBH NOT IN ( " +
                    "    SELECT DISTINCT ZLZLS2.CLBH FROM ZLZLS2 " +
                    "    LEFT JOIN BWZL ON BWZL.BWDH = ZLZLS2.BWBH " +
                    "    WHERE ZLZLS2.ZLBH = '{0}' AND(ZLZLS2.MJBH = 'ZZZZZZZZZZ' OR ZLZLS2.CSBH = 'JNG') AND BWZL.YWSM LIKE '%INSOLE%' " +
                    "  ) "
                    , request.RY_Begin
                );*/
            }
            else if (request.Section == "S") 
            {
                MatTypeCode = "'E', 'F', 'G', 'I', 'M', 'N', 'O'";
                MatCategoryCode = "'A01', 'A05', 'A31', 'A58', 'C03', 'C12', 'D01', 'D02', 'D11', 'J05', 'K02', 'L05', 'L09'";
                MatCode = "'A010000637'";
                MatECategoryCode = "'G12'";
                MatECode = "''";
                ExtraSQL = "";
            }
            else if (request.Section == "SF")
            {
                MatTypeCode = "''";
                MatCategoryCode = "'G01', 'G03', 'G12', 'I05', 'J03', 'J04', 'U1C'";
                MatCode = "''";
                MatECategoryCode = "''";
                MatECode = "''";
                ExtraSQL = "";
            }
            else if (request.Section == "A")
            {
                MatTypeCode = "''";
                MatCategoryCode = "'A38', 'E06', 'H04', 'H07', 'H10', 'H12', 'H13', 'H14', 'H16', 'L09', 'M02', 'U1D'";
                MatCode = "''";
                MatECategoryCode = "''";
                MatECode = "''";
                ExtraSQL = "";
                /*System.String.Format(
                    "  UNION ALL " +
                    "  SELECT ZLZLS2.CLBH, CAST(ZLZLS2.Pairs - ISNULL(MRCard.Usage, 0) AS NUMERIC(18, 4)) AS CLSL, CAST(ISNULL(MRCard.Usage, 0) AS NUMERIC(18, 4)) AS ReqUsage, ZLZLS2.DWBH, ZLZLS2.Remark FROM ( " +
                    "    SELECT DDZL.CLBH, DDZL.DWBH, DDZL.Pairs, DDZL.Remark FROM ( " +
                    "      SELECT 'INSOLE' AS CLBH, DDZL.Pairs, 'PRS' AS DWBH, N'[Đế trung]' AS Remark FROM DDZL " +
                    "      WHERE DDBH = '{0}' " +
                    "    ) AS DDZL " +
                    "    LEFT JOIN ( " +
                    "      SELECT COUNT(*) AS Counter FROM ZLZLS2 " +
                    "      LEFT JOIN BWZL ON BWZL.BWDH = ZLZLS2.BWBH " +
                    "      LEFT JOIN CLZL ON CLZL.CLDH = ZLZLS2.CLBH " +
                    "      WHERE ZLZLS2.ZLBH = '{0}' AND ZLZLS2.MJBH = 'ZZZZZZZZZZ' AND CLZL.DWBH = 'PRS' " +
                    "      AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(BWZL.YWSM, '0', ''), '1', ''), '2', ''), '3', ''), '4', ''), '5', ''), '6', ''), '7', ''), '8', ''), '9', ''), '#', ''), '-', ''), ' ', '') LIKE '%INSOLE' " +
                    "    ) AS ZLZLS2 ON 1 = 1 " +
                    "    WHERE ZLZLS2.Counter = 0 " +
                    "  ) AS ZLZLS2 " +
                    "  LEFT JOIN ( " +
                    "    SELECT MRCardS.MaterialID, SUM(CASE WHEN MRCard.DeliveryCFMDate IS NOT NULL THEN IssuanceUsage ELSE Usage END) AS Usage FROM MRCardS " +
                    "    LEFT JOIN MRCard ON MRCard.ListNo = MRCardS.ListNo " +
                    "    WHERE MRCardS.RY_Begin = '{0}' " +
                    "    GROUP BY MRCardS.MaterialID " +
                    "  ) AS MRCard ON MRCard.MaterialID = ZLZLS2.CLBH "
                    , request.RY_Begin
                );*/
            }
            else
            {
                MatTypeCode = "''";
                MatCategoryCode = "''";
                MatCode = "''";
                MatECategoryCode = "''";
                MatECode = "''";
                ExtraSQL = "";
            }

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT CLBH, CLSL, ReqUsage, DWBH, Remark FROM ( " +
                    "  SELECT CLBH, CAST(CASE WHEN CLSL - ReqUsage < 0 THEN 0 ELSE CLSL - ReqUsage END AS NUMERIC(18, 4)) AS CLSL, CAST(ReqUsage AS NUMERIC(18, 4)) AS ReqUsage, DWBH, " +
                    "  CASE WHEN ISNULL(Remark, '') <> '' THEN '[' + Remark + ']' ELSE '' END + CASE WHEN ISNULL(Remark, '') <> '' AND OnOrderQty > 0 THEN '\n' ELSE '' END + CASE WHEN OnOrderQty > 0 THEN '[*]' + CAST(CAST(OnOrderQty AS FLOAT) AS VARCHAR) + CFMDate ELSE '' END AS Remark FROM ( " +
                    "    SELECT ZLZLS2.CLBH, ZLZLS2.CLSL, ISNULL(MRCard.Usage, 0) AS ReqUsage, ZLZLS2.DWBH, ZLZLS2.Remark, " +
                    "    ZLZLS2.CLSL - CASE WHEN ZLZLS2.ZMLB = 'Y' THEN ISNULL(JGZL.JGQty, 0) ELSE ISNULL(RKZL.RKQty, 0) END - ISNULL(CGKCUSE.Qty, 0) AS OnOrderQty, " +
                    "    CASE WHEN ZLZLS2.ZMLB = 'Y' AND ISNULL(JGZL.CFMDate1, '') = '' THEN ISNULL(' (' + JGZL.CFMDate + ')', '') ELSE ISNULL(' (' + CGZL.CFMDate + ')', '') END AS CFMDate FROM ( " +
                    "      SELECT CLBH, SUM(CLSL) AS CLSL, DWBH, Remark, ZMLB FROM ( " +
                    "        SELECT ZLZLS2.CLBH, ZLZLS2.CLSL, CLZL.DWBH, ZLZLS2.ZMLB, " +
                    "        CASE WHEN SUBSTRING(REPLACE(REPLACE(CLZL.YWPM, '(V)', ''), ' ', ''), LEN(REPLACE(REPLACE(CLZL.YWPM, '(V)', ''), ' ', '')) - 11, 12) LIKE '%INNERBOX%' " +
                    "        AND SUBSTRING(REPLACE(REPLACE(CLZL.YWPM, '(V)', ''), ' ', ''), LEN(REPLACE(REPLACE(CLZL.YWPM, '(V)', ''), ' ', '')) - 11, 4) LIKE 'B%' " +
                    "        THEN SUBSTRING(REPLACE(REPLACE(CLZL.YWPM, '(V)', ''), ' ', ''), LEN(REPLACE(REPLACE(CLZL.YWPM, '(V)', ''), ' ', '')) - 11, 4) ELSE " +
                    "        CASE WHEN CLZL.YWPM LIKE '% PACK %' AND CHARINDEX('-B', CLZL.YWPM) > 0 AND CHARINDEX('-M', CLZL.YWPM) > CHARINDEX('-B', CLZL.YWPM) " +
                    "        THEN SUBSTRING(CLZL.YWPM, CHARINDEX('-B', CLZL.YWPM) + 1, CHARINDEX('-M', CLZL.YWPM) - CHARINDEX('-B', CLZL.YWPM) - 1) ELSE " +
                    "        CASE WHEN SUBSTRING(REPLACE(REPLACE(CLZL.YWPM, '(V)', ''), ' ', ''), LEN(REPLACE(REPLACE(CLZL.YWPM, '(V)', ''), ' ', '')) - 10, 11) LIKE '%TISSUEPAPER%' " +
                    "        AND SUBSTRING(CLZL.YWPM, 1, CHARINDEX('MM ', CLZL.YWPM) + 1) LIKE '%*%MM' " +
                    "        THEN SUBSTRING(CLZL.YWPM, 1, CHARINDEX('MM ', CLZL.YWPM) + 1) ELSE " +
                    "        CASE WHEN CLZL.YWPM LIKE '%PLASTIC TIP%' AND SUBSTRING(CLZL.YWPM, 1, CHARINDEX('MM ', CLZL.YWPM) + 1) LIKE '%\"%MM' " +
                    "        THEN SUBSTRING(CLZL.YWPM, 1, CHARINDEX('MM ', CLZL.YWPM) + 1) ELSE '' END END END END AS Remark FROM ZLZLS2 " +
                    "        LEFT JOIN CLZL ON CLZL.CLDH = ZLZLS2.CLBH " +
                    "        LEFT JOIN DDZL ON DDZL.DDBH = ZLZLS2.ZLBH " +
                    "        LEFT JOIN XXBWFL ON XXBWFL.XieXing = DDZL.XieXing AND XXBWFL.BWBH = ZLZLS2.BWBH " +
                    "        LEFT JOIN XXBWFLS ON XXBWFLS.FLBH = XXBWFL.FLBH " +
                    "        LEFT JOIN XXZLSVN ON XXZLSVN.XieXing = DDZL.XieXing AND XXZLSVN.SheHao = DDZL.SheHao AND XXZLSVN.BWBH = ZLZLS2.BWBH " +
                    "        LEFT JOIN XXBWFLS AS XXBWFLS2 on XXBWFLS2.FLBH = XXZLSVN.FLBH " +
                    "        WHERE ZLZLS2.ZLBH = '{0}' AND ZLZLS2.MJBH = 'ZZZZZZZZZZ' AND ZLZLS2.CLBH NOT LIKE 'W%' " + 
                    "        AND ( " +
                    (request.Section == "C" ? "          CASE WHEN LEFT(XXBWFL.BWBH, 1) = 'V' THEN ISNULL(XXBWFLS2.DFL, 'N') ELSE ISNULL(XXBWFLS.DFL, 'N') END IN ('B', 'C') " : "") +
                    (request.Section == "S" ? "          CASE WHEN LEFT(XXBWFL.BWBH, 1) = 'V' THEN ISNULL(XXBWFLS2.DFL, 'N') ELSE ISNULL(XXBWFLS.DFL, 'N') END IN ('S') " : "") +
                    (request.Section == "SF" ? "          CASE WHEN LEFT(XXBWFL.BWBH, 1) = 'V' THEN ISNULL(XXBWFLS2.DFL, 'N') ELSE ISNULL(XXBWFLS.DFL, 'N') END IN ('O') " : "") +
                    (request.Section == "A" ? "          CASE WHEN LEFT(XXBWFL.BWBH, 1) = 'V' THEN ISNULL(XXBWFLS2.DFL, 'N') ELSE ISNULL(XXBWFLS.DFL, 'N') END IN ('A') OR ZLZLS2.CLBH LIKE 'U1DE%' " : "") +
                    "        ) " +
                    "      ) AS ZLZLS2 " +
                    "      GROUP BY CLBH, DWBH, Remark, ZMLB " +
                    "      HAVING SUM(CLSL) > 0 " +
                    "    ) AS ZLZLS2 " +
                    "    LEFT JOIN ( " +
                    "      SELECT MRCardS.MaterialID, SUM(CASE WHEN MRCard.DeliveryCFMDate IS NOT NULL THEN IssuanceUsage ELSE Usage END) AS Usage FROM MRCardS " +
                    "      LEFT JOIN MRCard ON MRCard.ListNo = MRCardS.ListNo " +
                    "      WHERE MRCardS.RY_Begin = '{0}' AND MRCard.Section = '{1}' " +
                    "      GROUP BY MRCardS.MaterialID " +
                    "    ) AS MRCard ON MRCard.MaterialID = ZLZLS2.CLBH " +
                    "    LEFT JOIN ( " +
                    "      SELECT ZLBH, CLBH, 'ETA: ' + CAST(MONTH(MAX(CFMDate)) AS VARCHAR) + '/' + CAST(DAY(MAX(CFMDate)) AS VARCHAR) AS CFMDate FROM CGZLSS " +
                    "      WHERE ZLBH = '{0}' " +
                    "      GROUP BY ZLBH, CLBH " +
                    "    ) AS CGZL ON CGZL.CLBH = ZLZLS2.CLBH " +
                    "    LEFT JOIN ( " +
                    "      SELECT CGKCUSES.GSBH, CGKCUSES.ZLBH, CGKCUSES.CLBH, CASE WHEN SUM(CGKCUSES.Qty) < SUM(ZLZLS2.CLSL) THEN SUM(CGKCUSES.Qty) ELSE SUM(ZLZLS2.CLSL) END AS Qty FROM CGKCUSES " +
                    "      LEFT JOIN ZLZLS2 ON ZLZLS2.ZLBH = CGKCUSES.ZLBH AND ZLZLS2.CLBH = CGKCUSES.CLBH AND ZLZLS2.MJBH = 'ZZZZZZZZZZ' " +
                    "      WHERE CGKCUSES.ZLBH = '{0}' " +
                    "      GROUP BY CGKCUSES.GSBH, CGKCUSES.ZLBH, CGKCUSES.CLBH " +
                    "    ) AS CGKCUSE ON CGKCUSE.CLBH = ZLZLS2.CLBH " +
                    "    LEFT JOIN ( " +
                    "      SELECT KCRKS.CGBH AS ZLBH, KCRKS.CLBH, SUM(KCRKS.Qty) AS RKQty FROM KCRKS " +
                    "      LEFT JOIN KCRK ON KCRK.RKNO = KCRKS.RKNO " +
                    "      WHERE KCRK.SFL <> 'THU HOI' AND KCRKS.CGBH = '{0}' " +
                    "      GROUP BY KCRKS.CGBH, KCRKS.CLBH " +
                    "    ) AS RKZL ON RKZL.CLBH = ZLZLS2.CLBH " +
                    "    LEFT JOIN ( " +
                    "      SELECT JGZLSS.ZLBH, JGZLSS.CLBH, MIN(ISNULL(CONVERT(VARCHAR, JGZL.CFMDate1, 111), '')) AS CFMDate1, SUM(CASE WHEN JGZL.CFMDate1 IS NOT NULL THEN JGZLSS.Qty ELSE 0 END) AS JGQty, " +
                    "      'ETA: ' + CAST(MONTH(MAX(JGZLSS.CFMDate)) AS VARCHAR) + '/' + CAST(DAY(MAX(JGZLSS.CFMDate)) AS VARCHAR) AS CFMDate FROM JGZLSS " +
                    "      LEFT JOIN JGZL ON JGZL.JGNO = JGZLSS.JGNO " +
                    "      WHERE JGZLSS.ZLBH = '{0}' " +
                    "      GROUP BY JGZLSS.ZLBH, JGZLSS.CLBH " +
                    "    ) AS JGZL ON JGZL.CLBH = ZLZLS2.CLBH " +
                    /*"    WHERE ( " +
                    "      LEFT(ZLZLS2.CLBH, 1) IN (" + MatTypeCode + ") OR LEFT(ZLZLS2.CLBH, 3) IN (" + MatCategoryCode + ") OR ZLZLS2.CLBH IN (" + MatCode + ") " +
                    (request.Section == "A" ? "      OR (LEFT(ZLZLS2.CLBH, 3) = 'P21' AND ZLZLS2.DWBH = 'PRS') " : "") +
                    "    ) " +
                    "    AND SUBSTRING(ZLZLS2.CLBH, 1, 3) NOT IN (" + MatECategoryCode + ") AND ZLZLS2.CLBH NOT IN (" + MatECode + ") " +*/
                    "  ) AS ZLZLS2 " +
                    ExtraSQL +
                    ") AS ZLZLS2 " +
                    "ORDER BY CLBH "
                    , request.RY_Begin, request.Section
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);
            List<dynamic> ResultList = new List<dynamic>();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    RYMaterials ryMaterial = new RYMaterials();
                    ryMaterial.MaterialID = dt.Rows[Row]["CLBH"].ToString();
                    ryMaterial.Qty = Decimal.ToDouble((decimal)dt.Rows[Row]["CLSL"]);
                    ryMaterial.ReqQty = Decimal.ToDouble((decimal)dt.Rows[Row]["ReqUsage"]);
                    ryMaterial.Unit = dt.Rows[Row]["DWBH"].ToString();
                    ryMaterial.Remark = dt.Rows[Row]["Remark"].ToString();

                    ResultList.Add(ryMaterial);
                    Row++;
                }

                return JsonConvert.SerializeObject(ResultList);
            }
            else
            {
                return "{}";
            }
        }

        [HttpPost]
        [Route("generateMRCard")]
        public string generateMRCard(MRCardGenerateRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                string.Format(
                    "SELECT ListNo, CONVERT(VARCHAR, DemandDate, 111) AS Date FROM MRCard " +
                    "WHERE DeliveryCFMDate IS NOT NULL AND ReceiverConfirmDate IS NULL " +
                    "AND Building = '{1}' AND Lean = '{2}' AND Section = '{0}' " +
                    "AND CONVERT(SmallDateTime, CONVERT(VARCHAR, DemandDate, 111) + ' ' + SUBSTRING(DemandTime, 9, 5) + ':00') < GETDATE() ",
                    request.Section, request.Building, request.Lean
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count == 0)
            {
                string Time = request.DemandTime!.Substring(0, 5);
                da = new SqlDataAdapter(
                    string.Format(
                        "DECLARE @LastWorkingDay VARCHAR(10); " +
                        "SET @LastWorkingDay = ( " +
                        "  SELECT TOP 1 CONVERT(VARCHAR, CONVERT(SmallDateTime, SCYear + '/' + SCMonth + '/' + SCDay), 111) AS Date FROM SCRL " +
                        "  WHERE CONVERT(SmallDateTime, SCYear + '/' + SCMonth + '/' + SCDay) < '{0}' AND GSBH = '{2}' " +
                        "  GROUP BY CONVERT(SmallDateTime, SCYear + '/' + SCMonth + '/' + SCDay) " +
                        "  HAVING SUM(SCGS) > 0 " +
                        "  ORDER BY CONVERT(SmallDateTime, SCYear + '/' + SCMonth + '/' + SCDay) DESC " +
                        "); " +
                        "SELECT CASE WHEN '{1}' = '07:30:00' THEN DATEDIFF(SS, GETDATE(), @LastWorkingDay + ' 16:30:00')/60/60 " +
                        "ELSE CASE WHEN '{1}' = '09:30:00' THEN DATEDIFF(SS, GETDATE(), '{0} 10:00:00')/60/60 " +
                        "ELSE CASE WHEN '{1}' = '12:30:00' THEN DATEDIFF(SS, GETDATE(), '{0} 11:30:00')/60/60 " +
                        "ELSE DATEDIFF(SS, GETDATE(), '{0} {1}')/60/60 END END END AS Hours ",
                        request.DemandDate, Time + ":00", request.Factory
                    ), ERP
                );
                dt = new DataTable();
                da.Fill(dt);
                if ((int)dt.Rows[0]["Hours"] >= 2)
                {
                    string InsertSQL = string.Empty;
                    string[] RY = request.RequestString!.Split(';');
                    for (int i = 0; i < RY.Length; i++)
                    {
                        string[] RY_Data = RY[i].ToString().Split('@');
                        string[] RY_All = RY_Data[0].Split(" ~ ");
                        string RY_Begin = RY_All[0];
                        string RY_End = RY_All[0];
                        if (RY_All.Length > 1)
                        {
                            RY_End = RY_All[1];
                        }
                        string[] Materials = RY_Data[1].ToString().Split(':');
                        for (int j = 0; j < Materials.Length; j++)
                        {
                            string MatID = Materials[j].ToString().Split('-')[0];
                            string Usage = Materials[j].ToString().Split('-')[1];
                            if (InsertSQL == "")
                            {
                                InsertSQL += string.Format(
                                    "      SELECT @ListNo AS ListNo, '{0}' AS RY_Begin, '{1}' AS RY_End, '{2}' AS MaterialID, {3} AS Usage, NULL AS IssuanceUsage ",
                                    RY_Begin, RY_End, MatID, Usage
                                );
                            }
                            else
                            {
                                InsertSQL += string.Format(
                                    "      UNION ALL " +
                                    "      SELECT @ListNo AS ListNo, '{0}' AS RY_Begin, '{1}' AS RY_End, '{2}' AS MaterialID, {3} AS Usage, NULL AS IssuanceUsage ",
                                    RY_Begin, RY_End, MatID, Usage
                                );
                            }
                        }
                    }

                    if (InsertSQL != "")
                    {
                        SqlCommand SQL = new SqlCommand(
                            string.Format(
                                "DECLARE @Seq AS Int = ( " +
                                "  SELECT ISNULL(MAX(CAST(SUBSTRING(ListNo, 7, 5) AS INT)), 0) AS ListNo FROM MRCard " +
                                "  WHERE ListNo LIKE SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + '%' " +
                                "); " +

                                "DECLARE @ListNo AS VARCHAR(11) = ( " +
                                "  SELECT SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + RIGHT('0000' + CAST(@Seq + 1 AS VARCHAR), 5) AS ListNo " +
                                "); " +

                                "INSERT INTO MRCardS (ListNo, RY_Begin, RY_End, MaterialID, Usage, Source, UserID, UserDate, YN) " +
                                "SELECT ListNo, RY_Begin, RY_End, MaterialID, CASE WHEN Usage <= MaxUsage THEN Usage ELSE MaxUsage END AS Usage, 'WH' AS Source, '{7}' UserID, GetDate() AS UserDate, '1' AS YN FROM ( " +
                                "  SELECT NewCard.ListNo, NewCard.RY_Begin, NewCard.RY_End, NewCard.MaterialID, NewCard.Usage, NewCard.IssuanceUsage, " +
                                "  NewCard.ZLUsage - ISNULL(SUM(CASE WHEN MRCard.Section = '{0}' THEN CASE WHEN MRCard.DeliveryCFMDate IS NOT NULL THEN MRCardS.IssuanceUsage ELSE MRCardS.Usage END END), 0) AS MaxUsage FROM  ( " +
                                "    SELECT NewCard.ListNo, NewCard.RY_Begin, NewCard.RY_End, NewCard.MaterialID, NewCard.Usage, NewCard.IssuanceUsage, SUM(ZLZLS2.CLSL) AS ZLUsage FROM ( " +
                                InsertSQL +
                                "    ) AS NewCard " +
                                "    LEFT JOIN ZLZLS2 ON ZLZLS2.ZLBH = NewCard.RY_Begin AND ZLZLS2.CLBH = NewCard.MaterialID AND ZLZLS2.MJBH = 'ZZZZZZZZZZ' " +
                                "    LEFT JOIN DDZL ON DDZL.DDBH = ZLZLS2.ZLBH " +
                                "    LEFT JOIN XXBWFL ON XXBWFL.XieXing = DDZL.XieXing AND XXBWFL.BWBH = ZLZLS2.BWBH " +
                                "    LEFT JOIN XXBWFLS ON XXBWFLS.FLBH = XXBWFL.FLBH " +
                                "    LEFT JOIN XXZLSVN ON XXZLSVN.XieXing = DDZL.XieXing AND XXZLSVN.SheHao = DDZL.SheHao AND XXZLSVN.BWBH = ZLZLS2.BWBH " +
                                "    LEFT JOIN XXBWFLS AS XXBWFLS2 on XXBWFLS2.FLBH = XXZLSVN.FLBH " +
                                "    WHERE 1 = 1 " +
                                "    AND ( " +
                                (request.Section == "C" ? "      CASE WHEN LEFT(XXBWFL.BWBH, 1) = 'V' THEN ISNULL(XXBWFLS2.DFL, 'N') ELSE ISNULL(XXBWFLS.DFL, 'N') END IN ('B', 'C') " : "") +
                                (request.Section == "S" ? "      CASE WHEN LEFT(XXBWFL.BWBH, 1) = 'V' THEN ISNULL(XXBWFLS2.DFL, 'N') ELSE ISNULL(XXBWFLS.DFL, 'N') END IN ('S') " : "") +
                                (request.Section == "SF" ? "      CASE WHEN LEFT(XXBWFL.BWBH, 1) = 'V' THEN ISNULL(XXBWFLS2.DFL, 'N') ELSE ISNULL(XXBWFLS.DFL, 'N') END IN ('O') " : "") +
                                (request.Section == "A" ? "      CASE WHEN LEFT(XXBWFL.BWBH, 1) = 'V' THEN ISNULL(XXBWFLS2.DFL, 'N') ELSE ISNULL(XXBWFLS.DFL, 'N') END IN ('A') OR ZLZLS2.CLBH LIKE 'U1DE%' " : "") +
                                "    ) " +
                                "    GROUP BY NewCard.ListNo, NewCard.RY_Begin, NewCard.RY_End, NewCard.MaterialID, NewCard.Usage, NewCard.IssuanceUsage " +
                                "    HAVING ISNULL(SUM(ZLZLS2.CLSL), 0) > 0 " +
                                "  ) AS NewCard " +
                                "  LEFT JOIN MRCardS ON MRCardS.RY_Begin = NewCard.RY_Begin AND MRCardS.MaterialID = NewCard.MaterialID " +
                                "  LEFT JOIN MRCard ON MRCard.ListNo = MRCardS.ListNo " +
                                "  GROUP BY NewCard.ListNo, NewCard.RY_Begin, NewCard.RY_End, NewCard.MaterialID, NewCard.Usage, NewCard.IssuanceUsage, NewCard.ZLUsage " +
                                ") AS NewCard " +
                                "WHERE Usage > 0; " +
                                
                                "DECLARE @RowCount INT; " +
                                "SET @RowCount = @@ROWCOUNT; " +

                                "IF @RowCount > 0 " +
                                "BEGIN " +
                                "  INSERT INTO MRCard (ListNo, Section, Building, Lean, DemandDate, DemandTime, Source, Remark, ConfirmID, ConfirmDate, DeliveryCFMID, DeliveryCFMDate, ReceiverConfirmID, ReceiverConfirmDate, UserID, UserDate, GSBH, YN) " +
                                "  VALUES (@ListNo, '{0}', '{1}', '{2}', '{3}', '{4}', '{5}', N'{6}', 'NO', NULL, 'NO', NULL, 'NO', NULL, '{7}', GetDate(), '{8}', '1'); " +
                                "END ",
                                request.Section, request.Building, request.Lean, request.DemandDate, request.DemandTime, request.Source, request.Remark!.Replace("'", "''"), request.UserID, request.Factory
                            ), ERP
                        );

                        ERP.Open();
                        int recordCount = SQL.ExecuteNonQuery();
                        ERP.Dispose();

                        if (recordCount > 0)
                        {
                            return "{\"statusCode\": 200}";
                        }
                        else
                        {
                            return "{\"statusCode\": 400}";
                        }
                    }
                    else
                    {
                        return "{\"statusCode\": 200}";
                    }
                }
                else
                {
                    return "{\"statusCode\": 401}";
                }
            }
            else
            {
                return "{\"statusCode\": 404, \"Date\": \"" + dt.Rows[0]["Date"].ToString() + "\"}";
            }
        }

        [HttpPost]
        [Route("updateMRCard")]
        public string updateMRCard(MRCardGenerateRequest request)
        {
            string Time = request.DemandTime!.Substring(0, 5);
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                string.Format(
                    "DECLARE @LastWorkingDay VARCHAR(10); " +
                    "SET @LastWorkingDay = ( " +
                    "  SELECT TOP 1 CONVERT(VARCHAR, CONVERT(SmallDateTime, SCYear + '/' + SCMonth + '/' + SCDay), 111) AS Date FROM SCRL " +
                    "  WHERE CONVERT(SmallDateTime, SCYear + '/' + SCMonth + '/' + SCDay) < '{0}' AND GSBH = '{2}' " +
                    "  GROUP BY CONVERT(SmallDateTime, SCYear + '/' + SCMonth + '/' + SCDay) " +
                    "  HAVING SUM(SCGS) > 0 " +
                    "  ORDER BY CONVERT(SmallDateTime, SCYear + '/' + SCMonth + '/' + SCDay) DESC " +
                    "); " +
                    "SELECT CASE WHEN '{1}' = '07:30:00' THEN DATEDIFF(SS, GETDATE(),  @LastWorkingDay + ' 16:30:00')/60/60 " +
                    "ELSE CASE WHEN '{1}' = '09:30:00' THEN DATEDIFF(SS, GETDATE(), '{0} 10:00:00')/60/60 " +
                    "ELSE CASE WHEN '{1}' = '12:30:00' THEN DATEDIFF(SS, GETDATE(), '{0} 11:30:00')/60/60 " +
                    "ELSE DATEDIFF(SS, GETDATE(), '{0} {1}')/60/60 END END END AS Hours ",
                    request.DemandDate, Time + ":00", request.Factory
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);
            if ((int)dt.Rows[0]["Hours"] >= 2)
            {
                da = new SqlDataAdapter(
                    System.String.Format(
                        "SELECT ListNo, ConfirmDate FROM MRCard " +
                        "WHERE ListNo = '{0}' "
                        , request.ListNo
                    ), ERP
                );
                dt = new DataTable();
                da.Fill(dt);

                if (dt.Rows.Count > 0)
                {
                    if (dt.Rows[0]["ConfirmDate"] == DBNull.Value)
                    {
                        string InsertSQL = string.Empty;
                        string[] RY = request.RequestString!.Split(';');
                        for (int i = 0; i < RY.Length; i++)
                        {
                            string[] RY_Data = RY[i].ToString().Split('@');
                            string[] RY_All = RY_Data[0].Split(" ~ ");
                            string RY_Begin = RY_All[0];
                            string RY_End = RY_All[0];
                            if (RY_All.Length > 1)
                            {
                                RY_End = RY_All[1];
                            }
                            string[] Materials = RY_Data[1].ToString().Split(':');
                            for (int j = 0; j < Materials.Length; j++)
                            {
                                string MatID = Materials[j].ToString().Split('-')[0];
                                string Usage = Materials[j].ToString().Split('-')[1];
                                if (InsertSQL == "")
                                {
                                    InsertSQL += string.Format(
                                        "  SELECT '{4}' AS ListNo, '{0}' AS RY_Begin, '{1}' AS RY_End, '{2}' AS MaterialID, {3} AS Usage, NULL AS IssuanceUsage ",
                                        RY_Begin, RY_End, MatID, Usage, request.ListNo
                                    );
                                }
                                else
                                {
                                    InsertSQL += string.Format(
                                        "  UNION ALL " +
                                        "  SELECT '{4}' AS ListNo, '{0}' AS RY_Begin, '{1}' AS RY_End, '{2}' AS MaterialID, {3} AS Usage, NULL AS IssuanceUsage ",
                                        RY_Begin, RY_End, MatID, Usage, request.ListNo
                                    );
                                }
                            }
                        }

                        if (InsertSQL != "")
                        {
                            SqlCommand SQL = new SqlCommand(
                                string.Format(
                                    "DELETE FROM MRCardS WHERE ListNo = '{0}'; " +

                                    "INSERT INTO MRCardS (ListNo, RY_Begin, RY_End, MaterialID, Usage, Source, UserID, UserDate, YN) " +
                                    "SELECT ListNo, RY_Begin, RY_End, MaterialID, CASE WHEN Usage <= MaxUsage THEN Usage ELSE MaxUsage END AS Usage, 'WH' AS Source, '{8}' UserID, GetDate() AS UserDate, '1' AS YN FROM ( " +
                                    "  SELECT NewCard.ListNo, NewCard.RY_Begin, NewCard.RY_End, NewCard.MaterialID, NewCard.Usage, NewCard.IssuanceUsage, " +
                                    "  NewCard.ZLUsage - ISNULL(SUM(CASE WHEN MRCard.Section = '{1}' THEN CASE WHEN MRCard.DeliveryCFMDate IS NOT NULL THEN MRCardS.IssuanceUsage ELSE MRCardS.Usage END END), 0) AS MaxUsage FROM  ( " +
                                    "    SELECT NewCard.ListNo, NewCard.RY_Begin, NewCard.RY_End, NewCard.MaterialID, NewCard.Usage, NewCard.IssuanceUsage, SUM(ZLZLS2.CLSL) AS ZLUsage FROM ( " +
                                    InsertSQL +
                                    "    ) AS NewCard " +
                                    "    LEFT JOIN ZLZLS2 ON ZLZLS2.ZLBH = NewCard.RY_Begin AND ZLZLS2.CLBH = NewCard.MaterialID AND ZLZLS2.MJBH = 'ZZZZZZZZZZ' " +
                                    "    LEFT JOIN DDZL ON DDZL.DDBH = ZLZLS2.ZLBH " +
                                    "    LEFT JOIN XXBWFL ON XXBWFL.XieXing = DDZL.XieXing AND XXBWFL.BWBH = ZLZLS2.BWBH " +
                                    "    LEFT JOIN XXBWFLS ON XXBWFLS.FLBH = XXBWFL.FLBH " +
                                    "    LEFT JOIN XXZLSVN ON XXZLSVN.XieXing = DDZL.XieXing AND XXZLSVN.SheHao = DDZL.SheHao AND XXZLSVN.BWBH = ZLZLS2.BWBH " +
                                    "    LEFT JOIN XXBWFLS AS XXBWFLS2 on XXBWFLS2.FLBH = XXZLSVN.FLBH " +
                                    "    WHERE 1 = 1 " +
                                    "    AND ( " +
                                    (request.Section == "C" ? "      CASE WHEN LEFT(XXBWFL.BWBH, 1) = 'V' THEN ISNULL(XXBWFLS2.DFL, 'N') ELSE ISNULL(XXBWFLS.DFL, 'N') END IN ('B', 'C') " : "") +
                                    (request.Section == "S" ? "      CASE WHEN LEFT(XXBWFL.BWBH, 1) = 'V' THEN ISNULL(XXBWFLS2.DFL, 'N') ELSE ISNULL(XXBWFLS.DFL, 'N') END IN ('S') " : "") +
                                    (request.Section == "SF" ? "      CASE WHEN LEFT(XXBWFL.BWBH, 1) = 'V' THEN ISNULL(XXBWFLS2.DFL, 'N') ELSE ISNULL(XXBWFLS.DFL, 'N') END IN ('O') " : "") +
                                    (request.Section == "A" ? "      CASE WHEN LEFT(XXBWFL.BWBH, 1) = 'V' THEN ISNULL(XXBWFLS2.DFL, 'N') ELSE ISNULL(XXBWFLS.DFL, 'N') END IN ('A') OR ZLZLS2.CLBH LIKE 'U1DE%' " : "") +
                                    "    ) " +
                                    "    GROUP BY NewCard.ListNo, NewCard.RY_Begin, NewCard.RY_End, NewCard.MaterialID, NewCard.Usage, NewCard.IssuanceUsage " +
                                    "    HAVING ISNULL(SUM(ZLZLS2.CLSL), 0) > 0 " +
                                    "  ) AS NewCard " +
                                    "  LEFT JOIN MRCardS ON MRCardS.RY_Begin = NewCard.RY_Begin AND MRCardS.MaterialID = NewCard.MaterialID " +
                                    "  LEFT JOIN MRCard ON MRCard.ListNo = MRCardS.ListNo " +
                                    "  GROUP BY NewCard.ListNo, NewCard.RY_Begin, NewCard.RY_End, NewCard.MaterialID, NewCard.Usage, NewCard.IssuanceUsage, NewCard.ZLUsage " +
                                    ") AS NewCard " +
                                    "WHERE Usage > 0; " +

                                    "DECLARE @RowCount INT; " +
                                    "SET @RowCount = @@ROWCOUNT; " +

                                    "IF @RowCount = 0 " +
                                    "BEGIN " +
                                    "  DELETE FROM MRCard WHERE ListNo = '{0}'; " +
                                    "END " +
                                    "ELSE BEGIN " +
                                    "  UPDATE MRCard SET " +
                                    "  Section = '{1}', " +
                                    "  Building = '{2}', " +
                                    "  Lean = '{3}', " +
                                    "  DemandDate = '{4}', " +
                                    "  DemandTime = '{5}', " +
                                    "  Source = '{6}', " +
                                    "  Remark = N'{7}', " +
                                    "  UserID = '{8}', " +
                                    "  UserDate = GetDate(), " +
                                    "  GSBH = '{9}' " +
                                    "  WHERE ListNo = '{0}'; " +
                                    "END ",
                                    request.ListNo, request.Section, request.Building, request.Lean, request.DemandDate, request.DemandTime, request.Source, request.Remark!.Replace("'", "''"), request.UserID, request.Factory
                                ), ERP
                            );

                            ERP.Open();
                            int recordCount = SQL.ExecuteNonQuery();
                            ERP.Dispose();

                            if (recordCount > 0)
                            {
                                return "{\"statusCode\": 200}";
                            }
                            else
                            {
                                return "{\"statusCode\": 400}";
                            }
                        }
                        else
                        {
                            return "{\"statusCode\": 200}";
                        }
                    }
                    else
                    {
                        return "{\"statusCode\": 403}";
                    }
                }
                else
                {
                    return "{\"statusCode\": 402}";
                }
            }
            else
            {
                return "{\"statusCode\": 401}";
            }
        }

        [HttpPost]
        [Route("deleteMRCard")]
        public string deleteMRCard(MRCardGenerateRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT ListNo, ConfirmDate FROM MRCard " +
                    "WHERE ListNo = '{0}' "
                    , request.ListNo
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                if (dt.Rows[0]["ConfirmDate"] == DBNull.Value)
                {
                    SqlCommand SQL = new SqlCommand(
                        string.Format(
                            "DELETE FROM MRCard WHERE ListNo = '{0}'; " +
                            "DELETE FROM MRCardS WHERE ListNo = '{0}'; ",
                            request.ListNo
                        ), ERP
                    );

                    ERP.Open();
                    int recordCount = SQL.ExecuteNonQuery();
                    ERP.Dispose();

                    if (recordCount > 0)
                    {
                        return "{\"statusCode\": 200}";
                    }
                    else
                    {
                        return "{\"statusCode\": 400}";
                    }
                }
                else
                {
                    return "{\"statusCode\": 402}";
                }
            }
            else
            {
                return "{\"statusCode\": 401}";
            }
        }

        [HttpPost]
        [Route("signMRCard")]
        public string signMRCard(MRCardGenerateRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT ListNo, DeliveryCFMDate, ReceiverConfirmDate FROM MRCard " +
                    "WHERE ListNo = '{0}' "
                    , request.ListNo
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                if (dt.Rows[0]["DeliveryCFMDate"] != DBNull.Value)
                {
                    if (dt.Rows[0]["ReceiverConfirmDate"] == DBNull.Value)
                    {
                        SqlCommand SQL = new SqlCommand(
                            string.Format(
                                "UPDATE MRCard SET ReceiverConfirmID = '{1}', ReceiverConfirmDate = GetDate() WHERE ListNo = '{0}'; ",
                                request.ListNo, request.UserID
                            ), ERP
                        );

                        ERP.Open();
                        int recordCount = SQL.ExecuteNonQuery();
                        ERP.Dispose();

                        if (recordCount > 0)
                        {
                            return "{\"statusCode\": 200}";
                        }
                        else
                        {
                            return "{\"statusCode\": 400}";
                        }
                    }
                    else
                    {
                        return "{\"statusCode\": 403}";
                    }
                }
                else
                {
                    return "{\"statusCode\": 402}";
                }
            }
            else
            {
                return "{\"statusCode\": 401}";
            }
        }

        [HttpPost]
        [Route("getMRCardInfo")]
        public string getMRCardInfo(MRCardInfoRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT MRCardS.*, MRCard.Section, MRCard.Source FROM ( " +
                    "  SELECT MRCardS.ListNo, MRCardS.RY_Begin, MRCardS.RY_End, CAST(MONTH(MAX(SC.schedule_date)) AS VARCHAR) + '/' + CAST(DAY(MAX(SC.schedule_date)) AS VARCHAR) AS Date, " +
                    "  MRCardS.MaterialID, ISNULL(MRCardS.IssuanceUsage, MRCardS.Usage) AS Usage, MRCardS.Remark, CLZL.DWBH FROM MRCardS " +
                    "  LEFT JOIN MRCard ON MRCard.ListNo = MRCardS.ListNo " +
                    "  LEFT JOIN schedule_crawler AS SC ON CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END = MRCardS.RY_Begin AND SC.building_no = MRCard.Building AND SC.lean_no = MRCard.Lean " +
                    "  LEFT JOIN CLZL ON CLZL.CLDH = MRCardS.MaterialID " +
                    "  WHERE MRCardS.ListNo = '{0}' " +
                    "  GROUP BY MRCardS.ListNo, MRCardS.RY_Begin, MRCardS.RY_End, MRCardS.MaterialID, ISNULL(MRCardS.IssuanceUsage, MRCardS.Usage), MRCardS.Remark, CLZL.DWBH " +
                    "  UNION ALL " +
                    "  SELECT MRCardS.ListNo, 'Total' AS RY_Begin, 'Total' AS RY_End, 'Total' AS Date, MRCardS.MaterialID, ISNULL(SUM(MRCardS.IssuanceUsage), SUM(MRCardS.Usage)) AS Usage, '' AS Remark, CLZL.DWBH FROM MRCardS " +
                    "  LEFT JOIN CLZL ON CLZL.CLDH = MRCardS.MaterialID " +
                    "  WHERE MRCardS.ListNo = '{0}' " +
                    "  GROUP BY MRCardS.ListNo, MRCardS.MaterialID, MRCardS.Remark, CLZL.DWBH " +
                    ") AS MRCardS " +
                    "LEFT JOIN MRCard ON MRCard.ListNo = MRCardS.ListNo " +
                    "ORDER BY CASE WHEN MRCardS.RY_Begin = 'Total' THEN 1 ELSE 0 END, MRCardS.RY_Begin, MRCardS.RY_End, MRCardS.MaterialID "
                    , request.ListNo
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);
            List<dynamic> ResultList = new List<dynamic>();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    RYList rYList = new RYList();
                    rYList.RY_Begin = dt.Rows[Row]["RY_Begin"].ToString();
                    rYList.RY_End = dt.Rows[Row]["RY_End"].ToString();
                    rYList.Date = dt.Rows[Row]["Date"].ToString();
                    rYList.Section = dt.Rows[Row]["Section"].ToString();
                    rYList.Source = dt.Rows[Row]["Source"].ToString();
                    rYList.RYMaterial = new List<RYMaterials>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["RY_Begin"].ToString() == rYList.RY_Begin && dt.Rows[Row]["RY_End"].ToString() == rYList.RY_End)
                    {
                        RYMaterials ryMaterial = new RYMaterials();
                        ryMaterial.MaterialID = dt.Rows[Row]["MaterialID"].ToString();
                        ryMaterial.Qty = (double)dt.Rows[Row]["Usage"];
                        ryMaterial.Unit = dt.Rows[Row]["DWBH"].ToString();
                        ryMaterial.Remark = dt.Rows[Row]["Remark"].ToString();
                        rYList.RYMaterial.Add(ryMaterial);
                        Row++;
                    }
                    ResultList.Add(rYList);
                }

                return JsonConvert.SerializeObject(ResultList);
            }
            else
            {
                return "{}";
            }
        }

        [HttpPost]
        [Route("getDailyMaterialUsage")]
        public string getDailyMaterialUsage(MaterialRequisitionRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT MRCardS.MaterialID, SUM(CASE WHEN DeliveryCFMDate IS NOT NULL THEN ISNULL(IssuanceUsage, 0) ELSE ISNULL(Usage, 0) END) AS Usage, CLZL.DWBH FROM MRCard " +
                    "LEFT JOIN MRCardS ON MRCardS.ListNo = MRCard.ListNo " +
                    "LEFT JOIN CLZL ON CLZL.CLDH = MRCardS.MaterialID " +
                    "WHERE Section = '{0}' AND Building = '{1}' AND Lean = '{2}' AND DemandDate = '{3}' " +
                    "GROUP BY MRCardS.MaterialID, CLZL.DWBH " +
                    "ORDER BY MRCardS.MaterialID "
                    , request.Section, request.Building, request.Lean, request.Date
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);
            List<dynamic> ResultList = new List<dynamic>();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    RYMaterials ryMaterial = new RYMaterials();
                    ryMaterial.MaterialID = dt.Rows[Row]["MaterialID"].ToString();
                    ryMaterial.Qty = (double)dt.Rows[Row]["Usage"];
                    ryMaterial.Unit = dt.Rows[Row]["DWBH"].ToString();
                    ResultList.Add(ryMaterial);
                    Row++;
                }

                return JsonConvert.SerializeObject(ResultList);
            }
            else
            {
                return "{}";
            }
        }

        [HttpPost]
        [Route("getOrderGroupDispatchPart")]
        public string getOrderGroupDispatchPart(OrderRequest request)
        {
            if (request.MachineType == "Automatic")
            {
                CheckCuttingData(request.Order);
            }

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da;

            if (request.MachineType == "All")
            {
                da = new SqlDataAdapter(
                    System.String.Format(
                        "SELECT ZLZLS2.BWBH, BWZL.YWSM, BWZL.ZWSM, ZLZLS2.CLBH, ISNULL(KT_SOPCut.Type, 'Cutting') AS Type FROM ( " +
                        "  SELECT DISTINCT '{0}' AS ZLBH, MaterialID FROM MRCardS " +
                        "  LEFT JOIN MRCard ON MRCard.ListNo = MRCardS.ListNo " +
                        "  LEFT JOIN DDZL ON DDZL.DDBH = MRCardS.RY_Begin " +
                        "  WHERE DDZL.XieXing = (SELECT XieXing FROM DDZL WHERE DDBH = '{0}') AND DDZL.SheHao = (SELECT SheHao FROM DDZL WHERE DDBH = '{0}') AND Section = 'C' " +
                        ") AS MRCard " +
                        "LEFT JOIN ZLZLS2 ON ZLZLS2.ZLBH = MRCard.ZLBH AND ZLZLS2.CLBH = MRCard.MaterialID " +
                        "LEFT JOIN BWZL ON BWZL.BWDH = ZLZLS2.BWBH " +
                        "LEFT JOIN DDZL ON DDZL.DDBH = ZLZLS2.ZLBH " +
                        "LEFT JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao AND KT_SOPCut.BWBH = ZLZLS2.BWBH " +
                        "WHERE ZLZLS2.MJBH = 'ZZZZZZZZZZ' AND SUBSTRING(ZLZLS2.CLBH, 1, 1) NOT IN('L', 'N', 'J') " +
                        "UNION " +
                        "SELECT KT_SOPCut.BWBH, BWZL.YWSM, BWZL.ZWSM, ZLZLS2.CLBH, ISNULL(KT_SOPCut.Type, 'Cutting') AS Type FROM DDZL " +
                        "LEFT JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao " +
                        "LEFT JOIN ZLZLS2 ON ZLZLS2.ZLBH = DDZL.DDBH AND ZLZLS2.BWBH = KT_SOPCut.BWBH " +
                        "LEFT JOIN BWZL ON BWZL.BWDH = KT_SOPCut.BWBH " +
                        "WHERE DDZL.DDBH = '{0}' AND KT_SOPCut.piece > 0 " +
                        "AND ZLZLS2.MJBH = 'ZZZZZZZZZZ' AND SUBSTRING(ZLZLS2.CLBH, 1, 1) NOT IN('L', 'N', 'J') "
                        , request.Order
                    ), ERP
                );
            }
            else if (request.MachineType == "Material Requested")
            {
                da = new SqlDataAdapter(
                    System.String.Format(
                        "SELECT ZLZLS2.BWBH, BWZL.YWSM, BWZL.ZWSM, ZLZLS2.CLBH, 'Manual' AS Type FROM MRCardS " +
                        "LEFT JOIN MRCard ON MRCard.ListNo = MRCardS.ListNo " +
                        "LEFT JOIN ZLZLS2 ON ZLZLS2.ZLBH = MRCardS.RY_Begin AND ZLZLS2.CLBH = MRCardS.MaterialID " +
                        "LEFT JOIN BWZL ON BWZL.BWDH = ZLZLS2.BWBH " +
                        "WHERE MRCardS.RY_Begin = '{0}' AND MRCard.Section = 'C' AND ZLZLS2.MJBH = 'ZZZZZZZZZZ' AND ISNULL(MRCardS.Usage, 0) > 0 " +
                        "ORDER BY ZLZLS2.BWBH "
                        , request.Order
                    ), ERP
                );
            }
            else
            {
                da = new SqlDataAdapter(
                    System.String.Format(
                        "SELECT CutDispatchZL.BWBH, BWZL.YWSM, BWZL.ZWSM, CutDispatchZL.CLBH, KT_SOPCut.Type, SUM(CutDispatchZL.Qty) AS ZLQty FROM CutDispatchZL " +
                        "LEFT JOIN BWZL ON BWZL.BWDH = CutDispatchZL.BWBH " +
                        "LEFT JOIN DDZL ON DDZL.DDBH = CutDispatchZL.ZLBH " +
                        "LEFT JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao AND KT_SOPCut.BWBH = CutDispatchZL.BWBH " +
                        "WHERE CutDispatchZL.ZLBH = '{0}' AND SUBSTRING(CutDispatchZL.CLBH, 1, 1) NOT IN ('L', 'N', 'J') AND CutDispatchZL.Piece > 0 " +
                        (request.MachineType == "Automatic" ? "AND ISNULL(KT_SOPCut.Type, 'Manual') = 'AutoCutting' " : "") +
                        //(request.MachineType == "Manual" ? "AND ISNULL(KT_SOPCut.Type, 'Manual') = 'Manual' " : "") +
                        "GROUP BY CutDispatchZL.BWBH, CutDispatchZL.CLBH, BWZL.YWSM, BWZL.ZWSM, KT_SOPCut.Type " +
                        "ORDER BY CutDispatchZL.BWBH, CutDispatchZL.CLBH "
                        , request.Order
                    ), ERP
                );
            }

            DataTable dt = new DataTable();
            da.Fill(dt);
            List<dynamic> ResultList = new List<dynamic>();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    OrderPartResult Part = new OrderPartResult();
                    Part.PartID = dt.Rows[Row]["BWBH"].ToString();
                    Part.MaterialID = dt.Rows[Row]["CLBH"].ToString();
                    Part.PartName = new List<PartInfo>();
                    PartInfo Info = new PartInfo();
                    Info.ZH = dt.Rows[Row]["ZWSM"].ToString();
                    Info.EN = dt.Rows[Row]["YWSM"].ToString();
                    Info.VI = dt.Rows[Row]["YWSM"].ToString();
                    Info.Type = dt.Rows[Row]["Type"].ToString();
                    Part.PartName.Add(Info);
                    ResultList.Add(Part);
                    Row++;
                }

                return JsonConvert.SerializeObject(ResultList);
            }
            else
            {
                return "{}";
            }
        }

        [HttpPost]
        [Route("getOrderGroupDispatchCycle")]
        public string getOrderGroupDispatchCycle(OrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da;
            if (request.Section == "MachineDispatched")
            {
                da = new SqlDataAdapter(
                    System.String.Format(
                        "SELECT SMDD.DDBH, SMDD.Qty, CutDispatchSS.Machine, CASE WHEN CutDispatchSS.Machine IS NULL THEN 'N' ELSE 'Y' END AS Dispatched FROM SMDD " +
                        "LEFT JOIN ( " +
                        "  SELECT ZLBH, DDBH, ISNULL(MAX(Machine), '') AS Machine FROM CutDispatchSS " +
                        "  WHERE ZLBH = '{0}' AND BWBH IN ({1}) " +
                        "  GROUP BY ZLBH, DDBH " +
                        ") AS CutDispatchSS ON CutDispatchSS.ZLBH = SMDD.YSBH AND CutDispatchSS.DDBH = SMDD.DDBH " +
                        "WHERE YSBH = '{0}' AND GXLB = 'A' " +
                        "ORDER BY SMDD.DDBH "
                        , request.Order, request.PartID
                    ), ERP
                );
            }
            else
            {
                da = new SqlDataAdapter(
                    System.String.Format(
                        "SELECT SMDD.DDBH, SMDD.Qty, CASE WHEN CD.DDBH IS NULL THEN 'N' ELSE 'Y' END AS Dispatched FROM SMDD " +
                        "LEFT JOIN CycleDispatch AS CD ON CD.ZLBH = SMDD.YSBH AND CD.DDBH = SMDD.DDBH AND CD.GXLB = '{1}' " +
                        "WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = 'A' " +
                        "ORDER BY SMDD.DDBH "
                        , request.Order, request.Section
                    ), ERP
                );
            }
            DataTable dt = new DataTable();
            da.Fill(dt);
            List<OrderCycle> CycleList = new List<OrderCycle>();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    OrderCycle Cycle = new OrderCycle();
                    Cycle.Cycle = dt.Rows[Row]["DDBH"].ToString();
                    Cycle.Pairs = (int)dt.Rows[Row]["Qty"];
                    if (request.Section == "MachineDispatched")
                    {
                        Cycle.DispatchMachine = dt.Rows[Row]["Machine"].ToString();
                    }
                    Cycle.AllDispatched = dt.Rows[Row]["Dispatched"].ToString() == "N" ? false : true;
                    CycleList.Add(Cycle);
                    Row++;
                }

                return JsonConvert.SerializeObject(CycleList);
            }
            else
            {
                return "{}";
            }
        }

        [HttpPost]
        [Route("generateCuttingGroupWorkOrder")]
        public string generateCuttingGroupWorkOrder(CuttingWorkOrderRequest request)
        {
            try
            {
                SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
                SqlCommand SQL = new SqlCommand(
                    string.Format(
                        "IF OBJECT_ID('tempdb..#CutDispatch') IS NOT NULL " +
                        "BEGIN DROP TABLE #CutDispatch END; " +

                        "DECLARE @Seq AS Int = ( " +
                        "  SELECT ISNULL(MAX(CAST(SUBSTRING(DLNO, 7, 5) AS INT)), 0) AS DLNO FROM CutDispatch " +
                        "  WHERE DLNO LIKE SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + '%' " +
                        "); " +

                        "SELECT SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + RIGHT('0000' + CAST(@Seq + 1 AS VARCHAR), 5) AS DLNO, CutDispatchZL.ZLBH, SMDD.DDBH, CutDispatchZL.BWBH, " +
                        "CutDispatchZL.SIZE, CutDispatchZL.XXCC, CutDispatchZL.CLBH, SMDD.Qty, CASE WHEN ISNULL(CutDispatchZL.CutNum, 0) = 0 THEN SMDD.Qty ELSE CutDispatchZL.CutNum END AS CutNum, " +
                        "0 AS ScanQty, 0 AS QRCode, '' AS Machine, NULL AS MachineDate, NULL AS MachineEndDate, '{3}' AS UserID, GETDATE() AS UserDate, '1' AS YN INTO #CutDispatch FROM CutDispatchZL " +
                        "LEFT JOIN( " +
                        "  SELECT SMDD.YSBH, SMDD.DDBH, SMDDS.XXCC, SMDDS.Qty FROM SMDD " +
                        "  LEFT JOIN SMDDS ON SMDDS.DDBH = SMDD.DDBH " +
                        "  WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = 'C' " +
                        ") AS SMDD ON SMDD.YSBH = CutDispatchZL.ZLBH AND SMDD.XXCC = CutDispatchZL.SIZE " +
                        "LEFT JOIN CutDispatchSS ON CutDispatchSS.ZLBH = CutDispatchZL.ZLBH AND CutDispatchSS.BWBH = CutDispatchZL.BWBH AND CutDispatchSS.SIZE = CutDispatchZL.SIZE AND CutDispatchSS.DDBH = SMDD.DDBH " +
                        "WHERE CutDispatchZL.ZLBH = '{0}' AND CutDispatchZL.BWBH IN ({1}) AND SMDD.DDBH IN ({2}) AND CutDispatchSS.Qty IS NULL; " +

                        "INSERT INTO CutDispatch (DLNO, DLLB, GSBH, DepID, PlanDate, Memo, CustomLayers, USERID, USERDATE, YN) " +
                        "SELECT DISTINCT DLNO, '{6}' AS DLLB, '{4}' AS GSBH, '{5}' AS DepID, CONVERT(SmallDateTime, CONVERT(VARCHAR, UserDate, 111)) AS PlanDate, '' AS Memo, NULL AS CustomLayers, UserID, UserDate, YN FROM #CutDispatch " +
                        "GROUP BY DLNO, ZLBH, BWBH, SIZE, CLBH, XXCC, UserID, UserDate, YN; " +

                        "INSERT INTO CutDispatchS (DLNO, ZLBH, BWBH, SIZE, CLBH, Qty, XXCC, CutNum, okCutNum, USERID, USERDATE, ScanUser, ScanDate, YN) " +
                        "SELECT DLNO, ZLBH, BWBH, SIZE, CLBH, SUM(Qty) AS Qty, XXCC, SUM(CutNum) AS CutNum, 0 AS okCutNum, UserID, UserDate, '' AS ScanUser, NULL AS ScanDate, YN FROM #CutDispatch " +
                        "GROUP BY DLNO, ZLBH, BWBH, SIZE, CLBH, XXCC, UserID, UserDate, YN; " +

                        "INSERT INTO CutDispatchSS (DLNO, ZLBH, DDBH, BWBH, SIZE, CLBH, Qty, ScanQty, QRCode, Machine, MachineDate, MachineEndDate, USERID, USERDATE, YN) " +
                        "SELECT DLNO, ZLBH, DDBH, BWBH, SIZE, CLBH, Qty, ScanQty, QRCode, Machine, MachineDate, MachineEndDate, UserID, UserDate, YN FROM #CutDispatch; ",
                        request.Order, request.PartID, request.SelectedCycle, request.UserID, request.Factory, request.Department, request.Type
                    ), ERP
                );
                ERP.Open();
                int recordCount = SQL.ExecuteNonQuery();
                ERP.Dispose();

                if (recordCount > 0)
                {
                    return "{\"statusCode\": 200}";
                }
                else
                {
                    return "{\"statusCode\": 401}";
                }
            }
            catch (Exception ex)
            {
                return "{\"statusCode\": 400}";
            }
        }

        [HttpPost]
        [Route("submitCuttingGroupProgress")]
        public string submitCuttingGroupProgress(CuttingWorkOrderRequest request)
        {
            try
            {
                SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
                SqlCommand SQL = new SqlCommand(
                    string.Format(
                        "UPDATE CutDispatchSS SET ScanQty = Qty, Machine = '{4}', MachineDate = GETDATE() " +
                        "WHERE ZLBH = '{0}' AND BWBH IN ({1}) AND DDBH IN ({2}) AND ScanQty = 0 "
                        , request.Order, request.PartID, request.SelectedCycle, request.UserID, request.Department
                    ), ERP
                );
                ERP.Open();
                int recordCount = SQL.ExecuteNonQuery();
                ERP.Dispose();

                if (recordCount > 0)
                {
                    ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
                    SQL = new SqlCommand(
                        string.Format(
                            "UPDATE CutDispatchS SET okCutNum = FLOOR(CutNum * CutDispatchSS.ScanQty / CutDispatchSS.Qty), ScanUser = '{3}', " +
                            "ScanDate = CASE WHEN okCutNum <> FLOOR(CutNum * CutDispatchSS.ScanQty / CutDispatchSS.Qty) THEN GETDATE() ELSE NULL END " +
                            "FROM ( " +
                            "  SELECT CutDispatchSS.* FROM CutDispatchS " +
                            "  LEFT JOIN ( " +
                            "    SELECT ZLBH, BWBH, SIZE, SUM(Qty) AS Qty, SUM(ScanQty) AS ScanQty FROM CutDispatchSS " +
                            "    WHERE ZLBH = '{0}' AND BWBH IN ({1}) AND DDBH IN ({2}) " +
                            "    GROUP BY ZLBH, BWBH, SIZE " +
                            "  ) AS CutDispatchSS ON CutDispatchSS.ZLBH = CutDispatchS.ZLBH AND CutDispatchSS.BWBH = CutDispatchS.BWBH AND CutDispatchSS.SIZE = CutDispatchS.SIZE " +
                            "  WHERE CutDispatchS.ZLBH = '{0}' AND CutDispatchS.BWBH IN ({1}) " +
                            ") AS CutDispatchSS " +
                            "WHERE CutDispatchS.ZLBH = CutDispatchSS.ZLBH AND CutDispatchS.BWBH = CutDispatchSS.BWBH AND CutDispatchS.SIZE = CutDispatchSS.SIZE; "
                            , request.Order, request.PartID, request.SelectedCycle, request.UserID, request.Department
                        ), ERP
                    );
                    ERP.Open();
                    recordCount = SQL.ExecuteNonQuery();
                    ERP.Dispose();

                    return "{\"statusCode\": 200}";
                }
                else
                {
                    return "{\"statusCode\": 401}";
                }
            }
            catch (Exception ex)
            {
                return "{\"statusCode\": 400}";
            }
        }

        [HttpPost]
        [Route("getLastWorkingDay")]
        public string getLastWorkingDay(WorkingDayRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT TOP 1 CONVERT(VARCHAR, CONVERT(SmallDateTime, SCYear + '/' + SCMonth + '/' + SCDay), 111) AS Date FROM SCRL " +
                    "WHERE CONVERT(SmallDateTime, SCYear + '/' + SCMonth + '/' + SCDay) < '{0}' AND GSBH = '{1}' " +
                    "GROUP BY CONVERT(SmallDateTime, SCYear + '/' + SCMonth + '/' + SCDay) " +
                    "HAVING SUM(SCGS) > 0 " +
                    "ORDER BY CONVERT(SmallDateTime, SCYear + '/' + SCMonth + '/' + SCDay) DESC "
                    , request.Date, request.Factory
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                return "{\"Date\": \"" + dt.Rows[0]["Date"].ToString() + "\"}";
            }
            else
            {
                return "{}";
            }
        }

        [HttpPost]
        [Route("getAutoCuttingWorkOrder")]
        public string getAutoCuttingWorkOrder(EmmaRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SET ARITHABORT ON; " +
                    "IF OBJECT_ID('tempdb..#WorkOrder') IS NOT NULL " +
                    "BEGIN DROP TABLE #WorkOrder END; " +

                    "SELECT CutDispatch_Auto.ListNo, CONVERT(VARCHAR, CutDispatch_Auto.PlanDate, 111) AS PlanDate, CutDispatch_Auto.Machine, XXZL.DAOMH, " +
                    "CutDispatchS_Auto.RY, CutDispatchS_Auto.Part, CutDispatchS_Auto.Cycle, CutDispatchS_Auto.Qty, CutDispatchS_Auto.ScanQty INTO #WorkOrder FROM ( " +
                    "  SELECT ListNo, SUM(Qty) AS Qty, SUM(ScanQty) AS ScanQty FROM CutDispatchS_Auto " +
                    "  GROUP BY ListNo " +
                    (request.Type == "Completed" ? "  HAVING SUM(ScanQty) >= SUM(Qty) " : "  HAVING SUM(ScanQty) < SUM(Qty) ") +
                    ") AS WorkOrder " +
                    "LEFT JOIN CutDispatch_Auto ON CutDispatch_Auto.ListNo = WorkOrder.ListNo " +
                    "LEFT JOIN CutDispatchS_Auto ON CutDispatchS_Auto.ListNo = CutDispatch_Auto.ListNo " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = CutDispatchS_Auto.RY " +
                    "LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "WHERE CutDispatch_Auto.Machine LIKE '{0}%'" + (request.Type == "Completed" ? " AND CutDispatch_Auto.PlanDate = '{1}'; " : "; ") +

                    "IF OBJECT_ID('tempdb..#Part') IS NOT NULL " +
                    "BEGIN DROP TABLE #Part END; " +

                    "SELECT WorkOrder.ListNo, WorkOrder.RY, WorkOrder.BWBH, BWZL.ZWSM, BWZL.YWSM INTO #Part FROM ( " +
                    "  SELECT DISTINCT ListNo, RY, LTRIM(RTRIM(Split.a.value('.', 'VARCHAR(100)'))) 'BWBH' FROM ( " +
                    "    SELECT ListNo, RY, CAST('<M>' + REPLACE(Part, ',', '</M><M>') + '</M>' AS XML) AS Data FROM #WorkOrder " +
                    "  ) AS A " +
                    "  CROSS APPLY Data.nodes('/M') AS Split(a) " +
                    ") AS WorkOrder " +
                    "LEFT JOIN BWZL ON BWZL.BWDH = WorkOrder.BWBH; " +

                    "SELECT ListNo, PlanDate, Machine, MAX(DAOMH) AS DAOMH, RY, PartZH, PartEN, SUM(Pairs) AS Pairs, SUM(Qty) AS Qty, SUM(ScanQty) AS ScanQty FROM ( " +
                    "  SELECT #WorkOrder.ListNo, CONVERT(VARCHAR, #WorkOrder.PlanDate, 111) AS PlanDate, #WorkOrder.Machine, #WorkOrder.DAOMH, RYList.RY, " +
                    "  RYList.PartZH, RYList.PartEN, SMDD.YSBH, SMDD.DDBH, SUM(SMDD.Pairs) AS Pairs, #WorkOrder.Qty, #WorkOrder.ScanQty FROM #WorkOrder " +
                    "  LEFT JOIN ( " +
                    "    SELECT DISTINCT ListNo, STUFF(( " +
                    "      SELECT ',' + RY FROM #WorkOrder AS W2 " +
                    "      WHERE W2.ListNo = W1.ListNo " +
                    "      ORDER BY RY " +
                    "      FOR XML PATH('') " +
                    "    ), 1, 1, '') AS RY, STUFF(( " +
                    "      SELECT ',[' + BWBH + '] ' + ZWSM FROM ( " +
                    "        SELECT DISTINCT ListNo, BWBH, ZWSM FROM #Part " +
                    "      ) AS P2 " +
                    "      WHERE P2.ListNo = W1.ListNo " +
                    "      ORDER BY Part " +
                    "      FOR XML PATH('') " +
                    "    ), 1, 1, '') AS PartZH, STUFF(( " +
                    "      SELECT ',[' + BWBH + '] ' + YWSM FROM ( " +
                    "        SELECT DISTINCT ListNo, BWBH, YWSM FROM #Part " +
                    "      ) AS P2 " +
                    "      WHERE P2.ListNo = W1.ListNo " +
                    "      ORDER BY Part " +
                    "      FOR XML PATH('') " +
                    "    ), 1, 1, '') AS PartEN FROM #WorkOrder AS W1 " +
                    "  ) AS RYList ON RYList.ListNo = #WorkOrder.ListNo " +
                    "  LEFT JOIN ( " +
                    "    SELECT YSBH, DDBH, Qty AS Pairs FROM SMDD " +
                    "    WHERE YSBH IN (SELECT DISTINCT RY FROM #WorkOrder) " +
                    "    AND DDBH IN ( " +
                    "      SELECT DISTINCT LTRIM(RTRIM(Split.a.value('.', 'VARCHAR(300)'))) 'Cycle' FROM ( " +
                    "        SELECT CAST('<M>' + REPLACE(Cycle, ',', '</M><M>') + '</M>' AS XML) AS Data FROM #WorkOrder " +
                    "      ) AS A " +
                    "      CROSS APPLY Data.nodes('/M') AS Split(a) " +
                    "    ) AND GXLB = 'C' " +
                    "  ) AS SMDD ON SMDD.YSBH = #WorkOrder.RY " +
                    "  LEFT JOIN ( " +
                    "    SELECT DISTINCT RY, BWBH FROM #Part " +
                    "  ) AS BWZL ON BWZL.RY = #WorkOrder.RY " +
                    "  GROUP BY #WorkOrder.ListNo, CONVERT(VARCHAR, #WorkOrder.PlanDate, 111), #WorkOrder.Machine, #WorkOrder.DAOMH, " +
                    "  RYList.RY, RYList.PartZH, RYList.PartEN, SMDD.YSBH, SMDD.DDBH, #WorkOrder.Qty, #WorkOrder.ScanQty " +
                    ") AS WorkOrder " +
                    "GROUP BY ListNo, PlanDate, Machine, RY, PartZH, PartEN; "
                    , request.MachineID, request.PlanStartDate
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<EmmaWorkOrderResult> workOrderList = new List<EmmaWorkOrderResult>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    EmmaWorkOrderResult workOrder = new EmmaWorkOrderResult();
                    workOrder.ListNo = dt.Rows[i]["ListNo"].ToString();
                    workOrder.Machine = dt.Rows[i]["Machine"].ToString();
                    workOrder.PlanDate = dt.Rows[i]["PlanDate"].ToString();
                    workOrder.DieCut = dt.Rows[i]["DAOMH"].ToString();
                    workOrder.RY = dt.Rows[i]["RY"].ToString();
                    workOrder.ZH = dt.Rows[i]["PartZH"].ToString();
                    workOrder.EN = dt.Rows[i]["PartEN"].ToString();
                    workOrder.VI = dt.Rows[i]["PartEN"].ToString();
                    workOrder.Pairs = (int)dt.Rows[i]["Pairs"];

                    if ((int)dt.Rows[i]["ScanQty"] < (int)dt.Rows[i]["Qty"])
                    {
                        workOrder.Status = "InProduction";
                    }
                    else
                    {
                        workOrder.Status = "Completed";
                    }

                    workOrderList.Add(workOrder);
                }

                return JsonConvert.SerializeObject(workOrderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getAutoCuttingWorkOrderInfo")]
        public string getAutoCuttingWorkOrderInfo(EmmaRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SET ARITHABORT ON; " +
                    "IF OBJECT_ID('tempdb..#Part') IS NOT NULL " +
                    "BEGIN DROP TABLE #Part END; " +

                    "SELECT RY, Part, ZWSM, YWSM INTO #Part FROM ( " +
                    "  SELECT RY, LTRIM(RTRIM(Split.a.value('.', 'VARCHAR(100)'))) 'Part' FROM ( " +
                    "    SELECT RY, CAST ('<M>' + REPLACE(Part, ',', '</M><M>') + '</M>' AS XML) AS Data FROM CutDispatchS_Auto WHERE ListNo = '{0}' " +
                    "  ) AS A " +
                    "  CROSS APPLY Data.nodes ('/M') AS Split(a) " +
                    ") AS A " +
                    "LEFT JOIN BWZL ON BWZL.BWDH = A.Part " +

                    "SELECT CutDispatch_Auto.ListNo, CONVERT(VARCHAR, CutDispatch_Auto.PlanDate, 111) AS PlanDate, CutDispatch_Auto.Machine, " +
                    "CutDispatchS_Auto.RY, BWZL.PartZH, BWZL.PartEN, CutDispatchS_Auto.Cycle, CutDispatchS_Auto.ScanQty FROM CutDispatch_Auto " +
                    "LEFT JOIN CutDispatchS_Auto ON CutDispatchS_Auto.ListNo = CutDispatch_Auto.ListNo " +
                    "LEFT JOIN ( " +
                    "  SELECT DISTINCT RY, STUFF(( " +
                    "    SELECT ',[' + Part + '] ' + ZWSM FROM #Part AS P2 " +
                    "    WHERE P2.RY = P1.RY " +
                    "    FOR XML PATH('') " +
                    "  ), 1, 1, '') AS PartZH, STUFF(( " +
                    "    SELECT ',[' + Part + '] ' + YWSM FROM #Part AS P2 " +
                    "    WHERE P2.RY = P1.RY " +
                    "    FOR XML PATH('') " +
                    "  ), 1, 1, '') AS PartEN FROM #Part AS P1 " +
                    ") AS BWZL ON BWZL.RY = CutDispatchS_Auto.RY " +
                    "WHERE CutDispatch_Auto.ListNo = '{0}' " +
                    "ORDER BY CutDispatchS_Auto.RY "
                    , request.WorkOrder
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<EmmaWorkOrderInfoResult> workOrderList = new List<EmmaWorkOrderInfoResult>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    EmmaWorkOrderInfoResult workOrder = new EmmaWorkOrderInfoResult();
                    workOrder.ListNo = dt.Rows[i]["ListNo"].ToString();
                    workOrder.Machine = dt.Rows[i]["Machine"].ToString();
                    workOrder.PlanDate = dt.Rows[i]["PlanDate"].ToString();
                    workOrder.RY = dt.Rows[i]["RY"].ToString();
                    workOrder.ZH = dt.Rows[i]["PartZH"].ToString();
                    workOrder.EN = dt.Rows[i]["PartEN"].ToString();
                    workOrder.VI = dt.Rows[i]["PartEN"].ToString();
                    workOrder.Cycle = dt.Rows[i]["Cycle"].ToString();
                    workOrder.ScanQty = (int)dt.Rows[i]["ScanQty"];

                    workOrderList.Add(workOrder);
                }

                return JsonConvert.SerializeObject(workOrderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getRY")]
        public string getRY(EmmaRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da;
            if (request.Building!.Length > 0)
            {
                da = new SqlDataAdapter(
                    System.String.Format(
                        "SELECT DDZL.DDBH, DDZL.Article, REPLACE(XXZL.DAOMH, 'LY-', '') AS DAOMH, DDZL.Pairs FROM schedule_crawler AS SC " +
                        "LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END " +
                        "LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                        "WHERE SC.building_no = '{0}' AND SC.lean_no LIKE '{1}%' AND SC.schedule_date >= LEFT(CONVERT(VARCHAR, GETDATE(), 111), 7) + '/01' " +
                        "AND DDZL.ARTICLE LIKE '{2}%' AND DDZL.DDBH LIKE '{3}%' " +
                        "ORDER BY SC.schedule_date, SC.ry_index "
                        , request.Building, request.Lean, request.Model, request.RY
                    ), ERP
                );
            }
            else
            {
                da = new SqlDataAdapter(
                    System.String.Format(
                        "SELECT DDZL.DDBH, DDZL.Article, REPLACE(XXZL.DAOMH, 'LY-', '') AS DAOMH, DDZL.Pairs FROM DDZL " +
                        "LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                        "WHERE DDZL.DDZT = 'Y' AND DDZL.DDBH LIKE '{0}%' " +
                        "ORDER BY DDZL.DDBH "
                        , request.RY
                    ), ERP
                );
            }
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<MonthOrderResult> orderList = new List<MonthOrderResult>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    MonthOrderResult order = new MonthOrderResult();
                    order.Order = dt.Rows[i]["DDBH"].ToString();
                    order.DieCut = dt.Rows[i]["DAOMH"].ToString();
                    order.SKU = dt.Rows[i]["Article"].ToString();
                    order.Pairs = (int)dt.Rows[i]["Pairs"];

                    orderList.Add(order);
                }

                return JsonConvert.SerializeObject(orderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("generateAutoCuttingWorkOrder")]
        public string generateAutoCuttingWorkOrder(EmmaWorkOrderRequest request)
        {
            string insertSQL = string.Empty;
            string whereSQL = string.Empty;
            string whereSQL2 = string.Empty;
            string[] ry = request.RY.Split(";");
            string[] part = request.Part.Split(";");
            string[] cycle = request.Cycle.Split(";");

            for (int i = 0; i < ry.Length; i++)
            {
                whereSQL += System.String.Format(
                    "(SMDD.YSBH = '{0}' AND SMDD.DDBH IN ('{1}')) " + (i < ry.Length - 1 ? "OR " : "")
                    , ry[i], cycle[i].Replace(",", "','")
                );

                whereSQL2 += System.String.Format(
                    "(CutDispatchZL.ZLBH = '{0}' AND CutDispatchZL.BWBH IN ('{1}')) " + (i < ry.Length - 1 ? "OR " : "")
                    , ry[i], part[i].Replace(",", "','")
                );

                insertSQL += System.String.Format(
                    "  SELECT '{0}' AS RY, '{1}' AS Part, '{2}' AS Cycle "
                    , ry[i], part[i], cycle[i]
                ) + (i < ry.Length - 1 ? "UNION ALL " : "");
            }

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlCommand SQL = new SqlCommand(
                System.String.Format(
                    "SET ARITHABORT ON; " +
                    "IF OBJECT_ID('tempdb..#CutDispatch') IS NOT NULL " +
                    "BEGIN DROP TABLE #CutDispatch END; " +

                    "DECLARE @Seq AS Int = ( " +
                    "  SELECT ISNULL(MAX(CAST(SUBSTRING(DLNO, 7, 5) AS INT)), 0) AS DLNO FROM CutDispatch " +
                    "  WHERE DLNO LIKE SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + '%' " +
                    "); " +

                    "SELECT SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + RIGHT('0000' + CAST(@Seq + 1 AS VARCHAR), 5) AS DLNO, SMDD.ZLBH, SMDD.DDBH, CutDispatchZL.BWBH, " +
                    "CutDispatchZL.SIZE, CutDispatchZL.XXCC, CutDispatchZL.CLBH, SMDD.Qty, CASE WHEN ISNULL(CutDispatchZL.CutNum, 0) = 0 THEN SMDD.Qty ELSE CutDispatchZL.CutNum END AS CutNum, " +
                    "0 AS ScanQty, 0 AS QRCode, '' AS Machine, NULL AS MachineDate, NULL AS MachineEndDate, '{2}' AS UserID, GETDATE() AS UserDate, '1' AS YN INTO #CutDispatch FROM ( " +
                    "  SELECT SMDD.YSBH AS ZLBH, SMDD.DDBH, SMDDS.XXCC, SMDDS.Qty FROM SMDD " +
                    "  LEFT JOIN SMDDS ON SMDDS.DDBH = SMDD.DDBH " +
                    "  WHERE SMDD.GXLB = 'C' AND (" + whereSQL + ") " +
                    ") AS SMDD " +
                    "LEFT JOIN( " +
                    "  SELECT ZLBH, BWBH, CLBH, SIZE, XXCC, Qty, CutNum FROM CutDispatchZL " +
                    "  WHERE (" + whereSQL2 + ") " +
                    ") AS CutDispatchZL ON CutDispatchZL.ZLBH = SMDD.ZLBH AND CutDispatchZL.SIZE = SMDD.XXCC " +
                    "LEFT JOIN CutDispatchSS ON CutDispatchSS.ZLBH = SMDD.ZLBH AND CutDispatchSS.DDBH = SMDD.DDBH AND CutDispatchSS.BWBH = CutDispatchZL.BWBH AND CutDispatchSS.CLBH = CutDispatchZL.CLBH AND CutDispatchSS.SIZE = CutDispatchZL.SIZE " +
                    "WHERE CutDispatchSS.ZLBH IS NULL; " +

                    "INSERT INTO CutDispatch (DLNO, DLLB, GSBH, DepID, PlanDate, Memo, CustomLayers, USERID, USERDATE, YN) " +
                    "SELECT DISTINCT DLNO, '{1}' AS DLLB, '{4}' AS GSBH, '{3}' AS DepID, '{0}' AS PlanDate, '' AS Memo, NULL AS CustomLayers, UserID, UserDate, YN FROM #CutDispatch " +
                    "GROUP BY DLNO, ZLBH, BWBH, SIZE, CLBH, XXCC, UserID, UserDate, YN; " +

                    "INSERT INTO CutDispatchS (DLNO, ZLBH, BWBH, SIZE, CLBH, Qty, XXCC, CutNum, okCutNum, USERID, USERDATE, ScanUser, ScanDate, YN) " +
                    "SELECT DLNO, ZLBH, BWBH, SIZE, CLBH, SUM(Qty) AS Qty, XXCC, SUM(CutNum) AS CutNum, 0 AS okCutNum, UserID, UserDate, '' AS ScanUser, NULL AS ScanDate, YN FROM #CutDispatch " +
                    "GROUP BY DLNO, ZLBH, BWBH, SIZE, CLBH, XXCC, UserID, UserDate, YN; " +

                    "INSERT INTO CutDispatchSS (DLNO, ZLBH, DDBH, BWBH, SIZE, CLBH, Qty, ScanQty, QRCode, Machine, MachineDate, MachineEndDate, USERID, USERDATE, YN) " +
                    "SELECT DLNO, ZLBH, DDBH, BWBH, SIZE, CLBH, Qty, ScanQty, QRCode, Machine, MachineDate, MachineEndDate, UserID, UserDate, YN FROM #CutDispatch; " +

                    "DECLARE @Seq1 AS Int = ( " +
                    "  SELECT ISNULL(MAX(CAST(SUBSTRING(ListNo, 7, 5) AS INT)), 0) AS ListNo FROM CutDispatch_Auto " +
                    "  WHERE ListNo LIKE SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + '%' " +
                    "); " +

                    "DECLARE @DLNO VARCHAR(12) = ( " +
                    "  SELECT ISNULL((SELECT DLNO FROM CutDispatch WHERE DLNO = SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + RIGHT('0000' + CAST(@Seq + 1 AS VARCHAR), 5)), '') AS DLNO " +
                    "); " +

                    "INSERT INTO CutDispatch_Auto (ListNo, PlanDate, Machine, StartTime, EndTime, DLNO, UserID, UserDate, YN) " +
                    "SELECT SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + RIGHT('0000' + CAST(@Seq1 + 1 AS VARCHAR), 5) AS ListNo, '{0}' AS PlanDate, '{1}' AS Machine, NULL AS StartTime, NULL AS EndTime, @DLNO AS DLNO, '{2}' AS UserID, GETDATE() AS UserDate, '1' AS YN; " +

                    "IF OBJECT_ID('tempdb..#WorkOrder') IS NOT NULL " +
                    "BEGIN DROP TABLE #WorkOrder END; " +

                    "SELECT RY, Part, Cycle INTO #WorkOrder FROM ( " +
                    insertSQL +
                    ") AS WorkOrder; " +

                    "INSERT INTO CutDispatchS_Auto (ListNo, RY, Part, Cycle, Qty, ScanQty, StartTime, EndTime, UserID, UserDate, YN) " +
                    "SELECT SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + RIGHT('0000' + CAST(@Seq1 + 1 AS VARCHAR), 5) AS ListNo, RY, Part, Cycle, SUM(Pairs) AS Qty, 0 AS ScanQty, NULL AS StartTime, NULL AS EndTime, '{2}' AS UserID, GETDATE() AS UserDate, '1' AS YN FROM ( " +
                    "  SELECT #WorkOrder.RY, #WorkOrder.Part, #WorkOrder.Cycle, SMDD.DDBH, BWZL.BWBH, SMDD.Pairs FROM #WorkOrder " +
                    "  LEFT JOIN ( " +
                    "    SELECT YSBH, DDBH, Qty AS Pairs FROM SMDD " +
                    "    WHERE YSBH IN (SELECT DISTINCT RY FROM #WorkOrder) " +
                    "    AND DDBH IN ( " +
                    "      SELECT DISTINCT LTRIM(RTRIM(Split.a.value('.', 'VARCHAR(300)'))) 'Cycle' FROM ( " +
                    "        SELECT CAST('<M>' + REPLACE(Cycle, ',', '</M><M>') + '</M>' AS XML) AS Data FROM #WorkOrder " +
                    "      ) AS A " +
                    "      CROSS APPLY Data.nodes('/M') AS Split(a) " +
                    "    ) AND GXLB = 'C' " +
                    "  ) AS SMDD ON SMDD.YSBH = #WorkOrder.RY " +
                    "  LEFT JOIN ( " +
                    "    SELECT WorkOrder.RY, WorkOrder.BWBH FROM ( " +
                    "      SELECT DISTINCT RY, LTRIM(RTRIM(Split.a.value('.', 'VARCHAR(100)'))) 'BWBH' FROM ( " +
                    "        SELECT RY, CAST('<M>' + REPLACE(Part, ',', '</M><M>') + '</M>' AS XML) AS Data FROM #WorkOrder " +
                    "      ) AS A " +
                    "      CROSS APPLY Data.nodes('/M') AS Split(a) " +
                    "    ) AS WorkOrder " +
                    "  ) AS BWZL ON BWZL.RY = #WorkOrder.RY " +
                    ") AS Info " +
                    "GROUP BY RY, Part, Cycle; "
                    , request.PlanDate, request.MachineID, request.UserID, request.Department, request.Factory
                ), ERP
            );

            ERP.Open();
            int recordCount = SQL.ExecuteNonQuery();
            ERP.Dispose();


            if (recordCount > 0)
            {
                return "{\"statusCode\": 200}";
            }
            else
            {
                return "{\"statusCode\": 400}";
            }
        }

        [HttpPost]
        [Route("updateAutoCuttingWorkOrder")]
        public string updateAutoCuttingWorkOrder(EmmaWorkOrderRequest request)
        {
            string insertSQL = string.Empty;
            string whereSQL = string.Empty;
            string whereSQL2 = string.Empty;
            string[] ry = request.RY.Split(";");
            string[] part = request.Part.Split(";");
            string[] cycle = request.Cycle.Split(";");

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT ListNo FROM CutDispatchS_Auto WHERE ListNo = '{0}' AND ScanQty > 0 "
                    , request.ListNo
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count == 0)
            {
                for (int i = 0; i < ry.Length; i++)
                {
                    whereSQL += System.String.Format(
                       "(SMDD.YSBH = '{0}' AND SMDD.DDBH IN ('{1}')) " + (i < ry.Length - 1 ? "OR " : "")
                       , ry[i], cycle[i].Replace(",", "','")
                    );

                    whereSQL2 += System.String.Format(
                        "(CutDispatchZL.ZLBH = '{0}' AND CutDispatchZL.BWBH IN ('{1}')) " + (i < ry.Length - 1 ? "OR " : "")
                        , ry[i], part[i].Replace(",", "','")
                    );

                    insertSQL += System.String.Format(
                        "  SELECT '{0}' AS RY, '{1}' AS Part, '{2}' AS Cycle "
                        , ry[i], part[i], cycle[i]
                    ) + (i < ry.Length - 1 ? "UNION ALL " : "");
                }

                SqlCommand SQL = new SqlCommand(
                    System.String.Format(
                        "SET ARITHABORT ON; " +
                        "DECLARE @DLNO VARCHAR(12) = ( " +
                        "  SELECT DLNO FROM CutDispatch_Auto WHERE ListNo = '{0}' " +
                        "); " +

                        "IF LEN(@DLNO) = 11 " +
                        "BEGIN " +
                        "  DELETE FROM CutDispatch WHERE DLNO = @DLNO; " +
                        "  DELETE FROM CutDispatchS WHERE DLNO = @DLNO; " +
                        "  DELETE FROM CutDispatchSS WHERE DLNO = @DLNO; " +
                        "END; " +

                        "IF OBJECT_ID('tempdb..#CutDispatch') IS NOT NULL " +
                        "BEGIN DROP TABLE #CutDispatch END; " +

                        "DECLARE @Seq AS Int = ( " +
                        "  SELECT ISNULL(MAX(CAST(SUBSTRING(DLNO, 7, 5) AS INT)), 0) AS DLNO FROM CutDispatch " +
                        "  WHERE DLNO LIKE SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + '%' " +
                        "); " +

                        "SELECT SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + RIGHT('0000' + CAST(@Seq + 1 AS VARCHAR), 5) AS DLNO, SMDD.ZLBH, SMDD.DDBH, CutDispatchZL.BWBH, " +
                        "CutDispatchZL.SIZE, CutDispatchZL.XXCC, CutDispatchZL.CLBH, SMDD.Qty, CASE WHEN ISNULL(CutDispatchZL.CutNum, 0) = 0 THEN SMDD.Qty ELSE CutDispatchZL.CutNum END AS CutNum, " +
                        "0 AS ScanQty, 0 AS QRCode, '' AS Machine, NULL AS MachineDate, NULL AS MachineEndDate, '{3}' AS UserID, GETDATE() AS UserDate, '1' AS YN INTO #CutDispatch FROM ( " +
                        "  SELECT SMDD.YSBH AS ZLBH, SMDD.DDBH, SMDDS.XXCC, SMDDS.Qty FROM SMDD " +
                        "  LEFT JOIN SMDDS ON SMDDS.DDBH = SMDD.DDBH " +
                        "  WHERE SMDD.GXLB = 'C' AND (" + whereSQL + ") " +
                        ") AS SMDD " +
                        "LEFT JOIN( " +
                        "  SELECT ZLBH, BWBH, CLBH, SIZE, XXCC, Qty, CutNum FROM CutDispatchZL " +
                        "  WHERE (" + whereSQL2 + ") " +
                        ") AS CutDispatchZL ON CutDispatchZL.ZLBH = SMDD.ZLBH AND CutDispatchZL.SIZE = SMDD.XXCC " +
                        "LEFT JOIN CutDispatchSS ON CutDispatchSS.ZLBH = SMDD.ZLBH AND CutDispatchSS.DDBH = SMDD.DDBH AND CutDispatchSS.BWBH = CutDispatchZL.BWBH AND CutDispatchSS.CLBH = CutDispatchZL.CLBH AND CutDispatchSS.SIZE = CutDispatchZL.SIZE " +
                        "WHERE CutDispatchSS.ZLBH IS NULL; " +

                        "INSERT INTO CutDispatch (DLNO, DLLB, GSBH, DepID, PlanDate, Memo, CustomLayers, USERID, USERDATE, YN) " +
                        "SELECT DISTINCT DLNO, '{2}' AS DLLB, '{5}' AS GSBH, '{4}' AS DepID, '{1}' AS PlanDate, '' AS Memo, NULL AS CustomLayers, UserID, UserDate, YN FROM #CutDispatch " +
                        "GROUP BY DLNO, ZLBH, BWBH, SIZE, CLBH, XXCC, UserID, UserDate, YN; " +

                        "INSERT INTO CutDispatchS (DLNO, ZLBH, BWBH, SIZE, CLBH, Qty, XXCC, CutNum, okCutNum, USERID, USERDATE, ScanUser, ScanDate, YN) " +
                        "SELECT DLNO, ZLBH, BWBH, SIZE, CLBH, SUM(Qty) AS Qty, XXCC, SUM(CutNum) AS CutNum, 0 AS okCutNum, UserID, UserDate, '' AS ScanUser, NULL AS ScanDate, YN FROM #CutDispatch " +
                        "GROUP BY DLNO, ZLBH, BWBH, SIZE, CLBH, XXCC, UserID, UserDate, YN; " +

                        "INSERT INTO CutDispatchSS (DLNO, ZLBH, DDBH, BWBH, SIZE, CLBH, Qty, ScanQty, QRCode, Machine, MachineDate, MachineEndDate, USERID, USERDATE, YN) " +
                        "SELECT DLNO, ZLBH, DDBH, BWBH, SIZE, CLBH, Qty, ScanQty, QRCode, Machine, MachineDate, MachineEndDate, UserID, UserDate, YN FROM #CutDispatch; " +

                        "DECLARE @DLNO1 VARCHAR(12) = ( " +
                        "  SELECT ISNULL((SELECT DLNO FROM CutDispatch WHERE DLNO = SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + RIGHT('0000' + CAST(@Seq + 1 AS VARCHAR), 5)), '') AS DLNO " +
                        "); " +

                        "UPDATE CutDispatch_Auto SET PlanDate = '{1}', Machine = '{2}', DLNO = @DLNO1, UserID = '{3}', UserDate = GETDATE() " +
                        "WHERE ListNo = '{0}'; " +

                        "DELETE FROM CutDispatchS_Auto WHERE ListNo = '{0}'; " +

                        "IF OBJECT_ID('tempdb..#WorkOrder') IS NOT NULL " +
                        "BEGIN DROP TABLE #WorkOrder END; " +

                        "SELECT RY, Part, Cycle INTO #WorkOrder FROM ( " +
                        insertSQL +
                        ") AS WorkOrder; " +

                        "INSERT INTO CutDispatchS_Auto (ListNo, RY, Part, Cycle, Qty, ScanQty, StartTime, EndTime, UserID, UserDate, YN) " +
                        "SELECT '{0}' AS ListNo, RY, Part, Cycle, SUM(Pairs) AS Qty, 0 AS ScanQty, NULL AS StartTime, NULL AS EndTime, '{3}' AS UserID, GETDATE() AS UserDate, '1' AS YN FROM ( " +
                        "  SELECT #WorkOrder.RY, #WorkOrder.Part, #WorkOrder.Cycle, SMDD.DDBH, BWZL.BWBH, SMDD.Pairs FROM #WorkOrder " +
                        "  LEFT JOIN ( " +
                        "    SELECT YSBH, DDBH, Qty AS Pairs FROM SMDD " +
                        "    WHERE YSBH IN (SELECT DISTINCT RY FROM #WorkOrder) " +
                        "    AND DDBH IN ( " +
                        "      SELECT DISTINCT LTRIM(RTRIM(Split.a.value('.', 'VARCHAR(300)'))) 'Cycle' FROM ( " +
                        "        SELECT CAST('<M>' + REPLACE(Cycle, ',', '</M><M>') + '</M>' AS XML) AS Data FROM #WorkOrder " +
                        "      ) AS A " +
                        "      CROSS APPLY Data.nodes('/M') AS Split(a) " +
                        "    ) AND GXLB = 'C' " +
                        "  ) AS SMDD ON SMDD.YSBH = #WorkOrder.RY " +
                        "  LEFT JOIN ( " +
                        "    SELECT WorkOrder.RY, WorkOrder.BWBH FROM ( " +
                        "      SELECT DISTINCT RY, LTRIM(RTRIM(Split.a.value('.', 'VARCHAR(100)'))) 'BWBH' FROM ( " +
                        "        SELECT RY, CAST('<M>' + REPLACE(Part, ',', '</M><M>') + '</M>' AS XML) AS Data FROM #WorkOrder " +
                        "      ) AS A " +
                        "      CROSS APPLY Data.nodes('/M') AS Split(a) " +
                        "    ) AS WorkOrder " +
                        "  ) AS BWZL ON BWZL.RY = #WorkOrder.RY " +
                        ") AS Info " +
                        "GROUP BY RY, Part, Cycle; "
                        , request.ListNo, request.PlanDate, request.MachineID, request.UserID, request.Department, request.Factory
                    ), ERP
                );

                ERP.Open();
                int recordCount = SQL.ExecuteNonQuery();
                ERP.Dispose();


                if (recordCount > 0)
                {
                    return "{\"statusCode\": 200}";
                }
                else
                {
                    return "{\"statusCode\": 400}";
                }
            }
            else
            {
                return "{\"statusCode\": 401}";
            }
        }

        [HttpPost]
        [Route("deleteAutoCuttingWorkOrder")]
        public string deleteAutoCuttingWorkOrder(EmmaWorkOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT ListNo FROM CutDispatchS_Auto WHERE ListNo = '{0}' AND ScanQty > 0 "
                    , request.ListNo
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count == 0)
            {
                SqlCommand SQL = new SqlCommand(
                    System.String.Format(
                        "DECLARE @DLNO VARCHAR(12) = ( " +
                        "  SELECT DLNO FROM CutDispatch_Auto WHERE ListNo = '{0}' " +
                        "); " +

                        "IF LEN(@DLNO) = 11 " +
                        "BEGIN " +
                        "  DELETE FROM CutDispatch WHERE DLNO = @DLNO; " +
                        "  DELETE FROM CutDispatchS WHERE DLNO = @DLNO; " +
                        "  DELETE FROM CutDispatchSS WHERE DLNO = @DLNO; " +
                        "END; " +

                        "DELETE FROM CutDispatch_Auto WHERE ListNo = '{0}'; " +
                        "DELETE FROM CutDispatchS_Auto WHERE ListNo = '{0}'; "
                        , request.ListNo
                    ), ERP
                );

                ERP.Open();
                int recordCount = SQL.ExecuteNonQuery();
                ERP.Dispose();


                if (recordCount > 0)
                {
                    return "{\"statusCode\": 200}";
                }
                else
                {
                    return "{\"statusCode\": 400}";
                }
            }
            else
            {
                return "{\"statusCode\": 401}";
            }
        }

        [HttpPost]
        [Route("reportAutoCuttingWorkOrder")]
        public string reportAutoCuttingWorkOrder(EmmaWorkOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlCommand SQL = new SqlCommand(
                System.String.Format(
                    "DECLARE @DLNO VARCHAR(12) = ( " +
                    "  SELECT DLNO FROM CutDispatch_Auto WHERE ListNo = '{0}' " +
                    "); " +

                    "IF LEN(@DLNO) = 11 " +
                    "BEGIN " +
                    "  UPDATE CutDispatchS SET okCutNum = CutNum, ScanUser = '{1}', ScanDate = GetDate() WHERE DLNO = @DLNO; " +
                    "  UPDATE CutDispatchSS SET ScanQty = Qty, Machine = 'App', MachineDate = GetDate(), MachineEndDate = GetDate() WHERE DLNO = @DLNO " +
                    "END; " +

                    "UPDATE CutDispatch_Auto SET StartTime = GetDate(), EndTime = GetDate() WHERE ListNo = '{0}'; " +
                    "UPDATE CutDispatchS_Auto SET ScanQty = Qty, StartTime = GetDate(), EndTime = GetDate() WHERE ListNo = '{0}'; "
                    , request.ListNo, request.UserID
                ), ERP
            );

            ERP.Open();
            int recordCount = SQL.ExecuteNonQuery();
            ERP.Dispose();


            if (recordCount > 0)
            {
                return "{\"statusCode\": 200}";
            }
            else
            {
                return "{\"statusCode\": 400}";
            }
        }

        [HttpPost]
        [Route("setCuttingPart")]
        public string setCuttingPart(EmmaWorkOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlCommand SQL = new SqlCommand(
                System.String.Format(
                    "INSERT INTO KT_SOPCut (XieXing, SheHao, BWBH, Type, piece, layer, joinnum, LRcom, PartID, IMGName, USERID, USERDATE, YN) " +
                    "SELECT DDZL.XieXing, DDZL.SheHao, ZLZLS2.BWBH, NULL, 1, 1, 0, 0, NULL, NULL, 'System', GETDATE(), '1' FROM ZLZLS2 " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = ZLZLS2.ZLBH " +
                    "WHERE ZLZLS2.ZLBH = '{0}' AND ZLZLS2.MJBH = 'ZZZZZZZZZZ' AND ZLZLS2.BWBH IN ({1}) AND ZLZLS2.BWBH NOT IN ( " +
                    "  SELECT DISTINCT KT_SOPCut.BWBH FROM DDZL " +
                    "  LEFT JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao " +
                    "  WHERE DDZL.DDBH = '{0}' AND KT_SOPCut.BWBH IN ({1}) " +
                    "); " +

                    "UPDATE KT_SOPCut SET piece = 1, layer = 1 " +
                    "WHERE XieXing = (SELECT XieXing FROM DDZL WHERE DDBH = '{0}') AND SheHao = (SELECT SheHao FROM DDZL WHERE DDBH = '{0}') " +
                    "AND BWBH IN ({1}) AND piece = 0; " +

                    "INSERT INTO KT_SOPCutS (XieXing, SheHao, BWBH, SIZE, XXCC, USERID, USERDATE, YN) " +
                    "SELECT DDZL.XieXing, DDZL.SheHao, ZLZLS2.BWBH, XXCC, GJCC, 'System', GETDATE(), '1' FROM ZLZLS2 " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = ZLZLS2.ZLBH " +
                    "LEFT JOIN XXGJS ON XXGJS.XieXing = DDZL.XieXing AND XXGJS.GJLB = '100' " +
                    "WHERE ZLZLS2.ZLBH = '{0}' AND ZLZLS2.MJBH = 'ZZZZZZZZZZ' AND ZLZLS2.BWBH IN ({1}) AND ZLZLS2.BWBH NOT IN ( " +
                    "  SELECT DISTINCT KT_SOPCutS.BWBH FROM DDZL " +
                    "  LEFT JOIN KT_SOPCutS ON KT_SOPCutS.XieXing = DDZL.XieXing AND KT_SOPCutS.SheHao = DDZL.SheHao " +
                    "  WHERE DDZL.DDBH = '{0}' AND KT_SOPCutS.BWBH IN ({1}) " +
                    "); " +

                    "UPDATE KT_SOPCut SET Type = Data.Type " +
                    "FROM ( " +
                    "  SELECT KT_SOPCut.XieXing, KT_SOPCut.SheHao, KT_SOPCut.BWBH, CASE WHEN KT_SOPCut.BWBH IN ({1}) THEN ISNULL(KT_SOPCut.Type, 'Manual') ELSE NULL END AS Type FROM DDZL " +
                    "  LEFT JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao " +
                    "  WHERE DDZL.DDBH = '{0}' AND KT_SOPCut.XieXing IS NOT NULL " +
                    ") AS Data " +
                    "WHERE KT_SOPCut.XieXing = Data.XieXing AND KT_SOPCut.SheHao = Data.SheHao AND KT_SOPCut.BWBH = Data.BWBH; " +

                    "DELETE FROM CutDispatchZL " +
                    "FROM ( " +
                    "  SELECT XieXing, SheHao, BWBH FROM KT_SOPCut " +
                    "  WHERE XieXing = (SELECT XieXing FROM DDZL WHERE DDBH = '{0}') AND SheHao = (SELECT SheHao FROM DDZL WHERE DDBH = '{0}') " +
                    "  AND Type IS NULL " +
                    ") AS Data " +
                    "WHERE CutDispatchZL.ZLBH = '{0}' AND CutDispatchZL.BWBH = Data.BWBH; " +

                    "DELETE FROM KT_SOPCutS " +
                    "FROM ( " +
                    "  SELECT XieXing, SheHao, BWBH FROM KT_SOPCut " +
                    "  WHERE XieXing = (SELECT XieXing FROM DDZL WHERE DDBH = '{0}') AND SheHao = (SELECT SheHao FROM DDZL WHERE DDBH = '{0}') " +
                    "  AND Type IS NULL " +
                    ") AS Data " +
                    "WHERE KT_SOPCutS.XieXing = Data.XieXing AND KT_SOPCutS.SheHao = Data.SheHao AND KT_SOPCutS.BWBH = Data.BWBH; " +

                    "UPDATE KT_SOPCut SET piece = 0, layer = 0 " +
                    "WHERE XieXing = (SELECT XieXing FROM DDZL WHERE DDBH = '{0}') AND SheHao = (SELECT SheHao FROM DDZL WHERE DDBH = '{0}') " +
                    "AND Type IS NULL; "
                    , request.RY, request.Part
                ), ERP
            );

            ERP.Open();
            int recordCount = SQL.ExecuteNonQuery();
            ERP.Dispose();

            CheckCuttingData(request.RY);

            if (recordCount > 0)
            {
                return "{\"statusCode\": 200}";
            }
            else
            {
                return "{\"statusCode\": 400}";
            }
        }

        [HttpPost]
        [Route("setAutoCuttingPart")]
        public string setAutoCuttingPart(EmmaWorkOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlCommand SQL = new SqlCommand(
                System.String.Format(
                    "INSERT INTO KT_SOPCut (XieXing, SheHao, BWBH, Type, piece, layer, joinnum, LRcom, PartID, IMGName, USERID, USERDATE, YN) " +
                    "SELECT DDZL.XieXing, DDZL.SheHao, ZLZLS2.BWBH, NULL, 1, 1, 0, 0, NULL, NULL, 'System', GETDATE(), '1' FROM ZLZLS2 " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = ZLZLS2.ZLBH " +
                    "WHERE ZLZLS2.ZLBH = '{0}' AND ZLZLS2.MJBH = 'ZZZZZZZZZZ' AND ZLZLS2.BWBH IN ({1}) AND ZLZLS2.BWBH NOT IN ( " +
                    "  SELECT DISTINCT KT_SOPCut.BWBH FROM DDZL " +
                    "  LEFT JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao " +
                    "  WHERE DDZL.DDBH = '{0}' AND KT_SOPCut.BWBH IN ({1}) " +
                    "); " +

                    "UPDATE KT_SOPCut SET piece = 1, layer = 1 " +
                    "WHERE XieXing = (SELECT XieXing FROM DDZL WHERE DDBH = '{0}') AND SheHao = (SELECT SheHao FROM DDZL WHERE DDBH = '{0}') " +
                    "AND BWBH IN ({1}) AND piece = 0; " +

                    "INSERT INTO KT_SOPCutS (XieXing, SheHao, BWBH, SIZE, XXCC, USERID, USERDATE, YN) " +
                    "SELECT DDZL.XieXing, DDZL.SheHao, ZLZLS2.BWBH, XXCC, GJCC, 'System', GETDATE(), '1' FROM ZLZLS2 " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = ZLZLS2.ZLBH " +
                    "LEFT JOIN XXGJS ON XXGJS.XieXing = DDZL.XieXing AND XXGJS.GJLB = '100' " +
                    "WHERE ZLZLS2.ZLBH = '{0}' AND ZLZLS2.MJBH = 'ZZZZZZZZZZ' AND ZLZLS2.BWBH IN ({1}) AND ZLZLS2.BWBH NOT IN ( " +
                    "  SELECT DISTINCT KT_SOPCutS.BWBH FROM DDZL " +
                    "  LEFT JOIN KT_SOPCutS ON KT_SOPCutS.XieXing = DDZL.XieXing AND KT_SOPCutS.SheHao = DDZL.SheHao " +
                    "  WHERE DDZL.DDBH = '{0}' AND KT_SOPCutS.BWBH IN ({1}) " +
                    "); " +

                    "UPDATE KT_SOPCut SET Type = Data.Type " +
                    "FROM ( " +
                    "  SELECT KT_SOPCut.XieXing, KT_SOPCut.SheHao, KT_SOPCut.BWBH, CASE WHEN KT_SOPCut.BWBH IN ({1}) THEN 'AutoCutting' ELSE CASE WHEN KT_SOPCut.Type = 'Manual' OR MRCard.BWBH IS NOT NULL THEN 'Manual' ELSE NULL END END AS Type FROM DDZL " +
                    "  LEFT JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao " +
                    "  LEFT JOIN ( " +
                    "    SELECT DISTINCT '{0}' AS ZLBH, ZLZLS2.BWBH FROM MRCardS " +
                    "    LEFT JOIN MRCard ON MRCard.ListNo = MRCardS.ListNo " +
                    "    LEFT JOIN DDZL ON DDZL.DDBH = MRCardS.RY_Begin " +
                    "    LEFT JOIN ZLZLS2 ON ZLZLS2.ZLBH = DDZL.DDBH AND ZLZLS2.CLBH = MRCardS.MaterialID " +
                    "    WHERE DDZL.XieXing = (SELECT XieXing FROM DDZL WHERE DDBH = '{0}') AND DDZL.SheHao = (SELECT SheHao FROM DDZL WHERE DDBH = '{0}') " +
                    "    AND MRCard.Section = 'C' AND ZLZLS2.MJBH = 'ZZZZZZZZZZ' " +
                    "  ) AS MRCard ON MRCard.ZLBH = DDZL.DDBH AND MRCard.BWBH = KT_SOPCut.BWBH " +
                    "  WHERE DDZL.DDBH = '{0}' AND KT_SOPCut.XieXing IS NOT NULL " +
                    ") AS Data " +
                    "WHERE KT_SOPCut.XieXing = Data.XieXing AND KT_SOPCut.SheHao = Data.SheHao AND KT_SOPCut.BWBH = Data.BWBH; " +

                    "DELETE FROM CutDispatchZL " +
                    "FROM ( " +
                    "  SELECT XieXing, SheHao, BWBH FROM KT_SOPCut " +
                    "  WHERE XieXing = (SELECT XieXing FROM DDZL WHERE DDBH = '{0}') AND SheHao = (SELECT SheHao FROM DDZL WHERE DDBH = '{0}') " +
                    "  AND Type IS NULL " +
                    ") AS Data " +
                    "WHERE CutDispatchZL.ZLBH = '{0}' AND CutDispatchZL.BWBH = Data.BWBH; " +

                    "DELETE FROM KT_SOPCutS " +
                    "FROM ( " +
                    "  SELECT XieXing, SheHao, BWBH FROM KT_SOPCut " +
                    "  WHERE XieXing = (SELECT XieXing FROM DDZL WHERE DDBH = '{0}') AND SheHao = (SELECT SheHao FROM DDZL WHERE DDBH = '{0}') " +
                    "  AND Type IS NULL " +
                    ") AS Data " +
                    "WHERE KT_SOPCutS.XieXing = Data.XieXing AND KT_SOPCutS.SheHao = Data.SheHao AND KT_SOPCutS.BWBH = Data.BWBH; " +

                    "UPDATE KT_SOPCut SET piece = 0, layer = 0 " +
                    "WHERE XieXing = (SELECT XieXing FROM DDZL WHERE DDBH = '{0}') AND SheHao = (SELECT SheHao FROM DDZL WHERE DDBH = '{0}') " +
                    "AND Type IS NULL; "
                    , request.RY, request.Part
                ), ERP
            );

            ERP.Open();
            int recordCount = SQL.ExecuteNonQuery();
            ERP.Dispose();

            CheckCuttingData(request.RY);

            if (recordCount > 0)
            {
                return "{\"statusCode\": 200}";
            }
            else
            {
                return "{\"statusCode\": 400}";
            }
        }

        [HttpPost]
        [Route("getLaborDemand")]
        public string getLaborDemand(ScheduleRequest request)
        {
            DateTime firstDate = DateTime.ParseExact(request.Month + "/01", "yyyy/MM/dd", System.Globalization.CultureInfo.InvariantCulture);
            DateTime lastDate = new DateTime(firstDate.Year, firstDate.Month, DateTime.DaysInMonth(firstDate.Year, firstDate.Month));

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#Schedule') IS NOT NULL " +
                    "BEGIN DROP TABLE #Schedule END; " +

                    "SELECT ROW_NUMBER() OVER(PARTITION BY building_no, lean_no ORDER BY schedule_date) AS Seq, building_no, lean_no, schedule_date, " +
                    "MAX(C_DL) AS C_DL, MAX(C_IDL) AS C_IDL, MAX(S_DL) AS S_DL, MAX(S_IDL) AS S_IDL, MAX(A_DL) + MAX(P_DL) AS A_DL, MAX(A_IDL) + MAX(P_IDL) AS A_IDL INTO #Schedule FROM ( " +
                    "  SELECT Seq, building_no, lean_no, schedule_date, ry_index, DDBH, ARTICLE, Pairs, C_DL, C_IDL, S_DL, S_IDL, A_DL, A_IDL, P_DL, P_IDL FROM ( " +
                    "    SELECT ROW_NUMBER() OVER(PARTITION BY SC.building_no, SC.lean_no ORDER BY SC.schedule_date, SC.ry_index) AS Seq, " +
                    "    SC.building_no, SC.lean_no, SC.schedule_date, SC.ry_index, DDZL.DDBH, DDZL.ARTICLE, DDZL.Pairs, " +
                    "    ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'C' THEN SCXXCL.BZRS END), 0) AS C_DL, ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'C' THEN SCXXCL.BZJS END), 0) AS C_IDL, " +
                    "    ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'S' THEN SCXXCL.BZRS END), 0) AS S_DL, ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'S' THEN SCXXCL.BZJS END), 0) AS S_IDL, " +
                    "    ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'A' THEN SCXXCL.BZRS END), 0) AS A_DL, ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'A' THEN SCXXCL.BZJS END), 0) AS A_IDL, " +
                    "    ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'P' THEN SCXXCL.BZRS END), 0) AS P_DL, ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'P' THEN SCXXCL.BZJS END), 0) AS P_IDL FROM schedule_crawler AS SC " +
                    "    LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END " +
                    "    LEFT JOIN SCXXCL ON SCXXCL.XieXing = DDZL.XieXing AND SCXXCL.SheHao = DDZL.SheHao AND SCXXCL.BZLB = '3' " +
                    "    WHERE SC.schedule_date BETWEEN '{0}' AND '{1}' AND SC.building_no = '{2}' " + (request.Lean != "ALL" ? " AND 'LINE ' + RIGHT('00' + CAST(CAST(RIGHT(SC.lean_no, 2) AS INT) AS VARCHAR), 2) = '{3}' " : "") +
                    "    GROUP BY SC.building_no, SC.lean_no, SC.schedule_date, SC.ry_index, DDZL.DDBH, DDZL.ARTICLE, DDZL.Pairs " +
                    "    UNION ALL " +
                    "    SELECT 0 AS Seq, Schedule.building_no, Schedule.lean_no, Schedule.Date, Schedule.ry_index, DDZL.DDBH, DDZL.ARTICLE, DDZL.Pairs, " +
                    "    ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'C' THEN SCXXCL.BZRS END), 0) AS C_DL, ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'C' THEN SCXXCL.BZJS END), 0) AS C_IDL, " +
                    "    ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'S' THEN SCXXCL.BZRS END), 0) AS S_DL, ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'S' THEN SCXXCL.BZJS END), 0) AS S_IDL, " +
                    "    ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'A' THEN SCXXCL.BZRS END), 0) AS A_DL, ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'A' THEN SCXXCL.BZJS END), 0) AS A_IDL, " +
                    "    ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'P' THEN SCXXCL.BZRS END), 0) AS P_DL, ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'P' THEN SCXXCL.BZJS END), 0) AS P_IDL FROM ( " +
                    "      SELECT Schedule.building_no, Schedule.lean_no, Schedule.Date, MAX(SC.ry_index) AS ry_index FROM ( " +
                    "        SELECT Schedule.building_no, Schedule.lean_no, MAX(SC.schedule_date) AS Date FROM ( " +
                    "          SELECT DISTINCT building_no, lean_no FROM schedule_crawler " +
                    "          WHERE schedule_date BETWEEN '{0}' AND '{1}' AND building_no = '{2}' " + (request.Lean != "ALL" ? " AND 'LINE ' + RIGHT('00' + CAST(CAST(RIGHT(lean_no, 2) AS INT) AS VARCHAR), 2) = '{3}' " : "") +
                    "        ) AS Schedule " +
                    "        LEFT JOIN schedule_crawler AS SC ON SC.building_no = Schedule.building_no AND SC.lean_no = Schedule.lean_no AND SC.schedule_date < '{0}' " +
                    "        GROUP BY Schedule.building_no, Schedule.lean_no " +
                    "      ) AS Schedule " +
                    "      LEFT JOIN schedule_crawler AS SC ON SC.building_no = Schedule.building_no AND SC.lean_no = Schedule.lean_no AND SC.schedule_date = Schedule.Date " +
                    "      GROUP BY Schedule.building_no, Schedule.lean_no, Schedule.Date " +
                    "    ) AS Schedule " +
                    "    LEFT JOIN schedule_crawler AS SC ON SC.building_no = Schedule.building_no AND SC.lean_no = Schedule.lean_no AND SC.schedule_date = Schedule.Date AND SC.ry_index = Schedule.ry_index " +
                    "    LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END " +
                    "    LEFT JOIN SCXXCL ON SCXXCL.XieXing = DDZL.XieXing AND SCXXCL.SheHao = DDZL.SheHao AND SCXXCL.BZLB = '3' " +
                    "    GROUP BY Schedule.building_no, Schedule.lean_no, Schedule.Date, Schedule.ry_index, DDZL.DDBH, DDZL.ARTICLE, DDZL.Pairs " +
                    "  ) AS Schedule " +
                    ") AS Schedule " +
                    "GROUP BY building_no, lean_no, schedule_date " +

                    (
                        request.Type == "ALL" ? "SELECT S1.building_no, S1.lean_no, S1.schedule_date, S1.C_DL + S1.C_IDL AS C_Labor, S1.S_DL + S1.S_IDL AS S_Labor, S1.A_DL + S1.A_IDL AS A_Labor FROM #Schedule AS S1 " :
                        request.Type == "DL" ? "SELECT S1.building_no, S1.lean_no, S1.schedule_date, S1.C_DL AS C_Labor, S1.S_DL AS S_Labor, S1.A_DL AS A_Labor FROM #Schedule AS S1 " :
                        "SELECT S1.building_no, S1.lean_no, S1.schedule_date, S1.C_IDL AS C_Labor, S1.S_IDL AS S_Labor, S1.A_IDL AS A_Labor FROM #Schedule AS S1"
                    ) +
                    "LEFT JOIN #Schedule AS S2 ON S2.building_no = S1.building_no AND S2.lean_no = S1.lean_no AND S2.Seq = S1.Seq - 1 " +
                    "WHERE S1.schedule_date IS NOT NULL AND (S1.C_DL <> S2.C_DL OR S1.C_IDL <> S2.C_IDL OR S1.S_DL <> S2.S_DL OR S1.S_IDL <> S2.S_IDL OR S1.A_DL <> S2.A_DL OR S1.A_IDL <> S2.A_IDL OR S2.schedule_date IS NULL) " +
                    "ORDER BY S1.building_no, S1.lean_no, S1.schedule_date "
                    , firstDate.ToString("yyyy/MM/dd"), lastDate.ToString("yyyy/MM/dd"), request.Building, request.Lean
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                LaborDemandResult laborResult = new();
                laborResult.Cutting = new List<LaborData>();
                laborResult.Stitching = new List<LaborData>();
                laborResult.Assembly = new List<LaborData>();
                laborResult.Total = new List<LaborData>();

                string lean = "";
                int C_Labor = 0, S_Labor = 0, A_Labor = 0;
                int i = -1;
                DateTime searchDate = new DateTime(1900, 01, 01);
                List<List<List<int>>> LeanLabor = new List<List<List<int>>>();
                for (int row = 0; row < dt.Rows.Count; row++)
                {
                    if (dt.Rows[row]["building_no"].ToString() + dt.Rows[row]["lean_no"].ToString() != lean)
                    {
                        if (searchDate > new DateTime(1900, 01, 01) && searchDate < lastDate)
                        {
                            for (int j = (int)(searchDate-firstDate).TotalDays; j <= (int)(lastDate - firstDate).TotalDays; j++)
                            {
                                List<int> labor = new List<int> { C_Labor, S_Labor, A_Labor };
                                LeanLabor[i][j] = labor;
                            }
                        }

                        i++;
                        LeanLabor.Add(new List<List<int>>());
                        for (int j = 0; j <= (int)(lastDate - firstDate).TotalDays; j++)
                        {
                            LeanLabor[i].Add(new List<int>());
                        }
                        lean = dt.Rows[row]["building_no"].ToString() + dt.Rows[row]["lean_no"].ToString();
                        C_Labor = (int)dt.Rows[row]["C_Labor"];
                        S_Labor = (int)dt.Rows[row]["S_Labor"];
                        A_Labor = (int)dt.Rows[row]["A_Labor"];
                        searchDate = firstDate;
                    }

                    if ((DateTime)dt.Rows[row]["schedule_date"] >= searchDate)
                    {
                        for (int j = (int)(searchDate - firstDate).TotalDays; j <= (int)((DateTime)dt.Rows[row]["schedule_date"] - firstDate).TotalDays; j++)
                        {
                            List<int> labor = new List<int> { C_Labor, S_Labor, A_Labor };
                            LeanLabor[i][j] = labor;
                        }

                        C_Labor = (int)dt.Rows[row]["C_Labor"];
                        S_Labor = (int)dt.Rows[row]["S_Labor"];
                        A_Labor = (int)dt.Rows[row]["A_Labor"];
                        searchDate = (DateTime)dt.Rows[row]["schedule_date"];
                    }
                }

                if (searchDate > new DateTime(1900, 01, 01) && searchDate < lastDate)
                {
                    for (int j = (int)(searchDate - firstDate).TotalDays; j <= (int)(lastDate - firstDate).TotalDays; j++)
                    {
                        List<int> labor = new List<int> { C_Labor, S_Labor, A_Labor };
                        LeanLabor[i][j] = labor;
                    }
                }

                for (i = 0; i <= (int)(lastDate - firstDate).TotalDays; i++)
                {
                    C_Labor = 0;
                    S_Labor = 0;
                    A_Labor = 0;

                    for (int j = 0; j <= LeanLabor.Count-1; j++)
                    {
                        C_Labor += LeanLabor[j][i][0];
                        S_Labor += LeanLabor[j][i][1];
                        A_Labor += LeanLabor[j][i][2];
                    }

                    laborResult.Cutting.Add(new LaborData() { Id = i, Date = firstDate.AddDays(i).ToString("M/d"), Qty = C_Labor });
                    laborResult.Stitching.Add(new LaborData() { Id = i, Date = firstDate.AddDays(i).ToString("M/d"), Qty = S_Labor });
                    laborResult.Assembly.Add(new LaborData() { Id = i, Date = firstDate.AddDays(i).ToString("M/d"), Qty = A_Labor });
                    laborResult.Total.Add(new LaborData() { Id = i, Date = firstDate.AddDays(i).ToString("M/d"), Qty = C_Labor + S_Labor + A_Labor });
                }

                return JsonConvert.SerializeObject(laborResult);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getModelStandard")]
        public string getModelStandard(ScheduleRequest request)
        {
            DateTime firstDate = DateTime.ParseExact(request.Month + "/01", "yyyy/MM/dd", System.Globalization.CultureInfo.InvariantCulture);
            DateTime lastDate = new DateTime(firstDate.Year, firstDate.Month, DateTime.DaysInMonth(firstDate.Year, firstDate.Month));

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT UPPER(SC.lean_no) AS lean_no, SC.XieXing, SC.SheHao, REPLACE(XXZL.DAOMH, 'LY-', '') AS DAOMH, SC.ARTICLE, " +
                    "ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'C' THEN SCXXCL.BZRS END), 0) AS Labor_C, ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'S' THEN SCXXCL.BZRS END), 0) AS Labor_S, " +
                    "ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'A' THEN SCXXCL.BZRS END), 0) AS Labor_A, ISNULL(MAX(CASE WHEN SCXXCL.GXLB = 'P' THEN SCXXCL.BZRS END), 0) AS Labor_P, " +
                    "ISNULL(SUM(SCXXCL.BZJS), 0) AS IDL, ISNULL(SCXXCL.BZCL, 0) AS Standard, ISNULL(ModelStandard.Capacity, 0) AS Target FROM ( " +
                    "  SELECT SC.building_no, SC.lean_no, DDZL.XieXing, DDZL.SheHao, DDZL.ARTICLE, MIN(SC.schedule_date) AS Date FROM schedule_crawler AS SC " +
                    "  LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END " +
                    "  WHERE SC.schedule_date BETWEEN '{0}' AND '{1}' " +
                    "  AND SC.building_no = '{3}' " +
                    "  GROUP BY SC.building_no, SC.lean_no, DDZL.XieXing, DDZL.SheHao, DDZL.ARTICLE " +
                    ") AS SC " +
                    "LEFT JOIN XXZL ON XXZL.XieXing = SC.XieXing AND XXZL.SheHao = SC.SheHao " +
                    "LEFT JOIN SCXXCL ON SCXXCL.XieXing = SC.XieXing AND SCXXCL.SheHao = SC.SheHao AND SCXXCL.BZLB = '3' " +
                    "LEFT JOIN ( " +
                    "  SELECT MS1.Month AS CapacityMonth, MS1.Building, MS1.Lean, MS1.XieXing, MS1.SheHao, MS2.Capacity FROM ( " +
                    "    SELECT Building, Lean, XieXing, SheHao, MAX(Month) AS Month FROM ModelStandard " +
                    "    WHERE Month <= '{2}' " +
                    "    GROUP BY Building, Lean, XieXing, SheHao " +
                    "  ) AS MS1 " +
                    "  LEFT JOIN ModelStandard AS MS2 ON MS2.Month = MS1.Month AND MS2.Building = MS1.Building AND MS2.Lean = MS1.Lean AND MS2.XieXing = MS1.XieXing AND MS2.SheHao = MS1.SheHao " +
                    ") AS ModelStandard ON ModelStandard.XieXing = SC.XieXing AND ModelStandard.SheHao = SC.SheHao AND ModelStandard.Building = SC.building_no AND ModelStandard.Lean = SC.lean_no " +
                    "GROUP BY SC.lean_no, SC.XieXing, SC.SheHao, XXZL.DAOMH, SC.ARTICLE, SCXXCL.BZCL, ModelStandard.Capacity, SC.Date " +
                    "ORDER BY SC.lean_no, XXZL.DAOMH, SC.XieXing, SC.SheHao, SC.Date "
                    , firstDate.ToString("yyyy/MM/dd"), lastDate.ToString("yyyy/MM/dd"), request.Month, request.Building
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<LeanStandard> LeanResult = new List<LeanStandard>();
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    LeanStandard lean = new LeanStandard();
                    lean.Lean = dt.Rows[Row]["lean_no"].ToString();
                    lean.Models = new List<ModelStandard>();
                    
                    while (Row < dt.Rows.Count && dt.Rows[Row]["lean_no"].ToString() == lean.Lean)
                    {
                        ModelStandard modelStandard = new ModelStandard();
                        modelStandard.Model = dt.Rows[Row]["XieXing"].ToString() + '-' + dt.Rows[Row]["SheHao"].ToString();
                        modelStandard.DieCut = dt.Rows[Row]["DAOMH"].ToString();
                        modelStandard.SKU = dt.Rows[Row]["ARTICLE"].ToString();
                        modelStandard.Labor_C = (int)dt.Rows[Row]["Labor_C"];
                        modelStandard.Labor_S = (int)dt.Rows[Row]["Labor_S"];
                        modelStandard.Labor_A = (int)dt.Rows[Row]["Labor_A"];
                        modelStandard.Labor_P = (int)dt.Rows[Row]["Labor_P"];
                        modelStandard.Labor_Indirect = (int)dt.Rows[Row]["IDL"];
                        modelStandard.Standard = (int)dt.Rows[Row]["Standard"];
                        modelStandard.Target = (int)dt.Rows[Row]["Target"];
                        lean.Models.Add(modelStandard);

                        Row++;
                    }

                    LeanResult.Add(lean);
                }

                return JsonConvert.SerializeObject(LeanResult);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getStockFittingPlan")]
        public string getStockFittingPlan(ScheduleRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT PP.Building + ' ' + UPPER(PP.Lean) AS Lean, PP.RY, CAST(MONTH(DDZL.ShipDate) AS VARCHAR(2)) + '/' + CAST(DAY(DDZL.ShipDate) AS VARCHAR(2)) AS ShipDate, PP.NT, " +
                    "CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR) + ' BUY' AS BuyNo, DDZL.ARTICLE, ISNULL(DDZL.Pairs, 0) AS Pairs, REPLACE(XXZL.DAOMH, 'LY-', '') AS DAOMH, XXZL.DDMH, PP.CycleStart, PP.CycleEnd, " +
                    "MAX(CASE WHEN SMDD.DDBH = SMDD.YSBH THEN 1 ELSE CAST(SUBSTRING(SMDD.DDBH, LEN(SMDD.DDBH)-2, 3) AS INT) END) AS TotalCycle, PP.Remark, DDZL.DDGB FROM ProductionPlan AS PP " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = PP.RY " +
                    "LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "LEFT JOIN ( " +
                    "  SELECT building_no, lean_no, CASE WHEN LEN(ry) - LEN(REPLACE(ry, '-', '')) < 2 THEN ry ELSE SUBSTRING(ry, 1, LEN(ry) - CHARINDEX('-', REVERSE(ry))) END AS RY, " +
                    "  MAX(CONVERT(VARCHAR, schedule_date, 111) + '-' + CAST(ry_index AS VARCHAR)) AS Date, SUM(CASE WHEN ISNUMERIC(sl) = 1 THEN CAST(sl AS INT) ELSE 0 END) AS RYPairs FROM schedule_crawler " +
                    "  WHERE schedule_date >= GETDATE() - 60 " +
                    "  GROUP BY building_no, lean_no, CASE WHEN LEN(ry) - LEN(REPLACE(ry, '-', '')) < 2 THEN ry ELSE SUBSTRING(ry, 1, LEN(ry) - CHARINDEX('-', REVERSE(ry))) END " +
                    ") AS SC ON SC.building_no = PP.Building AND SC.lean_no = PP.Lean AND SC.RY = PP.RY " +
                    "LEFT JOIN SMDD ON SMDD.YSBH = PP.RY AND SMDD.GXLB = 'A' " +
                    "WHERE PP.PlanType = 'GCD' AND PP.PlanDate = '{0}' " +
                    "GROUP BY PP.Building, PP.Lean, PP.Seq, PP.RY, CAST(MONTH(DDZL.ShipDate) AS VARCHAR(2)) + '/' + CAST(DAY(DDZL.ShipDate) AS VARCHAR(2)), PP.NT, " +
                    "CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR), DDZL.ARTICLE, DDZL.Pairs, REPLACE(XXZL.DAOMH, 'LY-', ''), XXZL.DDMH, " +
                    "PP.CycleStart, PP.CycleEnd, PP.Remark, DDZL.DDGB, SC.Date " +
                    "ORDER BY PP.Building, PP.Lean, ISNULL(PP.Seq, 99), SC.Date "
                    , request.Date
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<LeanPlan> Plans = new List<LeanPlan>();
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    LeanPlan leanPlan = new LeanPlan();
                    leanPlan.Lean = dt.Rows[Row]["Lean"].ToString();
                    leanPlan.Plan = new List<PlanRY>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["Lean"].ToString() == leanPlan.Lean)
                    {
                        PlanRY plan = new PlanRY();
                        plan.RY = dt.Rows[Row]["RY"].ToString();
                        plan.ShipDate = dt.Rows[Row]["ShipDate"].ToString();
                        plan.Type = dt.Rows[Row]["NT"].ToString();
                        plan.BuyNo = dt.Rows[Row]["BuyNo"].ToString();
                        plan.SKU = dt.Rows[Row]["ARTICLE"].ToString();
                        plan.Pairs = (int)dt.Rows[Row]["Pairs"];
                        plan.DieCut = dt.Rows[Row]["DAOMH"].ToString();
                        plan.Outsole = dt.Rows[Row]["DDMH"].ToString();
                        if (dt.Rows[Row]["CycleStart"].ToString() != dt.Rows[Row]["CycleEnd"].ToString())
                        {
                            plan.Cycle = "T" + dt.Rows[Row]["CycleStart"].ToString() + " - T" + dt.Rows[Row]["CycleEnd"].ToString();
                        }
                        else
                        {
                            plan.Cycle = "T" + dt.Rows[Row]["CycleStart"].ToString();
                        }
                        plan.TotalCycle = "TC " + dt.Rows[Row]["TotalCycle"].ToString() + "T";
                        plan.Remark = dt.Rows[Row]["Remark"].ToString();
                        if (dt.Rows[Row]["DDGB"].ToString() == "CHI")
                        {
                            plan.Country = "CHINA";
                        }
                        else if (dt.Rows[Row]["DDGB"].ToString() == "KOR")
                        {
                            plan.Country = "S.KOREA";
                        }
                        else if (dt.Rows[Row]["DDGB"].ToString() == "TKY")
                        {
                            plan.Country = "TURKEY";
                        }
                        else if (dt.Rows[Row]["DDGB"].ToString() == "USA")
                        {
                            plan.Country = "USA";
                        }
                        else
                        {
                            plan.Country = "";
                        }

                        leanPlan.Plan.Add(plan);

                        Row++;
                    }

                    Plans.Add(leanPlan);
                }

                return JsonConvert.SerializeObject(Plans);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getR2Plan")]
        public string getR2Plan(ScheduleRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT PP.Lean, PP.RY, PP.ShipDate, PP.NT, PP.BuyNo, PP.ARTICLE, PP.Pairs, PP.DAOMH, PP.CyclePairs, " +
                    "PP.CycleStart, PP.CycleEnd, PP.XTMH, PP.DeliveryTime, PP.AssemblyTime, PP.TotalCycle, PP.Remark, PP.DDGB, " +
                    "CAST(ROW_NUMBER() OVER(PARTITION BY PP.Lean ORDER BY PP.AssemblyTime, ISNULL(PP.Seq, 99), PP.Date, PP.CycleStart) AS INT) AS Seq FROM ( " +
                    "  SELECT PP.Building + ' ' + UPPER(PP.Lean) AS Lean, PP.Seq, PP.RY, CAST(MONTH(DDZL.ShipDate) AS VARCHAR(2)) + '/' + CAST(DAY(DDZL.ShipDate) AS VARCHAR(2)) AS ShipDate, PP.NT, " +
                    "  CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR) + ' BUY' AS BuyNo, DDZL.ARTICLE, DDZL.Pairs, REPLACE(XXZL.DAOMH, 'LY-', '') AS DAOMH, " +
                    "  PP.Pairs AS CyclePairs, PP.CycleStart, PP.CycleEnd, REPLACE(XXZL.XTMH, 'TV-', '') AS XTMH, PP.DeliveryTime, PP.AssemblyTime, SC.Date, " +
                    "  MAX(CASE WHEN SMDD.DDBH = SMDD.YSBH THEN 1 ELSE CAST(SUBSTRING(SMDD.DDBH, LEN(SMDD.DDBH) - 2, 3) AS INT) END) AS TotalCycle, PP.Remark, DDZL.DDGB FROM ProductionPlan AS PP " +
                    "  LEFT JOIN DDZL ON DDZL.DDBH = PP.RY " +
                    "  LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "  LEFT JOIN ( " +
                    "    SELECT building_no, lean_no, CASE WHEN LEN(ry) - LEN(REPLACE(ry, '-', '')) < 2 THEN ry ELSE SUBSTRING(ry, 1, LEN(ry) - CHARINDEX('-', REVERSE(ry))) END AS RY, " +
                    "    MAX(CONVERT(VARCHAR, schedule_date, 111) + '-' + CAST(ry_index AS VARCHAR)) AS Date, SUM(CASE WHEN ISNUMERIC(sl) = 1 THEN CAST(sl AS INT) ELSE 0 END) AS RYPairs FROM schedule_crawler " +
                    "    WHERE schedule_date >= GETDATE() - 60 " +
                    "    GROUP BY building_no, lean_no, CASE WHEN LEN(ry) - LEN(REPLACE(ry, '-', '')) < 2 THEN ry ELSE SUBSTRING(ry, 1, LEN(ry) - CHARINDEX('-', REVERSE(ry))) END " +
                    "  ) AS SC ON SC.building_no = PP.Building AND SC.lean_no = PP.Lean AND SC.RY = PP.RY " +
                    "  LEFT JOIN SMDD ON SMDD.YSBH = PP.RY AND SMDD.GXLB = 'A' " +
                    "  WHERE PP.PlanType = 'R2' AND PP.PlanDate = '{0}' " +
                    "  GROUP BY PP.Building, PP.Lean, PP.Seq, PP.RY, CAST(MONTH(DDZL.ShipDate) AS VARCHAR(2)) + '/' + CAST(DAY(DDZL.ShipDate) AS VARCHAR(2)), PP.NT, " +
                    "  CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR), DDZL.ARTICLE, DDZL.Pairs, REPLACE(XXZL.DAOMH, 'LY-', ''), " +
                    "  PP.Pairs, PP.CycleStart, PP.CycleEnd, REPLACE(XXZL.XTMH, 'TV-', ''), PP.DeliveryTime, PP.AssemblyTime, PP.Remark, DDZL.DDGB, SC.Date " +
                    ") AS PP " +
                    "GROUP BY PP.Lean, PP.Seq, PP.RY, PP.ShipDate, PP.NT, PP.BuyNo, PP.ARTICLE, PP.Pairs, PP.DAOMH, PP.CyclePairs, PP.CycleStart, " +
                    "PP.CycleEnd, PP.XTMH, PP.DeliveryTime, PP.AssemblyTime, PP.TotalCycle, PP.Remark, PP.DDGB, PP.Date "
                    , request.Date
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<LeanPlan> Plans = new List<LeanPlan>();
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    LeanPlan leanPlan = new LeanPlan();
                    leanPlan.Lean = dt.Rows[Row]["Lean"].ToString();
                    leanPlan.Plan = new List<PlanRY>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["Lean"].ToString() == leanPlan.Lean)
                    {
                        PlanRY plan = new PlanRY();
                        plan.RY = dt.Rows[Row]["RY"].ToString();
                        plan.ShipDate = dt.Rows[Row]["ShipDate"].ToString();
                        plan.Type = dt.Rows[Row]["NT"].ToString();
                        plan.BuyNo = dt.Rows[Row]["BuyNo"].ToString();
                        plan.SKU = dt.Rows[Row]["ARTICLE"].ToString();
                        plan.Pairs = (int)dt.Rows[Row]["Pairs"];
                        plan.DieCut = dt.Rows[Row]["DAOMH"].ToString();
                        plan.CyclePairs = (int)dt.Rows[Row]["CyclePairs"];
                        if (dt.Rows[Row]["CycleStart"].ToString() != dt.Rows[Row]["CycleEnd"].ToString())
                        {
                            plan.Cycle = "T" + dt.Rows[Row]["CycleStart"].ToString() + " - T" + dt.Rows[Row]["CycleEnd"].ToString();
                        }
                        else
                        {
                            plan.Cycle = "T" + dt.Rows[Row]["CycleStart"].ToString();
                        }
                        plan.Last = dt.Rows[Row]["XTMH"].ToString();
                        plan.DeliveryTime = dt.Rows[Row]["DeliveryTime"].ToString();
                        plan.Seq = (int)dt.Rows[Row]["Seq"];
                        plan.AssemblyTime = dt.Rows[Row]["AssemblyTime"].ToString();
                        plan.TotalCycle = "TC " + dt.Rows[Row]["TotalCycle"].ToString() + "T";
                        plan.Remark = dt.Rows[Row]["Remark"].ToString();
                        if (dt.Rows[Row]["DDGB"].ToString() == "CHI")
                        {
                            plan.Country = "CHINA";
                        }
                        else if (dt.Rows[Row]["DDGB"].ToString() == "KOR")
                        {
                            plan.Country = "S.KOREA";
                        }
                        else if (dt.Rows[Row]["DDGB"].ToString() == "TKY")
                        {
                            plan.Country = "TURKEY";
                        }
                        else if (dt.Rows[Row]["DDGB"].ToString() == "USA")
                        {
                            plan.Country = "USA";
                        }
                        else
                        {
                            plan.Country = "";
                        }

                        leanPlan.Plan.Add(plan);

                        Row++;
                    }

                    Plans.Add(leanPlan);
                }

                return JsonConvert.SerializeObject(Plans);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getTestingPlan")]
        public string getTestingPlan(ScheduleRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT PP.Lean, PP.RY, PP.ShipDate, PP.NT, PP.BuyNo, PP.ARTICLE, PP.Pairs, PP.DAOMH, PP.CyclePairs, " +
                    "PP.CycleStart, PP.CycleEnd, PP.XTMH, PP.DeliveryTime, PP.AssemblyTime, PP.TotalCycle, PP.Remark, PP.DDGB, " +
                    "CAST(ROW_NUMBER() OVER(PARTITION BY PP.Lean ORDER BY PP.AssemblyTime, ISNULL(PP.Seq, 99), PP.Date, PP.CycleStart) AS INT) AS Seq FROM ( " +
                    "  SELECT PP.Building + ' ' + UPPER(PP.Lean) AS Lean, PP.Seq, PP.RY, CAST(MONTH(DDZL.ShipDate) AS VARCHAR(2)) + '/' + CAST(DAY(DDZL.ShipDate) AS VARCHAR(2)) AS ShipDate, PP.NT, " +
                    "  CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR) + ' BUY' AS BuyNo, DDZL.ARTICLE, DDZL.Pairs, REPLACE(XXZL.DAOMH, 'LY-', '') AS DAOMH, " +
                    "  PP.Pairs AS CyclePairs, PP.CycleStart, PP.CycleEnd, REPLACE(XXZL.XTMH, 'TV-', '') AS XTMH, PP.DeliveryTime, PP.AssemblyTime, SC.Date, " +
                    "  MAX(CASE WHEN SMDD.DDBH = SMDD.YSBH THEN 1 ELSE CAST(SUBSTRING(SMDD.DDBH, LEN(SMDD.DDBH) - 2, 3) AS INT) END) AS TotalCycle, PP.Remark, DDZL.DDGB FROM ProductionPlan AS PP " +
                    "  LEFT JOIN DDZL ON DDZL.DDBH = PP.RY " +
                    "  LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "  LEFT JOIN ( " +
                    "    SELECT building_no, lean_no, CASE WHEN LEN(ry) - LEN(REPLACE(ry, '-', '')) < 2 THEN ry ELSE SUBSTRING(ry, 1, LEN(ry) - CHARINDEX('-', REVERSE(ry))) END AS RY, " +
                    "    MAX(CONVERT(VARCHAR, schedule_date, 111) + '-' + CAST(ry_index AS VARCHAR)) AS Date, SUM(CASE WHEN ISNUMERIC(sl) = 1 THEN CAST(sl AS INT) ELSE 0 END) AS RYPairs FROM schedule_crawler " +
                    "    WHERE schedule_date >= GETDATE() - 60 " +
                    "    GROUP BY building_no, lean_no, CASE WHEN LEN(ry) - LEN(REPLACE(ry, '-', '')) < 2 THEN ry ELSE SUBSTRING(ry, 1, LEN(ry) - CHARINDEX('-', REVERSE(ry))) END " +
                    "  ) AS SC ON SC.building_no = PP.Building AND SC.lean_no = PP.Lean AND SC.RY = PP.RY " +
                    "  LEFT JOIN SMDD ON SMDD.YSBH = PP.RY AND SMDD.GXLB = 'A' " +
                    "  WHERE PP.PlanType = 'Testing' AND PP.PlanDate = '{0}' " +
                    "  GROUP BY PP.Building, PP.Lean, PP.Seq, PP.RY, CAST(MONTH(DDZL.ShipDate) AS VARCHAR(2)) + '/' + CAST(DAY(DDZL.ShipDate) AS VARCHAR(2)), PP.NT, " +
                    "  CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR), DDZL.ARTICLE, DDZL.Pairs, REPLACE(XXZL.DAOMH, 'LY-', ''), " +
                    "  PP.Pairs, PP.CycleStart, PP.CycleEnd, REPLACE(XXZL.XTMH, 'TV-', ''), PP.DeliveryTime, PP.AssemblyTime, PP.Remark, DDZL.DDGB, SC.Date " +
                    ") AS PP " +
                    "GROUP BY PP.Lean, PP.Seq, PP.RY, PP.ShipDate, PP.NT, PP.BuyNo, PP.ARTICLE, PP.Pairs, PP.DAOMH, PP.CyclePairs, " +
                    "PP.CycleStart, PP.CycleEnd, PP.XTMH, PP.DeliveryTime, PP.AssemblyTime, PP.TotalCycle, PP.Remark, PP.DDGB, PP.Date "
                    , request.Date
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<LeanPlan> Plans = new List<LeanPlan>();
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    LeanPlan leanPlan = new LeanPlan();
                    leanPlan.Lean = dt.Rows[Row]["Lean"].ToString();
                    leanPlan.Plan = new List<PlanRY>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["Lean"].ToString() == leanPlan.Lean)
                    {
                        PlanRY plan = new PlanRY();
                        plan.RY = dt.Rows[Row]["RY"].ToString();
                        plan.ShipDate = dt.Rows[Row]["ShipDate"].ToString();
                        plan.Type = dt.Rows[Row]["NT"].ToString();
                        plan.BuyNo = dt.Rows[Row]["BuyNo"].ToString();
                        plan.SKU = dt.Rows[Row]["ARTICLE"].ToString();
                        plan.Pairs = (int)dt.Rows[Row]["Pairs"];
                        plan.DieCut = dt.Rows[Row]["DAOMH"].ToString();
                        plan.CyclePairs = (int)dt.Rows[Row]["CyclePairs"];
                        if (dt.Rows[Row]["CycleStart"].ToString() != dt.Rows[Row]["CycleEnd"].ToString())
                        {
                            plan.Cycle = "T" + dt.Rows[Row]["CycleStart"].ToString() + " - T" + dt.Rows[Row]["CycleEnd"].ToString();
                        }
                        else
                        {
                            plan.Cycle = "T" + dt.Rows[Row]["CycleStart"].ToString();
                        }
                        plan.Last = dt.Rows[Row]["XTMH"].ToString();
                        plan.DeliveryTime = dt.Rows[Row]["DeliveryTime"].ToString();
                        plan.Seq = (int)dt.Rows[Row]["Seq"];
                        plan.AssemblyTime = dt.Rows[Row]["AssemblyTime"].ToString();
                        plan.TotalCycle = "TC " + dt.Rows[Row]["TotalCycle"].ToString() + "T";
                        plan.Remark = dt.Rows[Row]["Remark"].ToString();
                        if (dt.Rows[Row]["DDGB"].ToString() == "CHI")
                        {
                            plan.Country = "CHINA";
                        }
                        else if (dt.Rows[Row]["DDGB"].ToString() == "KOR")
                        {
                            plan.Country = "S.KOREA";
                        }
                        else if (dt.Rows[Row]["DDGB"].ToString() == "TKY")
                        {
                            plan.Country = "TURKEY";
                        }
                        else if (dt.Rows[Row]["DDGB"].ToString() == "USA")
                        {
                            plan.Country = "USA";
                        }
                        else
                        {
                            plan.Country = "";
                        }

                        leanPlan.Plan.Add(plan);

                        Row++;
                    }

                    Plans.Add(leanPlan);
                }

                return JsonConvert.SerializeObject(Plans);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("get3DayPlan")]
        public string get3DayPlan(ScheduleRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT 'LINE ' + RIGHT('00' + CAST(CAST(RIGHT(PP.Lean, 2) AS INT) AS VARCHAR), 2) AS Lean, PP.PlanType, PP.RY, CAST(MONTH(DDZL.ShipDate) AS VARCHAR(2)) + '/' + CAST(DAY(DDZL.ShipDate) AS VARCHAR(2)) AS ShipDate, DDZL.BuyNo, DDZL.ARTICLE, " +
                    "PP.Pairs, XXZL.DAOMH, PP.CycleStart, PP.CycleEnd, MAX(CASE WHEN SMDD.DDBH = SMDD.YSBH THEN 1 ELSE CAST(SUBSTRING(SMDD.DDBH, LEN(SMDD.DDBH) - 2, 3) AS INT) END) AS TotalCycle, PP.Remark, LBZLS.YWSM AS Country FROM ProductionPlan AS PP " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = PP.RY " +
                    "LEFT JOIN LBZLS ON LBZLS.LBDH = DDZL.DDGB AND LBZLS.LB = '06' " +
                    "LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "LEFT JOIN ( " +
                    "  SELECT building_no, lean_no, CASE WHEN LEN(ry) - LEN(REPLACE(ry, '-', '')) < 2 THEN ry ELSE SUBSTRING(ry, 1, LEN(ry) - CHARINDEX('-', REVERSE(ry))) END AS RY, " +
                    "  MAX(CONVERT(VARCHAR, schedule_date, 111) + '-' + CAST(ry_index AS VARCHAR)) AS Date, SUM(CASE WHEN ISNUMERIC(sl) = 1 THEN CAST(sl AS INT) ELSE 0 END) AS RYPairs FROM schedule_crawler " +
                    "  WHERE building_no = '{1}' " +
                    "  GROUP BY building_no, lean_no, CASE WHEN LEN(ry) - LEN(REPLACE(ry, '-', '')) < 2 THEN ry ELSE SUBSTRING(ry, 1, LEN(ry) - CHARINDEX('-', REVERSE(ry))) END " +
                    ") AS SC ON SC.building_no = PP.Building AND SC.lean_no = PP.Lean AND SC.RY = PP.RY " +
                    "LEFT JOIN SMDD ON SMDD.YSBH = PP.RY AND SMDD.GXLB = 'A' " +
                    "WHERE PP.PlanType IN ('3-Day', '3-Day U') AND PP.Building = '{1}' AND PP.PlanDate = '{0}' " +
                    "GROUP BY PP.Lean, PP.PlanType, PP.Seq, PP.RY, CAST(MONTH(DDZL.ShipDate) AS VARCHAR(2)) + '/' + CAST(DAY(DDZL.ShipDate) AS VARCHAR(2)), " +
                    "DDZL.BuyNo, DDZL.ARTICLE, DDZL.Pairs, XXZL.DAOMH, PP.CycleStart, PP.CycleEnd, PP.Remark, LBZLS.YWSM, SC.Date, PP.Pairs " +
                    "ORDER BY CAST(RIGHT(PP.Lean, 2) AS INT), PP.PlanType, ISNULL(PP.Seq, 99), SC.Date "
                    , request.Date, request.Building
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<LeanPlan> Plans = new List<LeanPlan>();
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    LeanPlan leanPlan = new LeanPlan();
                    leanPlan.Lean = dt.Rows[Row]["Lean"].ToString();
                    leanPlan.Plan = new List<PlanRY>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["Lean"].ToString() == leanPlan.Lean)
                    {
                        PlanRY plan = new PlanRY();
                        if (dt.Rows[Row]["PlanType"].ToString() == "3-Day U") 
                        {
                            plan.Version = "Urgency";
                        }
                        else
                        {
                            plan.Version = "Normal";
                        }
                        plan.RY = dt.Rows[Row]["RY"].ToString();
                        plan.ShipDate = dt.Rows[Row]["ShipDate"].ToString();
                        plan.BuyNo = dt.Rows[Row]["BuyNo"].ToString();
                        plan.SKU = dt.Rows[Row]["ARTICLE"].ToString();
                        plan.Pairs = (int)dt.Rows[Row]["Pairs"];
                        plan.DieCut = dt.Rows[Row]["DAOMH"].ToString();
                        if (dt.Rows[Row]["CycleStart"].ToString() != dt.Rows[Row]["CycleEnd"].ToString())
                        {
                            plan.Cycle = "T" + dt.Rows[Row]["CycleStart"].ToString() + " - T" + dt.Rows[Row]["CycleEnd"].ToString();
                        }
                        else
                        {
                            plan.Cycle = "T" + dt.Rows[Row]["CycleStart"].ToString();
                        }
                        plan.TotalCycle = "TC " + dt.Rows[Row]["TotalCycle"].ToString() + "T";
                        plan.Remark = dt.Rows[Row]["Remark"].ToString();
                        //plan.Country = dt.Rows[Row]["Country"].ToString();

                        leanPlan.Plan.Add(plan);

                        Row++;
                    }

                    Plans.Add(leanPlan);
                }

                return JsonConvert.SerializeObject(Plans);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("get1DayPlan")]
        public string get1DayPlan(ScheduleRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#CycleStatus') IS NOT NULL " +
                    "BEGIN DROP TABLE #CycleStatus END; " +

                    "SELECT PP.DDBH, CASE WHEN PP.Dispatched = 1 OR SUM(SMDDSS.okCTS) = SUM(SMDDSS.CTS) THEN 1 ELSE 0 END AS Dispatched INTO #CycleStatus FROM ( " +
                    "  SELECT PP.DDBH, CASE WHEN CycleDispatch.DDBH = PP.DDBH THEN 1 ELSE 0 END AS Dispatched FROM ( " +
                    "    SELECT SMDD.DDBH, SMDD.GXLB FROM ProductionPlan AS PP " +
                    "    LEFT JOIN SMDD ON SMDD.YSBH = PP.RY AND SMDD.DDBH = SMDD.DDBH AND SMDD.GXLB = SMDD.GXLB AND CASE WHEN SMDD.DDBH = SMDD.YSBH THEN 1 ELSE CAST(RIGHT(SMDD.DDBH, 3) AS INT) END BETWEEN PP.CycleStart AND PP.CycleEnd " +
                    "    WHERE PP.PlanType IN ('1-Day', '1-Day U') AND PP.Building = '{1}' AND PP.PlanDate = '{0}' AND SMDD.GXLB = 'A' " +
                    "  ) AS PP " +
                    "  LEFT JOIN CycleDispatch ON CycleDispatch.DDBH = PP.DDBH AND CycleDispatch.GXLB = PP.GXLB " +
                    ") AS PP " +
                    "LEFT JOIN SMDDSS ON SMDDSS.DDBH = PP.DDBH AND SMDDSS.GXLB = 'A' " +
                    "GROUP BY PP.DDBH, PP.Dispatched " +

                    "SELECT PP.Lean, PP.PlanType, PP.RY, PP.ShipDate, PP.BuyNo, PP.ARTICLE, PP.Pairs, PP.DAOMH, PP.CyclePairs, PP.CycleStart, PP.CycleEnd, PP.XTMH, PP.DeliveryTime, " +
                    "PP.AssemblyTime, PP.TotalCycle, PP.Remark, PP.Country, ISNULL(MIN(#CycleStatus.Dispatched), 0) AS Dispatched, " +
                    "CAST(ROW_NUMBER() OVER(PARTITION BY PP.Lean ORDER BY PP.PlanType, ISNULL(PP.Seq, 99), PP.AssemblyTime, PP.Date, PP.CycleStart) AS INT) AS Seq FROM ( " +
                    "  SELECT 'LINE ' + RIGHT('00' + CAST(CAST(RIGHT(PP.Lean, 2) AS INT) AS VARCHAR), 2) AS Lean, PP.PlanType, PP.Seq, PP.RY, CAST(MONTH(DDZL.ShipDate) AS VARCHAR(2)) + '/' + CAST(DAY(DDZL.ShipDate) AS VARCHAR(2)) AS ShipDate, " +
                    "  DDZL.BUYNO, DDZL.ARTICLE, DDZL.Pairs, XXZL.DAOMH, PP.Pairs AS CyclePairs, PP.CycleStart, PP.CycleEnd, XXZL.XTMH, PP.DeliveryTime, PP.AssemblyTime, SC.Date, " +
                    "  MAX(CASE WHEN SMDD.DDBH = SMDD.YSBH THEN 1 ELSE CAST(SUBSTRING(SMDD.DDBH, LEN(SMDD.DDBH) - 2, 3) AS INT) END) AS TotalCycle, PP.Remark, LBZLS.YWSM AS Country FROM ProductionPlan AS PP " +
                    "  LEFT JOIN DDZL ON DDZL.DDBH = PP.RY " +
                    "  LEFT JOIN LBZLS ON LBZLS.LBDH = DDZL.DDGB AND LBZLS.LB = '06' " +
                    "  LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "  LEFT JOIN ( " +
                    "    SELECT building_no, lean_no, CASE WHEN LEN(ry) - LEN(REPLACE(ry, '-', '')) < 2 THEN ry ELSE SUBSTRING(ry, 1, LEN(ry) - CHARINDEX('-', REVERSE(ry))) END AS RY, " +
                    "    MAX(CONVERT(VARCHAR, schedule_date, 111) + '-' + CAST(ry_index AS VARCHAR)) AS Date, SUM(CASE WHEN ISNUMERIC(sl) = 1 THEN CAST(sl AS INT) ELSE 0 END) AS RYPairs FROM schedule_crawler " +
                    "    WHERE building_no = '{1}' " +
                    "    GROUP BY building_no, lean_no, CASE WHEN LEN(ry) - LEN(REPLACE(ry, '-', '')) < 2 THEN ry ELSE SUBSTRING(ry, 1, LEN(ry) - CHARINDEX('-', REVERSE(ry))) END " +
                    "  ) AS SC ON SC.building_no = PP.Building AND SC.lean_no = PP.Lean AND SC.RY = PP.RY " +
                    "  LEFT JOIN SMDD ON SMDD.YSBH = PP.RY AND SMDD.GXLB = 'A' " +
                    "  WHERE PP.PlanType IN ('1-Day', '1-Day U') AND PP.Building = '{1}' AND PP.PlanDate = '{0}' " +
                    "  GROUP BY PP.Lean, PP.PlanType, PP.Seq, PP.RY, CAST(MONTH(DDZL.ShipDate) AS VARCHAR(2)) + '/' + CAST(DAY(DDZL.ShipDate) AS VARCHAR(2)), DDZL.BUYNO, " +
                    "  DDZL.ARTICLE, DDZL.Pairs, XXZL.DAOMH, XXZL.XTMH, PP.Pairs, PP.CycleStart, PP.CycleEnd, PP.DeliveryTime, PP.AssemblyTime, PP.Remark, LBZLS.YWSM, SC.Date " +
                    ") AS PP " +
                    "LEFT JOIN SMDD ON SMDD.YSBH = PP.RY AND SMDD.DDBH = SMDD.DDBH AND SMDD.GXLB = SMDD.GXLB AND CASE WHEN SMDD.DDBH = SMDD.YSBH THEN 1 ELSE CAST(RIGHT(SMDD.DDBH, 3) AS INT) END BETWEEN PP.CycleStart AND PP.CycleEnd AND SMDD.GXLB = 'A' " +
                    "LEFT JOIN #CycleStatus ON #CycleStatus.DDBH = SMDD.DDBH " +
                    "GROUP BY PP.Lean, PP.PlanType, PP.Seq, PP.RY, PP.ShipDate, PP.BuyNo, PP.ARTICLE, PP.Pairs, PP.DAOMH, PP.CyclePairs, PP.CycleStart, " +
                    "PP.CycleEnd, PP.XTMH, PP.DeliveryTime, PP.AssemblyTime, PP.TotalCycle, PP.Remark, PP.Country, PP.Date "
                    , request.Date, request.Building
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<LeanPlan> Plans = new List<LeanPlan>();
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    LeanPlan leanPlan = new LeanPlan();
                    leanPlan.Lean = dt.Rows[Row]["Lean"].ToString();
                    leanPlan.Plan = new List<PlanRY>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["Lean"].ToString() == leanPlan.Lean)
                    {
                        PlanRY plan = new PlanRY();
                        plan.RY = dt.Rows[Row]["RY"].ToString();
                        if (dt.Rows[Row]["PlanType"].ToString() == "1-Day U")
                        {
                            plan.Version = "Urgency";
                        }
                        else
                        {
                            plan.Version = "Normal";
                        }
                        plan.ShipDate = dt.Rows[Row]["ShipDate"].ToString();
                        plan.BuyNo = dt.Rows[Row]["BuyNo"].ToString();
                        plan.SKU = dt.Rows[Row]["ARTICLE"].ToString();
                        plan.Pairs = (int)dt.Rows[Row]["Pairs"];
                        plan.DieCut = dt.Rows[Row]["DAOMH"].ToString();
                        plan.CyclePairs = (int)dt.Rows[Row]["CyclePairs"];
                        if (dt.Rows[Row]["CycleStart"].ToString() != dt.Rows[Row]["CycleEnd"].ToString())
                        {
                            plan.Cycle = "T" + dt.Rows[Row]["CycleStart"].ToString() + " - T" + dt.Rows[Row]["CycleEnd"].ToString();
                        }
                        else
                        {
                            plan.Cycle = "T" + dt.Rows[Row]["CycleStart"].ToString();
                        }
                        plan.Last = dt.Rows[Row]["XTMH"].ToString();
                        plan.DeliveryTime = dt.Rows[Row]["DeliveryTime"].ToString();
                        plan.Seq = (int)dt.Rows[Row]["Seq"];
                        plan.AssemblyTime = dt.Rows[Row]["AssemblyTime"].ToString();
                        plan.TotalCycle = "TC " + dt.Rows[Row]["TotalCycle"].ToString() + "T";
                        plan.Remark = dt.Rows[Row]["Remark"].ToString();

                        if ((int)dt.Rows[Row]["Dispatched"] == 1)
                        {
                            plan.Status = "Completed";
                        }
                        else
                        {
                            plan.Status = "NotDispatched";
                        }

                        leanPlan.Plan.Add(plan);

                        Row++;
                    }

                    Plans.Add(leanPlan);
                }

                return JsonConvert.SerializeObject(Plans);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getDailyCycleList")]
        public string getDailyCycleList(ScheduleRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT CDL.ListNo, CDL.Type, CDL.Pairs, CDL.Remark, ISNULL(CD.ZLBH, CDO.ZLBH) AS ZLBH, " +
                    "ISNULL(CASE WHEN CD.DDBH = CD.ZLBH THEN 'T1' ELSE ISNULL('T' + CAST(CAST(RIGHT(CD.DDBH, 3) AS INT) AS VARCHAR), '') END, CASE WHEN CDO.DDBH = CDO.ZLBH THEN 'T1' ELSE ISNULL('T' + CAST(CAST(RIGHT(CDO.DDBH, 3) AS INT) AS VARCHAR), '') END) AS Cycle, " +
                    "SUBSTRING(CONVERT(VARCHAR, CDL.Date, 120), 12, 5) AS Time, CASE WHEN CDL.ConfirmDate IS NULL THEN 0 ELSE 1 END AS Confirmed FROM CycleDispatchList AS CDL " +
                    "LEFT JOIN CycleDispatch AS CD ON CD.ListNo = CDL.ListNo " +
                    "LEFT JOIN CycleDispatchOthers AS CDO ON CDO.ListNo = CDL.ListNo " +
                    "WHERE CONVERT(VARCHAR, CDL.Date, 111) = '{0}' AND CDL.Building = '{1}' AND CDL.Lean = '{2}' " +
                    "ORDER BY CDL.ListNo "
                    , request.Date, request.Building, request.Lean
                ), ERP
            );

            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<CycleDispatchList> CDList = new List<CycleDispatchList>();
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    CycleDispatchList RYList = new CycleDispatchList();
                    RYList.ListNo = dt.Rows[Row]["ListNo"].ToString();
                    RYList.Type = dt.Rows[Row]["Type"].ToString();
                    RYList.Pairs = (int)dt.Rows[Row]["Pairs"];
                    RYList.Remark = dt.Rows[Row]["Remark"].ToString();
                    RYList.RY = dt.Rows[Row]["ZLBH"].ToString();
                    RYList.Time = dt.Rows[Row]["Time"].ToString() != "00:00" ? dt.Rows[Row]["Time"].ToString() : "09:30";
                    RYList.Confirmed = Convert.ToBoolean((int)dt.Rows[Row]["Confirmed"]);
                    RYList.Cycle = new List<string>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["ListNo"].ToString() == RYList.ListNo && dt.Rows[Row]["ZLBH"].ToString() == RYList.RY)
                    {
                        RYList.Cycle.Add(dt.Rows[Row]["Cycle"].ToString()!);
                        Row++;
                    }

                    CDList.Add(RYList);
                }

                return JsonConvert.SerializeObject(CDList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getCycleListData")]
        public string getCycleListData(ScheduleRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT CDL.ListNo, SUBSTRING(CONVERT(VARCHAR, CDL.Date, 120), 12, 5) AS Time, CDL.Type, CDL.Pairs, CDL.Remark, ISNULL(CD.ZLBH, CDO.ZLBH) AS ZLBH, ISNULL(CD.DDBH, CDO.DDBH) AS Cycle FROM CycleDispatchList AS CDL " +
                    "LEFT JOIN CycleDispatch AS CD ON CD.ListNo = CDL.ListNo " +
                    "LEFT JOIN CycleDispatchOthers AS CDO ON CDO.ListNo = CDL.ListNo " +
                    "WHERE CDL.ListNo = '{0}' " +
                    "ORDER BY ISNULL(CD.DDBH, CDO.DDBH) "
                    , request.ListNo
                ), ERP
            );

            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<CycleDispatchList> CDList = new List<CycleDispatchList>();
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    CycleDispatchList RYList = new CycleDispatchList();
                    RYList.ListNo = dt.Rows[Row]["ListNo"].ToString();
                    RYList.Time = dt.Rows[Row]["Time"].ToString() != "00:00" ? dt.Rows[Row]["Time"].ToString() : "09:30";
                    RYList.Type = dt.Rows[Row]["Type"].ToString();
                    RYList.Pairs = (int)dt.Rows[Row]["Pairs"];
                    RYList.Remark = dt.Rows[Row]["Remark"].ToString();
                    RYList.RY = dt.Rows[Row]["ZLBH"].ToString();
                    RYList.Cycle = new List<string>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["ListNo"].ToString() == RYList.ListNo && dt.Rows[Row]["ZLBH"].ToString() == RYList.RY)
                    {
                        RYList.Cycle.Add(dt.Rows[Row]["Cycle"].ToString()!);
                        Row++;
                    }

                    CDList.Add(RYList);
                }

                return JsonConvert.SerializeObject(CDList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("updateCycleDispatchList")]
        public string updateCycleDispatchList(CuttingWorkOrderRequest request)
        {
            if (request.SelectedCycle != null)
            {
                string ListSQL = "";
                SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
                SqlCommand SQL;
                if (request.Section == "C")
                {
                    if (request.Date != "")
                    {
                        SqlDataAdapter da = new SqlDataAdapter(
                            string.Format(
                                "SELECT CASE WHEN RIGHT('{0}', 5) = '09:30' THEN DATEDIFF(SS, GETDATE(), LEFT('{0}', 10) + ' 08:30') " +
                                "ELSE CASE WHEN RIGHT('{0}', 5) = '13:30' THEN DATEDIFF(SS, GETDATE(), LEFT('{0}', 10) + ' 12:30') " +
                                "ELSE DATEDIFF(SS, GETDATE(), LEFT('{0}', 10) + ' 15:30') END END AS Time ",
                                request.Date
                            ), ERP
                        );
                        DataTable dt = new DataTable();
                        da.Fill(dt);

                        if ((int)dt.Rows[0]["Time"] < 0)
                        {
                            return "{\"statusCode\": 401}";
                        }
                    }

                    ListSQL = System.String.Format(
                        "UPDATE CycleDispatchList SET Type = '{0}', Building = '{1}', Lean = '{2}', Date = '{3}', Pairs = {4}, Remark = N'{5}', UserID = '{6}', UserDate = GetDate() " +
                        "WHERE ListNo = '{7}'; ",
                        request.Type, request.Department!.Split('_')[0], request.Department!.Split('_')[1], request.Date, request.Pairs, request.Remark!.Replace("'", "''"), request.UserID, request.ListNo
                    );
                }

                if (request.Type == "Others")
                {
                    if (request.SelectedCycle != "''")
                    {
                        SQL = new SqlCommand(
                            System.String.Format(
                                ListSQL +

                                "DELETE FROM CycleDispatchOthers WHERE ListNo = '{3}'; " +

                                "INSERT INTO CycleDispatchOthers (ListNo, ZLBH, DDBH) " +
                                "SELECT '{3}' AS ListNo, YSBH, DDBH FROM SMDD " +
                                "WHERE YSBH = '{0}' AND GXLB = '{1}' AND DDBH IN ({2}); ",
                                request.Order, request.Section, request.SelectedCycle, request.ListNo
                            ), ERP
                        );
                    }
                    else
                    {
                        SQL = new SqlCommand(
                            System.String.Format(
                                ListSQL +

                                "DELETE FROM CycleDispatchOthers WHERE ListNo = '{1}'; " +

                                "INSERT INTO CycleDispatchOthers (ListNo, ZLBH, DDBH) " +
                                "SELECT '{1}' AS ListNo, '{0}' AS ZLBH, '' AS DDBH ",
                                request.Order, request.ListNo
                            ), ERP
                        );
                    }
                }
                else
                {
                    SQL = new SqlCommand(
                        System.String.Format(
                            ListSQL +

                            "DELETE FROM CycleDispatch WHERE ListNo = '{6}' AND GXLB = '{1}'; " +

                            "INSERT INTO CycleDispatch (ZLBH, GXLB, DDBH, ListNo, GSBH, DepID, UserID, UserDate, YN) " +
                            "SELECT SMDD.YSBH, SMDD.GXLB, SMDD.DDBH, '{6}' AS ListNo, '{3}' AS GSBH, '{4}' AS DepID, '{2}' AS UserID, GETDATE() AS UserDate, '1' AS YN FROM SMDD " +
                            "LEFT JOIN CycleDispatch ON CycleDispatch.ZLBH = SMDD.YSBH AND CycleDispatch.DDBH = SMDD.DDBH AND CycleDispatch.GXLB = SMDD.GXLB " +
                            "WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = '{1}' AND CycleDispatch.DDBH IS NULL " +
                            "AND SMDD.DDBH IN ({5}); ",
                            request.Order, request.Section, request.UserID, request.Factory, request.Department, request.SelectedCycle, request.ListNo
                        ), ERP
                    );
                }

                ERP.Open();
                int recordCount = SQL.ExecuteNonQuery();
                ERP.Dispose();


                if (recordCount > 0)
                {
                    return "{\"statusCode\": 200}";
                }
                else
                {
                    return "{\"statusCode\": 400}";
                }
            }
            else
            {
                return "{\"statusCode\": 404}";
            }
        }

        [HttpPost]
        [Route("deleteCycleDispatchList")]
        public string deleteCycleDispatchList(CuttingWorkOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                string.Format(
                    "SELECT CASE WHEN ConfirmDate IS NULL THEN 0 ELSE 1 END AS Confirmed FROM CycleDispatchList WHERE ListNo = '{0}' ",
                    request.ListNo
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if ((int)dt.Rows[0]["Confirmed"] == 1)
            {
                return "{\"statusCode\": 402}";
            }

            SqlCommand SQL = new SqlCommand(
                System.String.Format(
                    "DELETE FROM CycleDispatchList WHERE ListNo = '{0}'; " +
                    "DELETE FROM CycleDispatch WHERE ListNo = '{0}' AND GXLB = '{1}'; " +
                    "DELETE FROM CycleDispatchOthers WHERE ListNo = '{0}'; ",
                    request.ListNo, request.Section
                ), ERP
            );

            ERP.Open();
            int recordCount = SQL.ExecuteNonQuery();
            ERP.Dispose();


            if (recordCount > 0)
            {
                return "{\"statusCode\": 200}";
            }
            else
            {
                return "{\"statusCode\": 400}";
            }
        }

        //Website
        [HttpPost]
        [Route("getProductionSchedule")]
        public string getProductionSchedule(ProductionScheduleRequest request)
        {
            DateTime StartDate = DateTime.Parse(request.StartDate!);
            DateTime EndDate = DateTime.Parse(request.EndDate!);
            string LastMonthFirstDate = new DateTime(StartDate.AddMonths(-1).Year, StartDate.AddMonths(-1).Month, 1).ToString("yyyy/MM/dd");
            string LastMonthLastDate = new DateTime(StartDate.Year, StartDate.Month, 1).AddDays(-1).ToString("yyyy/MM/dd");
            string NextMonthFirstDate = new DateTime(EndDate.AddMonths(1).Year, EndDate.AddMonths(1).Month, 1).ToString("yyyy/MM/dd");
            string NextMonthLastDate = new DateTime(EndDate.AddMonths(2).Year, EndDate.AddMonths(2).Month, 1).AddDays(-1).ToString("yyyy/MM/dd");
            DateTime SQLDate = new DateTime(StartDate.AddMonths(-1).Year, StartDate.AddMonths(-1).Month, 1);

            string DateRangeSQL = "SELECT '" + LastMonthFirstDate.Substring(0, 7) + "' AS Month UNION ALL ";
            int MonthDiff = (EndDate.Year - StartDate.Year) * 12 + (EndDate.Month - StartDate.Month);
            for (int i = 0; i <= MonthDiff; i++)
            {
                SQLDate = new DateTime(SQLDate.AddMonths(1).Year, SQLDate.AddMonths(1).Month, 1);
                DateRangeSQL += "SELECT '" + SQLDate.ToString("yyyy/MM") + "' AS Month " + (i < MonthDiff ? "UNION ALL " : "");
            }

            string Stage1SQL = "";
            string LastDateSQL = "";
            if (request.Mode == "Stage1")
            {
                Stage1SQL = System.String.Format(
                    "  UNION ALL " +
                    "  SELECT Building, Lean, 1000 + ROW_NUMBER() OVER(PARTITION BY Building, Lean ORDER BY StartDate) AS Seq, StartDate, CAST(CAST(SUBSTRING(BUY, 6, 2) AS INT) AS VARCHAR) + ' BUY', 'STAGE1' AS RYTYPE, Type AS RY, Pairs, NULL AS GAC, NULL AS XieXing, NULL AS SheHao FROM schedule_stage1 " +
                    "  WHERE Building LIKE '{0}%' AND BUY = '{1}' "
                    , request.Building, request.Version
                );

                LastDateSQL = System.String.Format(
                    "  SELECT S1.Building, S1.Lean, ISNULL(SS.Date, SP.Date) AS Date FROM ( " +
                    "    SELECT DISTINCT building_no AS Building, lean_no AS Lean FROM #SCHis " +
                    "    WHERE building_no NOT IN ('A11', 'PM') AND building_no + lean_no <> 'A12Lean05' " +
                    "  ) AS S1 " +
                    "  LEFT JOIN ( " +
                    "    SELECT Building, Lean, MAX(EndDate) AS Date FROM schedule_stage1 AS SS " +
                    "    WHERE BUY = '{0}' " +
                    "    GROUP BY Building, Lean " +
                    "  ) AS SS ON SS.Building = S1.Building AND SS.Lean = S1.Lean " +
                    "  LEFT JOIN ( " +
                    "    SELECT SP.Building, SP.Lean, SP.Date FROM schedule_parameter AS SP " +
                    "    LEFT JOIN ( " +
                    "      SELECT Building, MAX(version) AS version FROM #BVer " +
                    "      GROUP BY Building " +
                    "    ) AS BVer ON BVer.Building = SP.Building AND BVer.version = SP.Version " +
                    "    WHERE SP.Type = 'EndDate' AND BVer.Building IS NOT NULL " +
                    "  ) AS SP ON SP.Building = S1.Building AND SP.Lean = S1.Lean "
                    , request.Version
                );
            }
            else
            {
                LastDateSQL = (
                    "  SELECT SP.Building, SP.Lean, SP.Date, SP.Date AS Date2 FROM schedule_parameter AS SP " +
                    "  LEFT JOIN ( " +
                    "    SELECT Building, MAX(version) AS version FROM #BVer " +
                    "    GROUP BY Building " +
                    "  ) AS BVer ON BVer.Building = SP.Building AND BVer.version = SP.Version " +
                    "  WHERE SP.Type = 'EndDate' AND BVer.Building IS NOT NULL "
                );
            }

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#BVer') IS NOT NULL " +
                    "BEGIN DROP TABLE #BVer END; " +

                    "SELECT Building, Month, MAX(version) AS version INTO #BVer FROM ( " +
                    "  SELECT SH.building_no AS Building, SUBSTRING(CONVERT(VARCHAR, schedule_date, 111), 1, 7) AS Month, SH.version FROM schedule_history AS SH " +
                    "  LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SH.ry) - LEN(REPLACE(SH.ry, '-', '')) < 2 THEN SH.ry ELSE SUBSTRING(SH.ry, 1, LEN(SH.ry) - CHARINDEX('-', REVERSE(SH.ry))) END " +
                    "  WHERE SH.schedule_date >= '{0}' " + (request.Mode == "Stage2" ? "AND SH.version <= '{8}' " : "AND SH.version <= (SELECT TOP 1 Version FROM schedule_stage1 WHERE BUY = '{8}') ") +
                    "  GROUP BY SH.version, SH.building_no, SUBSTRING(CONVERT(VARCHAR, schedule_date, 111), 1, 7) " +
                    "  HAVING MAX(DDZL.DDRQ) <= '{9}' " +
                    ") AS SH " +
                    "GROUP BY Building, Month; " +

                    "IF OBJECT_ID('tempdb..#SCHis') IS NOT NULL " +
                    "BEGIN DROP TABLE #SCHis END; " +

                    "SELECT SH.* INTO #SCHis FROM #BVer AS BVer " +
                    "LEFT JOIN schedule_history AS SH ON SH.version = BVer.version AND SH.building_no = BVer.Building AND SUBSTRING(CONVERT(VARCHAR, SH.schedule_date, 111), 1, 7) = BVer.Month; " +

                    "IF OBJECT_ID('tempdb..#Schedule') IS NOT NULL " +
                    "BEGIN DROP TABLE #Schedule END; " +

                    "SELECT Building, Lean, Seq, Date, BUY, RYTYPE, RY, Pairs, GAC, CuttingDie, SKU, ModelCategory, StitchingCode, IE_LaborS, AssemblyCode, IE_LaborA, IE_Capacity, PM_Capacity, HisEff_A, HisPPH_A, TargetPPH_A, HisEff_S, HisPPH_S, TargetPPH_S, Lean_S, EndDate INTO #Schedule FROM ( " +
                    "  SELECT SC.building_no AS Building, SC.lean_no AS Lean, ROW_NUMBER() OVER(PARTITION BY SC.building_no, SC.lean_no ORDER BY SC.schedule_date, SC.Seq) AS Seq, " +
                    "  SC.schedule_date AS Date, SC.BUY, SC.RYTYPE, CASE WHEN SC.RYTYPE = 'STAGE1' THEN SC.BUY + ' 一階預排' ELSE SC.DDBH END AS RY, SC.Pairs, SC.GAC, " +
                    "  CASE WHEN SC.DDBH = '預告快速訂單' THEN '預告快速訂單' ELSE XXZL.DAOMH END AS CuttingDie, XXZL.ARTICLE AS SKU, CASE WHEN SC.RYTYPE = 'STAGE1' THEN SC.DDBH ELSE ISNULL(MC.Category, '未設定') END AS ModelCategory, " +
                    "  CASE WHEN SC.DDBH = '預告快速訂單' THEN '預告快速訂單' ELSE REPLACE(REPLACE(REPLACE(SA.StitchingCode, '\r', ''), '\n', ''), ' ', '') END AS StitchingCode, ISNULL(IE_S.BZRS, 0) + ISNULL(IE_S.BZJS, 0) AS IE_LaborS, " +
                    "  CASE WHEN SC.DDBH = '預告快速訂單' THEN '預告快速訂單' ELSE REPLACE(REPLACE(REPLACE(SA.AssemblyCode, '\r', ''), '\n', ''), ' ', '') END AS AssemblyCode, ISNULL(IE_A.BZRS, 0) + ISNULL(IE_A.BZJS, 0) + ISNULL(IE_P.BZRS, 0) + ISNULL(IE_P.BZJS, 0) AS IE_LaborA, " +
                    "  IE_A.BZCL AS IE_Capacity, MS.Capacity AS PM_Capacity, ISNULL(ISNULL(MP_A.Eff, CDP_A.Eff), LMP_A.Eff) AS HisEff_A, ISNULL(ISNULL(MP_A.PPH, CDP_A.PPH), LMP_A.PPH) AS HisPPH_A, CASE WHEN ISNULL(IE_A.BZRS, 0) + ISNULL(IE_A.BZJS, 0) + ISNULL(IE_P.BZRS, 0) + ISNULL(IE_P.BZJS, 0) > 0 THEN CAST(IE_A.BZCL * 1.0 / (ISNULL(IE_A.BZRS, 0) + ISNULL(IE_A.BZJS, 0) + ISNULL(IE_P.BZRS, 0) + ISNULL(IE_P.BZJS, 0)) AS NUMERIC(5, 2)) ELSE 0 END AS TargetPPH_A, " +
                    "  ISNULL(ISNULL(MP_S.Eff, CDP_S.Eff), LMP_S.Eff) AS HisEff_S, ISNULL(ISNULL(MP_S.PPH, CDP_S.PPH), LMP_S.PPH) AS HisPPH_S, CASE WHEN ISNULL(IE_S.BZRS, 0) + ISNULL(IE_S.BZJS, 0) > 0 THEN CAST(IE_S.BZCL * 1.0 / (ISNULL(IE_S.BZRS, 0) + ISNULL(IE_S.BZJS, 0)) AS NUMERIC(5, 2)) ELSE 0 END AS TargetPPH_S, ISNULL(ISNULL(MP_S.Lean_S, CDP_S.Lean_S), LMP_S.Lean_S) AS Lean_S, SP.Date AS EndDate FROM ( " +
                    "    SELECT SC.building_no, SUBSTRING(SC.lean_no, 1, 6) AS lean_no, ROW_NUMBER() OVER(PARTITION BY SC.building_no, SC.lean_no ORDER BY SC.schedule_date, SC.ry_index, SC.lean_no) AS Seq, " +
                    "    SC.schedule_date, CASE WHEN DDZL.GSBH = 'VA12' THEN CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR) + ' BUY' ELSE CASE WHEN DDZL.GSBH = 'VC2' THEN DDZL.BUYNO END END AS BUY, " +
                    "    ISNULL(DDZL.RYTYPE, 'GLOBAL') AS RYTYPE, DDZL.DDBH, CAST(SC.sl AS INT) AS Pairs, DDZL.ShipDate AS GAC, DDZL.XieXing, DDZL.SheHao FROM #SCHis AS SC " +
                    "    LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END " +
                    "    WHERE SC.schedule_date BETWEEN '{0}' AND '{1}' AND SC.building_no LIKE '{2}%' AND SC.building_no LIKE '{3}%' AND SC.building_no NOT IN ('A11', 'PM') AND SC.building_no + SC.lean_no <> 'A12Lean05' " +
                    "    UNION ALL " +
                    "    SELECT building_no, lean_no, 0 AS Seq, schedule_date, BUY, RYTYPE, DDBH, Pairs, GAC, XieXing, SheHao FROM ( " +
                    "      SELECT SC.building_no, SUBSTRING(SC.lean_no, 1, 6) AS lean_no, ROW_NUMBER() OVER(PARTITION BY SC.building_no, SC.lean_no ORDER BY SC.schedule_date DESC, SC.ry_index DESC, SC.lean_no DESC) AS Seq, " +
                    "      SC.schedule_date, CASE WHEN DDZL.GSBH = 'VA12' THEN CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR) + ' BUY' ELSE CASE WHEN DDZL.GSBH = 'VC2' THEN DDZL.BUYNO END END AS BUY, " +
                    "      ISNULL(DDZL.RYTYPE, 'GLOBAL') AS RYTYPE, DDZL.DDBH, CAST(SC.sl AS INT) AS Pairs, DDZL.ShipDate AS GAC, DDZL.XieXing, DDZL.SheHao FROM ( " +
                    "        SELECT SH.* FROM ( " +
                    "          SELECT Building, Month, MAX(version) AS version FROM ( " +
                    "            SELECT SH.building_no AS Building, SUBSTRING(CONVERT(VARCHAR, schedule_date, 111), 1, 7) AS Month, SH.version FROM schedule_history AS SH " +
                    "            LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SH.ry) - LEN(REPLACE(SH.ry, '-', '')) < 2 THEN SH.ry ELSE SUBSTRING(SH.ry, 1, LEN(SH.ry) - CHARINDEX('-', REVERSE(SH.ry))) END " +
                    "            WHERE SH.schedule_date BETWEEN '{4}' AND '{5}' " + (request.Mode == "Stage2" ? "AND SH.version <= '{8}' " : "AND SH.version <= '{9}' ") +
                    "            GROUP BY SH.version, SH.building_no, SUBSTRING(CONVERT(VARCHAR, schedule_date, 111), 1, 7) " +
                    "            HAVING MAX(DDZL.DDRQ) <= '{9}' " +
                    "          ) AS Ver " +
                    "          GROUP BY Building, Month " +
                    "        ) AS Ver " +
                    "        LEFT JOIN schedule_history AS SH ON SH.version = Ver.version AND SH.building_no = Ver.Building AND SUBSTRING(CONVERT(VARCHAR, SH.schedule_date, 111), 1, 7) = Ver.Month " +
                    "      ) AS SC " +
                    "      LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END " +
                    "      WHERE SC.schedule_date BETWEEN '{4}' AND '{5}' AND SC.building_no LIKE '{2}%' AND SC.building_no LIKE '{3}%' AND SC.building_no NOT IN ('A11', 'PM') AND SC.building_no + SC.lean_no <> 'A12Lean05' " +
                    "    ) AS SC " +
                    "    WHERE Seq = 1 " +
                    "    UNION ALL " +
                    "    SELECT building_no, lean_no, 500 AS Seq, schedule_date, BUY, RYTYPE, DDBH, Pairs, GAC, XieXing, SheHao FROM ( " +
                    "      SELECT SC.building_no, SUBSTRING(SC.lean_no, 1, 6) AS lean_no, ROW_NUMBER() OVER(PARTITION BY SC.building_no, SC.lean_no ORDER BY SC.schedule_date, SC.ry_index, SC.lean_no) AS Seq, " +
                    "      SC.schedule_date, CASE WHEN DDZL.GSBH = 'VA12' THEN CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR) + ' BUY' ELSE CASE WHEN DDZL.GSBH = 'VC2' THEN DDZL.BUYNO END END AS BUY, " +
                    "      ISNULL(DDZL.RYTYPE, 'GLOBAL') AS RYTYPE, DDZL.DDBH, CAST(SC.sl AS INT) AS Pairs, DDZL.ShipDate AS GAC, DDZL.XieXing, DDZL.SheHao FROM #SCHis AS SC " +
                    "      LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END " +
                    "      WHERE SC.schedule_date BETWEEN '{6}' AND '{7}' AND SC.building_no LIKE '{2}%' AND SC.building_no LIKE '{3}%' AND SC.building_no NOT IN ('A11', 'PM') AND SC.building_no + SC.lean_no <> 'A12Lean05' " +
                    "    ) AS SC " +
                    "    WHERE Seq = 1 " +
                    "    UNION ALL " +
                    "    SELECT SP.Building, SP.Lean, 250 AS Seq, SP.Date, SP.BUY, 'SLT' AS RYTYPE, '預告快速訂單' AS RY, NULL AS Pairs, SP.GAC, NULL AS XieXing, NULL AS SheHao FROM schedule_parameter AS SP " +
                    "    LEFT JOIN ( " +
                    "      SELECT Building, MAX(version) AS version FROM #BVer " +
                    "      GROUP BY Building " +
                    "    ) AS BVer ON BVer.Building = SP.Building AND BVer.version = SP.Version " +
                    "    WHERE SP.Type = 'Reserved' AND BVer.Building IS NOT NULL " +
                    "    UNION ALL " +
                    "    SELECT SP.Building, SP.Lean, 250 AS Seq, SP.Date, SP.BUY, 'EMPTY' AS RYTYPE, '' AS RY, NULL AS Pairs, SP.GAC, NULL AS XieXing, NULL AS SheHao FROM schedule_parameter AS SP " +
                    "    LEFT JOIN ( " +
                    "      SELECT Building, MAX(version) AS version FROM #BVer " +
                    "      GROUP BY Building " +
                    "    ) AS BVer ON BVer.Building = SP.Building AND BVer.version = SP.Version " +
                    "    WHERE SP.Type = 'Empty' AND BVer.Building IS NOT NULL " +
                    Stage1SQL +
                    "  ) AS SC " +
                    "  LEFT JOIN XXZL ON XXZL.XieXing = SC.XieXing AND XXZL.SheHao = SC.SheHao " +
                    "  LEFT JOIN ModelCategory AS MC ON MC.Model = XXZL.DAOMH " +
                    "  LEFT JOIN SKU_SA_CODE AS SA ON SA.XieXing = SC.XieXing AND SA.SheHao = SC.SheHao " +
                    "  LEFT JOIN SCXXCL AS IE_S ON IE_S.XieXing = SC.XieXing AND IE_S.SheHao = SC.SheHao AND IE_S.GXLB = 'S' AND IE_S.BZLB = '3' " +
                    "  LEFT JOIN SCXXCL AS IE_A ON IE_A.XieXing = SC.XieXing AND IE_A.SheHao = SC.SheHao AND IE_A.GXLB = 'A' AND IE_A.BZLB = '3' " +
                    "  LEFT JOIN SCXXCL AS IE_P ON IE_P.XieXing = SC.XieXing AND IE_P.SheHao = SC.SheHao AND IE_P.GXLB = 'P' AND IE_P.BZLB = '3' " +
                    "  LEFT JOIN ( " +
                    "    SELECT Building, Lean, XieXing, SheHao, Efficiency AS Eff, PPH FROM ( " +
                    "      SELECT Building, Lean, XieXing, SheHao, Efficiency, PPH, ROW_NUMBER() OVER(PARTITION BY Building, Lean, XieXing, SheHao ORDER BY Year DESC, Month DESC) AS Seq FROM ModelPerformance " +
                    "      WHERE Section = 'A' " +
                    "    ) AS MS " +
                    "    WHERE Seq = 1 " +
                    "  ) AS MP_A ON MP_A.Building = SC.building_no AND MP_A.Lean = SC.lean_no AND MP_A.XieXing = SC.XieXing AND MP_A.SheHao = SC.SheHao " +
                    "  LEFT JOIN ( " +
                    "    SELECT Building, Lean, DAOMH, Eff, PPH FROM ( " +
                    "      SELECT CDP.Year, CDP.Month, CDP.Building, CDP.Lean, XXZL.DAOMH, CAST(AVG(CDP.Efficiency) AS NUMERIC(5, 4)) AS Eff, CAST(AVG(CDP.PPH) AS NUMERIC(5, 2)) AS PPH, " +
                    "      ROW_NUMBER() OVER(PARTITION BY CDP.Building, CDP.Lean, XXZL.DAOMH ORDER BY CDP.Year DESC, CDP.Month DESC) AS Seq FROM ModelPerformance AS CDP " +
                    "      LEFT JOIN XXZL ON XXZL.XieXing = CDP.XieXing AND XXZL.SheHao = CDP.SheHao " +
                    "      WHERE CDP.Section = 'A' " +
                    "      GROUP BY CDP.Year, CDP.Month, CDP.Building, CDP.Lean, XXZL.DAOMH " +
                    "    ) AS CDP " +
                    "    WHERE Seq = 1 " +
                    "  ) AS CDP_A ON CDP_A.Building = SC.building_no AND CDP_A.Lean = SC.lean_no AND CDP_A.DAOMH = XXZL.DAOMH " +
                    "  LEFT JOIN ( " +
                    "    SELECT LM.Building, LM.Lean, CAST(AVG(MP.Efficiency) AS NUMERIC(5, 4)) AS Eff, CAST(AVG(MP.PPH) AS NUMERIC(5, 2)) AS PPH FROM ( " +
                    "      SELECT Building, Lean, Month FROM ( " +
                    "        SELECT Building, Lean, Month, ROW_NUMBER() OVER(PARTITION BY Building, Lean ORDER BY Month DESC) AS Seq FROM ( " +
                    "          SELECT DISTINCT Building, Lean, Year + '/' + Month AS Month FROM ModelPerformance " +
                    "          WHERE Year + '/' + Month <= SUBSTRING('{4}', 1, 7) AND Section = 'A' " +
                    "        ) AS MP " +
                    "      ) AS MP " +
                    "      WHERE Seq = 1 " +
                    "    ) AS LM " +
                    "    LEFT JOIN ModelPerformance AS MP ON MP.Building = LM.Building AND MP.Lean = LM.Lean AND MP.Year + '/' + MP.Month = LM.Month " +
                    "    GROUP BY LM.Building, LM.Lean " +
                    "  ) AS LMP_A ON LMP_A.Building = SC.building_no AND LMP_A.Lean = SC.lean_no " +
                    "  LEFT JOIN ( " +
                    "    SELECT Building, Lean, Lean_S, XieXing, SheHao, Efficiency AS Eff, PPH FROM ( " +
                    "      SELECT ISNULL(SF.Building_TX, MP.Building) AS Building, ISNULL(SF.Lean_TX, MP.Lean) AS Lean, SF.Building_VL + ' - ' + SF.Lean_VL AS Lean_S, MP.XieXing, MP.SheHao, MP.Efficiency, MP.PPH, " +
                    "      ROW_NUMBER() OVER(PARTITION BY ISNULL(SF.Building_TX, MP.Building), ISNULL(SF.Lean_TX, MP.Lean), MP.XieXing, MP.SheHao ORDER BY MP.Year DESC, MP.Month DESC) AS Seq FROM ModelPerformance AS MP " +
                    "      LEFT JOIN schedule_factorylink AS SF ON SF.Year = MP.Year AND SF.Month = MP.Month AND SF.Building_VL = MP.Building AND SF.Lean_VL = MP.Lean " +
                    "      WHERE MP.Section = 'S' " +
                    "    ) AS MS " +
                    "    WHERE Seq = 1 " +
                    "  ) AS MP_S ON MP_S.Building = SC.building_no AND MP_S.Lean = SC.lean_no AND MP_S.XieXing = SC.XieXing AND MP_S.SheHao = SC.SheHao " +
                    "  LEFT JOIN ( " +
                    "    SELECT Building, Lean, Lean_S, DAOMH, Eff, PPH FROM ( " +
                    "      SELECT CDP.Year, CDP.Month, ISNULL(SF.Building_TX, CDP.Building) AS Building, ISNULL(SF.Lean_TX, CDP.Lean) AS Lean, SF.Building_VL + ' - ' + SF.Lean_VL AS Lean_S, XXZL.DAOMH, CAST(AVG(CDP.Efficiency) AS NUMERIC(5, 4)) AS Eff, CAST(AVG(CDP.PPH) AS NUMERIC(5, 2)) AS PPH, " +
                    "      ROW_NUMBER() OVER(PARTITION BY ISNULL(SF.Building_TX, CDP.Building), ISNULL(SF.Lean_TX, CDP.Lean), XXZL.DAOMH ORDER BY CDP.Year DESC, CDP.Month DESC) AS Seq FROM ModelPerformance AS CDP " +
                    "      LEFT JOIN schedule_factorylink AS SF ON SF.Year = CDP.Year AND SF.Month = CDP.Month AND SF.Building_VL = CDP.Building AND SF.Lean_VL = CDP.Lean " +
                    "      LEFT JOIN XXZL ON XXZL.XieXing = CDP.XieXing AND XXZL.SheHao = CDP.SheHao " +
                    "      WHERE CDP.Section = 'S' " +
                    "      GROUP BY CDP.Year, CDP.Month, ISNULL(SF.Building_TX, CDP.Building), ISNULL(SF.Lean_TX, CDP.Lean), SF.Building_VL, SF.Lean_VL, XXZL.DAOMH " +
                    "    ) AS CDP " +
                    "    WHERE Seq = 1 " +
                    "  ) AS CDP_S ON CDP_S.Building = SC.building_no AND CDP_S.Lean = SC.lean_no AND CDP_S.DAOMH = XXZL.DAOMH " +
                    "  LEFT JOIN ( " +
                    "    SELECT ISNULL(SF.Building_TX, LM.Building) AS Building, ISNULL(SF.Lean_TX, LM.Lean) AS Lean, MAX(SF.Building_VL + ' - ' + SF.Lean_VL) AS Lean_S, CAST(AVG(MP.Efficiency) AS NUMERIC(5, 4)) AS Eff, CAST(AVG(MP.PPH) AS NUMERIC(5, 2)) AS PPH FROM ( " +
                    "      SELECT Building, Lean, Month FROM ( " +
                    "        SELECT Building, Lean, Month, ROW_NUMBER() OVER(PARTITION BY Building, Lean ORDER BY Month DESC) AS Seq FROM ( " +
                    "          SELECT DISTINCT Building, Lean, Year + '/' + Month AS Month FROM ModelPerformance " +
                    "          WHERE Year + '/' + Month <= SUBSTRING('{4}', 1, 7) AND Section = 'S' " +
                    "        ) AS MP " +
                    "      ) AS MP " +
                    "      WHERE Seq = 1 " +
                    "    ) AS LM " +
                    "    LEFT JOIN ModelPerformance AS MP ON MP.Building = LM.Building AND MP.Lean = LM.Lean AND MP.Year + '/' + MP.Month = LM.Month " +
                    "    LEFT JOIN schedule_factorylink AS SF ON SF.Year = MP.Year AND SF.Month = MP.Month AND SF.Building_VL = MP.Building AND SF.Lean_VL = MP.Lean " +
                    "    GROUP BY ISNULL(SF.Building_TX, LM.Building), ISNULL(SF.Lean_TX, LM.Lean) " +
                    "  ) AS LMP_S ON LMP_S.Building = SC.building_no AND LMP_S.Lean = SC.lean_no " +
                    "  LEFT JOIN ( " +
                    "    SELECT Building, Lean, Month, XieXing, SheHao, Capacity FROM ( " +
                    "      SELECT Range.Month, MS.Building, MS.Lean, ROW_NUMBER() OVER(PARTITION BY MS.Building, MS.Lean, MS.XieXing, MS.SheHao, Range.Month ORDER BY MS.Month DESC) AS Seq, MS.XieXing, MS.SheHao, MS.Capacity FROM ( " +
                    DateRangeSQL +
                    "      ) AS Range " +
                    "      LEFT JOIN ModelStandard AS MS ON MS.Month <= Range.Month " +
                    "    ) AS MS " +
                    "    WHERE Seq = 1 " +
                    "  ) AS MS ON MS.Building = SC.building_no AND MS.Lean = SC.lean_no AND MS.XieXing = SC.XieXing AND MS.SheHao = SC.SheHao AND MS.Month = SUBSTRING(CONVERT(VARCHAR, SC.schedule_date, 111), 1, 7) " +
                    "  LEFT JOIN ( " +
                    LastDateSQL +
                    "  ) AS SP ON SP.Building = SC.building_no AND SP.Lean = SC.lean_no " +
                    "  WHERE SC.building_no LIKE '{2}%' AND SC.building_no LIKE '{3}%' AND SC.schedule_date <= '{1}' " +
                    ") AS SC " +
                    "WHERE Date <= EndDate " +

                    "IF OBJECT_ID('tempdb..#SC') IS NOT NULL " +
                    "BEGIN DROP TABLE #SC END; " +

                    "SELECT S1.Building, S1.Lean, S1.Date AS SDate, CASE WHEN S1.RY = '預告快速訂單' THEN ISNULL(S2.Date-1, SP.Date) ELSE ISNULL(CASE WHEN S2.Date = S1.Date THEN S2.Date ELSE S2.Date-1 END, SP.Date) END AS EDate, S1.BUY, S1.RYTYPE, " +
                    "S1.Seq, S1.RY, S1.Pairs, S1.GAC, S1.CuttingDie, S1.ModelCategory, S1.SKU, S1.StitchingCode, S1.AssemblyCode, " +
                    "S1.IE_LaborS, CASE WHEN ISNULL(S3.IE_LaborS, S1.IE_LaborS) > 0 THEN CAST(ROUND(ABS(S1.IE_LaborS - ISNULL(S3.IE_LaborS, S1.IE_LaborS)) * 100.0 / ISNULL(S3.IE_LaborS, S1.IE_LaborS), 2) AS NUMERIC(5, 2)) ELSE 0 END AS GRateLaborS, " +
                    "S1.IE_LaborA, CASE WHEN ISNULL(S3.IE_LaborA, S1.IE_LaborA) > 0 THEN CAST(ROUND(ABS(S1.IE_LaborA - ISNULL(S3.IE_LaborA, S1.IE_LaborA)) * 100.0 / ISNULL(S3.IE_LaborA, S1.IE_LaborA), 2) AS NUMERIC(5, 2)) ELSE 0 END AS GRateLaborA, " +
                    "S1.PM_Capacity, S1.IE_Capacity, S1.HisEff_A, S1.HisPPH_A, S1.TargetPPH_A, S1.HisEff_S, S1.HisPPH_S, S1.TargetPPH_S, S1.Lean_S INTO #SC FROM #Schedule AS S1 " +
                    "LEFT JOIN #Schedule AS S2 ON S2.Building = S1.Building AND S2.Lean = S1.Lean AND S2.Seq = S1.Seq + 1 " +
                    "LEFT JOIN #Schedule AS S3 ON S3.Building = S1.Building AND S3.Lean = S1.Lean AND S3.Seq = S1.Seq - 1 " +
                    "LEFT JOIN ( " +
                    LastDateSQL +
                    ") AS SP ON SP.Building = S1.Building AND SP.Lean = S1.Lean " +
                    "WHERE S1.Date <= SP.Date AND ((S1.Seq = 0 AND S2.Date > '{0}') OR S1.Seq > 0) " + 

                    "IF OBJECT_ID('tempdb..#DayRY') IS NOT NULL " +
                    "BEGIN DROP TABLE #DayRY END; " +

                    "SELECT Building, Lean, SDate AS Date, COUNT(RY) AS Qty INTO #DayRY FROM ( " +
                    "  SELECT Building, Lean, SDate, RY FROM #SC " +
                    "  UNION " +
                    "  SELECT Building, Lean, EDate, RY FROM #SC " +
                    ") AS SC " +
                    "GROUP BY Building, Lean, SDate " +

                    "IF OBJECT_ID('tempdb..#RYSeq') IS NOT NULL " +
                    "BEGIN DROP TABLE #RYSeq END; " +

                    "SELECT Building, Lean, SDate AS Date, RY, ROW_NUMBER() OVER(PARTITION BY Building, Lean, SDate ORDER BY Seq) AS Seq INTO #RYSeq FROM ( " +
                    "  SELECT Building, Lean, SDate, Seq, RY FROM #SC " +
                    "  UNION " +
                    "  SELECT Building, Lean, EDate, Seq, RY FROM #SC " +
                    ") AS SC " +

                    /*"IF OBJECT_ID('tempdb..#WorkHours') IS NOT NULL " +
                    "BEGIN DROP TABLE #WorkHours END; " +

                    "SELECT ISNULL(SF.Building_TX, WA.Building) AS Building, ISNULL(SF.Lean_TX, WA.Lean) AS Lean, WA.GXLB, WA.Date, SUM(WA.WorkingHours) AS WorkingHours INTO #WorkHours FROM ( " +
                    "  SELECT SUBSTRING(WA.Department, 1, CHARINDEX('_', WA.Department)-1) AS Building, SUBSTRING(WA.Department, CHARINDEX('_', WA.Department)+1, 6) AS Lean, " +
                    "  CASE WHEN RIGHT(WA.Department, 1) = 'G' THEN 'A' ELSE CASE WHEN RIGHT(WA.Department, 1) = 'M' THEN 'S' ELSE RIGHT(WA.Department, 1) END END AS GXLB, " +
                    "  WA.Date, SUM(WorkTime.Hours) AS WorkingHours FROM ( " +
                    "    SELECT ID, Date, Department FROM WorkerAttendance " +
                    "    WHERE Date BETWEEN '{4}' AND '{1}' AND Department LIKE '%LEAN%' AND ISNULL(Attendance, 0) = 1 " +
                    "  ) AS WA " +
                    "  LEFT JOIN ( " +
                    "    SELECT ID, Date, Hours FROM OpenQuery([HRS], ' " +
                    "      SELECT NV_MA COLLATE Chinese_Taiwan_Stroke_CI_AS AS ID, QT_NGAY AS Date, ISNULL(CC_GIOBINHTHUONG, 0) + ISNULL(CC_GIOTANGCA, 0) AS Hours FROM [P0104-TYXUAN].[dbo].[ST_GIOQUETTHE] " +
                    "      WHERE QT_NGAY BETWEEN ''{4}'' AND ''{1}'' AND ISNULL(CC_GIOBINHTHUONG, 0) + ISNULL(CC_GIOTANGCA, 0) > 0' " +
                    "    ) " +
                    "  ) AS WorkTime ON WorkTime.ID = WA.ID AND WorkTime.Date = WA.Date " +
                    "  GROUP BY WA.Department, WA.Date " +
                    ") AS WA " +
                    "LEFT JOIN schedule_factorylink AS SF ON CAST(SF.Year AS INT) = YEAR(WA.Date) AND CAST(SF.Month AS INT) = MONTH(WA.Date) AND SF.Building_VL = WA.Building AND SF.Lean_VL = WA.Lean " +
                    "GROUP BY ISNULL(SF.Building_TX, WA.Building), ISNULL(SF.Lean_TX, WA.Lean), WA.GXLB, WA.Date " +

                    "IF OBJECT_ID('tempdb..#Eff') IS NOT NULL " +
                    "BEGIN DROP TABLE #Eff END; " +

                    "SELECT SCBB.Building, SCBB.Lean, SCBB.SCDate, SCBB.GXLB, SCBB.ModelTime / (WH.WorkingHours * 3600) AS Eff INTO #Eff FROM ( " +
                    "  SELECT Building, Lean, SCDate, GXLB, SUM(ModelTime) AS ModelTime FROM ( " +
                    "    SELECT ISNULL(SF.Building_TX, REPLACE(SUBSTRING(BDepartment.DepName, 1, 3), '_', '')) AS Building, ISNULL(SF.Lean_TX, REPLACE(SUBSTRING(BDepartment.DepName, 4, 7), '_', '')) AS Lean, SCBB.SCDate, SCBBS.GXLB, SCXXCL.TCT, SCBBS.Qty, SCXXCL.TCT*SCBBS.Qty AS ModelTime FROM SCBB " +
                    "    LEFT JOIN SCBBS ON SCBBS.ProNo = SCBB.ProNo " +
                    "    LEFT JOIN DDZL ON DDZL.DDBH = SCBBS.SCBH " +
                    "    LEFT JOIN ( " +
                    "      SELECT XieXing, SheHao, GXLB, 3600.0 / BZCL * Labor AS TCT FROM ( " +
                    "        SELECT XieXing, SheHao, BZCL, CASE WHEN GXLB IN ('A', 'P') THEN 'A' ELSE GXLB END AS GXLB, SUM(BZRS + BZJS) AS Labor FROM SCXXCL " +
                    "        WHERE GXLB IN ('S', 'A', 'P') AND BZLB = '3' " +
                    "        GROUP BY XieXing, SheHao, BZCL, CASE WHEN GXLB IN ('A', 'P') THEN 'A' ELSE GXLB END " +
                    "      ) AS SCXXCL " +
                    "    ) AS SCXXCL ON SCXXCL.XieXing = DDZL.XieXing AND SCXXCL.SheHao = DDZL.SheHao AND SCXXCL.GXLB = SCBBS.GXLB " +
                    "    LEFT JOIN BDepartment ON BDepartment.ID = SCBB.DepNo " +
                    "    LEFT JOIN schedule_factorylink AS SF ON CAST(SF.Year AS INT) = YEAR(SCBB.SCDate) AND CAST(SF.Month AS INT) = MONTH(SCBB.SCDate) AND SF.Building_VL = REPLACE(SUBSTRING(BDepartment.DepName, 1, 3), '_', '') AND SF.Lean_VL = REPLACE(SUBSTRING(BDepartment.DepName, 4, 7), '_', '') " +
                    "    WHERE SCBB.SCDate BETWEEN '{4}' AND '{1}' AND SCBB.GSBH = 'VA12' AND SCBBS.GXLB IN ('S', 'A') " +
                    "  ) AS SCBB " +
                    "  GROUP BY SCDate, Building, Lean, GXLB " +
                    ") AS SCBB " +
                    "LEFT JOIN #WorkHours AS WH ON WH.Building = SCBB.Building AND WH.Lean = SCBB.Lean AND WH.Date = SCBB.SCDate AND WH.GXLB = SCBB.GXLB " +

                    "IF OBJECT_ID('tempdb..#RYEffParam') IS NOT NULL " +
                    "BEGIN DROP TABLE #RYEffParam END; " +

                    "SELECT SCBB.Building, SCBB.Lean, SCBB.RY, SCBB.GXLB, SCBB.Qty, ISNULL(#Eff.Eff, 0) AS Eff INTO #RYEffParam FROM ( " +
                    "  SELECT ISNULL(SF.Building_TX, REPLACE(SUBSTRING(BDepartment.DepName, 1, 3), '_', '')) AS Building, ISNULL(SF.Lean_TX, REPLACE(SUBSTRING(BDepartment.DepName, 4, 7), '_', '')) AS Lean, SCBB.SCDate, SC.RY, SCBBS.GXLB, SCBBS.Qty FROM ( " +
                    "    SELECT DISTINCT RY FROM #SC " +
                    "  ) AS SC " +
                    "  LEFT JOIN SCBBS ON SCBBS.SCBH = SC.RY AND SCBBS.GXLB IN ('S', 'A') " +
                    "  LEFT JOIN SCBB ON SCBB.ProNo = SCBBS.ProNo " +
                    "  LEFT JOIN BDepartment ON BDepartment.ID = SCBB.DepNo " +
                    "  LEFT JOIN schedule_factorylink AS SF ON CAST(SF.Year AS INT) = YEAR(SCBB.SCDate) AND CAST(SF.Month AS INT) = MONTH(SCBB.SCDate) AND SF.Building_VL = REPLACE(SUBSTRING(BDepartment.DepName, 1, 3), '_', '') AND SF.Lean_VL = REPLACE(SUBSTRING(BDepartment.DepName, 4, 7), '_', '') " +
                    "  WHERE SCBBS.ProNo IS NOT NULL " +
                    ") AS SCBB " +
                    "LEFT JOIN #Eff ON #Eff.Building = SCBB.Building AND #Eff.Lean = SCBB.Lean AND #Eff.SCDate = SCBB.SCDate AND #Eff.GXLB = SCBB.GXLB " +
                    "WHERE ISNULL(#Eff.Eff, 0) > 0 " +

                    "IF OBJECT_ID('tempdb..#RYEff') IS NOT NULL " +
                    "BEGIN DROP TABLE #RYEff END; " +

                    "SELECT RE1.RY, RE1.GXLB, ROUND(RE1.Eff * 100 / RE2.Qty, 2) AS Eff INTO #RYEff FROM ( " +
                    "  SELECT RY, GXLB, SUM(Eff * Qty) AS Eff FROM #RYEffParam " +
                    "  GROUP BY RY, GXLB " +
                    ") AS RE1 " +
                    "LEFT JOIN ( " +
                    "  SELECT RY, GXLB, SUM(Qty) AS Qty FROM #RYEffParam " +
                    "  GROUP BY RY, GXLB " +
                    ") AS RE2 ON RE2.RY = RE1.RY AND RE2.GXLB = RE1.GXLB " +*/

                    "IF OBJECT_ID('tempdb..#LeanTargetEff') IS NOT NULL " +
                    "BEGIN DROP TABLE #LeanTargetEff END; " +

                    "SELECT Building, Lean, CAST(ROUND(SUM(PM_Capacity * Pairs) * 100.0 / SUM(IE_Capacity * Pairs), 2) AS NUMERIC(5, 2)) AS LeanTargetEff INTO #LeanTargetEff FROM #SC " +
                    "WHERE PM_Capacity IS NOT NULL AND IE_Capacity IS NOT NULL " +
                    "GROUP BY Building, Lean " +

                    /*"IF OBJECT_ID('tempdb..#LeanActualEff_A') IS NOT NULL " +
                    "BEGIN DROP TABLE #LeanActualEff_A END; " +

                    "SELECT #SC.Building, #SC.Lean, CAST(ROUND(SUM(#RYEff.Eff * #SC.Pairs) / SUM(#SC.Pairs), 2) AS NUMERIC(5, 2)) AS LeanActualEff_A INTO #LeanActualEff_A FROM #SC " +
                    "LEFT JOIN #RYEff ON #RYEff.RY = #SC.RY AND #RYEff.GXLB = 'A' " +
                    "WHERE #RYEff.Eff IS NOT NULL " +
                    "GROUP BY #SC.Building, #SC.Lean " +

                    "IF OBJECT_ID('tempdb..#LeanActualEff_S') IS NOT NULL " +
                    "BEGIN DROP TABLE #LeanActualEff_S END; " +

                    "SELECT #SC.Building, #SC.Lean, CAST(ROUND(SUM(#RYEff.Eff * #SC.Pairs) / SUM(#SC.Pairs), 2) AS NUMERIC(5, 2)) AS LeanActualEff_S INTO #LeanActualEff_S FROM #SC " +
                    "LEFT JOIN #RYEff ON #RYEff.RY = #SC.RY " +
                    "WHERE #RYEff.Eff IS NOT NULL AND #RYEff.GXLB = 'S' " +
                    "GROUP BY #SC.Building, #SC.Lean " +*/

                    "IF OBJECT_ID('tempdb..#LeanHisEff_A') IS NOT NULL " +
                    "BEGIN DROP TABLE #LeanHisEff_A END; " +

                    "SELECT Building, Lean, CAST(ROUND(SUM(HisEff_A * Pairs) * 100.0 / SUM(Pairs), 2) AS NUMERIC(5, 2)) AS LeanHisEff_A INTO #LeanHisEff_A FROM #SC " +
                    "WHERE HisEff_A IS NOT NULL " +
                    "GROUP BY Building, Lean " +

                    "IF OBJECT_ID('tempdb..#LeanHisEff_S') IS NOT NULL " +
                    "BEGIN DROP TABLE #LeanHisEff_S END; " +

                    "SELECT Building, Lean, CAST(ROUND(SUM(HisEff_S * Pairs) * 100.0 / SUM(Pairs), 2) AS NUMERIC(5, 2)) AS LeanHisEff_S INTO #LeanHisEff_S FROM #SC " +
                    "WHERE HisEff_S IS NOT NULL " +
                    "GROUP BY Building, Lean " +

                    "IF OBJECT_ID('tempdb..#LeanHisPPH_A') IS NOT NULL " +
                    "BEGIN DROP TABLE #LeanHisPPH_A END; " +

                    "SELECT Building, Lean, CAST(ROUND(SUM(HisPPH_A * Pairs) / SUM(Pairs), 2) AS NUMERIC(5, 2)) AS LeanHisPPH_A INTO #LeanHisPPH_A FROM #SC " +
                    "WHERE HisPPH_A IS NOT NULL " +
                    "GROUP BY Building, Lean " +

                    "IF OBJECT_ID('tempdb..#LeanHisPPH_S') IS NOT NULL " +
                    "BEGIN DROP TABLE #LeanHisPPH_S END; " +

                    "SELECT Building, Lean, CAST(ROUND(SUM(HisPPH_S * Pairs) / SUM(Pairs), 2) AS NUMERIC(5, 2)) AS LeanHisPPH_S INTO #LeanHisPPH_S FROM #SC " +
                    "WHERE HisPPH_S IS NOT NULL " +
                    "GROUP BY Building, Lean " +

                    "SELECT Building, UPPER(Lean) AS Lean, LeanTargetEff, /*LeanActualEff_A, LeanActualEff_S,*/ LeanHisEff_A, LeanHisEff_S, LeanHisPPH_A, LeanHisPPH_S, DATEADD(SECOND, ROUND(86400 * (SSeq - 1) / SQty, 0), SDate) AS SDate, " +
                    "CASE WHEN DATEADD(SECOND, ROUND(86400 * ESeq / EQty, 0), EDate) > '{1}' THEN DATEADD(DAY, 1, '{1}') ELSE DATEADD(SECOND, ROUND(86400 * ESeq / EQty, 0), EDate) END AS EDate, " +
                    "DATEDIFF(SECOND, DATEADD(SECOND, ROUND(86400 * (SSeq - 1) / SQty, 0), SDate), CASE WHEN DATEADD(SECOND, ROUND(86400 * ESeq / EQty, 0), EDate) > '{1}' THEN DATEADD(DAY, 1, '{1}') ELSE DATEADD(SECOND, ROUND(86400 * ESeq / EQty, 0), EDate) END) AS Value, " +
                    "BUY, RYTYPE, RY, Pairs, GAC, CuttingDie, SKU, ModelCategory, StitchingCode, IE_LaborS, AssemblyCode, IE_LaborA, DaysBeforeGAC, TargetEff, PM_Capacity, IE_Capacity, " +
                    //"CASE WHEN Eff_RY_A >= 90 THEN '高於 90%' ELSE CASE WHEN Eff_RY_A >= 80 THEN '高於 80%' ELSE CASE WHEN Eff_RY_A > 0 THEN '低於 80%' ELSE '未設定參數' END END END AS C_Eff_RY_A, Eff_RY_A, " +
                    //"CASE WHEN Eff_RY_S >= 90 THEN '高於 85%' ELSE CASE WHEN Eff_RY_S >= 70 THEN '高於 70%' ELSE CASE WHEN Eff_RY_S > 0 THEN '低於 70%' ELSE '未設定參數' END END END AS C_Eff_RY_S, Eff_RY_S, " +
                    "CASE WHEN HisEff_A >= 90 THEN '高於 90%' ELSE CASE WHEN HisEff_A >= 80 THEN '高於 80%' ELSE CASE WHEN HisEff_A > 0 THEN '低於 80%' ELSE '未設定參數' END END END AS C_HisEff_A, HisEff_A, " +
                    "CASE WHEN PPHRate_A >= 90 THEN '高於 90%' ELSE CASE WHEN PPHRate_A >= 80 THEN '高於 80%' ELSE CASE WHEN PPHRate_A > 0 THEN '低於 80%' ELSE '未設定參數' END END END AS C_HisPPH_A, HisPPH_A, TargetPPH_A, PPHRate_A, " +
                    "CASE WHEN HisEff_S >= 85 THEN '高於 85%' ELSE CASE WHEN HisEff_S >= 70 THEN '高於 70%' ELSE CASE WHEN HisEff_S > 0 THEN '低於 70%' ELSE '未設定參數' END END END AS C_HisEff_S, HisEff_S, " +
                    "CASE WHEN PPHRate_S >= 90 THEN '高於 90%' ELSE CASE WHEN PPHRate_S >= 80 THEN '高於 80%' ELSE CASE WHEN PPHRate_S > 0 THEN '低於 80%' ELSE '未設定參數' END END END AS C_HisPPH_S, HisPPH_S, TargetPPH_S, PPHRate_S, Lean_S, " +
                    "CASE WHEN TargetEff >= 90 THEN '高於 90%' ELSE CASE WHEN TargetEff >= 80 THEN '高於 80%' ELSE CASE WHEN TargetEff > 0 THEN '低於 80%' ELSE '未設定參數' END END END AS C_TargetEff, " +
                    "CASE WHEN DaysBeforeGAC <= 5 THEN '5 天內' ELSE CASE WHEN DaysBeforeGAC <= 10 THEN '10 天內' ELSE CASE WHEN DaysBeforeGAC <= 20 THEN '20 天內' ELSE '超過 20 天' END END END AS GACCategory, " +
                    "CASE WHEN GRateLaborS <= 5 THEN '低於 5%' ELSE CASE WHEN GRateLaborS <= 15 THEN '低於 15%' ELSE CASE WHEN GRateLaborS > 15 THEN '高於 15%' ELSE '未設定參數' END END END AS LSCategory, " +
                    "CASE WHEN GRateLaborA <= 5 THEN '低於 5%' ELSE CASE WHEN GRateLaborA <= 15 THEN '低於 15%' ELSE CASE WHEN GRateLaborA > 15 THEN '高於 15%' ELSE '未設定參數' END END END AS LACategory FROM ( " +
                    "  SELECT SC.Building, SC.Lean, LTE.LeanTargetEff, /*LAE_A.LeanActualEff_A, LAE_S.LeanActualEff_S,*/ LHE_A.LeanHisEff_A, LHE_S.LeanHisEff_S, LHP_A.LeanHisPPH_A, LHP_S.LeanHisPPH_S, CASE WHEN SC.SDate >= '{0}' THEN SC.SDate ELSE '{0}' END AS SDate, " +
                    "  SC.EDate, SC.BUY, SC.RYTYPE, SC.Seq, SC.RY, SC.Pairs, SC.GAC, ISNULL(DATEDIFF(DAY, SC.EDate, SC.GAC), 0) AS DaysBeforeGAC, SC.CuttingDie, SC.SKU, SC.ModelCategory, /*ISNULL(RYEff_A.Eff, -1) AS Eff_RY_A, ISNULL(RYEff_S.Eff, -1) AS Eff_RY_S,*/ " +
                    "  ISNULL(SC.StitchingCode, '未設定') AS StitchingCode, SC.IE_LaborS, SC.GRateLaborS, ISNULL(SC.AssemblyCode, '未設定') AS AssemblyCode, SC.IE_LaborA, SC.GRateLaborA, " +
                    "  ISNULL(CAST(ROUND(HisEff_A * 100, 2) AS NUMERIC(6, 2)), -1) AS HisEff_A, ISNULL(HisPPH_A, -1) AS HisPPH_A, ISNULL(TargetPPH_A, 0) AS TargetPPH_A, CASE WHEN TargetPPH_A > 0 THEN ISNULL(CAST(HisPPH_A * 100.0 / TargetPPH_A AS NUMERIC(6, 2)), 0) ELSE 0 END AS PPHRate_A, " +
                    "  ISNULL(CAST(ROUND(HisEff_S * 100, 2) AS NUMERIC(6, 2)), -1) AS HisEff_S, ISNULL(HisPPH_S, -1) AS HisPPH_S, ISNULL(TargetPPH_S, 0) AS TargetPPH_S, CASE WHEN TargetPPH_S > 0 THEN ISNULL(CAST(HisPPH_S * 100.0 / TargetPPH_S AS NUMERIC(6, 2)), 0) ELSE 0 END AS PPHRate_S, Lean_S, " +
                    "  ISNULL(PM_Capacity, 0) AS PM_Capacity, ISNULL(IE_Capacity, 0) AS IE_Capacity, ISNULL(CAST(ROUND(PM_Capacity * 100.0 / IE_Capacity, 2) AS NUMERIC(5, 2)), -1) AS TargetEff, DRS.Qty AS SQty, RSS.Seq AS SSeq, DRE.Qty AS EQty, RSE.Seq AS ESeq FROM #SC AS SC " +
                    "  LEFT JOIN #DayRY AS DRS ON DRS.Building = SC.Building AND DRS.Lean = SC.Lean AND DRS.Date = SC.SDate " +
                    "  LEFT JOIN #RYSeq AS RSS ON RSS.Building = SC.Building AND RSS.Lean = SC.Lean AND RSS.Date = SC.SDate AND RSS.RY = SC.RY " +
                    "  LEFT JOIN #DayRY AS DRE ON DRE.Building = SC.Building AND DRE.Lean = SC.Lean AND DRE.Date = SC.EDate " +
                    "  LEFT JOIN #RYSeq AS RSE ON RSE.Building = SC.Building AND RSE.Lean = SC.Lean AND RSE.Date = SC.EDate AND RSE.RY = SC.RY " +
                    "  LEFT JOIN #LeanTargetEff AS LTE ON LTE.Building = SC.Building AND LTE.Lean = SC.Lean " +
                    //"  LEFT JOIN #LeanActualEff_A AS LAE_A ON LAE_A.Building = SC.Building AND LAE_A.Lean = SC.Lean " +
                    //"  LEFT JOIN #LeanActualEff_S AS LAE_S ON LAE_S.Building = SC.Building AND LAE_S.Lean = SC.Lean " +
                    "  LEFT JOIN #LeanHisEff_A AS LHE_A ON LHE_A.Building = SC.Building AND LHE_A.Lean = SC.Lean " +
                    "  LEFT JOIN #LeanHisEff_S AS LHE_S ON LHE_S.Building = SC.Building AND LHE_S.Lean = SC.Lean " +
                    "  LEFT JOIN #LeanHisPPH_A AS LHP_A ON LHP_A.Building = SC.Building AND LHP_A.Lean = SC.Lean " +
                    "  LEFT JOIN #LeanHisPPH_S AS LHP_S ON LHP_S.Building = SC.Building AND LHP_S.Lean = SC.Lean " +
                    //"  LEFT JOIN #RYEff AS RYEff_A ON RYEff_A.RY = SC.RY AND RYEff_A.GXLB = 'A' " +
                    //"  LEFT JOIN #RYEff AS RYEff_S ON RYEff_S.RY = SC.RY AND RYEff_S.GXLB = 'S' " +
                    ") AS SC " +
                    "ORDER BY Building, Lean, SDate, Seq; "
                    , request.StartDate, request.EndDate, request.Area, request.Building, LastMonthFirstDate, LastMonthLastDate, NextMonthFirstDate, NextMonthLastDate, request.Version, request.OrderDate
                ), ERP
            );

            DataTable dt = new DataTable();
            da.Fill(dt);

            SqlDataAdapter da2 = new SqlDataAdapter(
                System.String.Format(
                    "WITH TEMPTAB(Date) AS ( " +
                    "  SELECT CONVERT(SmallDateTime, '{0}') " +
                    "  UNION ALL " +
                    "  SELECT DATEADD(D, 1, TEMPTAB.DATE) AS Date FROM TEMPTAB " +
                    "  WHERE DATEADD(D, 1, TEMPTAB.DATE) <= CONVERT(SmallDateTime, '{1}') " +
                    ") " +

                    "SELECT LeanList.Building, LeanList.Lean, CONVERT(VARCHAR, LeanList.Date, 111) AS SDate, CONVERT(VARCHAR, LeanList.Date + 1, 111) AS EDate, " +
                    "ISNULL(CASE WHEN SCRL.WorkHour = 8 THEN '8 小時' ELSE CASE WHEN SCRL.WorkHour = 9.5 THEN '9.5 小時' ELSE CASE WHEN SCRL.WorkHour = 12 THEN '12 小時' END END END, '無') AS WorkHour FROM ( " +
                    "  SELECT TEMPTAB.Date, SC.Building, SC.Lean FROM TEMPTAB " +
                    "  LEFT JOIN ( " +
                    "    SELECT DISTINCT building_no AS Building, LEFT(lean_no, 6) AS Lean FROM schedule_crawler " +
                    "    WHERE schedule_date BETWEEN '{0}' AND '{1}' AND building_no LIKE '{2}%' AND building_no LIKE '{3}%' " +
                    "  ) AS SC ON 1 = 1 " +
                    "  LEFT JOIN ( " +
                    "    SELECT DISTINCT SUBSTRING(BDepartment.DepName, 1, 3) AS Building, SUBSTRING(BDepartment.DepName, 5, 6) AS Lean FROM SCRL " +
                    "    LEFT JOIN BDepartment ON BDepartment.ID = SCRL.DepNO " +
                    "    WHERE CONVERT(SmallDateTime, SCRL.SCYEAR + '/' + SCRL.SCMONTH + '/' + SCRL.SCDay) BETWEEN '{0}' AND '{1}' " +
                    "    AND BDepartment.GXLB = 'A' AND SUBSTRING(BDepartment.DepName, 1, 1) LIKE '{2}%' AND SUBSTRING(BDepartment.DepName, 1, 3) LIKE '{3}%' " +
                    "  ) AS LeanList ON 1 = 1 " +
                    ") AS LeanList " +
                    "LEFT JOIN ( " +
                    "  SELECT SUBSTRING(BDepartment.DepName, 1, 3) AS Building, SUBSTRING(BDepartment.DepName, 5, 6) AS Lean, " +
                    "  CONVERT(SmallDateTime, SCRL.SCYEAR + '/' + SCRL.SCMONTH + '/' + SCRL.SCDay) AS Date, SCRL.SCGS AS WorkHour FROM SCRL " +
                    "  LEFT JOIN BDepartment ON BDepartment.ID = SCRL.DepNO " +
                    "  WHERE CONVERT(SmallDateTime, SCRL.SCYEAR + '/' + SCRL.SCMONTH + '/' + SCRL.SCDay) BETWEEN '{0}' AND '{1}' " +
                    "  AND BDepartment.GXLB = 'A' AND SUBSTRING(BDepartment.DepName, 1, 1) LIKE '{2}%' AND SUBSTRING(BDepartment.DepName, 1, 3) LIKE '{3}%' " +
                    ") AS SCRL ON SCRL.Date = LeanList.Date AND SCRL.Building = LeanList.Building AND SCRL.Lean = LeanList.Lean " +
                    "ORDER BY LeanList.Building, LeanList.Lean, LeanList.Date " +
                    "OPTION (MAXRECURSION 0) "
                    , request.StartDate, request.EndDate, request.Area, request.Building
                ), ERP
            );

            DataTable dt2 = new DataTable();
            da2.Fill(dt2);

            if (dt.Rows.Count > 0)
            {
                List<ProductionScheduleLean> LeanList = new List<ProductionScheduleLean>();
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    ProductionScheduleLean leanSchedule = new ProductionScheduleLean();
                    leanSchedule.Building = dt.Rows[Row]["Building"].ToString();
                    leanSchedule.Lean = dt.Rows[Row]["Lean"].ToString();
                    leanSchedule.TargetEff = dt.Rows[Row]["LeanTargetEff"].ToString();
                    //leanSchedule.ActualEff_A = dt.Rows[Row]["LeanActualEff_A"].ToString();
                    //leanSchedule.ActualEff_S = dt.Rows[Row]["LeanActualEff_S"].ToString();
                    leanSchedule.HisEff_A = dt.Rows[Row]["LeanHisEff_A"].ToString();
                    leanSchedule.HisEff_S = dt.Rows[Row]["LeanHisEff_S"].ToString();
                    leanSchedule.HisPPH_A = dt.Rows[Row]["LeanHisPPH_A"].ToString();
                    leanSchedule.HisPPH_S = dt.Rows[Row]["LeanHisPPH_S"].ToString();
                    leanSchedule.Schedule = new List<ProductionSchedule>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["Lean"].ToString() == leanSchedule.Lean)
                    {
                        ProductionSchedule schedule = new ProductionSchedule();
                        schedule.StartDate = ((DateTime)dt.Rows[Row]["SDate"]).ToString("yyyy/MM/dd hh:mm:ss");
                        schedule.EndDate = ((DateTime)dt.Rows[Row]["EDate"]).ToString("yyyy/MM/dd hh:mm:ss");
                        schedule.Value = (int)dt.Rows[Row]["Value"];
                        schedule.BUY = dt.Rows[Row]["BUY"].ToString();
                        schedule.Type = dt.Rows[Row]["RYTYPE"].ToString();
                        schedule.RY = dt.Rows[Row]["RY"].ToString();
                        schedule.Pairs = dt.Rows[Row]["Pairs"] != DBNull.Value ? (int)dt.Rows[Row]["Pairs"] : 0;
                        schedule.GAC = dt.Rows[Row]["GAC"] != DBNull.Value ? ((DateTime)dt.Rows[Row]["GAC"]).ToString("yyyy/MM/dd") : "";
                        schedule.CuttingDie = dt.Rows[Row]["CuttingDie"].ToString();
                        schedule.SKU = dt.Rows[Row]["SKU"].ToString();
                        schedule.ModelCategory = dt.Rows[Row]["ModelCategory"].ToString();
                        schedule.StitchingCode = dt.Rows[Row]["StitchingCode"].ToString();
                        schedule.IE_LaborS = dt.Rows[Row]["IE_LaborS"] != DBNull.Value ? (int)dt.Rows[Row]["IE_LaborS"] : 0;
                        schedule.LSCategory = dt.Rows[Row]["LSCategory"].ToString();
                        schedule.AssemblyCode = dt.Rows[Row]["AssemblyCode"].ToString();
                        schedule.IE_LaborA = dt.Rows[Row]["IE_LaborA"] != DBNull.Value ? (int)dt.Rows[Row]["IE_LaborA"] : 0;
                        schedule.LACategory = dt.Rows[Row]["LACategory"].ToString();
                        schedule.DaysBeforeGAC = (int)dt.Rows[Row]["DaysBeforeGAC"];
                        schedule.GACCategory = dt.Rows[Row]["GACCategory"].ToString();
                        schedule.PM_Capacity = (int)dt.Rows[Row]["PM_Capacity"];
                        schedule.IE_Capacity = (int)dt.Rows[Row]["IE_Capacity"];
                        //schedule.C_Eff_RY_A = dt.Rows[Row]["C_Eff_RY_A"].ToString();
                        //schedule.Eff_RY_A = dt.Rows[Row]["Eff_RY_A"].ToString();
                        //schedule.C_Eff_RY_S = dt.Rows[Row]["C_Eff_RY_S"].ToString();
                        //schedule.Eff_RY_S = dt.Rows[Row]["Eff_RY_S"].ToString();
                        schedule.C_TargetEff = dt.Rows[Row]["C_TargetEff"].ToString();
                        schedule.TargetEff = dt.Rows[Row]["TargetEff"].ToString();
                        schedule.C_HisEff_A = dt.Rows[Row]["C_HisEff_A"].ToString();
                        schedule.HisEff_A = dt.Rows[Row]["HisEff_A"].ToString();
                        schedule.C_HisPPH_A = dt.Rows[Row]["C_HisPPH_A"].ToString();
                        schedule.HisPPH_A = dt.Rows[Row]["HisPPH_A"].ToString();
                        schedule.TargetPPH_A = dt.Rows[Row]["TargetPPH_A"].ToString();
                        schedule.PPHRate_A = dt.Rows[Row]["PPHRate_A"].ToString();
                        schedule.C_HisEff_S = dt.Rows[Row]["C_HisEff_S"].ToString();
                        schedule.HisEff_S = dt.Rows[Row]["HisEff_S"].ToString();
                        schedule.C_HisPPH_S = dt.Rows[Row]["C_HisPPH_S"].ToString();
                        schedule.HisPPH_S = dt.Rows[Row]["HisPPH_S"].ToString();
                        schedule.TargetPPH_S = dt.Rows[Row]["TargetPPH_S"].ToString();
                        schedule.PPHRate_S = dt.Rows[Row]["PPHRate_S"].ToString();
                        schedule.Lean_S = dt.Rows[Row]["Lean_S"].ToString();

                        leanSchedule.Schedule.Add(schedule);
                        Row++;
                    }

                    leanSchedule.WorkDays = new List<WorkDay>();
                    DataRow[] results = dt2.Select("Building = '" + leanSchedule.Building + "' AND Lean = '" + leanSchedule.Lean + "'");
                    
                    foreach (DataRow row in results)
                    {
                        WorkDay workDay = new WorkDay();
                        workDay.StartDate = row["SDate"].ToString();
                        workDay.EndDate = row["EDate"].ToString();
                        workDay.WorkHour = row["WorkHour"].ToString();

                        leanSchedule.WorkDays.Add(workDay);
                    }

                    LeanList.Add(leanSchedule);
                }

                return JsonConvert.SerializeObject(LeanList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getScheduleVersion")]
        public string getScheduleVersion(ProductionScheduleRequest request)
        {
            DateTime StartDate = DateTime.Parse(request.StartDate!);
            DateTime EndDate = DateTime.Parse(request.EndDate!);

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#BVer') IS NOT NULL " +
                    "BEGIN DROP TABLE #BVer END; " +

                    "SELECT DISTINCT building_no, version INTO #BVer FROM schedule_history " +
                    "WHERE schedule_date BETWEEN '{0}' AND '{1}' AND building_no LIKE '{2}%' AND building_no LIKE '{3}%' AND building_no NOT IN ('A11', 'PM') AND building_no + lean_no <> 'A12Lean05' " +

                    "SELECT BVer.Ver, CONVERT(VARCHAR, MAX(DDZL.DDRQ), 111) AS OrderDate FROM ( " +
                    "  SELECT Building, Ver, version FROM ( " +
                    "    SELECT B.Building, V.Ver, #BVer.version, ROW_NUMBER() OVER(PARTITION BY B.Building, V.Ver ORDER BY #BVer.version DESC) AS Seq FROM ( " +
                    "      SELECT DISTINCT building_no AS Building FROM #BVer " +
                    "    ) AS B " +
                    "    LEFT JOIN ( " +
                    "      SELECT DISTINCT version AS Ver FROM #BVer " +
                    "    ) AS V ON 1 = 1 " +
                    "    LEFT JOIN #BVer ON #BVer.building_no = B.Building AND #BVer.version <= V.Ver " +
                    "  ) AS BVer " +
                    "  WHERE Seq = 1 " +
                    ") AS BVer " +
                    "LEFT JOIN schedule_history AS SH ON SH.building_no = BVer.Building AND SH.version = BVer.version " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SH.ry) - LEN(REPLACE(SH.ry, '-', '')) < 2 THEN SH.ry ELSE SUBSTRING(SH.ry, 1, LEN(SH.ry) - CHARINDEX('-', REVERSE(SH.ry))) END " +
                    "GROUP BY BVer.Ver " +
                    "ORDER BY BVer.Ver DESC "
                    , request.StartDate, request.EndDate, request.Area, request.Building
                ), ERP
            );

            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<ScheduleVersion> VersionList = new List<ScheduleVersion>();
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    ScheduleVersion version = new ScheduleVersion();
                    version.Version = dt.Rows[Row]["Ver"].ToString();
                    version.OrderDate = dt.Rows[Row]["OrderDate"].ToString();

                    VersionList.Add(version); 
                    Row++;
                }

                return JsonConvert.SerializeObject(VersionList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getStage1Date")]
        public string getStage1Date(ProductionScheduleRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT CONVERT(VARCHAR, MAX(DDZL.DDRQ), 111) AS OrderDate FROM ( " +
                    "  SELECT building_no, MAX(version) AS version FROM schedule_history " +
                    "  WHERE version <= (SELECT TOP 1 Version FROM schedule_stage1 WHERE BUY = '{0}') " +
                    "  GROUP BY building_no " +
                    ") AS Ver " +
                    "LEFT JOIN schedule_history AS SH ON SH.building_no = Ver.building_no AND SH.version = Ver.version " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SH.ry) - LEN(REPLACE(SH.ry, '-', '')) < 2 THEN SH.ry ELSE SUBSTRING(SH.ry, 1, LEN(SH.ry) - CHARINDEX('-', REVERSE(SH.ry))) END "
                    , request.Version
                ), ERP
            );

            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                return dt.Rows[0]["OrderDate"].ToString()!;
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getEstimatedInfo")]
        public string getEstimatedInfo(ProductionScheduleRequest request)
        {
            DateTime StartDate = DateTime.Parse(request.StartDate!);
            DateTime EndDate = DateTime.Parse(request.EndDate!);
            string LastMonthFirstDate = new DateTime(StartDate.AddMonths(-1).Year, StartDate.AddMonths(-1).Month, 1).ToString("yyyy/MM/dd");
            string LastMonthLastDate = new DateTime(StartDate.Year, StartDate.Month, 1).AddDays(-1).ToString("yyyy/MM/dd");

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#LeanModel') IS NOT NULL " +
                    "BEGIN DROP TABLE #LeanModel END; " +

                    "SELECT SC.Building, 'LINE ' + RIGHT('00' + CAST(CAST(RIGHT(SC.Lean, 2) AS INT) AS VARCHAR), 2) AS Lean, SC.Seq, SC.RY, SC.Pairs, " + (request.Mode == "CuttingDie" ? "XXZL.DAOMH AS Model" : "XXZL.ARTICLE AS Model") + ", ISNULL(MS.Capacity, 180) * 1.0 / IE_A.BZCL AS TargetEff, " +
                    "ISNULL(IE_A.BZRS, 0) + ISNULL(IE_A.BZJS, 0) + ISNULL(IE_P.BZRS, 0) + ISNULL(IE_P.BZJS, 0) AS Labor_A, ISNULL(ISNULL(MP_A.Eff, CDP_A.Eff), LMP_A.Eff) AS Eff_A, " +
                    "ISNULL(IE_S.BZRS, 0) + ISNULL(IE_S.BZJS, 0) AS Labor_S, ISNULL(ISNULL(MP_S.Eff, CDP_S.Eff), LMP_S.Eff) AS Eff_S, " +
                    "CASE WHEN OldModel.DAOMH IS NULL THEN CASE ISNULL(KFXXZL.KFLX, '') WHEN 'CU' THEN 'NC' WHEN 'MU' THEN 'NM' WHEN 'MU+' THEN 'NM+' ELSE ISNULL(KFXXZL.KFLX, 'OLD') END ELSE 'OLD' END AS Type INTO #LeanModel FROM ( " +
                    "  SELECT ROW_NUMBER() OVER(PARTITION BY SC.building_no, SC.lean_no ORDER BY SC.schedule_date, SC.ry_index) AS Seq, SC.building_no AS Building, SC.lean_no AS Lean, " +
                    "  RIGHT(CONVERT(VARCHAR, SC.schedule_date, 111), 5) AS Date, DDZL.DDBH AS RY, CAST(SC.sl AS INT) AS Pairs, DDZL.XieXing, DDZL.SheHao FROM schedule_crawler AS SC " +
                    "  LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END " +
                    "  WHERE SC.building_no = '{0}' AND SC.schedule_date BETWEEN '{1}' AND '{2}' " +
                    "  UNION ALL " +
                    "  SELECT 0 AS Seq, Building, Lean, Date, RY, Pairs, XieXing, SheHao FROM ( " +
                    "    SELECT ROW_NUMBER() OVER(PARTITION BY SC.building_no, SC.lean_no ORDER BY SC.schedule_date DESC, SC.ry_index DESC) AS Seq, SC.building_no AS Building, SC.lean_no AS Lean, " +
                    "    RIGHT(CONVERT(VARCHAR, SC.schedule_date, 111), 5) AS Date, DDZL.DDBH AS RY, CAST(SC.sl AS INT) AS Pairs, DDZL.XieXing, DDZL.SheHao FROM schedule_crawler AS SC " +
                    "    LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END " +
                    "    WHERE SC.building_no = '{0}' AND SC.schedule_date BETWEEN '{3}' AND '{4}' " +
                    "  ) AS PSC " +
                    "  WHERE Seq = 1 " +
                    ") AS SC " +
                    "LEFT JOIN XXZL ON XXZL.XieXing = SC.XieXing AND XXZL.SheHao = SC.SheHao " +
                    "LEFT JOIN KFXXZL ON KFXXZL.XieXing = SC.XieXing AND KFXXZL.SheHao = SC.SheHao " +
                    "LEFT JOIN SCXXCL AS IE_S ON IE_S.XieXing = SC.XieXing AND IE_S.SheHao = SC.SheHao AND IE_S.GXLB = 'S' AND IE_S.BZLB = '3' " +
                    "LEFT JOIN SCXXCL AS IE_A ON IE_A.XieXing = SC.XieXing AND IE_A.SheHao = SC.SheHao AND IE_A.GXLB = 'A' AND IE_A.BZLB = '3' " +
                    "LEFT JOIN SCXXCL AS IE_P ON IE_P.XieXing = SC.XieXing AND IE_P.SheHao = SC.SheHao AND IE_P.GXLB = 'P' AND IE_P.BZLB = '3' " +
                    "LEFT JOIN ( " +
                    "  SELECT Building, Lean, XieXing, SheHao, Efficiency AS Eff, PPH FROM ( " +
                    "    SELECT Building, Lean, XieXing, SheHao, Efficiency, PPH, ROW_NUMBER() OVER(PARTITION BY Building, Lean, XieXing, SheHao ORDER BY Year DESC, Month DESC) AS Seq FROM ModelPerformance " +
                    "    WHERE Building = '{0}' AND Section = 'A' " +
                    "  ) AS MS " +
                    "  WHERE Seq = 1 " +
                    ") AS MP_A ON MP_A.Building = SC.Building AND MP_A.Lean = SC.Lean AND MP_A.XieXing = SC.XieXing AND MP_A.SheHao = SC.SheHao " +
                    "LEFT JOIN ( " +
                    "  SELECT Building, Lean, DAOMH, Eff, PPH FROM ( " +
                    "    SELECT CDP.Year, CDP.Month, CDP.Building, CDP.Lean, XXZL.DAOMH, CAST(AVG(CDP.Efficiency) AS NUMERIC(5, 4)) AS Eff, CAST(AVG(CDP.PPH) AS NUMERIC(3, 2)) AS PPH, " +
                    "    ROW_NUMBER() OVER(PARTITION BY CDP.Building, CDP.Lean, XXZL.DAOMH ORDER BY CDP.Year DESC, CDP.Month DESC) AS Seq FROM ModelPerformance AS CDP " +
                    "    LEFT JOIN XXZL ON XXZL.XieXing = CDP.XieXing AND XXZL.SheHao = CDP.SheHao " +
                    "    WHERE CDP.Building = '{0}' AND CDP.Section = 'A' " +
                    "    GROUP BY CDP.Year, CDP.Month, CDP.Building, CDP.Lean, XXZL.DAOMH " +
                    "  ) AS CDP " +
                    "  WHERE Seq = 1 " +
                    ") AS CDP_A ON CDP_A.Building = SC.Building AND CDP_A.Lean = SC.Lean AND CDP_A.DAOMH = XXZL.DAOMH " +
                    "LEFT JOIN ( " +
                    "  SELECT LM.Building, LM.Lean, CAST(SUM(MP.Efficiency * MP.Pairs) / SUM(MP.Pairs) AS NUMERIC(5, 4)) AS Eff, CAST(SUM(MP.PPH * MP.Pairs) / SUM(Pairs) AS NUMERIC(3, 2)) AS PPH FROM ( " +
                    "    SELECT Building, Lean, Month FROM ( " +
                    "      SELECT Building, Lean, Month, ROW_NUMBER() OVER(PARTITION BY Building, Lean ORDER BY Month DESC) AS Seq FROM ( " +
                    "        SELECT DISTINCT Building, Lean, Year + '/' + Month AS Month FROM ModelPerformance " +
                    "        WHERE Year + '/' + Month <= SUBSTRING('{3}', 1, 7) AND Building = '{0}' AND Section = 'A' " +
                    "      ) AS MP " +
                    "    ) AS MP " +
                    "    WHERE Seq = 1 " +
                    "  ) AS LM " +
                    "  LEFT JOIN ModelPerformance AS MP ON MP.Building = LM.Building AND MP.Lean = LM.Lean AND MP.Year + '/' + MP.Month = LM.Month " +
                    "  GROUP BY LM.Building, LM.Lean " +
                    ") AS LMP_A ON LMP_A.Building = SC.Building AND LMP_A.Lean = SC.Lean " +
                    "LEFT JOIN ( " +
                    "  SELECT Building, Lean, Lean_S, XieXing, SheHao, Efficiency AS Eff, PPH FROM ( " +
                    "    SELECT ISNULL(SF.Building_TX, MP.Building) AS Building, ISNULL(SF.Lean_TX, MP.Lean) AS Lean, SF.Building_VL + ' - ' + SF.Lean_VL AS Lean_S, MP.XieXing, MP.SheHao, MP.Efficiency, MP.PPH, " +
                    "    ROW_NUMBER() OVER(PARTITION BY ISNULL(SF.Building_TX, MP.Building), ISNULL(SF.Lean_TX, MP.Lean), MP.XieXing, MP.SheHao ORDER BY MP.Year DESC, MP.Month DESC) AS Seq FROM ModelPerformance AS MP " +
                    "    LEFT JOIN schedule_factorylink AS SF ON SF.Year = MP.Year AND SF.Month = MP.Month AND SF.Building_VL = MP.Building AND SF.Lean_VL = MP.Lean " +
                    "    WHERE ISNULL(SF.Building_TX, MP.Building) = '{0}' AND MP.Section = 'S' " +
                    "  ) AS MS " +
                    "  WHERE Seq = 1 " +
                    ") AS MP_S ON MP_S.Building = SC.Building AND MP_S.Lean = SC.Lean AND MP_S.XieXing = SC.XieXing AND MP_S.SheHao = SC.SheHao " +
                    "LEFT JOIN ( " +
                    "  SELECT Building, Lean, Lean_S, DAOMH, Eff, PPH FROM ( " +
                    "    SELECT CDP.Year, CDP.Month, ISNULL(SF.Building_TX, CDP.Building) AS Building, ISNULL(SF.Lean_TX, CDP.Lean) AS Lean, SF.Building_VL + ' - ' + SF.Lean_VL AS Lean_S, XXZL.DAOMH, CAST(AVG(CDP.Efficiency) AS NUMERIC(5, 4)) AS Eff, CAST(AVG(CDP.PPH) AS NUMERIC(5, 2)) AS PPH, " +
                    "    ROW_NUMBER() OVER(PARTITION BY ISNULL(SF.Building_TX, CDP.Building), ISNULL(SF.Lean_TX, CDP.Lean), XXZL.DAOMH ORDER BY CDP.Year DESC, CDP.Month DESC) AS Seq FROM ModelPerformance AS CDP " +
                    "    LEFT JOIN schedule_factorylink AS SF ON SF.Year = CDP.Year AND SF.Month = CDP.Month AND SF.Building_VL = CDP.Building AND SF.Lean_VL = CDP.Lean " +
                    "    LEFT JOIN XXZL ON XXZL.XieXing = CDP.XieXing AND XXZL.SheHao = CDP.SheHao " +
                    "    WHERE ISNULL(SF.Building_TX, CDP.Building) = '{0}' AND CDP.Section = 'S' " +
                    "    GROUP BY CDP.Year, CDP.Month, ISNULL(SF.Building_TX, CDP.Building), ISNULL(SF.Lean_TX, CDP.Lean), SF.Building_VL, SF.Lean_VL, XXZL.DAOMH " +
                    "  ) AS CDP " +
                    "  WHERE Seq = 1 " +
                    ") AS CDP_S ON CDP_S.Building = SC.Building AND CDP_S.Lean = SC.Lean AND CDP_S.DAOMH = XXZL.DAOMH " +
                    "LEFT JOIN ( " +
                    "  SELECT LL.Building, LL.Lean, CASE WHEN LL.Lean_VL IS NULL THEN ISNULL(HisEff_TX.Eff, HisEff_VL.Eff) ELSE ISNULL(HisEff_VL.Eff, HisEff_TX.Eff) END AS Eff FROM ( " +
                    "    SELECT DISTINCT SC.building_no AS Building, SC.lean_no AS Lean, SF.Lean_VL FROM schedule_crawler AS SC " +
                    "    LEFT JOIN schedule_factorylink AS SF ON SF.Building_TX = SC.building_no AND SF.Lean_TX = SC.lean_no AND SF.Year + '/' + SF.Month = SUBSTRING('{1}', 1, 7) " +
                    "    WHERE SC.building_no = '{0}' AND SC.schedule_date BETWEEN '{1}' AND '{2}' " +
                    "  ) AS LL " +
                    "  LEFT JOIN ( " +
                    "    SELECT Building, Lean, Eff, PPH FROM ( " +
                    "      SELECT ROW_NUMBER() OVER(PARTITION BY Building, Lean ORDER BY Year DESC, Month DESC) AS Seq, " +
                    "      Building, Lean, CAST(SUM(Efficiency * Pairs) / SUM(Pairs) AS NUMERIC(6, 3)) AS Eff, CAST(SUM(PPH * Pairs) / SUM(Pairs) AS NUMERIC(6, 3)) AS PPH FROM ModelPerformance " +
                    "      WHERE Year + '/' + Month <= SUBSTRING('{3}', 1, 7) AND Building = '{0}' AND Section = 'S' " +
                    "      GROUP BY Building, Lean, Year, Month " +
                    "    ) AS HisEff_TX " +
                    "    WHERE Seq = 1 " +
                    "  ) AS HisEff_TX ON HisEff_TX.Building = LL.Building AND HisEff_TX.Lean = LL.Lean " +
                    "  LEFT JOIN ( " +
                    "    SELECT Building_TX, Lean_TX, Eff, PPH FROM ( " +
                    "      SELECT ROW_NUMBER() OVER(PARTITION BY Building_TX, Lean_TX ORDER BY MP.Year DESC, MP.Month DESC) AS Seq, " +
                    "      Building_TX, Lean_TX, CAST(AVG(MP.Efficiency) AS NUMERIC(6, 3)) AS Eff, CAST(AVG(MP.PPH) AS NUMERIC(6, 3)) AS PPH FROM ( " +
                    "        SELECT Building_VL, Lean_VL, Building_TX, Lean_TX, 'S' AS Section FROM ( " +
                    "          SELECT ROW_NUMBER() OVER(PARTITION BY Building_VL, Lean_VL ORDER BY Year DESC, Month DESC) AS Seq, Building_VL, Lean_VL, Building_TX, Lean_TX FROM schedule_factorylink " +
                    "          WHERE Year + '/' + Month >= SUBSTRING('{3}', 1, 7) AND Building_TX = '{0}' " +
                    "        ) AS SF " +
                    "        WHERE Seq = 1 " +
                    "      ) AS SF " +
                    "      LEFT JOIN ModelPerformance AS MP ON MP.Building = SF.Building_VL AND MP.Lean = SF.Lean_VL AND MP.Section = SF.Section " +
                    "      WHERE MP.Year + '/' + MP.Month <= SUBSTRING('{3}', 1, 7) " +
                    "      GROUP BY Building_TX, Lean_TX, MP.Year, MP.Month " +
                    "    ) AS SF " +
                    "    WHERE Seq = 1 " +
                    "  ) AS HisEff_VL ON HisEff_VL.Building_TX = LL.Building AND HisEff_VL.Lean_TX = LL.Lean " +
                    ") AS LMP_S ON LMP_S.Building = SC.Building AND LMP_S.Lean = SC.Lean " +
                    "LEFT JOIN ( " +
                    "  SELECT Building, Lean, XieXing, SheHao, Capacity FROM ( " +
                    "    SELECT ROW_NUMBER() OVER(PARTITION BY Building, Lean, XieXing, SheHao ORDER BY Month DESC) AS Seq, Building, Lean, XieXing, SheHao, Capacity FROM ModelStandard " +
                    "    WHERE Building = '{0}' AND Month <= SUBSTRING('{1}', 1, 7) " +
                    "  ) AS MS " +
                    "  WHERE Seq = 1 " +
                    ") AS MS ON MS.Building = SC.Building AND MS.Lean = SC.Lean AND MS.XieXing = SC.XieXing AND MS.SheHao = SC.SheHao " +
                    "LEFT JOIN ( " +
                    "  SELECT DISTINCT SC.building_no AS Building, SC.lean_no AS Lean, XXZL.DAOMH FROM schedule_crawler AS SC " +
                    "  LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END " +
                    "  LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "  WHERE SC.building_no = '{0}' AND SUBSTRING(CONVERT(VARCHAR, SC.schedule_date, 111), 1, 7) <= SUBSTRING('{3}', 1, 7) " +
                    ") AS OldModel ON OldModel.Building = SC.Building AND OldModel.Lean = SC.Lean AND OldModel.DAOMH = XXZL.DAOMH " + 
                    "ORDER BY SC.Building, SC.Lean, SC.Seq " +

                    "IF OBJECT_ID('tempdb..#TechLevel') IS NOT NULL " +
                    "BEGIN DROP TABLE #TechLevel END; " +

                    "SELECT * INTO #TechLevel FROM ( " +
                    "  SELECT 'TN+' AS Type, 0.8 AS Weight UNION ALL " +
                    "  SELECT 'TN' AS Type, 0.85 AS Weight UNION ALL " +
                    "  SELECT 'NU+' AS Type, 0.875 AS Weight UNION ALL " +
                    "  SELECT 'NU' AS Type, 0.9 AS Weight UNION ALL " +
                    "  SELECT 'NU-' AS Type, 0.925 AS Weight UNION ALL " +
                    "  SELECT 'NP' AS Type, 0.95 AS Weight UNION ALL " +
                    "  SELECT 'NT' AS Type, 0.95 AS Weight UNION ALL " +
                    "  SELECT 'ND' AS Type, 0.95 AS Weight UNION ALL " +
                    "  SELECT 'NM+' AS Type, 0.95 AS Weight UNION ALL " +
                    "  SELECT 'NM' AS Type, 0.975 AS Weight UNION ALL " +
                    "  SELECT 'NG' AS Type, 1 AS Weight UNION ALL " +
                    "  SELECT 'NC' AS Type, 1 AS Weight UNION ALL " +
                    "  SELECT 'OLD' AS Type, 1 AS Weight " +
                    ") AS TechLevel " +

                    "SELECT HighRisk.Building, HighRisk.Lean, ISNULL(LeanTarget.TargetEff, 0) AS TargetEff, HighRisk.Section, LeanEff.EstEff, HighRisk.Model, HighRisk.Type, HighRisk.LaborDiff, ISNULL(ROUND(HighRisk.HisEff * TL.Weight, 3), 0) AS HisEff FROM ( " +
                    "  SELECT LM1.Building, LM1.Lean, 'A' AS Section, LM1.Model, LM1.Type, " +
                    "  MAX(ABS(LM1.Labor_A - LM2.Labor_A)) AS LaborDiff, CASE WHEN LM1.Eff_A > 1 THEN 1 ELSE LM1.Eff_A END AS HisEff FROM #LeanModel AS LM1 " +
                    "  LEFT JOIN #LeanModel AS LM2 ON LM2.Building = LM1.Building AND LM2.Lean = LM1.Lean AND LM2.Seq = LM1.Seq - 1 " +
                    "  WHERE LM2.RY IS NOT NULL AND (LM1.Model <> LM2.Model OR LM1.Seq = 1) " +
                    "  GROUP BY LM1.Building, LM1.Lean, LM1.Model, LM1.Type, LM1.Eff_A " +
                    "  UNION ALL " +
                    "  SELECT LM1.Building, LM1.Lean, 'S' AS Section, LM1.Model, LM1.Type, " +
                    "  MAX(ABS(LM1.Labor_S - LM2.Labor_S)) AS LaborDiff, CASE WHEN LM1.Eff_S > 1 THEN 1 ELSE LM1.Eff_S END AS HisEff FROM #LeanModel AS LM1 " +
                    "  LEFT JOIN #LeanModel AS LM2 ON LM2.Building = LM1.Building AND LM2.Lean = LM1.Lean AND LM2.Seq = LM1.Seq - 1 " +
                    "  WHERE LM2.RY IS NOT NULL AND (LM1.Model <> LM2.Model OR LM1.Seq = 1) " +
                    "  GROUP BY LM1.Building, LM1.Lean, LM1.Model, LM1.Type, LM1.Eff_S " +
                    ") AS HighRisk " +
                    "LEFT JOIN ( " +
                    "  SELECT Building, Lean, Section, CASE WHEN EstEff < 1 THEN EstEff ELSE 1 END AS EstEff FROM ( " +
                    "    SELECT Building, Lean, 'A' AS Section, ROUND(SUM(Pairs * Eff_A * TL.Weight) / SUM(Pairs), 3) AS EstEff FROM #LeanModel " +
                    "    LEFT JOIN #TechLevel AS TL ON TL.Type = #LeanModel.Type " +
                    "    WHERE Seq > 0 " +
                    "    GROUP BY Building, Lean " +
                    "    UNION ALL " +
                    "    SELECT Building, Lean, 'S' AS Section, ROUND(SUM(Pairs * Eff_S * TL.Weight) / SUM(Pairs), 3) AS EstEff FROM #LeanModel " +
                    "    LEFT JOIN #TechLevel AS TL ON TL.Type = #LeanModel.Type " +
                    "    WHERE Seq > 0 " +
                    "    GROUP BY Building, Lean " +
                    "  ) AS LeanEff " +
                    ") AS LeanEff ON LeanEff.Building = HighRisk.Building AND LeanEff.Lean = HighRisk.Lean AND LeanEff.Section = HighRisk.Section " +
                    "LEFT JOIN ( " +
                    "  SELECT Building, Lean, CAST(ROUND(SUM(CASE WHEN TargetEff < 1 THEN TargetEff ELSE 1 END * Pairs) / SUM(Pairs), 3) AS NUMERIC(4, 3)) AS TargetEff FROM #LeanModel " +
                    "  WHERE ISNULL(TargetEff, 0) > 0 " +
                    "  GROUP BY Building, Lean " +
                    ") AS LeanTarget ON LeanTarget.Building = HighRisk.Building AND LeanTarget.Lean = HighRisk.Lean " +
                    "LEFT JOIN #TechLevel AS TL ON TL.Type = HighRisk.Type " +
                    "ORDER BY HighRisk.Building, HighRisk.Lean, HighRisk.Section "
                    , request.Building, request.StartDate, request.EndDate, LastMonthFirstDate, LastMonthLastDate
                ), ERP
            );

            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<LeanEstimatedInfo> LeanList = new List<LeanEstimatedInfo>();
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    LeanEstimatedInfo estInfo = new LeanEstimatedInfo();
                    estInfo.Building = dt.Rows[Row]["Building"].ToString();
                    estInfo.Lean = dt.Rows[Row]["Lean"].ToString();
                    estInfo.TargetEff = dt.Rows[Row]["TargetEff"].ToString();
                    estInfo.Model_A = new List<ModelRisk>();
                    estInfo.Model_S = new List<ModelRisk>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["Lean"].ToString() == estInfo.Lean)
                    {
                        if (dt.Rows[Row]["Section"].ToString() == "A")
                        {
                            estInfo.EstEff_A = dt.Rows[Row]["EstEff"].ToString();

                            ModelRisk model = new ModelRisk();
                            model.Model = dt.Rows[Row]["Model"].ToString();
                            model.Type = dt.Rows[Row]["Type"].ToString() != "OLD" ? "NEW" : "OLD";
                            model.LaborDiff = (int)dt.Rows[Row]["LaborDiff"];
                            model.HisEff = dt.Rows[Row]["HisEff"].ToString();

                            estInfo.Model_A.Add(model);
                        }
                        else
                        {
                            estInfo.EstEff_S = dt.Rows[Row]["EstEff"].ToString();

                            ModelRisk model = new ModelRisk();
                            model.Model = dt.Rows[Row]["Model"].ToString();
                            model.Type = dt.Rows[Row]["Type"].ToString() != "OLD" ? "NEW" : "OLD";
                            model.LaborDiff = (int)dt.Rows[Row]["LaborDiff"];
                            model.HisEff = dt.Rows[Row]["HisEff"].ToString();

                            estInfo.Model_S.Add(model);
                        }

                        Row++;
                    }

                    LeanList.Add(estInfo);
                }

                return JsonConvert.SerializeObject(LeanList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getLeanScheduleData")]
        public string getLeanScheduleData(ScheduleRequest request)
        {
            DateTime StartDate = DateTime.Parse(request.Month! + "/01");
            DateTime EndDate = new DateTime(StartDate.AddMonths(1).Year, StartDate.AddMonths(1).Month, 1).AddDays(-1);

            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#SC') IS NOT NULL " +
                    "BEGIN DROP TABLE #SC END; " +

                    "SET ARITHABORT ON; " +

                    "SELECT SC.lean_no, SC.Date, SC.ry_index, SC.DDBH, SC.RYPairs, SC.DAOMH, SC.BuyNo, SC.Article, SC.Labor, SC.sl, SC.ShipDate, SC.Country, SC.SubSeq, " +
                    "ISNULL(CASE WHEN ISNUMERIC(SUBSTRING(Cycles, CHARINDEX('-', Cycles)+1, 10)) = 1 AND ISNUMERIC(SUBSTRING(Cycles, 1, CHARINDEX('-', Cycles)-1)) = 1 THEN " +
                    "CAST(SUBSTRING(Cycles, 1, CHARINDEX('-', Cycles)-1) AS INT) END, 1) AS MinCycle, " +
                    "ISNULL(CASE WHEN ISNUMERIC(SUBSTRING(Cycles, CHARINDEX('-', Cycles)+1, 10)) = 1 AND ISNUMERIC(SUBSTRING(Cycles, 1, CHARINDEX('-', Cycles)-1)) = 1 THEN " +
                    "CAST(SUBSTRING(Cycles, CHARINDEX('-', Cycles)+1, 10) AS INT) END, MAX(CASE WHEN SMDD.DDBH = SMDD.YSBH THEN 1 ELSE CAST(RIGHT(SMDD.DDBH, 3) AS INT) END)) AS MaxCycle INTO #SC FROM ( " +
                    "  SELECT lean_no, Date, ry_index, DDBH, RYPairs, DAOMH, BuyNo, Article, Labor, sl, ShipDate, Country, SubSeq, x.value('.', 'NVARCHAR(50)') AS Cycles FROM ( " +
                    "    SELECT lean_no, Date, ry_index, DDBH, RYPairs, DAOMH, BuyNo, Article, Labor, sl, ShipDate, Country, SubSeq, CAST('<x>' + REPLACE(Cycles, '+', '</x><x>') + '</x>' AS XML) AS XmlData FROM ( " +
                    "      SELECT SC.building_no + ' ' + UPPER(SC.lean_no) AS lean_no, CONVERT(VARCHAR, SC.schedule_date, 111) AS Date, CAST(SC.ry_index AS INT) AS ry_index, DDZL.DDBH, DDZL.Pairs AS RYPairs, " +
                    "      XXZL.DAOMH, CASE WHEN DDZL.GSBH = 'VA12' THEN CAST(CAST(RIGHT(LEFT(DDZL.BUYNO, 6), 2) AS INT) AS VARCHAR) + ' BUY' ELSE DDZL.BUYNO END AS BuyNo, DDZL.Article, ISNULL(SCXXCL.BZRS, 0) AS Labor, CAST(SC.sl AS INT) AS sl, RIGHT(CONVERT(VARCHAR, DDZL.ShipDate, 111), 5) AS ShipDate, LBZLS.YWSM AS Country, " +
                    "      CASE WHEN RIGHT(SC.ry, 3) LIKE '%-%' THEN SUBSTRING(RIGHT(SC.ry, 3), CHARINDEX('-', RIGHT(SC.ry, 3)) + 1, LEN(RIGHT(SC.ry, 3)) - CHARINDEX('-', RIGHT(SC.ry, 3))) END AS SubSeq, " +
                    "      CASE WHEN REPLACE(SC.stitching, ' ', '') LIKE 'T%' THEN REPLACE(REPLACE(REPLACE(SC.stitching, ' ', ''), '~', '-'), 'T', '') ELSE NULL END AS Cycles FROM schedule_crawler AS SC " +
                    "      LEFT JOIN DDZL ON DDZL.DDBH = CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END " +
                    "      LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "      LEFT JOIN SCXXCL ON SCXXCL.XieXing = DDZL.XieXing AND SCXXCL.SheHao = DDZL.SheHao AND BZLB = '3' AND GXLB = '{3}' " +
                    "      LEFT JOIN LBZLS ON LBZLS.LB = '06' AND LBZLS.LBDH = DDZL.DDGB " +
                    "      WHERE SC.building_no = '{1}' AND 'LINE ' + RIGHT('00' + CAST(CAST(RIGHT(SC.lean_no, 2) AS INT) AS VARCHAR), 2) = '{2}' AND SUBSTRING(CONVERT(VARCHAR, SC.schedule_date, 111), 1, 7) = '{0}' " +
                    "    ) AS SC " +
                    "  ) AS SC " +
                    "  OUTER APPLY XmlData.nodes('/x') AS B(x) " +
                    ") AS SC " +
                    "LEFT JOIN SMDD ON SMDD.YSBH = SC.DDBH AND SMDD.GXLB = 'A' " +
                    "GROUP BY SC.lean_no, SC.Date, SC.ry_index, SC.DDBH, SC.RYPairs, SC.DAOMH, SC.BuyNo, SC.Article, SC.Labor, SC.sl, SC.ShipDate, SC.Country, SC.SubSeq, SC.Cycles; " +

                    "WITH TEMPTAB(Date) AS ( " +
                    "  SELECT CONVERT(SmallDateTime, '{4}') " +
                    "  UNION ALL " +
                    "  SELECT DATEADD(D, 1, TEMPTAB.DATE) AS Date FROM TEMPTAB " +
                    "  WHERE DATEADD(D, 1, TEMPTAB.DATE) <= CONVERT(SmallDateTime, '{5}') " +
                    ") " +

                    "SELECT SC.lean_no, CONVERT(VARCHAR, SC.Date, 111) AS Date, SC.ry_index, SC.DDBH, SC.SubDDBH, SC.DAOMH, SC.BuyNo, SC.Article, SC.Labor, SC.sl, SC.ShipDate, SC.Country, SC.Progress, SC.Location, SC.IsToday, Mat.MatStatus, QC.FTT FROM ( " +
                    "  SELECT SC.lean_no, SC.Date, SC.ry_index, SC.DDBH, ISNULL(SC.SubSeq, '') AS SubDDBH, SC.DAOMH, SC.BuyNo, SC.Article, SC.Labor, SC.sl, SC.ShipDate, SC.Country, " +
                    "  ISNULL(CAST(SC.FinishedPairs * 100.0 / " + (request.Section == "W" || request.Section == "SP" ? "SC.RYPairs" : "SC.sl") + " AS NUMERIC(4, 1)), 0) AS Progress, SC.Location, SC.IsToday FROM ( " +
                    (
                    request.Section == "SP"
                    ?   "    SELECT SC.lean_no, SC.Date, SC.ry_index, SC.DDBH, SC.RYPairs, SC.DAOMH, SC.BuyNo, SC.Article, SC.Labor, SC.sl, SC.ShipDate, SC.country, " +
                        "    FLOOR(SUM(CASE WHEN SC.Output >= SC.RYPairs THEN 1.0 ELSE 0 END) / COUNT(SC.Part + SC.Process) * SC.RYPairs) AS FinishedPairs, SC.SubSeq, SC.MinCycle, SC.MaxCycle, SC.Location, SC.IsToday FROM ( " +
                        "      SELECT SC.lean_no, SC.Date, SC.ry_index, SC.DDBH, SC.RYPairs, SC.DAOMH, SC.BuyNo, SC.Article, SC.Labor, SC.sl, SC.ShipDate, " +
                        "      SC.country, MSP.Process, MSP.Part, ISNULL(SUM(SPO.Pairs), 0) AS Output, SC.SubSeq, SC.MinCycle, SC.MaxCycle, " +
                        "      CASE WHEN MSP.Process IS NOT NULL THEN 'Ty Thac' ELSE 'None' END AS Location, " +
                        "      CASE WHEN CONVERT(VARCHAR, MAX(SPO.UserDate), 111) = CONVERT(VARCHAR, GETDATE(), 111) THEN 1 ELSE 0 END AS IsToday FROM #SC AS SC " +
                        "      LEFT JOIN DDZL ON DDZL.DDBH = SC.DDBH " +
                        "      LEFT JOIN ModelSecondProcess AS MSP ON MSP.XieXing = DDZL.XieXing AND MSP.SheHao = DDZL.SheHao AND MSP.Supplier = 'JNG' " +
                        "      LEFT JOIN SecondProcessOutput AS SPO ON SPO.RY = SC.DDBH AND SPO.Process = MSP.Process AND SPO.Part = MSP.Part " +
                        "      GROUP BY SC.lean_no, SC.Date, SC.ry_index, SC.DDBH, SC.RYPairs, SC.DAOMH, SC.BuyNo, SC.Article, SC.Labor, SC.sl, SC.ShipDate, SC.Country, MSP.Process, MSP.Part, SC.SubSeq, SC.MinCycle, SC.MaxCycle " +
                        "    ) AS SC " +
                        "    GROUP BY SC.lean_no, SC.Date, SC.ry_index, SC.DDBH, SC.RYPairs, SC.DAOMH, SC.BuyNo, SC.Article, SC.Labor, SC.sl, SC.ShipDate, SC.country, SC.SubSeq, SC.MinCycle, SC.MaxCycle, SC.Location, SC.IsToday "
                    : request.Section == "C" || request.Section == "S" || request.Section == "A"
                    ?
                        "    SELECT SC.lean_no, SC.Date, SC.ry_index, SC.DDBH, SC.DAOMH, SC.BuyNo, SC.Article, SC.Labor, SC.sl, SC.ShipDate, " +
                        "    SC.country, ISNULL(SUM(SMDDSS.okCTS), 0) AS FinishedPairs, SC.SubSeq, SC.MinCycle, SC.MaxCycle, " +
                        "    'Ty Thac' AS Location, CASE WHEN CONVERT(VARCHAR, MAX(SMDDSS.ScanEDate), 111) = CONVERT(VARCHAR, GETDATE(), 111) THEN 1 ELSE 0 END AS IsToday FROM #SC AS SC " +
                        "    LEFT JOIN SMDD ON SMDD.YSBH = SC.DDBH AND SMDD.GXLB = '{3}' AND CASE WHEN SMDD.DDBH = SMDD.YSBH THEN 1 ELSE CAST(RIGHT(SMDD.DDBH, 3) AS INT) END BETWEEN SC.MinCycle AND SC.MaxCycle " +
                        "    LEFT JOIN SMDDSS ON SMDDSS.DDBH = SMDD.DDBH AND SMDDSS.GXLB = SMDD.GXLB " +
                        "    GROUP BY SC.lean_no, SC.Date, SC.ry_index, SC.DDBH, SC.DAOMH, SC.BuyNo, SC.Article, SC.Labor, SC.sl, SC.ShipDate, SC.Country, SC.SubSeq, SC.MinCycle, SC.MaxCycle "
                    :
                        "    SELECT SC.lean_no, SC.Date, SC.ry_index, SC.DDBH, SC.RYPairs, SC.DAOMH, SC.BuyNo, SC.Article, SC.Labor, SC.sl, SC.ShipDate, " +
                        "    SC.country, SC.FinishedPairs + ISNULL(SUM(CASE WHEN YWCPOld.INDATE IS NOT NULL THEN YWCPOld.Qty ELSE 0 END), 0) AS FinishedPairs, SC.SubSeq, SC.MinCycle, SC.MaxCycle, SC.Location, " +
                        "    CASE WHEN CONVERT(VARCHAR, CASE WHEN SC.LastInDate > MAX(YWCPOld.LastInDate) THEN SC.LastInDate ELSE MAX(YWCPOld.LastInDate) END, 111) = CONVERT(VARCHAR, GETDATE(), 111) THEN 1 ELSE 0 END AS IsToday FROM ( " +
                        "      SELECT SC.lean_no, SC.Date, SC.ry_index, SC.DDBH, SC.RYPairs, SC.DAOMH, SC.BuyNo, SC.Article, SC.Labor, SC.sl, SC.ShipDate, " +
                        "      SC.country, ISNULL(SUM(CASE WHEN YWCP.INDATE IS NOT NULL THEN YWCP.Qty ELSE 0 END), 0) AS FinishedPairs, SC.SubSeq, SC.MinCycle, SC.MaxCycle, " +
                        "      'Ty Thac' AS Location, MAX(YWCP.LastInDate) AS LastInDate FROM #SC AS SC " +
                        "      LEFT JOIN YWCP ON YWCP.DDBH = SC.DDBH " +
                        "      GROUP BY SC.lean_no, SC.Date, SC.ry_index, SC.DDBH, SC.RYPairs, SC.DAOMH, SC.BuyNo, SC.Article, SC.Labor, SC.sl, SC.ShipDate, SC.Country, SC.SubSeq, SC.MinCycle, SC.MaxCycle " +
                        "    ) AS SC " +
                        "    LEFT JOIN YWCPOld ON YWCPOld.DDBH = SC.DDBH " +
                        "    GROUP BY SC.lean_no, SC.Date, SC.ry_index, SC.DDBH, SC.RYPairs, SC.DAOMH, SC.BuyNo, SC.Article, SC.Labor, SC.sl, SC.ShipDate, SC.Country, SC.FinishedPairs, SC.SubSeq, SC.MinCycle, SC.MaxCycle, SC.Location, SC.LastInDate "
                    ) +
                    "  ) AS SC " +
                    "  UNION ALL " +
                    "  SELECT Lean, Date, -1, '', '', '', '', '', 0, 0, '', '', 0, '', '' FROM ( " +
                    "    SELECT SC.Lean, TEMPTAB.Date FROM ( " +
                    "      SELECT DISTINCT building_no + ' ' + UPPER(lean_no) AS Lean FROM schedule_crawler " +
                    "      WHERE building_no = '{1}' AND 'LINE ' + RIGHT('00' + CAST(CAST(RIGHT(lean_no, 2) AS INT) AS VARCHAR), 2) = '{2}' AND SUBSTRING(CONVERT(VARCHAR, schedule_date, 111), 1, 7) = '{0}' " +
                    "    ) AS SC " +
                    "    LEFT JOIN TEMPTAB ON 1 = 1 " +
                    "    WHERE DATEPART(DW, TEMPTAB.Date) = 1 " +
                    "    UNION " +
                    "    SELECT SCRL.Lean, TEMPTAB.Date FROM TEMPTAB " +
                    "    LEFT JOIN ( " +
                    "      SELECT 'LINE ' + RIGHT('00' + CAST(CAST(RIGHT(BDepartment.DepName, 2) AS INT) AS VARCHAR), 2) AS Lean, CONVERT(SmallDateTime, SCRL.SCYEAR + '/' + SCRL.SCMONTH + '/' + SCRL.SCDay) AS Date FROM SCRL " +
                    "      LEFT JOIN BDepartment ON BDepartment.ID = SCRL.DepNO " +
                    "      WHERE CONVERT(SmallDateTime, SCRL.SCYEAR + '/' + SCRL.SCMONTH + '/' + SCRL.SCDay) BETWEEN '{4}' AND '{5}' " +
                    "      AND BDepartment.DepName LIKE 'DT_G-%' AND ISNUMERIC(RIGHT(BDepartment.DepName, 2)) = 1 AND 'LINE ' + RIGHT('00' + CAST(CAST(RIGHT(BDepartment.DepName, 2) AS INT) AS VARCHAR), 2) = '{2}' AND BDepartment.GXLB = 'A' AND ISNULL(SCRL.SCGS, 0) > 0 " +
                    "    ) AS SCRL ON SCRL.Date = TEMPTAB.Date " +
                    "    WHERE SCRL.Lean IS NOT NULL AND SCRL.Date IS NULL " +
                    "  ) AS SCRL " +
                    ") AS SC " +
                    "LEFT JOIN ( " +
                    "  SELECT ZLBH, CAST(FLOOR(SUM(CASE WHEN RKQty >= Usage THEN 1 ELSE 0 END) * 1000.0 / COUNT(CLBH)) / 10 AS NUMERIC(4, 1)) AS MatStatus FROM ( " +
                    "    SELECT ZLZLS2.ZLBH, ZLZLS2.CLBH, ZLZLS2.Usage, ISNULL(CGKCUSE.Qty, 0) + ISNULL(SUM(KCRKS.Qty), 0) AS RKQty FROM ( " +
                    "      SELECT ZLZLS2.ZLBH, ZLZLS2.CLBH, SUM(ZLZLS2.CLSL) AS Usage FROM ZLZLS2 " +
                    "      LEFT JOIN CLZL ON CLZL.CLDH = ZLZLS2.CLBH " +
                    "      WHERE ZLZLS2.ZLBH IN (SELECT DDBH FROM #SC) AND ZLZLS2.CSBH <> '' AND ZLZLS2.CLBH NOT LIKE 'W%' AND ZLZLS2.ZMLB = 'N' AND ZLZLS2.CLSL > 0 AND CLZL.YWPM NOT LIKE '%QC LABEL%' " +
                    (
                    request.Section == "C"
                    ? 
                        "      AND (LEFT(ZLZLS2.CLBH, 1) IN ('A', 'C', 'F', 'K', 'B') OR (LEFT(ZLZLS2.CLBH, 3) IN ('P21', 'P31') AND CLZL.DWBH <> 'PRS') OR (ZLZLS2.CSBH = 'M251' AND CLZL.DWBH = 'YRD')) "
                    : request.Section == "S"
                    ?
                        "      AND (((LEFT(ZLZLS2.CLBH, 1) IN ('E', 'G', 'L', 'M', 'N') OR LEFT(ZLZLS2.CLBH, 3) IN ('D01', 'D02', 'D11')) AND CASE WHEN LEFT(ZLZLS2.CLBH, 3) = 'G01' THEN CLZL.DWBH ELSE 'X' END <> 'PRS') OR ZLZLS2.CSBH = 'A390') "
                    : request.Section == "A"
                    ?
                        "      AND ((LEFT(ZLZLS2.CLBH, 1) IN ('D', 'H', 'I', 'O') AND LEFT(ZLZLS2.CLBH, 3) NOT IN ('D01', 'D02', 'D11')) OR (LEFT(ZLZLS2.CLBH, 3) = 'G01' AND CLZL.DWBH = 'PRS') " +
                        "      OR (ZLZLS2.CSBH = 'V204' AND LEFT(ZLZLS2.CLBH, 1) = 'L') OR (ZLZLS2.CSBH = 'M251' AND CLZL.DWBH = 'PRS') OR ZLZLS2.CSBH IN ('P144', 'V214')) "
                    :   
                        "      AND 1 = 0 "
                    ) +
                    "      GROUP BY ZLZLS2.ZLBH, ZLZLS2.CLBH " +
                    "    ) AS ZLZLS2 " +
                    "    LEFT JOIN CGKCUSE ON CGKCUSE.ZLBH = ZLZLS2.ZLBH AND CGKCUSE.CLBH = ZLZLS2.CLBH " +
                    "    LEFT JOIN KCRKS ON KCRKS.CGBH = ZLZLS2.ZLBH AND KCRKS.CLBH = ZLZLS2.CLBH " +
                    "    GROUP BY ZLZLS2.ZLBH, ZLZLS2.CLBH, ZLZLS2.Usage, CGKCUSE.Qty " +
                    "  ) AS Mat " +
                    "  GROUP BY ZLBH " +
                    ") AS Mat ON Mat.ZLBH = SC.DDBH " +
                    "LEFT JOIN ( " +
                    "  SELECT WOPR.SCBH, CASE WHEN SUM(WOPR.Qty) > 0 THEN CAST(FLOOR((SUM(WOPR.Qty) - SUM(WOPR.NGQty)) * 1000.0 / SUM(WOPR.Qty)) / 10 AS NUMERIC(4, 1)) END AS FTT FROM WOPR " +
                    "  LEFT JOIN BDepartment ON BDepartment.ID = WOPR.DepNo " +
                    "  WHERE WOPR.SCBH IN (SELECT DDBH FROM #SC) AND WOPR.GXLB = 'AR' AND BDepartment.DepName LIKE 'DT_G-%' AND ISNUMERIC(RIGHT(BDepartment.DepName, 2)) = 1 AND 'LINE ' + RIGHT('00' + CAST(CAST(RIGHT(BDepartment.DepName, 2) AS INT) AS VARCHAR), 2) = '{2}' " +
                    "  GROUP BY WOPR.SCBH " +
                    ") AS QC ON QC.SCBH = SC.DDBH " +
                    "ORDER BY SC.lean_no, SC.ry_index, CONVERT(VARCHAR, SC.Date, 111) " +
                    "OPTION (MAXRECURSION 0) "
                    , request.Month, request.Building, request.Lean, request.Section, StartDate.ToString("yyyy/MM/dd"), EndDate.ToString("yyyy/MM/dd")
                ), ERP
            );

            DataTable dt = new DataTable();
            da.Fill(dt);
            ScheduleLean scheduleLean = new ScheduleLean();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                int index = 1;
                scheduleLean.Lean = dt.Rows[Row]["lean_no"].ToString();
                scheduleLean.Holiday = new List<int>();
                scheduleLean.Sequence = new List<Sequence>();

                while (Row < dt.Rows.Count)
                {
                    if ((int)dt.Rows[Row]["ry_index"] > 0)
                    {
                        Sequence Seq = new Sequence();
                        Seq.Index = index;
                        Seq.Schedule = new List<ScheduleResult>();

                        while (Row < dt.Rows.Count && (int)dt.Rows[Row]["ry_index"] == Seq.Index)
                        {
                            ScheduleResult OrderInfo = new ScheduleResult();
                            OrderInfo.Date = dt.Rows[Row]["Date"].ToString();
                            OrderInfo.Order = dt.Rows[Row]["DDBH"].ToString();
                            OrderInfo.SubOrder = dt.Rows[Row]["SubDDBH"].ToString();
                            OrderInfo.DieCutMold = dt.Rows[Row]["DAOMH"].ToString();
                            OrderInfo.BuyNo = dt.Rows[Row]["BuyNo"].ToString();
                            OrderInfo.SKU = dt.Rows[Row]["Article"].ToString();
                            OrderInfo.Labor = (int)dt.Rows[Row]["Labor"];
                            OrderInfo.Pairs = (int)dt.Rows[Row]["sl"];
                            OrderInfo.ShipDate = dt.Rows[Row]["ShipDate"].ToString();
                            OrderInfo.Country = dt.Rows[Row]["Country"].ToString();
                            OrderInfo.Location = dt.Rows[Row]["Location"].ToString();
                            OrderInfo.Progress = dt.Rows[Row]["Progress"].ToString();
                            OrderInfo.IsToday = ((int)dt.Rows[Row]["IsToday"] == 1);
                            OrderInfo.MatStatus = dt.Rows[Row]["MatStatus"].ToString();
                            OrderInfo.FTT = dt.Rows[Row]["FTT"].ToString();

                            Seq.Schedule.Add(OrderInfo);
                            Row++;
                        }

                        scheduleLean.Sequence.Add(Seq);
                        index = Row < dt.Rows.Count ? (int)dt.Rows[Row]["ry_index"] : 0;
                    }
                    else
                    {
                        string HDate = dt.Rows[Row]["Date"].ToString()!;
                        scheduleLean.Holiday.Add(int.Parse(HDate.Substring(HDate.Length - 2)));
                        Row++;
                    }
                }

                return JsonConvert.SerializeObject(scheduleLean);
            }
            else
            {
                return "{}";
            }
        }

        [HttpPost]
        [Route("getLeanWorkOrder")]
        public string getLeanWorkOrder(CommonRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT PP.DDBH, PP.BUY, PP.ARTICLE, PP.PlanDate, PP.Pairs, " +
                    "ISNULL(SUM(CASE WHEN SCBB_Cycle.Type = 'INPUT' THEN ISNULL(SCBB_Cycle.Pairs, 0) - ISNULL(SCBB_Cycle.Shortage, 0) END), 0) AS Input, " +
                    "ISNULL(SUM(CASE WHEN SCBB_Cycle.Type = 'OUTPUT' THEN ISNULL(SCBB_Cycle.Pairs, 0) - ISNULL(SCBB_Cycle.Shortage, 0) END), 0) AS Output FROM ( " +
                    "  SELECT DDZL.DDBH, CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR) + ' BUY' AS BUY, DDZL.ARTICLE, PP.PlanDate, DDZL.Pairs FROM ( " +
                    "    SELECT RY, RIGHT(CONVERT(VARCHAR, ISNULL(MIN(CASE WHEN PlanType LIKE '1-Day%' THEN PlanDate END), MIN(CASE WHEN PlanType LIKE '3-Day%' THEN PlanDate END)), 111), 5) AS PlanDate FROM ProductionPlan " +
                    "    WHERE Building = '{0}' AND Lean = '{1}' AND RY LIKE '{2}%' AND (PlanType LIKE '1-Day%' OR PlanType LIKE '3-Day%') " +
                    "    GROUP BY RY " +
                    "  ) AS PP " +
                    "  LEFT JOIN DDZL ON DDZL.DDBH = PP.RY " +
                    "  LEFT JOIN SCBBS ON SCBBS.SCBH = DDZL.DDBH AND SCBBS.GXLB = '{3}' " +
                    "  WHERE DDZL.DDBH IS NOT NULL " +
                    "  GROUP BY DDZL.DDBH, DDZL.BUYNO, DDZL.ARTICLE, PP.PlanDate, DDZL.Pairs " +
                    "  HAVING DDZL.Pairs > ISNULL(SUM(SCBBS.Qty), 0) " +
                    ") AS PP " +
                    "LEFT JOIN SCBB_Cycle ON SCBB_Cycle.ZLBH = PP.DDBH AND SCBB_Cycle.GXLB = '{3}' " +
                    "GROUP BY PP.DDBH, PP.BUY, PP.ARTICLE, PP.PlanDate, PP.Pairs " +
                    (request.Type == "Completed" 
                    ? "HAVING PP.Pairs = ISNULL(SUM(CASE WHEN SCBB_Cycle.Type = 'OUTPUT' THEN ISNULL(SCBB_Cycle.Pairs, 0) - ISNULL(SCBB_Cycle.Shortage, 0) END), 0) AND CONVERT(VARCHAR, MAX(SCBB_Cycle.UserDate), 111) = '{4}' " 
                    : "HAVING PP.Pairs > ISNULL(SUM(CASE WHEN SCBB_Cycle.Type = 'OUTPUT' THEN ISNULL(SCBB_Cycle.Pairs, 0) - ISNULL(SCBB_Cycle.Shortage, 0) END), 0) ") +
                    "ORDER BY PP.PlanDate, PP.ARTICLE "
                    , request.Building, request.Lean, request.RY, request.Section, request.Date
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<LeanWorkOrder> orderList = new List<LeanWorkOrder>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    LeanWorkOrder order = new LeanWorkOrder();
                    order.RY = dt.Rows[i]["DDBH"].ToString();
                    order.BUY = dt.Rows[i]["BUY"].ToString();
                    order.SKU = dt.Rows[i]["ARTICLE"].ToString();
                    order.PlanDate = dt.Rows[i]["PlanDate"].ToString();
                    order.Pairs = (int)dt.Rows[i]["Pairs"];
                    order.Input = (int)dt.Rows[i]["Input"];
                    order.Output = (int)dt.Rows[i]["Output"];

                    orderList.Add(order);
                }

                return JsonConvert.SerializeObject(orderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getMachineWorkOrder")]
        public string getMachineWorkOrder(MonthOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT CAST(ROW_NUMBER() OVER(ORDER BY MIN(SC.schedule_date)) AS INT) AS Seq, " +
                    "CONVERT(VARCHAR, MIN(SC.schedule_date), 111) AS AssemblyDate, CONVERT(VARCHAR, DDZL.ShipDate, 111) AS ShipDate, CutDispatch.ZLBH, DDZL.Pairs, " +
                    "DDZL.Article, XXZL.DAOMH, CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR) + ' BUY' AS BuyNo, CutDispatch.Status FROM ( " +
                    "  SELECT ZLBH, CASE WHEN SUM(Qty) = ISNULL(SUM(ScanQty), 0) THEN 'Completed' ELSE 'InProduction' END AS Status FROM CutDispatchSS " +
                    "  WHERE Machine = '{0}' AND ZLBH LIKE '{1}%' AND(Qty > ISNULL(ScanQty, 0) OR CONVERT(VARCHAR, MachineDate, 111) = CONVERT(VARCHAR, GETDATE(), 111)) " +
                    "  GROUP BY ZLBH " +
                    ") AS CutDispatch " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = CutDispatch.ZLBH " +
                    "LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "LEFT JOIN schedule_crawler AS SC ON CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END = CutDispatch.ZLBH " +
                    "GROUP BY DDZL.ShipDate, CutDispatch.ZLBH, DDZL.Pairs, DDZL.Article, XXZL.DAOMH, DDZL.BUYNO, CutDispatch.Status "
                    , request.Machine, request.Order
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<MonthOrderResult> orderList = new List<MonthOrderResult>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    MonthOrderResult order = new MonthOrderResult();
                    order.Seq = (int)dt.Rows[i]["Seq"];
                    order.AssemblyDate = dt.Rows[i]["AssemblyDate"].ToString();
                    order.ShipDate = dt.Rows[i]["ShipDate"].ToString();
                    order.Order = dt.Rows[i]["ZLBH"].ToString();
                    order.Pairs = (int)dt.Rows[i]["Pairs"];
                    order.SKU = dt.Rows[i]["Article"].ToString();
                    order.DieCut = dt.Rows[i]["DAOMH"].ToString();
                    order.BuyNo = dt.Rows[i]["BuyNo"].ToString();
                    order.Status = dt.Rows[i]["Status"].ToString();

                    orderList.Add(order);
                }

                return JsonConvert.SerializeObject(orderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getLeanRYMatStatus")]
        public string getLeanRYMatStatus(CommonRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT ZLZLS2.ZLBH, ZLZLS2.CSBH, ZLZLS2.ZSYWJC, ZLZLS2.CLBH, ZLZLS2.YWPM, ZLZLS2.DWBH, ZLZLS2.Usage, ZLZLS2.RKQty, " +
                    "RIGHT(CONVERT(VARCHAR, ZLZLS2.ArrivalDate, 111), 5) AS ArrivalDate, RIGHT(CONVERT(VARCHAR, SM.ArrivalDate, 111), 5) AS EstimatedDate FROM ( " +
                    "  SELECT ZLZLS2.ZLBH, ZLZLS2.CSBH, ZLZLS2.ZSYWJC, ZLZLS2.CLBH, ZLZLS2.YWPM, ZLZLS2.DWBH, CAST(ZLZLS2.Usage AS NUMERIC(10, 1)) AS Usage, " +
                    "  CAST(ISNULL(CGKCUSE.Qty, 0) + ISNULL(SUM(KCRKS.Qty), 0) AS NUMERIC(10, 1)) AS RKQty, ISNULL(CGKCUSE.UserDate, MAX(KCRKS.UserDate)) AS ArrivalDate FROM ( " +
                    "    SELECT ZLZLS2.ZLBH, ZLZLS2.CSBH, ZSZL.ZSYWJC, ZLZLS2.CLBH, CLZL.YWPM, CLZL.DWBH, SUM(ZLZLS2.CLSL) AS Usage FROM ZLZLS2 " +
                    "    LEFT JOIN CLZL ON CLZL.CLDH = ZLZLS2.CLBH " +
                    "    LEFT JOIN ZSZL ON ZSZL.ZSDH = ZLZLS2.CSBH " +
                    "    WHERE ZLZLS2.ZLBH = '{0}' AND ZLZLS2.CSBH <> '' AND ZLZLS2.CLBH NOT LIKE 'W%' AND ZLZLS2.ZMLB = 'N' AND ZLZLS2.CLSL > 0 AND CLZL.YWPM NOT LIKE '%QC LABEL%' " +
                    (
                    request.Section == "C"
                    ?
                        "    AND (LEFT(ZLZLS2.CLBH, 1) IN ('A', 'C', 'F', 'K', 'B') OR (LEFT(ZLZLS2.CLBH, 3) IN ('P21', 'P31') AND CLZL.DWBH <> 'PRS') OR (ZLZLS2.CSBH = 'M251' AND CLZL.DWBH = 'YRD')) "
                    : request.Section == "S"
                    ?
                        "    AND (((LEFT(ZLZLS2.CLBH, 1) IN ('E', 'G', 'L', 'M', 'N') OR LEFT(ZLZLS2.CLBH, 3) IN ('D01', 'D02', 'D11')) AND CASE WHEN LEFT(ZLZLS2.CLBH, 3) = 'G01' THEN CLZL.DWBH ELSE 'X' END <> 'PRS') OR ZLZLS2.CSBH = 'A390') "
                    : request.Section == "A"
                    ?
                        "    AND ((LEFT(ZLZLS2.CLBH, 1) IN ('D', 'H', 'I', 'O') AND LEFT(ZLZLS2.CLBH, 3) NOT IN ('D01', 'D02', 'D11')) OR (LEFT(ZLZLS2.CLBH, 3) = 'G01' AND CLZL.DWBH = 'PRS') " +
                        "    OR (ZLZLS2.CSBH = 'V204' AND LEFT(ZLZLS2.CLBH, 1) = 'L') OR (ZLZLS2.CSBH = 'M251' AND CLZL.DWBH = 'PRS') OR ZLZLS2.CSBH IN ('P144', 'V214')) "
                    :
                        "    AND 1 = 0 "
                    ) +
                    "    GROUP BY ZLZLS2.ZLBH, ZLZLS2.CSBH, ZSZL.ZSYWJC, ZLZLS2.CLBH, CLZL.YWPM, CLZL.DWBH " +
                    "  ) AS ZLZLS2 " +
                    "  LEFT JOIN CGKCUSE ON CGKCUSE.ZLBH = ZLZLS2.ZLBH AND CGKCUSE.CLBH = ZLZLS2.CLBH " +
                    "  LEFT JOIN KCRKS ON KCRKS.CGBH = ZLZLS2.ZLBH AND KCRKS.CLBH = ZLZLS2.CLBH " +
                    "  GROUP BY ZLZLS2.ZLBH, ZLZLS2.CSBH, ZLZLS2.ZSYWJC, ZLZLS2.CLBH, ZLZLS2.YWPM, ZLZLS2.DWBH, ZLZLS2.Usage, CGKCUSE.Qty, CGKCUSE.UserDate " +
                    ") AS ZLZLS2 " +
                    "LEFT JOIN ( " +
                    "  SELECT DDBH, CSBH, CLBH, ArrivalDate FROM ( " +
                    "    SELECT DDBH, CSBH, CLBH, ArrivalDate, ROW_NUMBER() OVER(PARTITION BY CSBH, CLBH ORDER BY UserDate DESC) AS Seq FROM schedule_materials " +
                    "    WHERE DDBH = '{0}' " +
                    "  ) AS SM " +
                    "  WHERE Seq = 1 " +
                    ") AS SM ON SM.DDBH = ZLZLS2.ZLBH AND SM.CSBH = ZLZLS2.CSBH AND SM.CSBH = ZLZLS2.CSBH AND SM.CLBH = ZLZLS2.CLBH " +
                    "ORDER BY ZLZLS2.CLBH "
                    , request.RY
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<MaterialStatus> msList = new List<MaterialStatus>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    MaterialStatus ms = new MaterialStatus();
                    ms.MatID = dt.Rows[i]["CLBH"].ToString();
                    ms.MatName = dt.Rows[i]["YWPM"].ToString();
                    ms.SupID = dt.Rows[i]["CSBH"].ToString();
                    ms.SupName = dt.Rows[i]["ZSYWJC"].ToString();
                    ms.Unit = dt.Rows[i]["DWBH"].ToString();
                    ms.Usage = Convert.ToDouble((decimal)dt.Rows[i]["Usage"]);
                    ms.InStock = Convert.ToDouble((decimal)dt.Rows[i]["RKQty"]);
                    ms.ArrivalDate = dt.Rows[i]["ArrivalDate"].ToString();
                    ms.EstimatedDate = dt.Rows[i]["EstimatedDate"].ToString();

                    msList.Add(ms);
                }

                return JsonConvert.SerializeObject(msList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getLeanRYSecondProcess")]
        public string getLeanRYSecondProcess(CommonRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT MSP.DDBH, SPP_P.EN AS P_EN, SPP_P.CH AS P_CH, SPP_P.VN AS P_VN, SPP_C.EN AS C_EN, SPP_C.CH AS C_CH, SPP_C.VN AS C_VN, MSP.Pairs, " +
                    "CASE WHEN ISNULL(SUM(SPO.Pairs), 0) <= MSP.Pairs THEN ISNULL(SUM(SPO.Pairs), 0) ELSE MSP.Pairs END AS Finished, MSP.LaunchDate, RIGHT(CONVERT(VARCHAR, MAX(SPO.UserDate), 111), 5) AS EndDate FROM ( " +
                    "  SELECT DDZL.DDBH, DDZL.Pairs, MSP.Process, MSP.Part, RIGHT(CONVERT(VARCHAR, MIN(SPI.UserDate), 111), 5) AS LaunchDate FROM DDZL " +
                    "  LEFT JOIN ModelSecondProcess AS MSP ON MSP.XieXing = DDZL.XieXing AND MSP.SheHao = DDZL.SheHao AND MSP.Supplier = 'JNG' " +
                    "  LEFT JOIN SecondProcessInput AS SPI ON SPI.RY = DDZL.DDBH AND SPI.Process = MSP.Process AND SPI.Part = MSP.Part " +
                    "  WHERE DDZL.DDBH = '{0}' " +
                    "  GROUP BY DDZL.DDBH, DDZL.Pairs, MSP.Process, MSP.Part " +
                    ") AS MSP " +
                    "LEFT JOIN SecondProcessOutput AS SPO ON SPO.RY = MSP.DDBH AND SPO.Process = MSP.Process AND SPO.Part = MSP.Part " +
                    "LEFT JOIN SecondProcessParameter AS SPP_P ON SPP_P.Category = 'PROCESS' AND SPP_P.ID = MSP.Process " +
                    "LEFT JOIN SecondProcessParameter AS SPP_C ON SPP_C.Category = 'COMPONENT' AND SPP_C.ID = MSP.Part " +
                    "GROUP BY MSP.DDBH, MSP.Pairs, SPP_P.EN, SPP_P.CH, SPP_P.VN, SPP_C.EN, SPP_C.CH, SPP_C.VN, MSP.LaunchDate " +
                    "ORDER BY SPP_P.EN, SPP_C.EN "
                    , request.RY
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<SecondProcess> spList = new List<SecondProcess>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    SecondProcess sp = new SecondProcess();
                    sp.P_EN = dt.Rows[i]["P_EN"].ToString();
                    sp.P_CH = dt.Rows[i]["P_CH"].ToString();
                    sp.P_VN = dt.Rows[i]["P_VN"].ToString();
                    sp.C_EN = dt.Rows[i]["C_EN"].ToString();
                    sp.C_CH = dt.Rows[i]["C_CH"].ToString();
                    sp.C_VN = dt.Rows[i]["C_VN"].ToString();
                    sp.Pairs = (int)dt.Rows[i]["Pairs"];
                    sp.Finished = (int)dt.Rows[i]["Finished"];
                    sp.LaunchDate = dt.Rows[i]["LaunchDate"].ToString();
                    sp.EndDate = dt.Rows[i]["EndDate"].ToString();

                    spList.Add(sp);
                }

                return JsonConvert.SerializeObject(spList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getLeanRYDefects")]
        public string getLeanRYDefects(CommonRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT CAST(RANK() OVER(ORDER BY SUM(QCRD.Qty) DESC) AS INT) AS Seq, " +
                    "LEFT(BDepartment.DepName, 3) AS Building, RIGHT(REPLACE(BDepartment.DepName, '_G', ''), 6) AS Lean, QCR.SCBH, " +
                    "QCBLYY.YYBH, RTRIM(LTRIM(UPPER(QCBLYY.YWSM))) AS EN, RTRIM(LTRIM(UPPER(QCBLYY.ZWSM))) AS VN, " +
                    "RTRIM(LTRIM(UPPER(ISNULL(QCBLYY.YXSM, QCBLYY.YWSM)))) AS CH, SUM(QCRD.Qty) AS Pairs FROM QCR " +
                    "LEFT JOIN QCRD ON QCRD.ProNo = QCR.ProNo " +
                    "LEFT JOIN QCBLYY ON QCBLYY.YYBH = QCRD.YYBH AND QCBLYY.DFL = QCR.GXLB AND QCBLYY.GSBH = QCR.GSBH " +
                    "LEFT JOIN BDepartment ON BDepartment.ID = QCR.DepNo " +
                    "WHERE BDepartment.DepName LIKE '%{1}%{2}%' AND QCR.SCBH = '{0}' AND QCR.GXLB = 'AR' AND ISNULL(QCRD.Qty, 0) > 0 " +
                    "GROUP BY BDepartment.DepName, QCR.SCBH, QCBLYY.YYBH, QCBLYY.YWSM, QCBLYY.YXSM, QCBLYY.ZWSM "
                    , request.RY, request.Building, request.Lean
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<RYDefects> defectList = new List<RYDefects>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    RYDefects defect = new RYDefects();
                    defect.Seq = (int)dt.Rows[i]["Seq"];
                    defect.EN = dt.Rows[i]["EN"].ToString();
                    defect.VN = dt.Rows[i]["VN"].ToString();
                    defect.CH = dt.Rows[i]["CH"].ToString();
                    defect.Pairs = (int)dt.Rows[i]["Pairs"];

                    defectList.Add(defect);
                }

                return JsonConvert.SerializeObject(defectList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getMachineDispatchedPart")]
        public string getMachineDispatchedPart(OrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT CutDispatchSS.BWBH, CutDispatchSS.CLBH, BWZL.ZWSM, BWZL.YWSM, 'Manual' AS Type, " +
                    "SUM(CutDispatchSS.Qty) AS ZLQty, ISNULL(SUM(CutDispatchSS.ScanQty), 0) AS ScanQty FROM CutDispatchSS " +
                    "LEFT JOIN BWZL ON BWZL.BWDH = CutDispatchSS.BWBH " +
                    "WHERE ZLBH = '{0}' AND Machine = '{1}' " +
                    "GROUP BY CutDispatchSS.BWBH, CutDispatchSS.CLBH, BWZL.ZWSM, BWZL.YWSM "
                    , request.Order, request.Machine
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<OrderPartResult> orderList = new List<OrderPartResult>();
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    OrderPartResult part = new OrderPartResult();
                    part.PartName = new List<PartInfo>();
                    part.PartID = dt.Rows[i]["BWBH"].ToString();
                    part.MaterialID = dt.Rows[i]["CLBH"].ToString();

                    PartInfo partInfo = new PartInfo();
                    partInfo.ZH = dt.Rows[i]["ZWSM"].ToString();
                    partInfo.EN = dt.Rows[i]["YWSM"].ToString();
                    partInfo.VI = dt.Rows[i]["YWSM"].ToString();
                    partInfo.Type = dt.Rows[i]["Type"].ToString();
                    if ((int)dt.Rows[i]["ZLQty"] > (int)dt.Rows[i]["ScanQty"])
                    {
                        if ((int)dt.Rows[i]["ScanQty"] == 0)
                        {
                            partInfo.Status = 0;
                        }
                        else
                        {
                            partInfo.Status = 1;
                        }
                    }
                    else
                    {
                        partInfo.Status = 2;
                    }
                    part.PartName.Add(partInfo);
                    orderList.Add(part);
                }

                return JsonConvert.SerializeObject(orderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getReportingOrderSize")]
        public string getReportingOrderSize(OrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da;
            if (request.Machine == "")
            {
                if (request.Section == "A")
                {
                    da = new SqlDataAdapter(
                        System.String.Format(
                            "SELECT SMDDSS.XXCC AS Size, CASE WHEN ISNULL(SUM(SMDDSS.okCTS), 0) < SUM(SMDDSS.CTS) THEN 0 ELSE 1 END AS AllDispatched FROM SMDD " +
                            "LEFT JOIN SMDDSS ON SMDDSS.DDBH = SMDD.DDBH AND SMDDSS.GXLB = SMDD.GXLB " +
                            "WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = '{1}' AND ISNULL(SMDDSS.CTS, 0) > 0 " +
                            "GROUP BY SMDDSS.XXCC " +
                            "ORDER BY SMDDSS.XXCC ",
                            request.Order, request.Section
                        ), ERP
                    );
                }
                else
                {
                    da = new SqlDataAdapter(
                        System.String.Format(
                            "SELECT SMDDS.XXCC AS Size, CASE WHEN ISNULL(SUM(SCBB.Pairs), 0) < SUM(SMDDS.Qty) THEN 0 ELSE 1 END AS AllDispatched FROM SMDD " +
                            "LEFT JOIN SMDDS ON SMDDS.DDBH = SMDD.DDBH " +
                            "LEFT JOIN SCBB_Cycle AS SCBB ON SCBB.ZLBH = SMDD.YSBH AND SCBB.DDBH = SMDD.DDBH AND SCBB.Size = SMDDS.XXCC AND SCBB.GXLB = '{1}' AND SCBB.Type = '{2}' " +
                            "WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = '{1}' AND ISNULL(SMDDS.Qty, 0) > 0 " +
                            "GROUP BY SMDDS.XXCC " +
                            "ORDER BY SMDDS.XXCC ",
                            request.Order, request.Section, request.Type
                        ), ERP
                    );
                }
            }
            else
            {
                da = new SqlDataAdapter(
                    System.String.Format(
                        "SELECT DDZLS.CC AS Size, CASE WHEN SUM(SS.ScanQty) < SUM(SS.Qty) THEN 0 ELSE 1 END AS AllDispatched FROM DDZLS " +
                        "LEFT JOIN CutDispatchSS AS SS ON SS.ZLBH = DDZLS.DDBH AND SS.SIZE = DDZLS.CC AND SS.BWBH = '{1}' AND SS.Machine = '{2}' " +
                        "WHERE DDZLS.DDBH = '{0}' " +
                        "GROUP BY DDZLS.CC " +
                        "ORDER BY DDZLS.CC ",
                        request.Order, request.PartID, request.Machine
                    ), ERP
                );
            }

            DataTable dt = new DataTable();
            da.Fill(dt);
            List<OrderSize> SizeList = new List<OrderSize>();

            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    OrderSize Size = new OrderSize();
                    Size.Size = dt.Rows[i]["Size"].ToString();
                    if ((int)dt.Rows[i]["AllDispatched"] == 0)
                    {
                        Size.AllDispatched = false;
                    }
                    else
                    {
                        Size.AllDispatched = true;
                    }
                    SizeList.Add(Size);
                }

                return JsonConvert.SerializeObject(SizeList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getReportingCycle")]
        public string getReportingCycle(OrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da;
            if (request.Section == "A")
            {
                da = new SqlDataAdapter(
                    System.String.Format(
                        "SELECT CASE WHEN SMDD.DDBH = SMDD.YSBH THEN SMDD.DDBH + '-001' ELSE SMDD.DDBH END AS DDBH, CASE WHEN ISNULL(SUM(SMDDSS.okCTS), 0) < ISNULL(SUM(SMDDSS.CTS), 0) THEN 0 ELSE 1 END AS AllDispatched FROM SMDD " +
                        "LEFT JOIN SMDDSS ON SMDDSS.DDBH = SMDD.DDBH AND SMDDSS.GXLB = SMDD.GXLB " +
                        "WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = '{1}' AND ISNULL(SMDDSS.CTS, 0) > 0 " +
                        "GROUP BY SMDD.YSBH, SMDD.DDBH " +
                        "ORDER BY SMDD.DDBH ",
                        request.Order, request.Section
                    ), ERP
                );
            }
            else
            {
                da = new SqlDataAdapter(
                    System.String.Format(
                        "SELECT CASE WHEN SMDD.DDBH = SMDD.YSBH THEN SMDD.DDBH + '-001' ELSE SMDD.DDBH END AS DDBH, CASE WHEN ISNULL(SUM(SCBB.Pairs), 0) < ISNULL(SUM(SMDDS.Qty), 0) THEN 0 ELSE 1 END AS AllDispatched FROM SMDD " +
                        "LEFT JOIN SMDDS ON SMDDS.DDBH = SMDD.DDBH " +
                        "LEFT JOIN SCBB_Cycle AS SCBB ON SCBB.ZLBH = SMDD.YSBH AND SCBB.DDBH = SMDD.DDBH AND SCBB.Size = SMDDS.XXCC AND SCBB.GXLB = '{1}' AND SCBB.Type = '{2}' " +
                        "WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = 'A' AND ISNULL(SMDDS.Qty, 0) > 0 " +
                        "GROUP BY SMDD.YSBH, SMDD.DDBH " +
                        "ORDER BY SMDD.DDBH ",
                        request.Order, request.Section, request.Type
                    ), ERP
                );
            }
            DataTable dt = new DataTable();
            da.Fill(dt);
            List<OrderCycle> CycleList = new List<OrderCycle>();

            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    OrderCycle Cycle = new OrderCycle();
                    Cycle.Cycle = dt.Rows[i]["DDBH"].ToString();
                    if ((int)dt.Rows[i]["AllDispatched"] == 0)
                    {
                        Cycle.AllDispatched = false;
                    }
                    else
                    {
                        Cycle.AllDispatched = true;
                    }
                    CycleList.Add(Cycle);
                }

                return JsonConvert.SerializeObject(CycleList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getReportingDispatchedSizeRun")]
        public string getReportingDispatchedSizeRun(OrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da;
            if (request.Machine == "")
            {
                if (request.Section == "A")
                {
                    da = new SqlDataAdapter(
                        System.String.Format(
                            "SELECT SMDD.DDBH, '' AS BWBH, '' AS YWSM, SMDDSS.XXCC AS SIZE, ISNULL(SMDDSS.CTS, 0) AS Qty, CASE WHEN ISNULL(SMDDSS.okCTS, 0) > 0 THEN ISNULL(SMDDSS.CTS, 0) - ISNULL(SMDDSS.okCTS, 0) ELSE 0 END AS Shortage, CASE WHEN ISNULL(SMDDSS.okCTS, 0) > 0 THEN 1 ELSE 0 END AS Reported FROM SMDD " +
                            "LEFT JOIN SMDDSS ON SMDDSS.DDBH = SMDD.DDBH AND SMDDSS.GXLB = SMDD.GXLB " +
                            "WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = '{1}' AND ISNULL(SMDDSS.CTS, 0) > 0 " +
                            "ORDER BY SMDD.DDBH, SMDDSS.XXCC "
                            , request.Order, request.Section
                        ), ERP
                    );
                }
                else
                {
                    da = new SqlDataAdapter(
                        System.String.Format(
                            "SELECT SMDD.DDBH, '' AS BWBH, '' AS YWSM, SMDDS.XXCC AS SIZE, ISNULL(SMDDS.Qty, 0) AS Qty, ISNULL(SCBB.Shortage, 0) AS Shortage, CASE WHEN ISNULL(SCBB.Pairs, 0) > 0 THEN 1 ELSE 0 END AS Reported FROM SMDD " +
                            "LEFT JOIN SMDDS ON SMDDS.DDBH = SMDD.DDBH " +
                            "LEFT JOIN SCBB_Cycle AS SCBB ON SCBB.ZLBH = SMDD.YSBH AND SCBB.DDBH = SMDD.DDBH AND SCBB.Size = SMDDS.XXCC AND SCBB.GXLB = '{1}' AND SCBB.Type = '{2}' " +
                            "WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = 'A' AND ISNULL(SMDDS.Qty, 0) > 0 " +
                            "ORDER BY SMDD.DDBH, SMDDS.XXCC "
                            , request.Order, request.Section, request.Type
                        ), ERP
                    );
                }
            }
            else
            {
                da = new SqlDataAdapter(
                    System.String.Format(
                        "SELECT SMDD.DDBH, CutDispatchSS.BWBH, BWZL.YWSM, CutDispatchSS.SIZE, ISNULL(CutDispatchSS.Qty, 0) AS Qty, 0 AS Shortage, CASE WHEN ISNULL(CutDispatchSS.ScanQty, 0) > 0 THEN 1 ELSE 0 END AS Reported FROM SMDD " +
                        "LEFT JOIN SMDDS ON SMDDS.DDBH = SMDD.DDBH " +
                        "LEFT JOIN CutDispatchSS ON CutDispatchSS.ZLBH = SMDD.YSBH AND CutDispatchSS.DDBH = SMDD.DDBH AND CutDispatchSS.SIZE = SMDDS.XXCC " +
                        "LEFT JOIN BWZL ON BWZL.BWDH = CutDispatchSS.BWBH " +
                        "WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = 'A' AND CutDispatchSS.BWBH = '{1}' AND CutDispatchSS.Machine = '{2}' " +
                        "ORDER BY SMDD.DDBH, CutDispatchSS.BWBH, CutDispatchSS.SIZE "
                        , request.Order, request.PartID, request.Machine
                    ), ERP
                );
            }

            DataTable dt = new DataTable();
            da.Fill(dt);
            List<OrderCycleResult> CycleList = new List<OrderCycleResult>();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    OrderCycleResult Cycles = new OrderCycleResult();
                    Cycles.Cycle = dt.Rows[Row]["DDBH"].ToString();

                    Cycles.Parts = new List<OrderCyclePart>();
                    OrderCyclePart Part = new OrderCyclePart();
                    Part.ID = dt.Rows[Row]["BWBH"].ToString();
                    Part.Name = dt.Rows[Row]["YWSM"].ToString();
                    Part.SizeQty = new List<OrderCyclePartSize>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["DDBH"].ToString() == Cycles.Cycle)
                    {
                        OrderCyclePartSize PartSize = new OrderCyclePartSize();
                        PartSize.Size = dt.Rows[Row]["SIZE"].ToString();
                        PartSize.Qty = (int)dt.Rows[Row]["Qty"];
                        PartSize.Shortage = (int)dt.Rows[Row]["Shortage"];
                        if ((int)dt.Rows[Row]["Reported"] == 0)
                        {
                            PartSize.Dispatched = false;
                        }
                        else
                        {
                            PartSize.Dispatched = true;
                        }
                        Part.SizeQty.Add(PartSize);
                        Row++;
                    }

                    Cycles.Parts.Add(Part);
                    CycleList.Add(Cycles);
                }

                return JsonConvert.SerializeObject(CycleList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("submitLeanSectionProgress")]
        public string submitLeanSectionProgress(CuttingWorkOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlCommand SQL;
            if (request.ExecuteType == "Completed") {
                SQL = new SqlCommand(
                    System.String.Format(
                        "INSERT INTO SCBB_Cycle (ZLBH, GXLB, Type, DDBH, Size, Pairs, Shortage, UserID, UserDate) " +
                        "SELECT SMDD.YSBH, '{1}' AS GXLB, '{2}' AS Type, SMDD.DDBH, SMDDS.XXCC AS Size, SMDDS.Qty AS Pairs, 0 AS Shortage, '{5}' AS UserID, GETDATE() AS UserDate FROM SMDD " +
                        "LEFT JOIN SMDDS ON SMDDS.DDBH = SMDD.DDBH " +
                        "LEFT JOIN SCBB_Cycle AS SCBB ON SCBB.ZLBH = SMDD.YSBH AND SCBB.GXLB = '{1}' AND SCBB.Type = '{2}' AND SCBB.DDBH = SMDD.DDBH AND SCBB.Size = SMDDS.XXCC " +
                        "WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = 'A' AND SCBB.ZLBH IS NULL " +
                        (request.SelectedCycle != "" ? "AND SMDD.DDBH = '{3}' " : "") +
                        (request.SelectedSize != "" ? "AND SMDDS.XXCC = '{4}' " : "") + "; " +

                        "UPDATE SCBB_Cycle SET Shortage = 0, UserID = '{5}', UserDate = GETDATE() " +
                        "WHERE ZLBH = '{0}' AND GXLB = '{1}' AND Type = '{2}' " +
                        (request.SelectedCycle != "" ? "AND DDBH = '{3}' " : "") +
                        (request.SelectedSize != "" ? "AND Size = '{4}' " : "") + "; " +

                        "DELETE FROM SCBBS_Cycle " +
                        "WHERE ZLBH = '{0}' AND GXLB = '{1}' AND Type = '{2}' " +
                        (request.SelectedCycle != "" ? "AND DDBH = '{3}' " : "") +
                        (request.SelectedSize != "" ? "AND Size = '{4}' " : "") +
                        "AND Date = CONVERT(VARCHAR, GETDATE(), 111); "
                        , request.Order, request.Section, request.Type, request.SelectedCycle, request.SelectedSize, request.UserID
                    ), ERP
                );
            }
            else if (request.ExecuteType == "Shortage")
            {
                SQL = new SqlCommand(
                    System.String.Format(
                        "DECLARE @Result INT = ( " +
                        "  SELECT COUNT(*) AS Exist FROM SCBB_Cycle " +
                        "  WHERE ZLBH = '{0}' AND GXLB = '{1}' AND Type = '{2}' AND DDBH = '{3}' AND Size = '{4}' " +
                        ") " +

                        "IF (@Result > 0) " +
                        "BEGIN " +
                        "    UPDATE SCBB_Cycle SET Shortage = {5}, UserID = '{6}', UserDate = GETDATE() " +
                        "    WHERE ZLBH = '{0}' AND GXLB = '{1}' AND Type = '{2}' AND DDBH = '{3}' AND Size = '{4}' " +
                        "END " +
                        "ELSE BEGIN " +
                        "    INSERT INTO SCBB_Cycle (ZLBH, GXLB, Type, DDBH, Size, Pairs, Shortage, UserID, UserDate) " +
                        "    SELECT SMDD.YSBH, '{1}' AS GXLB, '{2}' AS Type, SMDD.DDBH, SMDDS.XXCC AS Size, SMDDS.Qty AS Pairs, {5} AS Shortage, '{6}' AS UserID, GETDATE() AS UserDate FROM SMDD " +
                        "    LEFT JOIN SMDDS ON SMDDS.DDBH = SMDD.DDBH " +
                        "    WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = 'A' AND SMDD.DDBH = '{3}' AND SMDDS.XXCC = '{4}' " +
                        "END; " +

                        "DELETE FROM SCBBS_Cycle " +
                        "WHERE ZLBH = '{0}' AND GXLB = '{1}' AND Type = '{2}' AND DDBH = '{3}' AND Size = '{4}' AND Date = CONVERT(VARCHAR, GETDATE(), 111); " +

                        "INSERT INTO SCBBS_Cycle (ZLBH, GXLB, Type, DDBH, Size, Date, Shortage) " +
                        "VALUES ('{0}', '{1}', '{2}', '{3}', '{4}', CONVERT(VARCHAR, GETDATE(), 111), {5}); "
                        , request.Order, request.Section, request.Type, request.SelectedCycle, request.SelectedSize, request.Shortage, request.UserID
                    ), ERP
                );
            }
            else
            {
                SQL = new SqlCommand(
                    System.String.Format(
                        "DELETE FROM SCBB_Cycle " +
                        "WHERE ZLBH = '{0}' AND GXLB = '{1}' AND Type = '{2}' " +
                        (request.SelectedCycle != "" ? "AND DDBH = '{3}' " : "") +
                        (request.SelectedSize != "" ? "AND Size = '{4}' " : "") + "; " +

                        "DELETE FROM SCBBS_Cycle " +
                        "WHERE ZLBH = '{0}' AND GXLB = '{1}' AND Type = '{2}' " +
                        (request.SelectedCycle != "" ? "AND DDBH = '{3}' " : "") +
                        (request.SelectedSize != "" ? "AND Size = '{4}' " : "") + 
                        "AND Date = CONVERT(VARCHAR, GETDATE(), 111); "
                        , request.Order, request.Section, request.Type, request.SelectedCycle, request.SelectedSize
                    ), ERP
                );
            }

            Task.Run(() =>
            {
                ERP.Open();
                int recordCount = SQL.ExecuteNonQuery();
                ERP.Dispose();
            });

            return "{\"statusCode\": 200}";
        }

        [HttpPost]
        [Route("submitMachineCuttingProgress")]
        public string submitMachineCuttingProgress(CuttingWorkOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlCommand SQL = new SqlCommand(
                System.String.Format(
                    "UPDATE CutDispatchSS SET ScanQty = " + (request.Type == "Completed" ? "Qty" : "0") + ", Machine = '{4}', MachineDate = GETDATE() " +
                    "WHERE ZLBH = '{0}' AND DDBH LIKE '{1}%' AND BWBH = '{2}' AND Size = '{3}'; " +
                        
                    "UPDATE CutDispatchS SET okCutNum = FLOOR(CutNum * (SELECT ISNULL(SUM(ScanQty), 0) * 1.0 / SUM(Qty) FROM CutDispatchSS WHERE ZLBH = '{0}' AND BWBH = '{2}' AND Size = '{3}')), ScanUser = 'APP', ScanDate = GETDATE() " +
                    "WHERE ZLBH = '{0}' AND BWBH = '{2}' AND Size = '{3}'; "
                    , request.Order, request.SelectedCycle, request.PartID, request.SelectedSize, request.Machine
                ), ERP
            );

            Task.Run(() =>
            {
                ERP.Open();
                int recordCount = SQL.ExecuteNonQuery();
                ERP.Dispose();
            });

            return "{\"statusCode\": 200}";
        }

        [HttpPost]
        [Route("getBuildingMachine")]
        public string getBuildingMachine(CuttingWorkOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT MachineName FROM BuildingMachine " +
                    "WHERE Building = '{0}' AND Type = '{1}' " +
                    "ORDER BY MachineName "
                    , request.Factory, request.Type
                ), ERP
            );

            DataTable dt = new DataTable();
            da.Fill(dt);
            List<MachineResult> MachineList = new List<MachineResult>();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    MachineResult Machine = new MachineResult();
                    Machine.Machine = dt.Rows[Row]["MachineName"].ToString();

                    MachineList.Add(Machine);
                    Row++;
                }

                return JsonConvert.SerializeObject(MachineList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getMachineDispatchedWorkOrder")]
        public string getMachineDispatchedWorkOrder(EmmaRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#SS') IS NOT NULL " +
                    "BEGIN DROP TABLE #SS END; " +

                    "IF OBJECT_ID('tempdb..#WorkOrder') IS NOT NULL " +
                    "BEGIN DROP TABLE #WorkOrder END; " +

                    "SELECT CutDispatchSS.ZLBH, CutDispatchSS.BWBH, MIN(CutDispatchSS.MachineDate) AS AssignDate, SUM(CutDispatchSS.Qty) AS Qty, ISNULL(SUM(CutDispatchSS.ScanQty), 0) AS ScanQty, " +
                    "CASE WHEN MIN(CutDispatchSS.DDBH) = CutDispatchSS.ZLBH THEN 1 ELSE CAST(RIGHT(MIN(CutDispatchSS.DDBH), 3) AS INT) END AS MinCycle, " +
                    "CASE WHEN MAX(CutDispatchSS.DDBH) = CutDispatchSS.ZLBH THEN 1 ELSE CAST(RIGHT(MAX(CutDispatchSS.DDBH), 3) AS INT) END AS MaxCycle INTO #SS FROM CutDispatchSS " +
                    "WHERE CutDispatchSS.Machine = '{0}' " +
                    "GROUP BY CutDispatchSS.ZLBH, CutDispatchSS.BWBH " +
                    "HAVING SUM(CutDispatchSS.Qty) > ISNULL(SUM(CutDispatchSS.ScanQty), 0) " +

                    "SELECT SS.ZLBH, CAST(CAST(SUBSTRING(DDZL.BUYNO, 5, 2) AS INT) AS VARCHAR) + ' BUY' AS Buy, XXZL.DAOMH, DDZL.ARTICLE, DDZL.Pairs, CONVERT(VARCHAR, DDZL.ShipDate, 111) AS ShipDate, " +
                    "SS.BWBH, BWZL.ZWSM AS PartZH, BWZL.YWSM AS PartEN, CONVERT(VARCHAR, MIN(SC.schedule_date), 111) AS PlanDate, CONVERT(VARCHAR, SS.AssignDate, 111) AS AssignDate, SS.Qty, SS.MinCycle, SS.MaxCycle, " +
                    "DENSE_RANK() OVER(ORDER BY MIN(CONVERT(VARCHAR, SC.schedule_date, 111) + '-' + CAST(SC.ry_index AS VARCHAR))) AS Seq INTO #WorkOrder FROM #SS AS SS " +
                    "LEFT JOIN schedule_crawler AS SC ON CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END = SS.ZLBH " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = SS.ZLBH " +
                    "LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "LEFT JOIN BWZL ON BWZL.BWDH = SS.BWBH " +
                    "GROUP BY SS.ZLBH, DDZL.BUYNO, XXZL.DAOMH, DDZL.ARTICLE, DDZL.Pairs, DDZL.ShipDate, SS.BWBH, BWZL.ZWSM, BWZL.YWSM, SS.AssignDate, SS.Qty, SS.MinCycle, SS.MaxCycle " +

                    "SELECT ZLBH, Buy, DAOMH, ARTICLE, Pairs, ShipDate, PlanDate, MIN(AssignDate) AS AssignDate, " +
                    "CASE WHEN MIN(MinCycle) = MAX(MaxCycle) THEN 'T' + CAST(MIN(MinCycle) AS VARCHAR) ELSE 'T' + CAST(MIN(MinCycle) AS VARCHAR) + ' ~ T' + CAST(MIN(MaxCycle) AS VARCHAR) END AS Cycles, " +
                    "Seq, STUFF(( " +
                    "  SELECT ',[' + BWBH + '] ' + PartEN FROM #WorkOrder AS W2 " +
                    "  WHERE W2.ZLBH = W1.ZLBH " +
                    "  ORDER BY BWBH " +
                    "  FOR XML PATH('') " +
                    "), 1, 1, '') AS PartEN, STUFF(( " +
                    "  SELECT ',[' + BWBH + '] ' + PartZH FROM #WorkOrder AS W2 " +
                    "  WHERE W2.ZLBH = W1.ZLBH " +
                    "  ORDER BY BWBH " +
                    "  FOR XML PATH('') " +
                    "), 1, 1, '') AS PartZH FROM #WorkOrder AS W1 " +
                    "GROUP BY ZLBH, Buy, DAOMH, ARTICLE, Pairs, ShipDate, PlanDate, Seq " +
                    "ORDER BY Seq "
                    , request.MachineID
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            List<EmmaWorkOrderResult> workOrderList = new List<EmmaWorkOrderResult>();
            if (dt.Rows.Count > 0)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    EmmaWorkOrderResult workOrder = new EmmaWorkOrderResult();
                    workOrder.RY = dt.Rows[i]["ZLBH"].ToString();
                    workOrder.Buy = dt.Rows[i]["Buy"].ToString();
                    workOrder.PlanDate = dt.Rows[i]["PlanDate"].ToString();
                    workOrder.DieCut = dt.Rows[i]["DAOMH"].ToString();
                    workOrder.SKU = dt.Rows[i]["ARTICLE"].ToString();
                    workOrder.ZH = dt.Rows[i]["PartZH"].ToString();
                    workOrder.EN = dt.Rows[i]["PartEN"].ToString();
                    workOrder.VI = dt.Rows[i]["PartEN"].ToString();
                    workOrder.Cycles = dt.Rows[i]["Cycles"].ToString();
                    workOrder.Pairs = (int)dt.Rows[i]["Pairs"];
                    workOrder.GAC = dt.Rows[i]["ShipDate"].ToString();
                    workOrder.Status = "InProduction";

                    workOrderList.Add(workOrder);
                }

                return JsonConvert.SerializeObject(workOrderList);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("generateMachineCuttingWorkOrder")]
        public string generateMachineCuttingWorkOrder(EmmaWorkOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlCommand SQL = new SqlCommand(
                System.String.Format(
                    "INSERT INTO KT_SOPCut (XieXing, SheHao, BWBH, Type, piece, layer, joinnum, LRcom, PartID, IMGName, USERID, USERDATE, YN) " +
                    "SELECT DDZL.XieXing, DDZL.SheHao, ZLZLS2.BWBH, 'Manual', 1, 1, 0, 1, NULL, NULL, 'System', GETDATE(), '1' FROM DDZL " +
                    "LEFT JOIN ZLZLS2 ON ZLZLS2.ZLBH = DDZL.DDBH " +
                    "LEFT JOIN KT_SOPCut ON KT_SOPCut.XieXing = DDZL.XieXing AND KT_SOPCut.SheHao = DDZL.SheHao AND KT_SOPCut.BWBH = ZLZLS2.BWBH " +
                    "WHERE DDZL.DDBH = '{0}' AND ZLZLS2.MJBH = 'ZZZZZZZZZZ' AND ZLZLS2.BWBH IN ({1}) AND KT_SOPCut.BWBH IS NULL; " +

                    "INSERT INTO KT_SOPCutS (XieXing, SheHao, BWBH, SIZE, XXCC, USERID, USERDATE, YN) " +
                    "SELECT DDZL.XieXing, DDZL.SheHao, ZLZLS2.BWBH, XXCC, GJCC, 'System', GETDATE(), '1' FROM ZLZLS2 " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = ZLZLS2.ZLBH " +
                    "LEFT JOIN XXGJS ON XXGJS.XieXing = DDZL.XieXing AND XXGJS.GJLB = '100' " +
                    "WHERE ZLZLS2.ZLBH = '{0}' AND ZLZLS2.MJBH = 'ZZZZZZZZZZ' AND ZLZLS2.BWBH IN ({1}) AND ZLZLS2.BWBH NOT IN ( " +
                    "  SELECT DISTINCT KT_SOPCutS.BWBH FROM DDZL " +
                    "  LEFT JOIN KT_SOPCutS ON KT_SOPCutS.XieXing = DDZL.XieXing AND KT_SOPCutS.SheHao = DDZL.SheHao " +
                    "  WHERE DDZL.DDBH = '{0}' AND KT_SOPCutS.BWBH IN ({1}) " +
                    "); "
                    , request.RY, request.Part
                ), ERP
            );
            ERP.Open();
            int recordCount = SQL.ExecuteNonQuery();
            CheckCuttingData(request.RY!);

            SQL = new SqlCommand(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#CutDispatch') IS NOT NULL " +
                    "BEGIN DROP TABLE #CutDispatch END; " +

                    "DECLARE @Seq AS Int = ( " +
                    "  SELECT ISNULL(MAX(CAST(SUBSTRING(DLNO, 7, 5) AS INT)), 0) AS DLNO FROM CutDispatch " +
                    "  WHERE DLNO LIKE SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + '%' " +
                    "); " +

                    "SELECT SUBSTRING(CONVERT(VARCHAR, GETDATE(), 112), 1, 6) + RIGHT('0000' + CAST(@Seq + 1 AS VARCHAR), 5) AS DLNO, SMDD.ZLBH, SMDD.DDBH, CutDispatchZL.BWBH, " +
                    "CutDispatchZL.SIZE, CutDispatchZL.XXCC, CutDispatchZL.CLBH, SMDD.Qty, CASE WHEN ISNULL(CutDispatchZL.CutNum, 0) = 0 THEN SMDD.Qty ELSE CutDispatchZL.CutNum END AS CutNum, " +
                    "0 AS ScanQty, 0 AS QRCode, '{3}' AS Machine, GETDATE() AS MachineDate, NULL AS MachineEndDate, '{4}' AS UserID, GETDATE() AS UserDate, '1' AS YN, SC.DepID, SMDD.GSBH INTO #CutDispatch FROM ( " +
                    "  SELECT SMDD.YSBH AS ZLBH, SMDD.DDBH, SMDDS.XXCC, SMDDS.Qty, SMDD.GSBH FROM SMDD " +
                    "  LEFT JOIN SMDDS ON SMDDS.DDBH = SMDD.DDBH " +
                    "  WHERE SMDD.YSBH = '{0}' AND SMDD.GXLB = 'C' AND SMDD.DDBH IN ({2}) " +
                    ") AS SMDD " +
                    "LEFT JOIN ( " +
                    "  SELECT DDZL.DDBH, MIN(SC.building_no + '_' + UPPER(SC.lean_no)) AS DepID FROM DDZL " +
                    "  LEFT JOIN schedule_crawler AS SC ON CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END = DDZL.DDBH " +
                    "  WHERE DDZL.DDBH = '{0}' " +
                     " GROUP BY DDZL.DDBH " +
                    ") AS SC ON SC.DDBH = SMDD.ZLBH " +
                    "LEFT JOIN ( " +
                    "  SELECT ZLBH, BWBH, CLBH, SIZE, XXCC, Qty, CutNum FROM CutDispatchZL " +
                    "  WHERE ZLBH = '{0}' AND BWBH IN ({1}) " +
                    ") AS CutDispatchZL ON CutDispatchZL.ZLBH = SMDD.ZLBH AND CutDispatchZL.SIZE = SMDD.XXCC " +
                    "LEFT JOIN CutDispatchSS ON CutDispatchSS.ZLBH = SMDD.ZLBH AND CutDispatchSS.DDBH = SMDD.DDBH AND CutDispatchSS.BWBH = CutDispatchZL.BWBH AND CutDispatchSS.CLBH = CutDispatchZL.CLBH AND CutDispatchSS.SIZE = CutDispatchZL.SIZE " +
                    "WHERE CutDispatchSS.ZLBH IS NULL; " +

                    "INSERT INTO CutDispatch (DLNO, DLLB, GSBH, DepID, PlanDate, Memo, CustomLayers, USERID, USERDATE, YN) " +
                    "SELECT DISTINCT DLNO, 'Manual' AS DLLB, GSBH, DepID, CONVERT(VARCHAR, GETDATE(), 111) AS PlanDate, '' AS Memo, NULL AS CustomLayers, UserID, UserDate, YN FROM #CutDispatch; " +

                    "INSERT INTO CutDispatchS (DLNO, ZLBH, BWBH, SIZE, CLBH, Qty, XXCC, CutNum, okCutNum, USERID, USERDATE, ScanUser, ScanDate, YN) " +
                    "SELECT DLNO, ZLBH, BWBH, SIZE, CLBH, SUM(Qty) AS Qty, XXCC, SUM(CutNum) AS CutNum, 0 AS okCutNum, UserID, UserDate, '' AS ScanUser, NULL AS ScanDate, YN FROM #CutDispatch " +
                    "GROUP BY DLNO, ZLBH, BWBH, SIZE, CLBH, XXCC, UserID, UserDate, YN; " +

                    "INSERT INTO CutDispatchSS (DLNO, ZLBH, DDBH, BWBH, SIZE, CLBH, Qty, ScanQty, QRCode, Machine, MachineDate, MachineEndDate, USERID, USERDATE, YN) " +
                    "SELECT DLNO, ZLBH, DDBH, BWBH, SIZE, CLBH, Qty, ScanQty, QRCode, Machine, MachineDate, MachineEndDate, UserID, UserDate, YN FROM #CutDispatch; " +

                    "UPDATE CutDispatchSS SET Machine = '{3}', MachineDate = GETDATE() " +
                    "WHERE ZLBH = '{0}' AND DDBH IN ({2}) AND BWBH IN ({1}) AND ISNULL(Machine, '') <> '{3}'; "
                    , request.RY, request.Part, request.Cycle, request.MachineID, request.UserID
                ), ERP
            );

            recordCount = SQL.ExecuteNonQuery();
            ERP.Dispose();


            if (recordCount > 0)
            {
                return "{\"statusCode\": 200}";
            }
            else
            {
                return "{\"statusCode\": 400}";
            }
        }

        [HttpPost]
        [Route("cancelMachineCuttingWorkOrder")]
        public string cancelMachineCuttingWorkOrder(EmmaWorkOrderRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlCommand SQL = new SqlCommand(
                System.String.Format(
                    "UPDATE CutDispatchSS SET Machine = '', MachineDate = NULL " +
                    "WHERE ZLBH = '{0}' AND Machine = '{1}'; "
                    , request.RY, request.MachineID
                ), ERP
            );

            ERP.Open();
            int recordCount = SQL.ExecuteNonQuery();
            ERP.Dispose();


            if (recordCount > 0)
            {
                return "{\"statusCode\": 200}";
            }
            else
            {
                return "{\"statusCode\": 400}";
            }
        }

        [HttpPost]
        [Route("getShippingPlan")]
        public string getShippingPlan(CommonRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#SP') IS NOT NULL " +
                    "BEGIN DROP TABLE #SP END; " +

                    "SELECT CAST(SUBSTRING(Container, CHARINDEX('Container-', Container) + 10, CHARINDEX(' [', Container) - CHARINDEX('Container-', Container) - 10) AS INT) AS ID, " +
                    "SUBSTRING(Container, CHARINDEX(' [', Container) + 2, CHARINDEX(']', Container) - CHARINDEX(' [', Container) - 2) AS Container, " +
                    "CAST(ROW_NUMBER() OVER(PARTITION BY Container ORDER BY Seq) AS INT) AS Seq, Building, RY, PO, SKU, Pairs, Cartons, CBM, Country INTO #SP FROM ShippingPlan " +
                    "WHERE Date = '{0}' AND GSBH = '{1}' " +

                    "SELECT CAST(DENSE_RANK() OVER(ORDER BY SP.ID, SP.Container) AS INT) AS ID, SP.Container, SP.Seq, SP.Building, SP.RY, SP.PO, SP.SKU, SP.Pairs, SP.Cartons, SP.CBM, SP.Country, " +
                    "CASE WHEN ISNULL(YWCP.RKPairs, 0) < DDZL.Pairs THEN 'In Production' ELSE 'Finished' END AS Status FROM #SP AS SP " +
                    "LEFT JOIN DDZL ON DDZL.DDBH = SP.RY " +
                    "LEFT JOIN ( " +
                    "  SELECT DDBH, SUM(Qty) AS RKPairs FROM ( " +
                    "    SELECT CARTONBAR, DDBH, Qty FROM YWCP " +
                    "    WHERE DDBH IN (SELECT RY FROM #SP) AND INDATE IS NOT NULL " +
                    "    UNION " +
                    "    SELECT CARTONBAR, DDBH, Qty FROM YWCPOld " +
                    "    WHERE DDBH IN (SELECT RY FROM #SP) AND INDATE IS NOT NULL " +
                    "  ) AS YWCP " +
                    "  GROUP BY DDBH " +
                    ") AS YWCP ON YWCP.DDBH = SP.RY " +
                    "ORDER BY SP.ID, SP.Container, SP.Seq "
                    , request.Date, request.Factory
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            ShippingPlan plan = new ShippingPlan();
            plan.Date = request.Date;
            plan.Estimate = new List<ShippingContainer>();
            plan.Actual = new List<ShippingContainer>();

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    ShippingContainer container = new ShippingContainer();
                    container.ID = (int)dt.Rows[Row]["ID"];
                    container.Container = dt.Rows[Row]["Container"].ToString();
                    container.Content = new List<ShippingContent>();
                    int pairs = 0, cartons = 0;
                    double cbm = 0;

                    while (Row < dt.Rows.Count && (int)dt.Rows[Row]["ID"] == container.ID)
                    {
                        ShippingContent Content = new ShippingContent();
                        Content.Seq = (int)dt.Rows[Row]["Seq"];
                        Content.Building = dt.Rows[Row]["Building"].ToString();
                        Content.RY = dt.Rows[Row]["RY"].ToString();
                        Content.PO = dt.Rows[Row]["PO"].ToString();
                        Content.SKU = dt.Rows[Row]["SKU"].ToString();
                        Content.Pairs = (int)dt.Rows[Row]["Pairs"];
                        Content.Cartons = (int)dt.Rows[Row]["Cartons"];
                        Content.CBM = (double)dt.Rows[Row]["CBM"];
                        Content.Country = dt.Rows[Row]["Country"].ToString();
                        Content.Status = dt.Rows[Row]["Status"].ToString();

                        pairs = pairs + Content.Pairs;
                        cartons = cartons + Content.Cartons;
                        cbm = cbm + Content.CBM;
                        container.Content.Add(Content);
                        Row++;
                    }

                    container.Pairs = pairs;
                    container.Cartons = cartons;
                    container.CBM = Math.Round(cbm, 4);
                    plan.Estimate.Add(container);
                }
            }

            da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT SB.ID, SB.Inv_No, CAST(ROW_NUMBER() OVER(PARTITION BY SB.INV_NO ORDER BY MIN(SC.building_no), SB.RY) AS INT) AS Seq, " +
                    "MIN(SC.building_no) AS Building, SB.RY, SB.PO, SB.SKU, SB.Pairs, SB.Cartons, SB.CBM, SB.Country, " +
                    "CASE WHEN SB.RKPairs + ISNULL(SUM(YWCPOld.Qty), 0) < SB.RYPairs THEN 'In Production' ELSE 'Finished' END AS Status FROM ( " +
                    "  SELECT CAST(DENSE_RANK() OVER(ORDER BY SB.INV_NO) AS INT) AS ID, SB.Inv_No, INVOICE_D.RYNO AS RY, " +
                    "  INVOICE_D.CUSTORDNO AS PO, INVOICE_D.Article AS SKU, INVOICE_D.Pairs, PACKING_D.CTS AS Cartons, " +
                    "  PACKING_D.CBM, INVOICE_M.TO_WHERE AS Country, DDZL.Pairs AS RYPairs, ISNULL(SUM(YWCP.Qty), 0) AS RKPairs FROM Ship_Booking AS SB " +
                    "  LEFT JOIN INVOICE_M ON INVOICE_M.INV_NO = SB.INV_NO " +
                    "  LEFT JOIN INVOICE_D ON INVOICE_D.INV_NO = SB.INV_NO " +
                    "  LEFT JOIN DDZL ON DDZL.DDBH = INVOICE_D.RYNO " +
                    "  LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "  LEFT JOIN PACKING_D ON PACKING_D.INV_NO = INVOICE_D.INV_NO AND PACKING_D.RYNO = INVOICE_D.RYNO " +
                    "  LEFT JOIN YWCP ON YWCP.DDBH = INVOICE_D.RYNO AND YWCP.INDATE IS NOT NULL " +
                    "  WHERE SB.ExFty_Date = '{0}' AND DDZL.GSBH = '{1}' AND DDZL.DDBH IS NOT NULL " +
                    "  GROUP BY SB.Inv_No, INVOICE_D.RYNO, INVOICE_D.CUSTORDNO, INVOICE_D.Article, INVOICE_D.Pairs, PACKING_D.CTS, PACKING_D.CBM, INVOICE_M.TO_WHERE, DDZL.Pairs " +
                    ") AS SB " +
                    "LEFT JOIN schedule_crawler AS SC ON CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END = SB.RY " +
                    "LEFT JOIN YWCPOld ON YWCPOld.DDBH = SB.RY AND YWCPOld.INDATE IS NOT NULL " +
                    "GROUP BY SB.ID, SB.Inv_No, SB.RY, SB.PO, SB.SKU, SB.Pairs, SB.Cartons, SB.CBM, SB.Country, SB.RKPairs, SB.RYPairs " +
                    "ORDER BY SB.ID "
                    , request.Date, request.Factory
                ), ERP
            );
            dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    ShippingContainer container = new ShippingContainer();
                    container.ID = (int)dt.Rows[Row]["ID"];
                    container.Container = dt.Rows[Row]["Inv_No"].ToString();
                    container.Content = new List<ShippingContent>();
                    int pairs = 0, cartons = 0;
                    double cbm = 0;

                    while (Row < dt.Rows.Count && (int)dt.Rows[Row]["ID"] == container.ID)
                    {
                        ShippingContent Content = new ShippingContent();
                        Content.Seq = (int)dt.Rows[Row]["Seq"];
                        Content.Building = dt.Rows[Row]["Building"].ToString();
                        Content.RY = dt.Rows[Row]["RY"].ToString();
                        Content.PO = dt.Rows[Row]["PO"].ToString();
                        Content.SKU = dt.Rows[Row]["SKU"].ToString();
                        Content.Pairs = (int)dt.Rows[Row]["Pairs"];
                        Content.Cartons = (int)dt.Rows[Row]["Cartons"];
                        Content.CBM = (double)dt.Rows[Row]["CBM"];
                        Content.Country = dt.Rows[Row]["Country"].ToString();
                        Content.Status = dt.Rows[Row]["Status"].ToString();

                        pairs = pairs + Content.Pairs;
                        cartons = cartons + Content.Cartons;
                        cbm = cbm + Content.CBM;
                        container.Content.Add(Content);
                        Row++;
                    }

                    container.Pairs = pairs;
                    container.Cartons = cartons;
                    container.CBM = Math.Round(cbm, 4);
                    plan.Actual.Add(container);
                }
            }

            return JsonConvert.SerializeObject(plan);
        }

        [HttpPost]
        [Route("getShipmentTrackingData")]
        public string getShipmentTrackingData(ScheduleRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#SC') IS NOT NULL " +
                    "BEGIN DROP TABLE #SC END; " +

                    "SELECT RY INTO #SC FROM ( " +
                    "  SELECT DISTINCT INVOICE_D.RYNO AS RY FROM Ship_Booking AS SB " +
                    "  LEFT JOIN INVOICE_D ON INVOICE_D.INV_NO = SB.INV_NO " +
                    "  LEFT JOIN schedule_crawler AS SC ON CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END = INVOICE_D.RYNO " +
                    "  WHERE SB.ExFty_Date >= CONVERT(VARCHAR, GETDATE(), 111) AND SC.building_no = '{1}' " + 
                    "  UNION " +
                    "  SELECT DISTINCT SP.RY FROM ShippingPlan AS SP " +
                    "  LEFT JOIN INVOICE_D ON INVOICE_D.RYNO = SP.RY " +
                    "  LEFT JOIN Ship_Booking AS SB ON SB.INV_NO = INVOICE_D.INV_NO " +
                    "  LEFT JOIN schedule_crawler AS SC ON CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END = SP.RY " +
                    "  WHERE SP.Date <= '{0}' AND SB.ExFty_Date IS NULL AND SC.building_no = '{1}' " +
                    ") AS SC " +

                    "SELECT SP.Type, RIGHT(CONVERT(VARCHAR, SP.ExFactoryDate, 111), 5) AS ExFactoryDate, SP.Building, SP.Lean, SP.PlanDate, SP.DAOMH, SP.ARTICLE, SP.BuyNo, " +
                    "SP.RY, SP.Pairs, SP.ShipDate, SP.Country, ISNULL(SUM(YWCP.Qty), 0) AS RKPairs FROM ( " +
                    "  SELECT SP.Type, SP.ExFactoryDate, SC.building_no AS Building, 'LINE ' + RIGHT('00' + CAST(CAST(RIGHT(SC.lean_no, 2) AS INT) AS VARCHAR), 2) AS Lean, " +
                    "  CONVERT(VARCHAR, MAX(SC.schedule_date), 111) AS PlanDate, XXZL.DAOMH, DDZL.ARTICLE, DDZL.BUYNO, SP.RY, DDZL.Pairs, CONVERT(VARCHAR, DDZL.ShipDate, 111) AS ShipDate, LBZLS.YWSM AS Country FROM ( " +
                    "    SELECT CASE WHEN MAX(SB.ExFty_Date) IS NOT NULL THEN 'Actual' ELSE 'Estimate' END AS Type, SC.RY, ISNULL(MAX(SB.ExFty_Date), SC.SPDate) AS ExFactoryDate FROM ( " +
                    "      SELECT SC.RY, MAX(SP.Date) AS SPDate FROM #SC AS SC " +
                    "      LEFT JOIN ShippingPlan AS SP ON SP.RY = SC.RY " +
                    "      GROUP BY SC.RY " +
                    "    ) AS SC " +
                    "    LEFT JOIN INVOICE_D ON INVOICE_D.RYNO = SC.RY " +
                    "    LEFT JOIN Ship_Booking AS SB ON SB.INV_NO = INVOICE_D.INV_NO " +
                    "    GROUP BY SC.RY, SC.SPDate " +
                    "  ) AS SP " +
                    "  LEFT JOIN DDZL ON DDZL.DDBH = SP.RY " +
                    "  LEFT JOIN schedule_crawler AS SC ON CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END = DDZL.DDBH " +
                    "  LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "  LEFT JOIN LBZLS ON LBZLS.LBDH = DDZL.DDGB AND LBZLS.LB = '06' " +
                    "  WHERE SC.building_no = '{1}' " +
                    "  GROUP BY SP.Type, SP.ExFactoryDate, SC.building_no, SC.lean_no, XXZL.DAOMH, DDZL.ARTICLE, DDZL.BUYNO, SP.RY, DDZL.Pairs, DDZL.ShipDate, LBZLS.YWSM " +
                    ") AS SP " +
                    "LEFT JOIN ( " +
                    "  SELECT CARTONBAR, DDBH, Qty FROM YWCP " +
                    "    WHERE DDBH IN (SELECT RY FROM #SC) AND INDATE IS NOT NULL " +
                    "    UNION " +
                    "    SELECT CARTONBAR, DDBH, Qty FROM YWCPOld " +
                    "    WHERE DDBH IN (SELECT RY FROM #SC) AND INDATE IS NOT NULL " +
                    ") AS YWCP ON YWCP.DDBH = SP.RY " +
                    "GROUP BY SP.Type, SP.ExFactoryDate, SP.Building, SP.Lean, SP.PlanDate, SP.DAOMH, SP.ARTICLE, SP.BuyNo, SP.RY, SP.Pairs, SP.ShipDate, SP.Country " +
                    (request.Type == "NotFinished" ? "HAVING ISNULL(SUM(YWCP.Qty), 0) < SP.Pairs " : "") +
                    "ORDER BY SP.Building, SP.Lean, SP.ExFactoryDate, SP.PlanDate, SP.RY "
                    , request.Date, request.Building
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<ShipmentTrackingLean> leans = new List<ShipmentTrackingLean>();
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    ShipmentTrackingLean lean = new ShipmentTrackingLean();
                    lean.Building = dt.Rows[Row]["Building"].ToString();
                    lean.Lean = dt.Rows[Row]["Lean"].ToString();
                    lean.Data = new List<ShipmentTrackingData>();

                    while (Row < dt.Rows.Count && dt.Rows[Row]["Lean"].ToString() == lean.Lean)
                    {
                        ShipmentTrackingData data = new ShipmentTrackingData();
                        data.Type = dt.Rows[Row]["Type"].ToString();
                        data.ExFactoryDate = dt.Rows[Row]["ExFactoryDate"].ToString();
                        data.PlanDate = dt.Rows[Row]["PlanDate"].ToString();
                        data.CuttingDie = dt.Rows[Row]["DAOMH"].ToString();
                        data.SKU = dt.Rows[Row]["ARTICLE"].ToString();
                        data.BUY = dt.Rows[Row]["BuyNo"].ToString();
                        data.RY = dt.Rows[Row]["RY"].ToString();
                        data.Pairs = (int)dt.Rows[Row]["Pairs"];
                        data.CompletedPairs = (int)dt.Rows[Row]["RKPairs"];
                        data.ShipDate = dt.Rows[Row]["ShipDate"].ToString();
                        data.Country = dt.Rows[Row]["Country"].ToString();

                        lean.Data.Add(data);

                        Row++;
                    }

                    leans.Add(lean);
                }

                return JsonConvert.SerializeObject(leans);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getBuyModels")]
        public string getBuyModels(CommonRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT DDZL.BUYNO, SUM(DDZL.RKPairs) AS RKPairs, " +
                    "ISNULL(SUM(DDZL.Pairs), 0) AS Global, " +
                    "ISNULL(SUM(CASE WHEN MC.Category IS NOT NULL AND MC.Category NOT IN('半冷貼半加硫', '冷貼') THEN DDZL.Pairs END), 0) AS Vulcanize, " +
                    "ISNULL(SUM(CASE WHEN MC.Category = '半冷貼半加硫' THEN DDZL.Pairs END), 0) AS ColdVulcanize, " +
                    "ISNULL(SUM(CASE WHEN MC.Category = '冷貼' THEN DDZL.Pairs END), 0) AS ColdCement, " +
                    "ISNULL(SUM(CASE WHEN MC.Category IS NULL THEN DDZL.Pairs END), 0) AS NoCategory FROM ( " +
                    "  SELECT DDZL.BUYNO, DDZL.DDBH, DDZL.Pairs, DDZL.DAOMH, DDZL.RKPairs + ISNULL(SUM(CASE WHEN YWCPOld.INDATE IS NOT NULL THEN YWCPOld.Qty ELSE 0 END), 0) AS RKPairs FROM ( " +
                    "    SELECT LEFT(CONVERT(VARCHAR, DDZL.DDRQ, 112), 6) AS BUYNO, DDZL.DDBH, DDZL.Pairs, XXZL.DAOMH, ISNULL(SUM(CASE WHEN YWCP.INDATE IS NOT NULL THEN YWCP.Qty ELSE 0 END), 0) AS RKPairs FROM DDZL " +
                    "    LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "    LEFT JOIN YWCP ON YWCP.DDBH = DDZL.DDBH " +
                    "    WHERE CONVERT(VARCHAR, DDZL.DDRQ, 112) LIKE '{0}%' AND DDZL.GSBH = '{1}' AND DDZL.DDZT = 'Y' AND DDZL.DDBH NOT LIKE 'F%' " +
                    "    GROUP BY LEFT(CONVERT(VARCHAR, DDZL.DDRQ, 112), 6), DDZL.DDBH, DDZL.Pairs, XXZL.DAOMH " +
                    "  ) AS DDZL " +
                    "  LEFT JOIN YWCPOld ON YWCPOld.DDBH = DDZL.DDBH " +
                    "  GROUP BY DDZL.BUYNO, DDZL.DDBH, DDZL.Pairs, DDZL.DAOMH, DDZL.RKPairs " +
                    ") AS DDZL " +
                    "LEFT JOIN ModelCategory AS MC ON MC.Model = DDZL.DAOMH " +
                    "GROUP BY DDZL.BUYNO "
                    , request.BuyNo, request.Factory
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                BuyData buyData = new BuyData();
                buyData.BuyNo = dt.Rows[0]["BUYNO"].ToString();
                buyData.FinishedPairs = (int)dt.Rows[0]["RKPairs"];
                buyData.Global = (int)dt.Rows[0]["Global"];
                //buyData.SLT = (int)dt.Rows[0]["SLT"];
                buyData.Vulcanize = (int)dt.Rows[0]["Vulcanize"];
                buyData.ColdVulcanize = (int)dt.Rows[0]["ColdVulcanize"];
                buyData.ColdCement = (int)dt.Rows[0]["ColdCement"];
                buyData.NoCategory = (int)dt.Rows[0]["NoCategory"];
                buyData.GlobalModels = new List<BuyModel>();
                buyData.SLTModels = new List<BuyModel>();

                da = new SqlDataAdapter(
                    System.String.Format(
                        "IF OBJECT_ID('tempdb..#DDZL') IS NOT NULL " +
                        "BEGIN DROP TABLE #DDZL END; " +

                        "IF OBJECT_ID('tempdb..#DDB') IS NOT NULL " +
                        "BEGIN DROP TABLE #DDB END; " +

                        "SELECT LEFT(CONVERT(VARCHAR, DDZL.DDRQ, 112), 6) AS BUYNO, DDZL.DDBH, DDZL.Pairs, XXZL.DAOMH, MC.Category, ISNULL(DDZL.RYType, 'GLOBAL') AS RYType INTO #DDZL FROM DDZL " +
                        "LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                        "LEFT JOIN ModelCategory AS MC ON MC.Model = XXZL.DAOMH " +
                        "WHERE CONVERT(VARCHAR, DDZL.DDRQ, 112) LIKE '{0}%' AND DDZL.GSBH = '{1}' AND DDZL.DDZT = 'Y' AND DDZL.DDBH NOT LIKE 'F%' " +
                        "AND XXZL.DAOMH LIKE '{2}%' AND XXZL.XTMH LIKE '{3}%' AND XXZL.ARTICLE LIKE '{4}%' AND DDZL.DDBH LIKE '{5}%' " +

                        "SELECT DISTINCT DDZL.DAOMH, DDZL.RYType, 'LINE ' + RIGHT('00' + CAST(CAST(ISNULL(RIGHT(SC.lean_no, 2), RIGHT(BDepartment.DepName, 2)) AS INT) AS VARCHAR), 2) AS Lean INTO #DDB FROM #DDZL AS DDZL " +
                        "LEFT JOIN schedule_crawler AS SC ON CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END = DDZL.DDBH " +
                        "LEFT JOIN SMDD ON SMDD.YSBH = DDZL.DDBH AND SMDD.GXLB = 'A' " +
                        "LEFT JOIN BDepartment ON BDepartment.ID = SMDD.DepNO " +

                        "SELECT DDZL.BUYNO, DDZL.DAOMH, SUM(DDZL.Pairs) AS Pairs, " +
                        "CASE WHEN DDZL.Category = '冷貼' THEN 'Cold Cement' ELSE CASE WHEN DDZL.Category = '半冷貼半加硫' THEN 'Cold Vulcanize' ELSE " +
                        "CASE WHEN DDZL.Category IS NOT NULL THEN 'Vulcanize' ELSE 'No Category' END END END AS Category, " +
                        "CASE WHEN DDZL.Category LIKE '滑板鞋%' THEN '滑板鞋' ELSE DDZL.Category END AS SubCategory, " +
                        "DDZL.RYType, ISNULL(YWCP.RKPairs, 0) AS RKPairs, PL.Buildings FROM #DDZL AS DDZL " +
                        "LEFT JOIN ( " +
                        "  SELECT DISTINCT DDB1.DAOMH, DDB1.RYType, STUFF(( " +
                        "    SELECT ', ' + DDB2.Lean FROM #DDB AS DDB2 " +
                        "    WHERE DDB2.DAOMH = DDB1.DAOMH AND DDB2.RYType = DDB1.RYType " +
                        "    ORDER BY DDB2.Lean " +
                        "    FOR XML PATH('') " +
                        "  ), 1, 2, '') AS Buildings FROM #DDB AS DDB1 " +
                        ") AS PL ON PL.DAOMH = DDZL.DAOMH AND PL.RYType = DDZL.RYType " +
                        "LEFT JOIN ( " +
                        "  SELECT RYType, DAOMH, SUM(RKPairs) AS RKPairs FROM ( " +
                        "    SELECT DDZL.RYType, DDZL.DAOMH, DDZL.DDBH, DDZL.RKPairs + ISNULL(SUM(YWCPOld.Qty), 0) AS RKPairs FROM ( " +
                        "      SELECT DDZL.RYType, DDZL.DAOMH, DDZL.DDBH, ISNULL(SUM(YWCP.Qty), 0) AS RKPairs FROM #DDZL AS DDZL " +
                        "      LEFT JOIN YWCP ON YWCP.DDBH = DDZL.DDBH AND YWCP.INDATE IS NOT NULL " +
                        "      GROUP BY DDZL.RYType, DDZL.DAOMH, DDZL.DDBH " +
                        "    ) AS DDZL " +
                        "    LEFT JOIN YWCPOld ON YWCPOld.DDBH = DDZL.DDBH AND YWCPOld.INDATE IS NOT NULL " +
                        "    GROUP BY DDZL.RYType, DDZL.DAOMH, DDZL.DDBH, DDZL.RKPairs " +
                        "  ) AS YWCP " +
                        "  GROUP BY RYType, DAOMH " +
                        ") AS YWCP ON YWCP.RYType = DDZL.RYType AND YWCP.DAOMH = DDZL.DAOMH " +
                        "GROUP BY DDZL.BUYNO, DDZL.DAOMH, DDZL.Category, DDZL.RYType, YWCP.RKPairs, PL.Buildings " +
                        "ORDER BY DDZL.RYType, SUM(DDZL.Pairs) DESC "
                        , request.BuyNo, request.Factory, request.CuttingDie, request.Last, request.SKU, request.RY
                    ), ERP
                );
                DataTable dt2 = new DataTable();
                da.Fill(dt2);

                if (dt2.Rows.Count > 0)
                {
                    int Row = 0;
                    while (Row < dt2.Rows.Count)
                    {
                        if (dt2.Rows[Row]["RYType"].ToString() == "GLOBAL")
                        {
                            BuyModel model = new BuyModel();
                            model.ID = buyData.GlobalModels.Count;
                            model.Category = dt2.Rows[Row]["Category"].ToString();
                            model.SubCategory = dt2.Rows[Row]["SubCategory"].ToString();
                            model.CuttingDie = dt2.Rows[Row]["DAOMH"].ToString();
                            model.Buildings = dt2.Rows[Row]["Buildings"].ToString();
                            model.Pairs = (int)dt2.Rows[Row]["Pairs"];
                            model.FinishedPairs = (int)dt2.Rows[Row]["RKPairs"];

                            buyData.GlobalModels.Add(model);
                        }
                        else
                        {
                            BuyModel model = new BuyModel();
                            model.ID = buyData.SLTModels.Count;
                            model.Category = dt2.Rows[Row]["Category"].ToString();
                            model.SubCategory = dt2.Rows[Row]["SubCategory"].ToString();
                            model.CuttingDie = dt2.Rows[Row]["DAOMH"].ToString();
                            model.Buildings = dt2.Rows[Row]["Buildings"].ToString();
                            model.Pairs = (int)dt2.Rows[Row]["Pairs"];
                            model.FinishedPairs = (int)dt2.Rows[Row]["RKPairs"];

                            buyData.SLTModels.Add(model);
                        }

                        Row++;
                    }
                }

                return JsonConvert.SerializeObject(buyData);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getBuySKUs")]
        public string getBuySKUs(CommonRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#DDZL') IS NOT NULL " +
                    "BEGIN DROP TABLE #DDZL END; " +

                    "IF OBJECT_ID('tempdb..#DDB') IS NOT NULL " +
                    "BEGIN DROP TABLE #DDB END; " +

                    "SELECT LEFT(CONVERT(VARCHAR, DDZL.DDRQ, 112), 6) AS BUYNO, DDZL.DDBH, XXZL.DAOMH, XXZL.XTMH, XXZL.ARTICLE, KFXXZL.DEVCODE, XXZL.XieMing, XXZL.YSSM, DDZL.Pairs INTO #DDZL FROM DDZL " +
                    "LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "LEFT JOIN KFXXZL ON KFXXZL.XieXing = DDZL.XieXing AND KFXXZL.SheHao = DDZL.SheHao " +
                    "WHERE CONVERT(VARCHAR, DDZL.DDRQ, 112) LIKE '{0}%' AND DDZL.GSBH = '{1}' AND DDZL.DDZT = 'Y' AND DDZL.DDBH NOT LIKE 'F%' " +
                    "AND XXZL.DAOMH = '{3}' AND XXZL.XTMH LIKE '{4}%' AND XXZL.ARTICLE LIKE '{5}%' AND DDZL.DDBH LIKE '{6}%' " +

                    "SELECT DISTINCT DDZL.ARTICLE, SC.building_no + ' - ' + SC.lean_no AS Lean INTO #DDB FROM #DDZL AS DDZL " +
                    "LEFT JOIN schedule_crawler AS SC ON CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END = DDZL.DDBH " +
                    "LEFT JOIN SMDD ON SMDD.YSBH = DDZL.DDBH AND SMDD.GXLB = 'A' " +

                    "SELECT DDZL.BUYNO, DDZL.DAOMH, DDZL.XTMH, DDZL.ARTICLE, DDZL.DEVCODE, DDZL.XieMing, DDZL.YSSM, SUM(DDZL.Pairs) AS Pairs, ISNULL(YWCP.RKPairs, 0) AS RKPairs, PL.Buildings FROM #DDZL AS DDZL " +
                    "LEFT JOIN ( " +
                    "  SELECT DISTINCT DDB1.ARTICLE, STUFF(( " +
                    "    SELECT DISTINCT ', ' + DDB2.Lean FROM #DDB AS DDB2 " +
                    "    WHERE DDB2.ARTICLE = DDB1.ARTICLE " +
                    "    FOR XML PATH('') " +
                    "  ), 1, 2, '') AS Buildings FROM #DDB AS DDB1 " +
                    ") AS PL ON PL.ARTICLE = DDZL.ARTICLE " +
                    "LEFT JOIN ( " +
                    "  SELECT ARTICLE, SUM(RKPairs) AS RKPairs FROM ( " +
                    "    SELECT DDZL.ARTICLE, DDZL.DDBH, DDZL.RKPairs + ISNULL(SUM(YWCPOld.Qty), 0) AS RKPairs FROM ( " +
                    "      SELECT DDZL.ARTICLE, DDZL.DDBH, ISNULL(SUM(YWCP.Qty), 0) AS RKPairs FROM #DDZL AS DDZL " +
                    "      LEFT JOIN YWCP ON YWCP.DDBH = DDZL.DDBH AND YWCP.INDATE IS NOT NULL " +
                    "      GROUP BY DDZL.ARTICLE, DDZL.DDBH " +
                    "    ) AS DDZL " +
                    "    LEFT JOIN YWCPOld ON YWCPOld.DDBH = DDZL.DDBH AND YWCPOld.INDATE IS NOT NULL " +
                    "    GROUP BY DDZL.ARTICLE, DDZL.DDBH, DDZL.RKPairs " +
                    "  ) AS YWCP " +
                    "  GROUP BY ARTICLE " +
                    ") AS YWCP ON YWCP.ARTICLE = DDZL.ARTICLE " +
                    "GROUP BY DDZL.BUYNO, DDZL.DAOMH, DDZL.XTMH, DDZL.ARTICLE, DDZL.DEVCODE, DDZL.YSSM, DDZL.XieMing, YWCP.RKPairs, PL.Buildings " +
                    "ORDER BY SUM(DDZL.Pairs) DESC "
                    , request.BuyNo, request.Factory, request.RYType, request.CuttingDie, request.Last, request.SKU, request.RY
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<BuySKU> buySKUs = new List<BuySKU>();

                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    BuySKU sku = new BuySKU();
                    sku.ID = buySKUs.Count;
                    sku.Name = dt.Rows[Row]["XieMing"].ToString();
                    sku.Color = dt.Rows[Row]["YSSM"].ToString();
                    sku.Last = dt.Rows[Row]["XTMH"].ToString();
                    sku.SKU = dt.Rows[Row]["ARTICLE"].ToString();
                    sku.SR = dt.Rows[Row]["DEVCODE"].ToString();
                    sku.Buildings = dt.Rows[Row]["Buildings"].ToString();
                    sku.Pairs = (int)dt.Rows[Row]["Pairs"];
                    sku.FinishedPairs = (int)dt.Rows[Row]["RKPairs"];

                    buySKUs.Add(sku);
                    Row++;
                }

                return JsonConvert.SerializeObject(buySKUs);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getBuyRYs")]
        public string getBuyRYs(CommonRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#DDZL') IS NOT NULL " +
                    "BEGIN DROP TABLE #DDZL END; " +

                    "SELECT DDZL.DDBH, DDZL.Pairs, DDZL.DDRQ, DDZL.ShipDate, SC.building_no + ' - ' + SC.lean_no AS Lean, SC.schedule_date AS PlanDate, SC.ry_index INTO #DDZL FROM DDZL " +
                    "LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                    "LEFT JOIN schedule_crawler AS SC ON CASE WHEN LEN(SC.ry) - LEN(REPLACE(SC.ry, '-', '')) < 2 THEN SC.ry ELSE SUBSTRING(SC.ry, 1, LEN(SC.ry) - CHARINDEX('-', REVERSE(SC.ry))) END = DDZL.DDBH " +
                    "WHERE CONVERT(VARCHAR, DDZL.DDRQ, 112) LIKE '{0}%' AND DDZL.GSBH = '{1}' AND XXZL.DAOMH = '{3}' AND XXZL.ARTICLE = '{4}' AND DDZL.DDBH LIKE '{5}%' AND DDZL.DDZT = 'Y' AND DDZL.DDBH NOT LIKE 'F%' " +

                    "SELECT DDZL.DDBH, CONVERT(VARCHAR, DDZL.DDRQ, 111) AS DDRQ, CONVERT(VARCHAR, DDZL.ShipDate, 111) AS ShipDate, PL.Lean, " +
                    "CONVERT(VARCHAR, MIN(DDZL.PlanDate), 111) As PlanDate, DDZL.Pairs, ISNULL(YWCP.RKPairs, 0) AS RKPairs FROM #DDZL AS DDZL " +
                    "LEFT JOIN ( " +
                    "  SELECT DISTINCT DDZL1.DDBH, STUFF(( " +
                    "    SELECT DISTINCT ', ' + DDZL2.Lean FROM #DDZL AS DDZL2 " +
                    "    WHERE DDZL2.DDBH = DDZL1.DDBH " +
                    "    FOR XML PATH('') " +
                    "  ), 1, 2, '') AS Lean FROM #DDZL AS DDZL1 " +
                    ") AS PL ON PL.DDBH = DDZL.DDBH " +
                    "LEFT JOIN ( " +
                    "  SELECT DDZL.DDBH, DDZL.RKPairs + ISNULL(SUM(YWCPOld.Qty), 0) AS RKPairs FROM ( " +
                    "    SELECT DDZL.DDBH, ISNULL(SUM(YWCP.Qty), 0) AS RKPairs FROM ( " +
                    "      SELECT DISTINCT DDBH FROM #DDZL " +
                    "    ) AS DDZL " +
                    "    LEFT JOIN YWCP ON YWCP.DDBH = DDZL.DDBH AND YWCP.INDATE IS NOT NULL " +
                    "    GROUP BY DDZL.DDBH " +
                    "  ) AS DDZL " +
                    "  LEFT JOIN YWCPOld ON YWCPOld.DDBH = DDZL.DDBH AND YWCPOld.INDATE IS NOT NULL " +
                    "  GROUP BY DDZL.DDBH, DDZL.RKPairs " +
                    ") AS YWCP ON YWCP.DDBH = DDZL.DDBH " +
                    "GROUP BY DDZL.DDBH, DDZL.DDRQ, DDZL.ShipDate, PL.Lean, DDZL.Pairs, YWCP.RKPairs, DDZL.ry_index " +
                    "ORDER BY DDZL.PlanDate, DDZL.ry_index "
                    , request.BuyNo, request.Factory, request.RYType, request.CuttingDie, request.SKU, request.RY
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<BuyRYs> buyRYs = new List<BuyRYs>();
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    BuyRYs ry = new BuyRYs();
                    ry.RY = dt.Rows[Row]["DDBH"].ToString();
                    ry.ReceiveDate = dt.Rows[Row]["DDRQ"].ToString();
                    ry.ShippingDate = dt.Rows[Row]["ShipDate"].ToString();
                    ry.LaunchDate = dt.Rows[Row]["PlanDate"].ToString();
                    ry.LaunchLine = dt.Rows[Row]["Lean"].ToString();
                    ry.Pairs = (int)dt.Rows[Row]["Pairs"];
                    ry.FinishedPairs = (int)dt.Rows[Row]["RKPairs"];

                    Row++;
                    buyRYs.Add(ry);
                }

                return JsonConvert.SerializeObject(buyRYs);
            }
            else
            {
                return "[]";
            }
        }

        [HttpPost]
        [Route("getRYBom")]
        public string getRYBom(CommonRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "IF OBJECT_ID('tempdb..#Level1') IS NOT NULL " +
                    "BEGIN DROP TABLE #Level1 END; " +

                    "IF OBJECT_ID('tempdb..#Level2') IS NOT NULL " +
                    "BEGIN DROP TABLE #Level2 END; " +

                    "IF OBJECT_ID('tempdb..#Level3') IS NOT NULL " +
                    "BEGIN DROP TABLE #Level3 END; " +

                    "SELECT ZLBH, CAST(ROW_NUMBER() OVER(PARTITION BY ZLZLS2.ZLBH ORDER BY ZLZLS2.BWBH) AS INT) AS L1, 0 AS L2, 0 AS L3, BWBH, CSBH, CLBH, CAST(SUM(CLSL) AS Float) AS CLSL INTO #Level1 FROM ZLZLS2 " +
                    "WHERE ZLBH = '{0}' AND MJBH = 'ZZZZZZZZZZ' AND ISNULL(ZLZLS2.CLSL, 0) > 0 " +
                    "GROUP BY ZLBH, BWBH, ZLZLS2.CSBH, ZLZLS2.CLBH " +

                    "SELECT ZLZLS2.ZLBH, L1.L1, CAST(ROW_NUMBER() OVER(PARTITION BY ZLZLS2.ZLBH, ZLZLS2.BWBH ORDER BY ZLZLS2.CLBH) AS INT) AS L2, 0 AS L3, " +
                    "ZLZLS2.BWBH, ZLZLS2.CSBH, ZLZLS2.CLBH, CAST(SUM(ZLZLS2.CLSL) AS Float) AS CLSL INTO #Level2 FROM #Level1 AS L1 " +
                    "INNER JOIN ZLZLS2 ON ZLZLS2.ZLBH = L1.ZLBH AND ZLZLS2.BWBH = L1.BWBH AND ZLZLS2.MJBH = L1.CLBH " +
                    "GROUP BY ZLZLS2.ZLBH, L1.L1, ZLZLS2.BWBH, ZLZLS2.CSBH, ZLZLS2.CLBH " +

                    "SELECT ZLZLS2.ZLBH, L2.L1, L2.L2, CAST(ROW_NUMBER() OVER(PARTITION BY ZLZLS2.ZLBH, ZLZLS2.BWBH ORDER BY ZLZLS2.CLBH) AS INT) AS L3, " +
                    "ZLZLS2.BWBH, ZLZLS2.CSBH, ZLZLS2.CLBH, CAST(SUM(ZLZLS2.CLSL) AS Float) AS CLSL INTO #Level3 FROM #Level2 AS L2 " +
                    "INNER JOIN ZLZLS2 ON ZLZLS2.ZLBH = L2.ZLBH AND ZLZLS2.BWBH = L2.BWBH AND ZLZLS2.MJBH = L2.CLBH " +
                    "GROUP BY ZLZLS2.ZLBH, L2.L1, L2.L2, ZLZLS2.BWBH, ZLZLS2.CSBH, ZLZLS2.CLBH " +

                    "SELECT ZLZLS2.ZLBH, ZLZLS2.BWBH, BWZL.YWSM, ZLZLS2.L1, ZLZLS2.L2, ZLZLS2.L3, ZLZLS2.CSBH, ZSZL.ZSYWJC, ZLZLS2.CLBH, CLZL.YWPM, ZLZLS2.CLSL, CLZL.DWBH FROM ( " +
                    "  SELECT ZLBH, L1, L2, L3, BWBH, CSBH, CLBH, CLSL FROM #Level1 " +
                    "  UNION " +
                    "  SELECT ZLBH, L1, L2, L3, BWBH, CSBH, CLBH, CLSL FROM #Level2 " +
                    "  UNION " +
                    "  SELECT ZLBH, L1, L2, L3, BWBH, CSBH, CLBH, CLSL FROM #Level3 " +
                    ") AS ZLZLS2 " +
                    "LEFT JOIN BWZL ON BWZL.BWDH = ZLZLS2.BWBH " +
                    "LEFT JOIN ZSZL ON ZSZL.ZSDH = ZLZLS2.CSBH " +
                    "LEFT JOIN CLZL ON CLZL.CLDH = ZLZLS2.CLBH " +
                    "ORDER BY ZLZLS2.BWBH, ZLZLS2.L1, ZLZLS2.L2, ZLZLS2.L3 "
                    , request.RY
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            if (dt.Rows.Count > 0)
            {
                List<BomPart> parts = new List<BomPart>();
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    if ((int)dt.Rows[Row]["L2"] == 0)
                    {
                        BomPart part = new BomPart();
                        part.PartID = dt.Rows[Row]["BWBH"].ToString();
                        part.PartName = dt.Rows[Row]["YWSM"].ToString();
                        part.SupID = dt.Rows[Row]["CSBH"].ToString();
                        part.SupName = dt.Rows[Row]["ZSYWJC"].ToString();
                        part.MatID = dt.Rows[Row]["CLBH"].ToString();
                        part.MatName = dt.Rows[Row]["YWPM"].ToString();
                        part.Usage = (double)dt.Rows[Row]["CLSL"];
                        part.Unit = dt.Rows[Row]["DWBH"].ToString();
                        part.SubMaterials = new List<BomMaterial>();

                        parts.Add(part);
                    }
                    else if ((int)dt.Rows[Row]["L2"] > 0 && (int)dt.Rows[Row]["L3"] == 0)
                    {
                        BomMaterial material = new BomMaterial();
                        material.SupID = dt.Rows[Row]["CSBH"].ToString();
                        material.SupName = dt.Rows[Row]["ZSYWJC"].ToString();
                        material.MatID = dt.Rows[Row]["CLBH"].ToString();
                        material.MatName = dt.Rows[Row]["YWPM"].ToString();
                        material.Usage = (double)dt.Rows[Row]["CLSL"];
                        material.Unit = dt.Rows[Row]["DWBH"].ToString();
                        material.SubMaterials = new List<BomMaterial>();

                        parts[(int)dt.Rows[Row]["L1"] - 1].SubMaterials.Add(material);
                    }
                    else if ((int)dt.Rows[Row]["L3"] > 0)
                    {
                        BomMaterial material = new BomMaterial();
                        material.SupID = dt.Rows[Row]["CSBH"].ToString();
                        material.SupName = dt.Rows[Row]["ZSYWJC"].ToString();
                        material.MatID = dt.Rows[Row]["CLBH"].ToString();
                        material.MatName = dt.Rows[Row]["YWPM"].ToString();
                        material.Usage = (double)dt.Rows[Row]["CLSL"];
                        material.Unit = dt.Rows[Row]["DWBH"].ToString();
                        material.SubMaterials = new List<BomMaterial>();

                        parts[(int)dt.Rows[Row]["L1"] - 1].SubMaterials[(int)dt.Rows[Row]["L2"] - 1].SubMaterials.Add(material);
                    }

                    Row++;
                }

                return JsonConvert.SerializeObject(parts);
            }
            else
            {
                return "[]";
            }
        }

        //Emma
        [HttpPost]
        [Route("getEmmaWorkOrder")]
        public string getEmmaWorkOrder(EmmaRequest request)
        {
            try
            {
                if (request.PlanStartDate == "" || request.PlanEndDate == "")
                {
                    throw new Exception();
                }

                SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
                SqlDataAdapter da = new SqlDataAdapter(
                    System.String.Format(
                        "SET ARITHABORT ON; " +
                        "IF OBJECT_ID('tempdb..#WorkOrder') IS NOT NULL " +
                        "BEGIN DROP TABLE #WorkOrder END; " +

                        "SELECT CutDispatch_Auto.ListNo, CONVERT(VARCHAR, CutDispatch_Auto.PlanDate, 111) AS PlanDate, CutDispatch_Auto.Machine, " +
                        "XXZL.DAOMH, CutDispatchS_Auto.RY, CutDispatchS_Auto.Part, CutDispatchS_Auto.Cycle INTO #WorkOrder FROM CutDispatch_Auto " +
                        "LEFT JOIN CutDispatchS_Auto ON CutDispatchS_Auto.ListNo = CutDispatch_Auto.ListNo " +
                        "LEFT JOIN DDZL ON DDZL.DDBH = CutDispatchS_Auto.RY " +
                        "LEFT JOIN XXZL ON XXZL.XieXing = DDZL.XieXing AND XXZL.SheHao = DDZL.SheHao " +
                        "WHERE CutDispatch_Auto.Machine LIKE 'EMMA%' AND CutDispatch_Auto.ListNo LIKE '{1}%' " +
                        //"AND CutDispatch_Auto.PlanDate BETWEEN '{2}' AND '{3}' " +
                        "AND CutDispatchS_Auto.Cycle LIKE '%{4}%' AND XXZL.DAOMH LIKE '{5}%' " +

                        "SELECT #WorkOrder.ListNo, CONVERT(VARCHAR, #WorkOrder.PlanDate, 111) AS PlanDate, #WorkOrder.Machine, #WorkOrder.DAOMH, SMDD.YSBH, " +
                        "SMDD.DDBH, CAST(SMDD.Size AS FLOAT) AS Size, BWZL.BWBH, BWZL.YWSM, SMDD.Pairs, CutDispatchZL.CLBH FROM #WorkOrder " +
                        "LEFT JOIN ( " +
                        "  SELECT SMDD.YSBH, SMDD.DDBH, SMDDS.XXCC AS RYSize, XXGJS.GJCC AS Size, SMDDS.Qty AS Pairs FROM SMDD " +
                        "  LEFT JOIN SMDDS ON SMDDS.DDBH = SMDD.DDBH " +
                        "  LEFT JOIN DDZL ON DDZL.DDBH = SMDD.YSBH " +
                        "  LEFT JOIN XXGJS ON XXGJS.XieXing = DDZL.XieXing AND XXGJS.XXCC = SMDDS.XXCC AND XXGJS.GJLB = '100' " +
                        "  WHERE SMDD.YSBH IN (SELECT DISTINCT RY FROM #WorkOrder) " +
                        "  AND SMDD.DDBH IN ( " +
                        "    SELECT DISTINCT LTRIM(RTRIM(Split.a.value('.', 'VARCHAR(300)'))) 'Cycle' FROM ( " +
                        "      SELECT CAST('<M>' + REPLACE(Cycle, ',', '</M><M>') + '</M>' AS XML) AS Data FROM #WorkOrder " +
                        "    ) AS A " +
                        "    CROSS APPLY Data.nodes('/M') AS Split(a) " +
                        "  ) AND SMDD.GXLB = 'C' " +
                        ") AS SMDD ON SMDD.YSBH = #WorkOrder.RY " +
                        "LEFT JOIN ( " +
                        "  SELECT WorkOrder.ListNo, WorkOrder.RY, WorkOrder.BWBH, BWZL.YWSM FROM ( " +
                        "    SELECT DISTINCT ListNo, RY, LTRIM(RTRIM(Split.a.value('.', 'VARCHAR(100)'))) 'BWBH' FROM ( " +
                        "      SELECT ListNo, RY, CAST('<M>' + REPLACE(Part, ',', '</M><M>') + '</M>' AS XML) AS Data FROM #WorkOrder " +
                        "    ) AS A " +
                        "    CROSS APPLY Data.nodes('/M') AS Split(a) " +
                        "  ) AS WorkOrder " +
                        "  LEFT JOIN BWZL ON BWZL.BWDH = WorkOrder.BWBH " +
                        ") AS BWZL ON BWZL.RY = #WorkOrder.RY " +
                        "LEFT JOIN CutDispatchZL ON CutDispatchZL.ZLBH = SMDD.YSBH AND CutDispatchZL.BWBH = BWZL.BWBH AND CutDispatchZL.SIZE = SMDD.RYSize " +
                        "WHERE CutDispatchZL.ZLBH IS NOT NULL AND SMDD.DDBH LIKE '{4}%' " +
                        "ORDER BY SMDD.DDBH, BWZL.BWBH, CAST(SMDD.Size AS FLOAT) "
                        , request.MachineID, request.WorkOrder, request.PlanStartDate, request.PlanEndDate, request.RY, request.Model
                    ), ERP
                );
                DataTable dt = new DataTable();
                da.Fill(dt);

                EmmaResponse eResponse = new EmmaResponse();
                eResponse.Success = true;
                eResponse.Data = new List<EmmaResult>();

                if (dt.Rows.Count > 0)
                {
                    int Row = 0;
                    while (Row < dt.Rows.Count)
                    {
                        EmmaResult Result = new EmmaResult();
                        Result.MachineID = dt.Rows[Row]["Machine"].ToString();
                        Result.WorkOrder = dt.Rows[Row]["ListNo"].ToString();
                        Result.PlanDate = dt.Rows[Row]["PlanDate"].ToString();
                        Result.RY = dt.Rows[Row]["DDBH"].ToString();
                        Result.Model = dt.Rows[Row]["DAOMH"].ToString();
                        Result.PartID = dt.Rows[Row]["BWBH"].ToString();
                        string name = dt.Rows[Row]["YWSM"].ToString();
                        for (int i = name.Length - 1; i > 0; i--)
                        {
                            if (int.TryParse(name[i].ToString(), out _) || name[i].ToString() == " " || name[i].ToString() == "#")
                            {
                                name = name.Remove(name.Length - 1);
                            }
                            else
                            {
                                break;
                            }
                        }
                        Result.PartName = name;
                        Result.Size = dt.Rows[Row]["Size"].ToString();
                        Result.Qty = (int)dt.Rows[Row]["Pairs"];
                        Result.MaterialID = dt.Rows[Row]["CLBH"].ToString();
                        eResponse.Data.Add(Result);
                        Row++;
                    }

                    return JsonConvert.SerializeObject(eResponse);
                }
                else
                {
                    eResponse.Data = new List<EmmaResult>();
                    return JsonConvert.SerializeObject(eResponse);
                }
            }
            catch (Exception ex)
            {
                EmmaResponse eResponse = new EmmaResponse();
                eResponse.Success = false;
                eResponse.Data = new List<EmmaResult>();
                return JsonConvert.SerializeObject(eResponse);
            }
        }

        [HttpPost]
        [Route("submitEmmaCuttingProgress")]
        public string submitEmmaCuttingProgress(EmmaCompleteRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlCommand SQL;
            try {
                if (request.MachineID != "" && request.StartTime != "" && request.EndTime != "" && request.Completed!.Count > 0)
                {
                    ERP.Open();
                    for (int i = 0; i < request.Completed.Count; i++) {
                        if (request.Completed[i].WorkOrder != "" && request.Completed[i].Data!.Count > 0)
                        {
                            string whereSQL = string.Empty;
                            string setSQL = string.Empty;
                            
                            foreach (CompleteData Data in request.Completed[i].Data!)
                            {
                                if (Data.RY != "" && Data.PartID != "" && Data.Size != "" && Data.MaterialID != "" && Data.Qty > 0)
                                {
                                    SQL = new SqlCommand(
                                        System.String.Format(
                                            "DECLARE @DLNO VARCHAR(12) = ( " +
                                            "  SELECT DLNO FROM CutDispatch_Auto WHERE ListNo = '{0}' " +
                                            "); " +

                                            "IF LEN(@DLNO) = 11 " +
                                            "BEGIN " +
                                            "  UPDATE CutDispatchSS SET ScanQty = CutDispatchSS.ScanQty + Dispatch.ScanQty, Machine = '{1}', MachineDate = CASE WHEN CutDispatchSS.MachineDate IS NULL THEN '{2}' ELSE CutDispatchSS.MachineDate END, MachineEndDate = '{3}' " +
                                            "  FROM ( " +
                                            "    SELECT CutDispatchSS.DLNO, CutDispatchSS.ZLBH, CutDispatchSS.DDBH, CutDispatchSS.BWBH, CutDispatchSS.SIZE, CutDispatchSS.CLBH, " +
                                            "    CASE WHEN Dispatch.CompleteQty - SUM(Dispatch.Qty) >= 0 THEN CutDispatchSS.Qty ELSE CutDispatchSS.Qty + Dispatch.CompleteQty - SUM(Dispatch.Qty) END AS ScanQty FROM ( " +
                                            "      SELECT ROW_NUMBER() OVER(ORDER BY DDBH) AS Seq, CutDispatchSS.DLNO, ZLBH, DDBH, BWBH, SIZE, Qty - ScanQty AS Qty, CLBH FROM CutDispatchSS " +
                                            "      LEFT JOIN CutDispatch ON CutDispatch.DLNO = CutDispatchSS.DLNO " +
                                            "      WHERE CutDispatchSS.DLNO = @DLNO AND DDBH = '{4}' AND BWBH = '{5}' AND REPLACE(SIZE, ' ', '') = '{6}' AND CLBH = '{7}' AND Qty > ScanQty " +
                                            "      AND CutDispatch.DLLB LIKE 'EMMA%' " +
                                            "    ) AS CutDispatchSS " +
                                            "    LEFT JOIN ( " +
                                            "      SELECT ROW_NUMBER() OVER(ORDER BY DDBH) AS Seq, Qty - ScanQty AS Qty, {8} AS CompleteQty FROM CutDispatchSS " +
                                            "      WHERE DLNO = @DLNO AND DDBH = '{4}' AND BWBH = '{5}' AND REPLACE(SIZE, ' ', '') = '{6}' AND CLBH = '{7}' AND Qty > ScanQty " +
                                            "    ) AS Dispatch ON Dispatch.Seq <= CutDispatchSS.Seq " +
                                            "    GROUP BY CutDispatchSS.Seq, CutDispatchSS.DLNO, CutDispatchSS.ZLBH, CutDispatchSS.DDBH, CutDispatchSS.BWBH, CutDispatchSS.SIZE, " +
                                            "    CutDispatchSS.Qty, CutDispatchSS.CLBH, Dispatch.CompleteQty " +
                                            "    HAVING CASE WHEN Dispatch.CompleteQty - SUM(Dispatch.Qty) >= 0 THEN CutDispatchSS.Qty ELSE CutDispatchSS.Qty + Dispatch.CompleteQty - SUM(Dispatch.Qty) END > 0 " +
                                            "  ) AS Dispatch " +
                                            "  WHERE CutDispatchSS.DLNO = Dispatch.DLNO AND CutDispatchSS.ZLBH = Dispatch.ZLBH AND CutDispatchSS.DDBH = Dispatch.DDBH " +
                                            "  AND CutDispatchSS.BWBH = Dispatch.BWBH AND CutDispatchSS.SIZE = Dispatch.SIZE AND CutDispatchSS.CLBH = Dispatch.CLBH " +
                                            "END; " +

                                            "UPDATE CutDispatchS_Auto SET ScanQty = CASE WHEN ScanQty + {8} < Qty THEN ScanQty + {8} ELSE Qty END, StartTime = CASE WHEN StartTime IS NULL THEN '{2}' ELSE StartTime END, EndTime = '{3}' WHERE ListNo = '{0}' AND Cycle LIKE '%{4}%' ; "
                                            , request.Completed[i].WorkOrder, request.MachineID, request.StartTime, request.EndTime, Data.RY, Data.PartID, Data.Size, Data.MaterialID, Data.Qty.ToString()
                                        ), ERP
                                    );
                                    SQL.ExecuteNonQuery();
                                }
                            }

                            SQL = new SqlCommand(
                                System.String.Format(
                                    "DECLARE @DLNO VARCHAR(12) = ( " +
                                    "  SELECT DLNO FROM CutDispatch_Auto WHERE ListNo = '{0}' " +
                                    "); " +

                                    "IF LEN(@DLNO) = 11 " +
                                    "BEGIN " +
                                    "  UPDATE CutDispatchS SET okCutNum = FLOOR(CutNum * CutDispatchSS.ScanQty / CutDispatchSS.Qty), ScanUser = '{1}', " +
                                    "  ScanDate = CASE WHEN okCutNum <> FLOOR(CutNum * CutDispatchSS.ScanQty / CutDispatchSS.Qty) THEN GETDATE() ELSE NULL END " +
                                    "  FROM ( " +
                                    "    SELECT CutDispatchSS.* FROM CutDispatchS " +
                                    "    LEFT JOIN ( " +
                                    "      SELECT DLNO, ZLBH, BWBH, SIZE, SUM(Qty) AS Qty, SUM(ScanQty) AS ScanQty FROM CutDispatchSS " +
                                    "      WHERE DLNO = @DLNO " +
                                    "      GROUP BY DLNO, ZLBH, BWBH, SIZE " +
                                    "    ) AS CutDispatchSS ON CutDispatchSS.DLNO = CutDispatchS.DLNO AND CutDispatchSS.ZLBH = CutDispatchS.ZLBH AND CutDispatchSS.BWBH = CutDispatchS.BWBH AND CutDispatchSS.SIZE = CutDispatchS.SIZE " +
                                    "    WHERE CutDispatchS.DLNO = @DLNO " +
                                    "  ) AS CutDispatchSS " +
                                    "  WHERE CutDispatchS.ZLBH = CutDispatchSS.ZLBH AND CutDispatchS.BWBH = CutDispatchSS.BWBH AND CutDispatchS.SIZE = CutDispatchSS.SIZE; " +
                                    "END; " +

                                    "UPDATE CutDispatch_Auto SET StartTime = CASE WHEN StartTime IS NULL THEN '{2}' ELSE StartTime END, EndTime = '{3}' WHERE ListNo = '{0}'; "
                                    , request.Completed[i].WorkOrder, request.MachineID, request.StartTime, request.EndTime
                                ), ERP
                            );
                            SQL.ExecuteNonQuery();
                        }
                    }

                    EmmaFeedbackResponse eResponse = new EmmaFeedbackResponse();
                    eResponse.Success = true;
                    return JsonConvert.SerializeObject(eResponse);
                }
                else
                {
                    throw new Exception();
                }
            }
            catch (Exception ex)
            {
                EmmaFeedbackResponse eResponse = new EmmaFeedbackResponse();
                eResponse.Success = false;
                return JsonConvert.SerializeObject(eResponse);
            }
            finally
            {
                ERP.Dispose();
            }
        }

        //Stock
        [HttpPost]
        [Route("getLatestStockPrice")]
        public async Task<IActionResult> getLatestStockPrice(Stock request)
        {
            using HttpClient client = new HttpClient();
            try
            {
                if (request.Type == "LISTED")
                {
                    string url = "https://www.twse.com.tw/rwd/zh/afterTrading/STOCK_DAY_AVG?date=" + DateTime.Now.ToString("yyyyMMdd") + "&stockNo=" + request.ID + "&response=json";
                    HttpResponseMessage response = await client.GetAsync(url);
                    if (response.IsSuccessStatusCode)
                    {
                        string json = await response.Content.ReadAsStringAsync();
                        ListedResponse data = JsonConvert.DeserializeObject<ListedResponse>(json);
                        return Ok(data.data[^2][1]);
                    }
                    else
                    {
                        return StatusCode((int)response.StatusCode, response.Content.ReadAsStringAsync());
                    }
                }
                else
                {
                    string url = "https://www.tpex.org.tw/web/stock/aftertrading/daily_close_quotes/stk_quote_result.php";
                    DateTime today = DateTime.Today;
                    string rocYear = (today.Year - 1911).ToString("000");
                    string rocMonth = today.Month.ToString("00");
                    string rocDay = today.Day.ToString("00");
                    var body = new Dictionary<string, string>
                    {
                        { "l", "zh-tw" },
                        { "d", rocYear + "/" + rocMonth + "/" + rocDay },
                        { "stkno", request.ID! },
                        { "syear", rocYear },
                        { "smonth", rocMonth },
                        { "sday", rocDay }
                    };
                    var content = new FormUrlEncodedContent(body);
                    client.DefaultRequestHeaders.Referrer = new Uri("https://www.tpex.org.tw/");
                    client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                    HttpResponseMessage response = await client.PostAsync(url, content);
                    if (response.IsSuccessStatusCode)
                    {
                        string json = await response.Content.ReadAsStringAsync();
                        OTCResponse data = JsonConvert.DeserializeObject<OTCResponse>(json);
                        var targetStock = data.tables[0].data.FirstOrDefault(row => row[0] == request.ID);

                        return Ok(targetStock[2]);
                    }
                    else
                    {
                        return StatusCode((int)response.StatusCode, response.Content.ReadAsStringAsync());
                    }
                }
            }
            catch (HttpRequestException ex) {
                return StatusCode(404, ex.Message);
            }
        }

        //Telegram Bot
        [HttpPost]
        [Route("getDailyMenu")]
        public string getDailyMenu(CommonRequest request)
        {
            SqlConnection ERP = new SqlConnection(_configuration.GetConnectionString("ERP")!.ToString());
            SqlDataAdapter da = new SqlDataAdapter(
                System.String.Format(
                    "SELECT CAST(Seq AS VARCHAR) + '. ' + DishCN AS Dish FROM [LIY_TYXUAN].[dbo].[DailyMenu] " +
                    "WHERE Date = " + (request.Date == "" ? "CONVERT(VARCHAR, GETDATE(), 111)" : "'" + request.Date + "'") + " AND Category = '{0}' " +
                    "ORDER BY Seq "
                    , request.Type
                ), ERP
            );
            DataTable dt = new DataTable();
            da.Fill(dt);

            string menu = "";
            if (dt.Rows.Count > 0)
            {
                int Row = 0;
                while (Row < dt.Rows.Count)
                {
                    menu += (Row > 0 ? "\n" : "") + dt.Rows[Row]["Dish"].ToString();
                    Row++;
                }

                return menu;
            }
            else
            {
                return "No Menu";
            }
        }
    }
}
