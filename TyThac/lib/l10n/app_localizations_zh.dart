// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get ok => '確定';

  @override
  String get cancel => '取消';

  @override
  String get close => '關閉';

  @override
  String get delete => '刪除';

  @override
  String get modify => '編輯';

  @override
  String get secondProcess => '二次加工';

  @override
  String get cutting => '裁斷';

  @override
  String get stitching => '針車';

  @override
  String get stockFitting => '底加工';

  @override
  String get productionManagement => '生管';

  @override
  String get assembly => '成型';

  @override
  String get packing => '包裝';

  @override
  String get date => '日期';

  @override
  String get month => '月份';

  @override
  String get building => '棟別';

  @override
  String get floor => '樓層';

  @override
  String get lean => '線別';

  @override
  String get time => '時間';

  @override
  String get ry => '訂單';

  @override
  String get sku => 'SKU';

  @override
  String get cycle => '輪次';

  @override
  String get part => '部位';

  @override
  String get remark => '備註';

  @override
  String get material => '材料';

  @override
  String get alreadyAdded => '已有相同資料';

  @override
  String get generating => '產生中';

  @override
  String get executing => '執行中';

  @override
  String get section => '工段';

  @override
  String get loading => '載入中';

  @override
  String get confirmTitle => '確認';

  @override
  String get confirmToProceed => '確定要執行嗎?';

  @override
  String get confirmToDelete => '確定要刪除嗎?';

  @override
  String get confirmToUpdate => '確定要更新嗎?';

  @override
  String get confirmToReport => '確定要報工嗎?';

  @override
  String get confirmToCancel => '確定要取消嗎?';

  @override
  String get confirmToCancelAssignment => '確定要取消派工嗎?';

  @override
  String get successTitle => '完成';

  @override
  String get successContent => '執行成功';

  @override
  String get failedTitle => '錯誤';

  @override
  String get failedContent => '執行時發生異常';

  @override
  String get information => '訊息';

  @override
  String get dataNotExist => '查無相關資料';

  @override
  String get downloadError => '無法進行下載';

  @override
  String get manualUpdate => '請點擊 [確定] 按鈕後透過瀏覽器下載安裝';

  @override
  String get warehouse => '倉庫';

  @override
  String get filter => '篩選';

  @override
  String get noDispatchedOrder => '尚無派工訂單';

  @override
  String get chooseNone => '不選擇';

  @override
  String get total => '總計';

  @override
  String get requisitioned => '已申領';

  @override
  String get notRequisitioned => '未申領';

  @override
  String get notInStock => '未入庫';

  @override
  String get generateWorkOrderConfirm => '確定要產生派工單?';

  @override
  String get dispatchNoSelection => '請選擇要派工的範圍';

  @override
  String get reportingNoSelection => '請選擇要報工的範圍';

  @override
  String get dispatch => '派工';

  @override
  String get reporting => '報工';

  @override
  String get noneGenerated => '無相關資料或已報工完成';

  @override
  String get status => '狀態';

  @override
  String get warehouseUnread => '未確認';

  @override
  String get warehousePreparing => '確認中';

  @override
  String get warehouseConfirmed => '已確認';

  @override
  String get applicantSigned => '已簽收';

  @override
  String get machine => '機台';

  @override
  String get notInProduction => '未生產';

  @override
  String get inProduction => '生產中';

  @override
  String get completed => '已完成';

  @override
  String get notCompleted => '未完成';

  @override
  String get noWorkOrder => '查無派工單資訊';

  @override
  String get type => '類型';

  @override
  String get dieCut => '型體';

  @override
  String get pairs => '雙數';

  @override
  String get noRYData => '無訂單資料';

  @override
  String get inputLengthNotEnough => '請在SKU輸入至少%1個字元，或在訂單輸入%2個字元';

  @override
  String get automaticCutting => '自動化';

  @override
  String get modifyDenied => '已開始生產，禁止變更派工單內容';

  @override
  String get semiAutomaticCuttingMachine => '刀斬機';

  @override
  String get selectAll => '全選';

  @override
  String get unselectAll => '取消\n全選';

  @override
  String get partSettings => '部位設定';

  @override
  String get all => '全部';

  @override
  String get directLabor => '直工';

  @override
  String get indirectLabor => '間工';

  @override
  String get indirect => '間';

  @override
  String get noDataFound => '查無資料';

  @override
  String get rememberPWD => '記住密碼';

  @override
  String get inStock => '入庫';

  @override
  String get dispatchedByPM => '生管已派工';

  @override
  String get prepare => '準備';

  @override
  String get addMark => '增加標記';

  @override
  String get fromDep => '配送單位';

  @override
  String get destination => '配送地點';

  @override
  String get originalPlan => '原計畫';

  @override
  String get extraPlan => '增加計畫';

  @override
  String get componentReady => '裁片配套';

  @override
  String get notReady => '未配套完成';

  @override
  String get noPairs => '請輸入雙數';

  @override
  String get noCycle => '請選擇輪次';

  @override
  String get tapToSelect => '點擊以選擇';

  @override
  String get notConfirmed => '未確認';

  @override
  String get pmConfirmed => '生管已確認';

  @override
  String get allReady => '已配套';

  @override
  String get others => '其它';

  @override
  String get prohibited => '已超過截止時間';

  @override
  String get sqConfirmed => '生管已確認，無法變更內容';

  @override
  String get target => '目標';

  @override
  String get estEff => '預估效率';

  @override
  String get riskDistribution => '風險分布';

  @override
  String get hisEff => '歷史效率';

  @override
  String get laborDiff => '人數差異';

  @override
  String get estAssemblyEff => '成型預估';

  @override
  String get estStitchingEff => '針車預估';

  @override
  String get model => '型體';

  @override
  String get highRiskModel => '高風險型體';

  @override
  String get cuttingDie => '斬刀';

  @override
  String get noHighRiskModel => '無高風險型體';

  @override
  String get average => '平均';

  @override
  String get newModel => '新型體';

  @override
  String get noNewModel => '無新型體';

  @override
  String get userAccount => '使用者帳號';

  @override
  String get machineAccount => '機台設備';

  @override
  String get machineAssignment => '機台派工';

  @override
  String get loginModeSwitch => '登入模式切換';

  @override
  String get shippingPlan => '裝櫃明細';

  @override
  String get vulcanize => '加硫';

  @override
  String get coldVulcanize => '雙流程';

  @override
  String get coldCement => '冷貼';

  @override
  String get category => '分類';

  @override
  String get noCategory => '未分類';

  @override
  String get shoeName => '鞋名';

  @override
  String get completionRate => '完成率';

  @override
  String get shippingDate => '交期';

  @override
  String get supplier => '供應商';

  @override
  String get subMaterials => '子材料';

  @override
  String get usage => '用量';

  @override
  String get estimatedShipping => '預計出貨';

  @override
  String get actualShipping => '實際出貨';

  @override
  String get shipmentTracking => '出貨追蹤';

  @override
  String get country => '國家';

  @override
  String get asOf => '截至';

  @override
  String get color => '配色';

  @override
  String get tyDat => '億達';

  @override
  String get productionLine => '生產線';

  @override
  String get input => '投入';

  @override
  String get output => '產出';

  @override
  String get assignmentDate => '派工日期';

  @override
  String get shortage => '欠數';

  @override
  String get incomplete => '未完成';

  @override
  String get orderProductionLine => '訂單所屬線別';

  @override
  String get unit => '單位';

  @override
  String get defectCause => '不良原因';

  @override
  String get times => '次';

  @override
  String get todaySummary => '本日統計';

  @override
  String get dailySummary => '每日統計';

  @override
  String get monthlySummary => '當月累計';

  @override
  String get orderMonth => '接單月份';

  @override
  String get loginPageTitle => '使用者登入';

  @override
  String get loginPageID => '帳號';

  @override
  String get loginPagePassword => '密碼';

  @override
  String get loginPageLogin => '登入';

  @override
  String get loginPageServerSetting => '伺服器設定';

  @override
  String get loginPageSuccess => '登入成功';

  @override
  String get loginPageConnectFailed => '無法連接伺服器';

  @override
  String get loginPageWrongPassword => '帳號或密碼錯誤';

  @override
  String get loginPageLanguage => '語言:';

  @override
  String get loginPageVersionCheckTitle => '訊息';

  @override
  String get loginPageVersionCheckContent => '檢測到新版本 [%]，請進行更新';

  @override
  String get loginPageVersionUpgradeTitle => '下載中';

  @override
  String get loginPageVersionUpgradeConnecting => '連線中...';

  @override
  String get loginPageVersionUpgradeFailed => '下載過程中發生錯誤';

  @override
  String get serverSettingTitle => '伺服器設定';

  @override
  String get serverSettingAddress => '伺服器地址';

  @override
  String get serverSettingPort => '埠號';

  @override
  String get serverSettingSave => '儲存';

  @override
  String get homePageTitle => '主頁';

  @override
  String get homePageInProgress => '派工中訂單';

  @override
  String get homePageCutting => '裁斷';

  @override
  String get homePageProcessing => '加工';

  @override
  String get homePageLeanFilterAll => '全部';

  @override
  String get homePageCycle => '輪次';

  @override
  String get sideMenuMainPage => '主頁';

  @override
  String get sideMenuOrderInformation => '訂單資訊';

  @override
  String get sideMenuProductionPlan => '生產計畫';

  @override
  String get sideMenuOrderSchedule => '訂單排程';

  @override
  String get sideMenuOrderScheduleGantt => '排程甘特圖';

  @override
  String get sideMenuStockFittingPlan => '底加工計畫';

  @override
  String get sideMenuTestPlan => '送測計畫';

  @override
  String get sideMenuR2Plan => 'R2 計畫';

  @override
  String get sideMenu3DayPlan => '三日計畫';

  @override
  String get sideMenu1DayPlan => '一日計畫';

  @override
  String get sideMenuLaborDemand => '需求人數';

  @override
  String get sideMenuCapacityStandard => '型體標準';

  @override
  String get sideMenuEstimatedInformation => '效率及風險評估';

  @override
  String get sideMenuMaterialRequisition => '領料';

  @override
  String get sideMenuCuttingWorkOrders => '裁斷';

  @override
  String get sideMenuDispatching => '派工';

  @override
  String get sideMenuProgressReporting => '報工';

  @override
  String get sideMenuProcessWorkOrders => '加工';

  @override
  String get sideMenuProcessDispatching => '派工';

  @override
  String get sideMenuProcessReporting => '報工';

  @override
  String get sideMenuProductionTracking => '生產追蹤';

  @override
  String get sideMenuSettings => '系統設定';

  @override
  String get scheduleTitle => '訂單排程';

  @override
  String get scheduleNoOrder => '無排程訂單';

  @override
  String get scheduleSequence => '序號';

  @override
  String get scheduleDetailTitle => '訂單資訊';

  @override
  String get scheduleOrder => '訂單：';

  @override
  String get scheduleMaterial => '類型：';

  @override
  String get scheduleLast => '楦頭：';

  @override
  String get scheduleBUY => 'BUY：';

  @override
  String get scheduleSKU => 'SKU：';

  @override
  String get scheduleShipDate => '交期：';

  @override
  String get scheduleCountry => '國家：';

  @override
  String get scheduleProgress => '進度：';

  @override
  String get materialRequisitionTitle => '領料';

  @override
  String get materialRequisitionGenerateCardConfirmTitle => '確認';

  @override
  String get materialRequisitionConfirmAdd => '確定要新增領料卡嗎?';

  @override
  String get materialRequisitionConfirmUpdate => '確定要更新領料卡嗎?';

  @override
  String get materialRequisitionGenerateCardNoUsage => '請輸入材料用量';

  @override
  String get materialRequisitionGenerateCardSuccessTitle => '完成';

  @override
  String get materialRequisitionGenerateCardSuccessContent => '已新增完成';

  @override
  String get materialRequisitionGenerateCardFailedTitle => '錯誤';

  @override
  String get materialRequisitionGenerateCardFailedContent => '新增時發生異常';

  @override
  String get materialRequisitionGenerateCardAlreadyExistContent => '選擇的時段已有領料卡';

  @override
  String get materialRequisitionGenerateCardNotSelectContent => '請選擇要領取的材料';

  @override
  String get materialRequisitionWarehouseConfirmed => '倉庫已確認，無法變更內容';

  @override
  String get materialRequisitionLeanReceived => '簽收';

  @override
  String get materialRequisitionSignConfirmContent => '確定要簽收嗎';

  @override
  String get materialRequisitionWarehouseNotConfirmed => '倉庫尚未確認，無法簽收';

  @override
  String get materialRequisitionAlreadySigned => '已有簽收紀錄';

  @override
  String get materialRequisitionExceed => '剩餘可領料量為';

  @override
  String get materialRequisitionTotalUsage => '總領料量';

  @override
  String get materialRequisitionProhibitTips => '新增或修改截止時間';

  @override
  String get materialRequisitionProhibited => '已超過截止時間，禁止新增或修改領料卡';

  @override
  String get materialRequisitionNotSigned => '[%] 有未簽收的領料卡，請先完成簽收';

  @override
  String get cuttingWorkOrderTitle => '裁斷派工';

  @override
  String get cuttingWorkOrderNoScheduleOrder => '尚無排程訂單';

  @override
  String get cuttingWorkOrderFilterIncomplete => '未派工完成';

  @override
  String get cuttingWorkOrderFilterAll => '全部';

  @override
  String get cuttingWorkOrderFilterDate => '成型月份：';

  @override
  String get cuttingWorkOrderFilterFactory => '棟別：';

  @override
  String get cuttingWorkOrderFilterLean => '線別：';

  @override
  String get cuttingWorkOrderNoCuttingData => '無裁斷資料';

  @override
  String get cuttingWorkOrderNotDispatch => '未派工';

  @override
  String get cuttingWorkOrderInProduction => '生產中';

  @override
  String get cuttingWorkOrderCompleted => '已完成';

  @override
  String get cuttingWorkOrderAssemblyDate => '成型上線日：';

  @override
  String get cuttingWorkOrderShipDate => '出貨日期：';

  @override
  String get cuttingWorkOrderBuyNo => 'BUY別';

  @override
  String get cuttingWorkOrderSKU => 'SKU：';

  @override
  String get cuttingWorkOrderLoadingError => '資料載入失敗';

  @override
  String get cuttingWorkOrderDispatchNoData => '查無相關資訊';

  @override
  String get cuttingWorkOrderDispatchSizeRunTableCycle => '輪次';

  @override
  String get cuttingWorkOrderDispatchSizeRunTableSelectAll => '全選';

  @override
  String get cuttingWorkOrderDispatchSizeRunTableDispatch => '派工';

  @override
  String get cuttingWorkOrderDispatchSizeRunTableDialogNotSelectTitle => '訊息';

  @override
  String get cuttingWorkOrderDispatchSizeRunTableDialogNotSelectContent => '請選擇要派工的項目';

  @override
  String get cuttingWorkOrderDispatchSizeRunTableDialogConfirmTitle => '確認';

  @override
  String get cuttingWorkOrderDispatchSizeRunTableDialogConfirmContent => '確定要產生派工單?';

  @override
  String get cuttingWorkOrderDispatchSizeRunTableDialogGeneratingTitle => '產生中';

  @override
  String get cuttingWorkOrderDispatchSizeRunTableDialogSuccessTitle => '完成';

  @override
  String get cuttingWorkOrderDispatchSizeRunTableDialogSuccessContent => '已派工完成';

  @override
  String get cuttingWorkOrderDispatchSizeRunTableDialogFailedTitle => '錯誤';

  @override
  String get cuttingWorkOrderDispatchSizeRunTableDialogFailedContent => '派工時發生異常';

  @override
  String get cuttingProgressTitle => '裁斷報工';

  @override
  String get cuttingProgressNoDispatchedOrder => '尚無派工訂單';

  @override
  String get cuttingProgressFilterDate => '日期：';

  @override
  String get cuttingProgressFilterFactory => '棟別：';

  @override
  String get cuttingProgressFilterLean => '線別：';

  @override
  String get cuttingProgressInProduction => '生產中';

  @override
  String get cuttingProgressCompleted => '已完成';

  @override
  String get cuttingProgressAssemblyDate => '成型上線日：';

  @override
  String get cuttingProgressShipDate => '出貨日期：';

  @override
  String get cuttingProgressBuyNo => 'BUY別';

  @override
  String get cuttingProgressSKU => 'SKU：';

  @override
  String get cuttingProgressLoadingError => '資料載入失敗';

  @override
  String get cuttingProgressReportingNoData => '查無相關資訊';

  @override
  String get cuttingProgressReportingSizeRunTableCycle => '輪次';

  @override
  String get cuttingProgressReportingSizeRunTableSelectAll => '全選';

  @override
  String get cuttingProgressReportingSizeRunTableDispatch => '報工';

  @override
  String get cuttingProgressReportingSizeRunTableDialogNotSelectTitle => '訊息';

  @override
  String get cuttingProgressReportingSizeRunTableDialogNotSelectContent => '請選擇要報工的項目';

  @override
  String get cuttingProgressReportingSizeRunTableDialogConfirmTitle => '確認';

  @override
  String get cuttingProgressReportingSizeRunTableDialogConfirmContent => '確定要進行報工?';

  @override
  String get cuttingProgressReportingSizeRunTableDialogGeneratingTitle => '報工中';

  @override
  String get cuttingProgressReportingSizeRunTableDialogSuccessTitle => '完成';

  @override
  String get cuttingProgressReportingSizeRunTableDialogSuccessContent => '已完成報工';

  @override
  String get cuttingProgressReportingSizeRunTableDialogFailedTitle => '錯誤';

  @override
  String get cuttingProgressReportingSizeRunTableDialogFailedContent => '報工時發生異常';

  @override
  String get processWorkOrderTitle => '加工派工';

  @override
  String get processWorkOrderMergeDispatching => '合併派工';

  @override
  String get processWorkOrderNotSelectTitle => '訊息';

  @override
  String get processWorkOrderNotSelectContent => '請選擇要派工的項目';

  @override
  String get processWorkOrderNoScheduleOrder => '尚無排程訂單';

  @override
  String get processWorkOrderFilterIncomplete => '未派工完成';

  @override
  String get processWorkOrderFilterAll => '全部';

  @override
  String get processWorkOrderFilterDate => '成型月份：';

  @override
  String get processWorkOrderFilterFactory => '棟別：';

  @override
  String get processWorkOrderFilterLean => '線別：';

  @override
  String get processWorkOrderNoCuttingData => '無加工資料';

  @override
  String get processWorkOrderNotDispatch => '未派工';

  @override
  String get processWorkOrderInProduction => '生產中';

  @override
  String get processWorkOrderCompleted => '已完成';

  @override
  String get processWorkOrderAssemblyDate => '成型上線日：';

  @override
  String get processWorkOrderShipDate => '出貨日期：';

  @override
  String get processWorkOrderBuyNo => 'BUY別';

  @override
  String get processWorkOrderSKU => 'SKU：';

  @override
  String get processWorkOrderLoadingError => '資料載入失敗';

  @override
  String get processWorkOrderDispatchCycle => '輪次';

  @override
  String get processWorkOrderDispatchSelectAll => '全選';

  @override
  String get processWorkOrderDispatchDispatch => '派工';

  @override
  String get processWorkOrderDispatchDialogNotSelectTitle => '訊息';

  @override
  String get processWorkOrderDispatchDialogNotSelectContent => '請選擇要派工的項目';

  @override
  String get processWorkOrderDispatchDialogConfirmTitle => '確認';

  @override
  String get processWorkOrderDispatchDialogConfirmContent => '確定要產生派工單?';

  @override
  String get processWorkOrderDispatchDialogGeneratingTitle => '產生中';

  @override
  String get processWorkOrderDispatchDialogSuccessTitle => '完成';

  @override
  String get processWorkOrderDispatchDialogSuccessContent => '已派工完成';

  @override
  String get processWorkOrderDispatchDialogFailedTitle => '錯誤';

  @override
  String get processWorkOrderDispatchDialogFailedContent => '派工時發生異常';

  @override
  String get processWorkOrderMergeChartConfirmTitle => '訊息';

  @override
  String get processWorkOrderMergeChartConfirmContent => '確定要產生派工單?';

  @override
  String get processWorkOrderMergeChartAllDispatched => '這項加工已經有派工紀錄';

  @override
  String get processWorkOrderMergeDispatchSuccessTitle => '完成';

  @override
  String get processWorkOrderMergeDispatchSuccessContent => '已派工完成';

  @override
  String get processWorkOrderMergeDispatchFailedTitle => '錯誤';

  @override
  String get processWorkOrderMergeDispatchFailedContent => '派工時發生異常';

  @override
  String get processProgressTitle => '加工報工';

  @override
  String get processProgressNoDispatchedOrder => '尚無派工訂單';

  @override
  String get processProgressFilterDate => '日期：';

  @override
  String get processProgressFilterFactory => '棟別：';

  @override
  String get processProgressFilterLean => '線別：';

  @override
  String get processProgressInProduction => '生產中';

  @override
  String get processProgressCompleted => '已完成';

  @override
  String get processProgressAssemblyDate => '成型上線日：';

  @override
  String get processProgressShipDate => '出貨日期：';

  @override
  String get processProgressBuyNo => 'BUY別';

  @override
  String get processProgressSKU => 'SKU：';

  @override
  String get processProgressLoadingError => '資料載入失敗';

  @override
  String get processProgressReportingNoData => '查無相關資訊';

  @override
  String get processProgressReportingCycle => '輪次';

  @override
  String get processProgressReportingSelectAll => '全選';

  @override
  String get processProgressReportingDispatch => '報工';

  @override
  String get processProgressReportingDialogNotSelectTitle => '訊息';

  @override
  String get processProgressReportingDialogNotSelectContent => '請選擇要報工的項目';

  @override
  String get processProgressReportingDialogConfirmTitle => '確認';

  @override
  String get processProgressReportingDialogConfirmContent => '確定要進行報工?';

  @override
  String get processProgressReportingDialogGeneratingTitle => '報工中';

  @override
  String get processProgressReportingDialogSuccessTitle => '完成';

  @override
  String get processProgressReportingDialogSuccessContent => '已完成報工';

  @override
  String get processProgressReportingDialogFailedTitle => '錯誤';

  @override
  String get processProgressReportingDialogFailedContent => '報工時發生異常';

  @override
  String get stitchingWorkOrderTitle => '針車派工';

  @override
  String get stitchingWorkOrderNoScheduleOrder => '尚無排程訂單';

  @override
  String get stitchingWorkOrderFilterIncomplete => '未派工完成';

  @override
  String get stitchingWorkOrderFilterAll => '全部';

  @override
  String get stitchingWorkOrderFilterDate => '成型月份：';

  @override
  String get stitchingWorkOrderFilterFactory => '棟別：';

  @override
  String get stitchingWorkOrderFilterLean => '線別：';

  @override
  String get stitchingWorkOrderNoCuttingData => '無輪次資料';

  @override
  String get stitchingWorkOrderNotDispatch => '未派工';

  @override
  String get stitchingWorkOrderInProduction => '生產中';

  @override
  String get stitchingWorkOrderCompleted => '已完成';

  @override
  String get stitchingWorkOrderAssemblyDate => '成型上線日：';

  @override
  String get stitchingWorkOrderShipDate => '出貨日期：';

  @override
  String get stitchingWorkOrderBuyNo => 'BUY別';

  @override
  String get stitchingWorkOrderSKU => 'SKU：';

  @override
  String get stitchingWorkOrderLoadingError => '資料載入失敗';

  @override
  String get stitchingWorkOrderDispatchDispatching => '派工';

  @override
  String get stitchingWorkOrderDispatchNotSelectTitle => '訊息';

  @override
  String get stitchingWorkOrderDispatchDispatchingNotSelectContent => '請選擇要派工的項目';

  @override
  String get stitchingWorkOrderDispatchDispatchingConfirmContent => '確定要產生派工單?';

  @override
  String get assemblyWorkOrderTitle => '成型派工';

  @override
  String get assemblyWorkOrderNoScheduleOrder => '尚無排程訂單';

  @override
  String get assemblyWorkOrderFilterIncomplete => '未派工完成';

  @override
  String get assemblyWorkOrderFilterAll => '全部';

  @override
  String get assemblyWorkOrderFilterDate => '成型月份：';

  @override
  String get assemblyWorkOrderFilterFactory => '棟別：';

  @override
  String get assemblyWorkOrderFilterLean => '線別：';

  @override
  String get assemblyWorkOrderNoCuttingData => '無輪次資料';

  @override
  String get assemblyWorkOrderNotDispatch => '未派工';

  @override
  String get assemblyWorkOrderInProduction => '生產中';

  @override
  String get assemblyWorkOrderCompleted => '已完成';

  @override
  String get assemblyWorkOrderAssemblyDate => '成型上線日：';

  @override
  String get assemblyWorkOrderShipDate => '出貨日期：';

  @override
  String get assemblyWorkOrderBuyNo => 'BUY別';

  @override
  String get assemblyWorkOrderSKU => 'SKU：';

  @override
  String get assemblyWorkOrderLoadingError => '資料載入失敗';

  @override
  String get assemblyWorkOrderDispatchDispatching => '派工';

  @override
  String get assemblyWorkOrderDispatchNotSelectTitle => '訊息';

  @override
  String get assemblyWorkOrderDispatchDispatchingNotSelectContent => '請選擇要派工的項目';

  @override
  String get assemblyWorkOrderDispatchDispatchingConfirmContent => '確定要產生派工單?';

  @override
  String get settingsTitle => '系統設定';

  @override
  String get settingsPassword => '密碼變更';

  @override
  String get settingsPasswordOldPassword => '目前密碼';

  @override
  String get settingsPasswordNewPassword => '新密碼';

  @override
  String get settingsPasswordConfirmPassword => '確認新密碼';

  @override
  String get settingsPasswordCheckFailed => '密碼錯誤';

  @override
  String get settingsPasswordConfirmFailed => '兩次輸入的密碼不一致';

  @override
  String get settingsPasswordRuleCheckFailed => '密碼長度不能小於8個字元、需包含英文大小寫及特殊符號';

  @override
  String get settingsLanguage => '語言';

  @override
  String get settingsUpgrade => '系統更新';

  @override
  String get settingsVersionCheckTitle => '訊息';

  @override
  String get settingsVersionCheckContent => '檢測到新版本 [%]，請進行更新';

  @override
  String get settingsVersionUpgradeTitle => '下載中';

  @override
  String get settingsVersionUpgradeConnecting => '連線中...';

  @override
  String get settingsVersionUpgradeFailed => '下載過程中發生錯誤';

  @override
  String get settingsVersionIsLatest => '已為最新版本';

  @override
  String get settingsServerSetting => '伺服器設定';

  @override
  String get settingsLogout => '登出';

  @override
  String get settingsLogoutConfirm => '確定要登出嗎?';
}
