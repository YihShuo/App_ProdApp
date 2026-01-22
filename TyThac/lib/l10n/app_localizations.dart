import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
    Locale('zh')
  ];

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @modify.
  ///
  /// In en, this message translates to:
  /// **'Modify'**
  String get modify;

  /// No description provided for @secondProcess.
  ///
  /// In en, this message translates to:
  /// **'Second Process'**
  String get secondProcess;

  /// No description provided for @cutting.
  ///
  /// In en, this message translates to:
  /// **'Cutting'**
  String get cutting;

  /// No description provided for @stitching.
  ///
  /// In en, this message translates to:
  /// **'Stitching'**
  String get stitching;

  /// No description provided for @stockFitting.
  ///
  /// In en, this message translates to:
  /// **'Stock Fitting'**
  String get stockFitting;

  /// No description provided for @productionManagement.
  ///
  /// In en, this message translates to:
  /// **'P.M.'**
  String get productionManagement;

  /// No description provided for @assembly.
  ///
  /// In en, this message translates to:
  /// **'Assembly'**
  String get assembly;

  /// No description provided for @packing.
  ///
  /// In en, this message translates to:
  /// **'Packing'**
  String get packing;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @building.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get building;

  /// No description provided for @floor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get floor;

  /// No description provided for @lean.
  ///
  /// In en, this message translates to:
  /// **'Lean'**
  String get lean;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @ry.
  ///
  /// In en, this message translates to:
  /// **'RY'**
  String get ry;

  /// No description provided for @sku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get sku;

  /// No description provided for @cycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get cycle;

  /// No description provided for @part.
  ///
  /// In en, this message translates to:
  /// **'Part'**
  String get part;

  /// No description provided for @remark.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get remark;

  /// No description provided for @material.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get material;

  /// No description provided for @alreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Duplicate data already exists'**
  String get alreadyAdded;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating'**
  String get generating;

  /// No description provided for @executing.
  ///
  /// In en, this message translates to:
  /// **'Executing'**
  String get executing;

  /// No description provided for @section.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get section;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @confirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get confirmTitle;

  /// No description provided for @confirmToProceed.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to proceed ?'**
  String get confirmToProceed;

  /// No description provided for @confirmToDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to delete it ?'**
  String get confirmToDelete;

  /// No description provided for @confirmToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to update it ?'**
  String get confirmToUpdate;

  /// No description provided for @confirmToReport.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to report it ?'**
  String get confirmToReport;

  /// No description provided for @confirmToCancel.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to cancel it ?'**
  String get confirmToCancel;

  /// No description provided for @confirmToCancelAssignment.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to cancel the assignment ?'**
  String get confirmToCancelAssignment;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get successTitle;

  /// No description provided for @successContent.
  ///
  /// In en, this message translates to:
  /// **'Execution success'**
  String get successContent;

  /// No description provided for @failedTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get failedTitle;

  /// No description provided for @failedContent.
  ///
  /// In en, this message translates to:
  /// **'Execution failed'**
  String get failedContent;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @dataNotExist.
  ///
  /// In en, this message translates to:
  /// **'No related data found'**
  String get dataNotExist;

  /// No description provided for @downloadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to download the apk'**
  String get downloadError;

  /// No description provided for @manualUpdate.
  ///
  /// In en, this message translates to:
  /// **'Please click the [OK] button to download and install through the browser'**
  String get manualUpdate;

  /// No description provided for @warehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get warehouse;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @noDispatchedOrder.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noDispatchedOrder;

  /// No description provided for @chooseNone.
  ///
  /// In en, this message translates to:
  /// **'Choose none'**
  String get chooseNone;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @requisitioned.
  ///
  /// In en, this message translates to:
  /// **'Req'**
  String get requisitioned;

  /// No description provided for @notRequisitioned.
  ///
  /// In en, this message translates to:
  /// **'Not Req'**
  String get notRequisitioned;

  /// No description provided for @notInStock.
  ///
  /// In en, this message translates to:
  /// **'Not In Stock'**
  String get notInStock;

  /// No description provided for @generateWorkOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to generate the work order?'**
  String get generateWorkOrderConfirm;

  /// No description provided for @dispatchNoSelection.
  ///
  /// In en, this message translates to:
  /// **'Please choose the scope of the assignment'**
  String get dispatchNoSelection;

  /// No description provided for @reportingNoSelection.
  ///
  /// In en, this message translates to:
  /// **'Please select the scope for reporting work'**
  String get reportingNoSelection;

  /// No description provided for @dispatch.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get dispatch;

  /// No description provided for @reporting.
  ///
  /// In en, this message translates to:
  /// **'Reporting'**
  String get reporting;

  /// No description provided for @noneGenerated.
  ///
  /// In en, this message translates to:
  /// **'No relevant data or reporting completed'**
  String get noneGenerated;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @warehouseUnread.
  ///
  /// In en, this message translates to:
  /// **'Not Confirmed'**
  String get warehouseUnread;

  /// No description provided for @warehousePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get warehousePreparing;

  /// No description provided for @warehouseConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get warehouseConfirmed;

  /// No description provided for @applicantSigned.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get applicantSigned;

  /// No description provided for @machine.
  ///
  /// In en, this message translates to:
  /// **'Machine'**
  String get machine;

  /// No description provided for @notInProduction.
  ///
  /// In en, this message translates to:
  /// **'Not In Production'**
  String get notInProduction;

  /// No description provided for @inProduction.
  ///
  /// In en, this message translates to:
  /// **'In Production'**
  String get inProduction;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @notCompleted.
  ///
  /// In en, this message translates to:
  /// **'Not Completed'**
  String get notCompleted;

  /// No description provided for @noWorkOrder.
  ///
  /// In en, this message translates to:
  /// **'No work order'**
  String get noWorkOrder;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @dieCut.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get dieCut;

  /// No description provided for @pairs.
  ///
  /// In en, this message translates to:
  /// **'Pairs'**
  String get pairs;

  /// No description provided for @noRYData.
  ///
  /// In en, this message translates to:
  /// **'No RY data'**
  String get noRYData;

  /// No description provided for @inputLengthNotEnough.
  ///
  /// In en, this message translates to:
  /// **'Please enter at least % characters in SKU, or at least %2 characters in RY'**
  String get inputLengthNotEnough;

  /// No description provided for @automaticCutting.
  ///
  /// In en, this message translates to:
  /// **'Automatic Machine'**
  String get automaticCutting;

  /// No description provided for @modifyDenied.
  ///
  /// In en, this message translates to:
  /// **'Production has started, and changes to the work order content are prohibited'**
  String get modifyDenied;

  /// No description provided for @semiAutomaticCuttingMachine.
  ///
  /// In en, this message translates to:
  /// **'Semi-Automatic'**
  String get semiAutomaticCuttingMachine;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select\nAll'**
  String get selectAll;

  /// No description provided for @unselectAll.
  ///
  /// In en, this message translates to:
  /// **'Unselect\nAll'**
  String get unselectAll;

  /// No description provided for @partSettings.
  ///
  /// In en, this message translates to:
  /// **'Part Settings'**
  String get partSettings;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @directLabor.
  ///
  /// In en, this message translates to:
  /// **'Direct Labor'**
  String get directLabor;

  /// No description provided for @indirectLabor.
  ///
  /// In en, this message translates to:
  /// **'Indirect Labor'**
  String get indirectLabor;

  /// No description provided for @indirect.
  ///
  /// In en, this message translates to:
  /// **'IDL'**
  String get indirect;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get noDataFound;

  /// No description provided for @rememberPWD.
  ///
  /// In en, this message translates to:
  /// **'Remember Password'**
  String get rememberPWD;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get inStock;

  /// No description provided for @dispatchedByPM.
  ///
  /// In en, this message translates to:
  /// **'Dispatched by PM'**
  String get dispatchedByPM;

  /// No description provided for @prepare.
  ///
  /// In en, this message translates to:
  /// **'Prepare'**
  String get prepare;

  /// No description provided for @addMark.
  ///
  /// In en, this message translates to:
  /// **'Add Mark'**
  String get addMark;

  /// No description provided for @fromDep.
  ///
  /// In en, this message translates to:
  /// **'Delivery By'**
  String get fromDep;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @originalPlan.
  ///
  /// In en, this message translates to:
  /// **'Original Plan'**
  String get originalPlan;

  /// No description provided for @extraPlan.
  ///
  /// In en, this message translates to:
  /// **'Extra Plan'**
  String get extraPlan;

  /// No description provided for @componentReady.
  ///
  /// In en, this message translates to:
  /// **'Component Ready'**
  String get componentReady;

  /// No description provided for @notReady.
  ///
  /// In en, this message translates to:
  /// **'Not Ready'**
  String get notReady;

  /// No description provided for @noPairs.
  ///
  /// In en, this message translates to:
  /// **'Please enter the valid number of pairs'**
  String get noPairs;

  /// No description provided for @noCycle.
  ///
  /// In en, this message translates to:
  /// **'Please select a cycle'**
  String get noCycle;

  /// No description provided for @tapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get tapToSelect;

  /// No description provided for @notConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Not Confirmed'**
  String get notConfirmed;

  /// No description provided for @pmConfirmed.
  ///
  /// In en, this message translates to:
  /// **'PM confirmed'**
  String get pmConfirmed;

  /// No description provided for @allReady.
  ///
  /// In en, this message translates to:
  /// **'All Ready'**
  String get allReady;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @prohibited.
  ///
  /// In en, this message translates to:
  /// **'The deadline has passed'**
  String get prohibited;

  /// No description provided for @sqConfirmed.
  ///
  /// In en, this message translates to:
  /// **'P.M. team has been confirmed, execution denied'**
  String get sqConfirmed;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @estEff.
  ///
  /// In en, this message translates to:
  /// **'Estimated Efficiency'**
  String get estEff;

  /// No description provided for @riskDistribution.
  ///
  /// In en, this message translates to:
  /// **'Risk Distribution'**
  String get riskDistribution;

  /// No description provided for @hisEff.
  ///
  /// In en, this message translates to:
  /// **'Historical efficiency'**
  String get hisEff;

  /// No description provided for @laborDiff.
  ///
  /// In en, this message translates to:
  /// **'Difference in labor'**
  String get laborDiff;

  /// No description provided for @estAssemblyEff.
  ///
  /// In en, this message translates to:
  /// **'Estimated Assembling'**
  String get estAssemblyEff;

  /// No description provided for @estStitchingEff.
  ///
  /// In en, this message translates to:
  /// **'Estimated Stitching'**
  String get estStitchingEff;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @highRiskModel.
  ///
  /// In en, this message translates to:
  /// **'High Risk Model'**
  String get highRiskModel;

  /// No description provided for @cuttingDie.
  ///
  /// In en, this message translates to:
  /// **'Cutting Die'**
  String get cuttingDie;

  /// No description provided for @noHighRiskModel.
  ///
  /// In en, this message translates to:
  /// **'No High Risk Models'**
  String get noHighRiskModel;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @newModel.
  ///
  /// In en, this message translates to:
  /// **'New Model'**
  String get newModel;

  /// No description provided for @noNewModel.
  ///
  /// In en, this message translates to:
  /// **'No New Model'**
  String get noNewModel;

  /// No description provided for @userAccount.
  ///
  /// In en, this message translates to:
  /// **'User Account'**
  String get userAccount;

  /// No description provided for @machineAccount.
  ///
  /// In en, this message translates to:
  /// **'Machine'**
  String get machineAccount;

  /// No description provided for @machineAssignment.
  ///
  /// In en, this message translates to:
  /// **'Machine Assignment'**
  String get machineAssignment;

  /// No description provided for @loginModeSwitch.
  ///
  /// In en, this message translates to:
  /// **'Login Mode Switch'**
  String get loginModeSwitch;

  /// No description provided for @shippingPlan.
  ///
  /// In en, this message translates to:
  /// **'Shipping Plan'**
  String get shippingPlan;

  /// No description provided for @vulcanize.
  ///
  /// In en, this message translates to:
  /// **'Vulcanize'**
  String get vulcanize;

  /// No description provided for @coldVulcanize.
  ///
  /// In en, this message translates to:
  /// **'Cold Vulcanize'**
  String get coldVulcanize;

  /// No description provided for @coldCement.
  ///
  /// In en, this message translates to:
  /// **'Cold Cement'**
  String get coldCement;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @noCategory.
  ///
  /// In en, this message translates to:
  /// **'No Category'**
  String get noCategory;

  /// No description provided for @shoeName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get shoeName;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get completionRate;

  /// No description provided for @shippingDate.
  ///
  /// In en, this message translates to:
  /// **'Shipping Date'**
  String get shippingDate;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @subMaterials.
  ///
  /// In en, this message translates to:
  /// **'Sub-Materials'**
  String get subMaterials;

  /// No description provided for @usage.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get usage;

  /// No description provided for @estimatedShipping.
  ///
  /// In en, this message translates to:
  /// **'Estimated Shipping'**
  String get estimatedShipping;

  /// No description provided for @actualShipping.
  ///
  /// In en, this message translates to:
  /// **'Actual Shipping'**
  String get actualShipping;

  /// No description provided for @shipmentTracking.
  ///
  /// In en, this message translates to:
  /// **'Shipment Tracking'**
  String get shipmentTracking;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @asOf.
  ///
  /// In en, this message translates to:
  /// **'As of'**
  String get asOf;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @tyDat.
  ///
  /// In en, this message translates to:
  /// **'Tỷ Đạt'**
  String get tyDat;

  /// No description provided for @productionLine.
  ///
  /// In en, this message translates to:
  /// **'Production Line'**
  String get productionLine;

  /// No description provided for @input.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get input;

  /// No description provided for @output.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get output;

  /// No description provided for @assignmentDate.
  ///
  /// In en, this message translates to:
  /// **'Assignment Date'**
  String get assignmentDate;

  /// No description provided for @shortage.
  ///
  /// In en, this message translates to:
  /// **'Shortage'**
  String get shortage;

  /// No description provided for @incomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get incomplete;

  /// No description provided for @orderProductionLine.
  ///
  /// In en, this message translates to:
  /// **'Order\'s Production Line'**
  String get orderProductionLine;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @defectCause.
  ///
  /// In en, this message translates to:
  /// **'Defect Cause'**
  String get defectCause;

  /// No description provided for @times.
  ///
  /// In en, this message translates to:
  /// **'Times'**
  String get times;

  /// No description provided for @todaySummary.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todaySummary;

  /// No description provided for @dailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailySummary;

  /// No description provided for @monthlySummary.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlySummary;

  /// No description provided for @orderMonth.
  ///
  /// In en, this message translates to:
  /// **'Order Month'**
  String get orderMonth;

  /// No description provided for @loginPageTitle.
  ///
  /// In en, this message translates to:
  /// **'USER LOGIN'**
  String get loginPageTitle;

  /// No description provided for @loginPageID.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get loginPageID;

  /// No description provided for @loginPagePassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPagePassword;

  /// No description provided for @loginPageLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginPageLogin;

  /// No description provided for @loginPageServerSetting.
  ///
  /// In en, this message translates to:
  /// **'Server setting'**
  String get loginPageServerSetting;

  /// No description provided for @loginPageSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginPageSuccess;

  /// No description provided for @loginPageConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Can\'t connect to server'**
  String get loginPageConnectFailed;

  /// No description provided for @loginPageWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'User id or password incorrect'**
  String get loginPageWrongPassword;

  /// No description provided for @loginPageLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language:'**
  String get loginPageLanguage;

  /// No description provided for @loginPageVersionCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get loginPageVersionCheckTitle;

  /// No description provided for @loginPageVersionCheckContent.
  ///
  /// In en, this message translates to:
  /// **'Detected new version [%], please proceed with the update'**
  String get loginPageVersionCheckContent;

  /// No description provided for @loginPageVersionUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get loginPageVersionUpgradeTitle;

  /// No description provided for @loginPageVersionUpgradeConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get loginPageVersionUpgradeConnecting;

  /// No description provided for @loginPageVersionUpgradeFailed.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during the download process'**
  String get loginPageVersionUpgradeFailed;

  /// No description provided for @serverSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'Server setting'**
  String get serverSettingTitle;

  /// No description provided for @serverSettingAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get serverSettingAddress;

  /// No description provided for @serverSettingPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get serverSettingPort;

  /// No description provided for @serverSettingSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get serverSettingSave;

  /// No description provided for @homePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Home Page'**
  String get homePageTitle;

  /// No description provided for @homePageInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get homePageInProgress;

  /// No description provided for @homePageCutting.
  ///
  /// In en, this message translates to:
  /// **'Cutting'**
  String get homePageCutting;

  /// No description provided for @homePageProcessing.
  ///
  /// In en, this message translates to:
  /// **'Second Process'**
  String get homePageProcessing;

  /// No description provided for @homePageLeanFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get homePageLeanFilterAll;

  /// No description provided for @homePageCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get homePageCycle;

  /// No description provided for @sideMenuMainPage.
  ///
  /// In en, this message translates to:
  /// **'Home Page'**
  String get sideMenuMainPage;

  /// No description provided for @sideMenuOrderInformation.
  ///
  /// In en, this message translates to:
  /// **'Order Information'**
  String get sideMenuOrderInformation;

  /// No description provided for @sideMenuProductionPlan.
  ///
  /// In en, this message translates to:
  /// **'Production Plan'**
  String get sideMenuProductionPlan;

  /// No description provided for @sideMenuOrderSchedule.
  ///
  /// In en, this message translates to:
  /// **'Monthly Plan'**
  String get sideMenuOrderSchedule;

  /// No description provided for @sideMenuOrderScheduleGantt.
  ///
  /// In en, this message translates to:
  /// **'Production Gantt Chart'**
  String get sideMenuOrderScheduleGantt;

  /// No description provided for @sideMenuStockFittingPlan.
  ///
  /// In en, this message translates to:
  /// **'Stock Fitting Plan'**
  String get sideMenuStockFittingPlan;

  /// No description provided for @sideMenuTestPlan.
  ///
  /// In en, this message translates to:
  /// **'Testing Plan'**
  String get sideMenuTestPlan;

  /// No description provided for @sideMenuR2Plan.
  ///
  /// In en, this message translates to:
  /// **'R2 Plan'**
  String get sideMenuR2Plan;

  /// No description provided for @sideMenu3DayPlan.
  ///
  /// In en, this message translates to:
  /// **'3-Day Plan'**
  String get sideMenu3DayPlan;

  /// No description provided for @sideMenu1DayPlan.
  ///
  /// In en, this message translates to:
  /// **'1-Day Plan'**
  String get sideMenu1DayPlan;

  /// No description provided for @sideMenuLaborDemand.
  ///
  /// In en, this message translates to:
  /// **'Labor Demand'**
  String get sideMenuLaborDemand;

  /// No description provided for @sideMenuCapacityStandard.
  ///
  /// In en, this message translates to:
  /// **'Model Standard'**
  String get sideMenuCapacityStandard;

  /// No description provided for @sideMenuEstimatedInformation.
  ///
  /// In en, this message translates to:
  /// **'EFF. & Risk ASMT.'**
  String get sideMenuEstimatedInformation;

  /// No description provided for @sideMenuMaterialRequisition.
  ///
  /// In en, this message translates to:
  /// **'Material Requirements'**
  String get sideMenuMaterialRequisition;

  /// No description provided for @sideMenuCuttingWorkOrders.
  ///
  /// In en, this message translates to:
  /// **'Cutting'**
  String get sideMenuCuttingWorkOrders;

  /// No description provided for @sideMenuDispatching.
  ///
  /// In en, this message translates to:
  /// **'Dispatching'**
  String get sideMenuDispatching;

  /// No description provided for @sideMenuProgressReporting.
  ///
  /// In en, this message translates to:
  /// **'Progress Feedback'**
  String get sideMenuProgressReporting;

  /// No description provided for @sideMenuProcessWorkOrders.
  ///
  /// In en, this message translates to:
  /// **'Second Process'**
  String get sideMenuProcessWorkOrders;

  /// No description provided for @sideMenuProcessDispatching.
  ///
  /// In en, this message translates to:
  /// **'Dispatching'**
  String get sideMenuProcessDispatching;

  /// No description provided for @sideMenuProcessReporting.
  ///
  /// In en, this message translates to:
  /// **'Progress Feedback'**
  String get sideMenuProcessReporting;

  /// No description provided for @sideMenuProductionTracking.
  ///
  /// In en, this message translates to:
  /// **'Production Tracking'**
  String get sideMenuProductionTracking;

  /// No description provided for @sideMenuSettings.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get sideMenuSettings;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Plan'**
  String get scheduleTitle;

  /// No description provided for @scheduleNoOrder.
  ///
  /// In en, this message translates to:
  /// **'No scheduled orders'**
  String get scheduleNoOrder;

  /// No description provided for @scheduleSequence.
  ///
  /// In en, this message translates to:
  /// **'Seq.'**
  String get scheduleSequence;

  /// No description provided for @scheduleDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get scheduleDetailTitle;

  /// No description provided for @scheduleOrder.
  ///
  /// In en, this message translates to:
  /// **'Order：'**
  String get scheduleOrder;

  /// No description provided for @scheduleMaterial.
  ///
  /// In en, this message translates to:
  /// **'Type：'**
  String get scheduleMaterial;

  /// No description provided for @scheduleLast.
  ///
  /// In en, this message translates to:
  /// **'Last：'**
  String get scheduleLast;

  /// No description provided for @scheduleBUY.
  ///
  /// In en, this message translates to:
  /// **'BUY：'**
  String get scheduleBUY;

  /// No description provided for @scheduleSKU.
  ///
  /// In en, this message translates to:
  /// **'SKU：'**
  String get scheduleSKU;

  /// No description provided for @scheduleShipDate.
  ///
  /// In en, this message translates to:
  /// **'GAC：'**
  String get scheduleShipDate;

  /// No description provided for @scheduleCountry.
  ///
  /// In en, this message translates to:
  /// **'Country：'**
  String get scheduleCountry;

  /// No description provided for @scheduleProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress：'**
  String get scheduleProgress;

  /// No description provided for @materialRequisitionTitle.
  ///
  /// In en, this message translates to:
  /// **'Material Requirements'**
  String get materialRequisitionTitle;

  /// No description provided for @materialRequisitionGenerateCardConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get materialRequisitionGenerateCardConfirmTitle;

  /// No description provided for @materialRequisitionConfirmAdd.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to generate the material requisition card?'**
  String get materialRequisitionConfirmAdd;

  /// No description provided for @materialRequisitionConfirmUpdate.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to update the material requisition card?'**
  String get materialRequisitionConfirmUpdate;

  /// No description provided for @materialRequisitionGenerateCardNoUsage.
  ///
  /// In en, this message translates to:
  /// **'Please input the usage of each material'**
  String get materialRequisitionGenerateCardNoUsage;

  /// No description provided for @materialRequisitionGenerateCardSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get materialRequisitionGenerateCardSuccessTitle;

  /// No description provided for @materialRequisitionGenerateCardSuccessContent.
  ///
  /// In en, this message translates to:
  /// **'Material requisition card successfully created'**
  String get materialRequisitionGenerateCardSuccessContent;

  /// No description provided for @materialRequisitionGenerateCardFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get materialRequisitionGenerateCardFailedTitle;

  /// No description provided for @materialRequisitionGenerateCardFailedContent.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while generating the material requisition card'**
  String get materialRequisitionGenerateCardFailedContent;

  /// No description provided for @materialRequisitionGenerateCardAlreadyExistContent.
  ///
  /// In en, this message translates to:
  /// **'The selected time period already has a material requisition card'**
  String get materialRequisitionGenerateCardAlreadyExistContent;

  /// No description provided for @materialRequisitionGenerateCardNotSelectContent.
  ///
  /// In en, this message translates to:
  /// **'Please select the materials to be collected'**
  String get materialRequisitionGenerateCardNotSelectContent;

  /// No description provided for @materialRequisitionWarehouseConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Warehouse has been confirmed, execution denied'**
  String get materialRequisitionWarehouseConfirmed;

  /// No description provided for @materialRequisitionLeanReceived.
  ///
  /// In en, this message translates to:
  /// **'Sign for|materials'**
  String get materialRequisitionLeanReceived;

  /// No description provided for @materialRequisitionSignConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to sign for it?'**
  String get materialRequisitionSignConfirmContent;

  /// No description provided for @materialRequisitionWarehouseNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Warehouse has not confirmed, execution denied'**
  String get materialRequisitionWarehouseNotConfirmed;

  /// No description provided for @materialRequisitionAlreadySigned.
  ///
  /// In en, this message translates to:
  /// **'There is already a signed receipt record'**
  String get materialRequisitionAlreadySigned;

  /// No description provided for @materialRequisitionExceed.
  ///
  /// In en, this message translates to:
  /// **'Remaining available quantity for issuance is'**
  String get materialRequisitionExceed;

  /// No description provided for @materialRequisitionTotalUsage.
  ///
  /// In en, this message translates to:
  /// **'Total material requisition'**
  String get materialRequisitionTotalUsage;

  /// No description provided for @materialRequisitionProhibitTips.
  ///
  /// In en, this message translates to:
  /// **'Deadline for addition or modification'**
  String get materialRequisitionProhibitTips;

  /// No description provided for @materialRequisitionProhibited.
  ///
  /// In en, this message translates to:
  /// **'The deadline has passed, adding or modifying material requisition cards is prohibited'**
  String get materialRequisitionProhibited;

  /// No description provided for @materialRequisitionNotSigned.
  ///
  /// In en, this message translates to:
  /// **'There is an unsigned material requisition card for [%], Please sign it first'**
  String get materialRequisitionNotSigned;

  /// No description provided for @cuttingWorkOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cutting Work Orders'**
  String get cuttingWorkOrderTitle;

  /// No description provided for @cuttingWorkOrderNoScheduleOrder.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get cuttingWorkOrderNoScheduleOrder;

  /// No description provided for @cuttingWorkOrderFilterIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get cuttingWorkOrderFilterIncomplete;

  /// No description provided for @cuttingWorkOrderFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get cuttingWorkOrderFilterAll;

  /// No description provided for @cuttingWorkOrderFilterDate.
  ///
  /// In en, this message translates to:
  /// **'Assembly Month：'**
  String get cuttingWorkOrderFilterDate;

  /// No description provided for @cuttingWorkOrderFilterFactory.
  ///
  /// In en, this message translates to:
  /// **'Building：'**
  String get cuttingWorkOrderFilterFactory;

  /// No description provided for @cuttingWorkOrderFilterLean.
  ///
  /// In en, this message translates to:
  /// **'Lean：'**
  String get cuttingWorkOrderFilterLean;

  /// No description provided for @cuttingWorkOrderNoCuttingData.
  ///
  /// In en, this message translates to:
  /// **'No cutting data'**
  String get cuttingWorkOrderNoCuttingData;

  /// No description provided for @cuttingWorkOrderNotDispatch.
  ///
  /// In en, this message translates to:
  /// **'Not dispatch'**
  String get cuttingWorkOrderNotDispatch;

  /// No description provided for @cuttingWorkOrderInProduction.
  ///
  /// In en, this message translates to:
  /// **'In production'**
  String get cuttingWorkOrderInProduction;

  /// No description provided for @cuttingWorkOrderCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get cuttingWorkOrderCompleted;

  /// No description provided for @cuttingWorkOrderAssemblyDate.
  ///
  /// In en, this message translates to:
  /// **'Assembly date：'**
  String get cuttingWorkOrderAssemblyDate;

  /// No description provided for @cuttingWorkOrderShipDate.
  ///
  /// In en, this message translates to:
  /// **'Ship date：'**
  String get cuttingWorkOrderShipDate;

  /// No description provided for @cuttingWorkOrderBuyNo.
  ///
  /// In en, this message translates to:
  /// **'BUY'**
  String get cuttingWorkOrderBuyNo;

  /// No description provided for @cuttingWorkOrderSKU.
  ///
  /// In en, this message translates to:
  /// **'SKU：'**
  String get cuttingWorkOrderSKU;

  /// No description provided for @cuttingWorkOrderLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Data loading error'**
  String get cuttingWorkOrderLoadingError;

  /// No description provided for @cuttingWorkOrderDispatchNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get cuttingWorkOrderDispatchNoData;

  /// No description provided for @cuttingWorkOrderDispatchSizeRunTableCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get cuttingWorkOrderDispatchSizeRunTableCycle;

  /// No description provided for @cuttingWorkOrderDispatchSizeRunTableSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get cuttingWorkOrderDispatchSizeRunTableSelectAll;

  /// No description provided for @cuttingWorkOrderDispatchSizeRunTableDispatch.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get cuttingWorkOrderDispatchSizeRunTableDispatch;

  /// No description provided for @cuttingWorkOrderDispatchSizeRunTableDialogNotSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get cuttingWorkOrderDispatchSizeRunTableDialogNotSelectTitle;

  /// No description provided for @cuttingWorkOrderDispatchSizeRunTableDialogNotSelectContent.
  ///
  /// In en, this message translates to:
  /// **'Please select an item'**
  String get cuttingWorkOrderDispatchSizeRunTableDialogNotSelectContent;

  /// No description provided for @cuttingWorkOrderDispatchSizeRunTableDialogConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get cuttingWorkOrderDispatchSizeRunTableDialogConfirmTitle;

  /// No description provided for @cuttingWorkOrderDispatchSizeRunTableDialogConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to generate the work order?'**
  String get cuttingWorkOrderDispatchSizeRunTableDialogConfirmContent;

  /// No description provided for @cuttingWorkOrderDispatchSizeRunTableDialogGeneratingTitle.
  ///
  /// In en, this message translates to:
  /// **'Generating'**
  String get cuttingWorkOrderDispatchSizeRunTableDialogGeneratingTitle;

  /// No description provided for @cuttingWorkOrderDispatchSizeRunTableDialogSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get cuttingWorkOrderDispatchSizeRunTableDialogSuccessTitle;

  /// No description provided for @cuttingWorkOrderDispatchSizeRunTableDialogSuccessContent.
  ///
  /// In en, this message translates to:
  /// **'Work order successfully created'**
  String get cuttingWorkOrderDispatchSizeRunTableDialogSuccessContent;

  /// No description provided for @cuttingWorkOrderDispatchSizeRunTableDialogFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get cuttingWorkOrderDispatchSizeRunTableDialogFailedTitle;

  /// No description provided for @cuttingWorkOrderDispatchSizeRunTableDialogFailedContent.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while generating the work order'**
  String get cuttingWorkOrderDispatchSizeRunTableDialogFailedContent;

  /// No description provided for @cuttingProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Cutting Progress Reporting'**
  String get cuttingProgressTitle;

  /// No description provided for @cuttingProgressNoDispatchedOrder.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get cuttingProgressNoDispatchedOrder;

  /// No description provided for @cuttingProgressFilterDate.
  ///
  /// In en, this message translates to:
  /// **'Date：'**
  String get cuttingProgressFilterDate;

  /// No description provided for @cuttingProgressFilterFactory.
  ///
  /// In en, this message translates to:
  /// **'Building：'**
  String get cuttingProgressFilterFactory;

  /// No description provided for @cuttingProgressFilterLean.
  ///
  /// In en, this message translates to:
  /// **'Lean：'**
  String get cuttingProgressFilterLean;

  /// No description provided for @cuttingProgressInProduction.
  ///
  /// In en, this message translates to:
  /// **'In production'**
  String get cuttingProgressInProduction;

  /// No description provided for @cuttingProgressCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get cuttingProgressCompleted;

  /// No description provided for @cuttingProgressAssemblyDate.
  ///
  /// In en, this message translates to:
  /// **'Assembly date：'**
  String get cuttingProgressAssemblyDate;

  /// No description provided for @cuttingProgressShipDate.
  ///
  /// In en, this message translates to:
  /// **'Ship date：'**
  String get cuttingProgressShipDate;

  /// No description provided for @cuttingProgressBuyNo.
  ///
  /// In en, this message translates to:
  /// **'BUY'**
  String get cuttingProgressBuyNo;

  /// No description provided for @cuttingProgressSKU.
  ///
  /// In en, this message translates to:
  /// **'SKU：'**
  String get cuttingProgressSKU;

  /// No description provided for @cuttingProgressLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Data loading error'**
  String get cuttingProgressLoadingError;

  /// No description provided for @cuttingProgressReportingNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get cuttingProgressReportingNoData;

  /// No description provided for @cuttingProgressReportingSizeRunTableCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get cuttingProgressReportingSizeRunTableCycle;

  /// No description provided for @cuttingProgressReportingSizeRunTableSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get cuttingProgressReportingSizeRunTableSelectAll;

  /// No description provided for @cuttingProgressReportingSizeRunTableDispatch.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get cuttingProgressReportingSizeRunTableDispatch;

  /// No description provided for @cuttingProgressReportingSizeRunTableDialogNotSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get cuttingProgressReportingSizeRunTableDialogNotSelectTitle;

  /// No description provided for @cuttingProgressReportingSizeRunTableDialogNotSelectContent.
  ///
  /// In en, this message translates to:
  /// **'Please select an item'**
  String get cuttingProgressReportingSizeRunTableDialogNotSelectContent;

  /// No description provided for @cuttingProgressReportingSizeRunTableDialogConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get cuttingProgressReportingSizeRunTableDialogConfirmTitle;

  /// No description provided for @cuttingProgressReportingSizeRunTableDialogConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to submit?'**
  String get cuttingProgressReportingSizeRunTableDialogConfirmContent;

  /// No description provided for @cuttingProgressReportingSizeRunTableDialogGeneratingTitle.
  ///
  /// In en, this message translates to:
  /// **'Submitting'**
  String get cuttingProgressReportingSizeRunTableDialogGeneratingTitle;

  /// No description provided for @cuttingProgressReportingSizeRunTableDialogSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get cuttingProgressReportingSizeRunTableDialogSuccessTitle;

  /// No description provided for @cuttingProgressReportingSizeRunTableDialogSuccessContent.
  ///
  /// In en, this message translates to:
  /// **'Report successfully submitted'**
  String get cuttingProgressReportingSizeRunTableDialogSuccessContent;

  /// No description provided for @cuttingProgressReportingSizeRunTableDialogFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get cuttingProgressReportingSizeRunTableDialogFailedTitle;

  /// No description provided for @cuttingProgressReportingSizeRunTableDialogFailedContent.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while submitting'**
  String get cuttingProgressReportingSizeRunTableDialogFailedContent;

  /// No description provided for @processWorkOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Second Process Work Orders'**
  String get processWorkOrderTitle;

  /// No description provided for @processWorkOrderMergeDispatching.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get processWorkOrderMergeDispatching;

  /// No description provided for @processWorkOrderNotSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get processWorkOrderNotSelectTitle;

  /// No description provided for @processWorkOrderNotSelectContent.
  ///
  /// In en, this message translates to:
  /// **'Please select an item'**
  String get processWorkOrderNotSelectContent;

  /// No description provided for @processWorkOrderNoScheduleOrder.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get processWorkOrderNoScheduleOrder;

  /// No description provided for @processWorkOrderFilterIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get processWorkOrderFilterIncomplete;

  /// No description provided for @processWorkOrderFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get processWorkOrderFilterAll;

  /// No description provided for @processWorkOrderFilterDate.
  ///
  /// In en, this message translates to:
  /// **'Assembly Month：'**
  String get processWorkOrderFilterDate;

  /// No description provided for @processWorkOrderFilterFactory.
  ///
  /// In en, this message translates to:
  /// **'Building：'**
  String get processWorkOrderFilterFactory;

  /// No description provided for @processWorkOrderFilterLean.
  ///
  /// In en, this message translates to:
  /// **'Lean：'**
  String get processWorkOrderFilterLean;

  /// No description provided for @processWorkOrderNoCuttingData.
  ///
  /// In en, this message translates to:
  /// **'No process data'**
  String get processWorkOrderNoCuttingData;

  /// No description provided for @processWorkOrderNotDispatch.
  ///
  /// In en, this message translates to:
  /// **'Not dispatch'**
  String get processWorkOrderNotDispatch;

  /// No description provided for @processWorkOrderInProduction.
  ///
  /// In en, this message translates to:
  /// **'In production'**
  String get processWorkOrderInProduction;

  /// No description provided for @processWorkOrderCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get processWorkOrderCompleted;

  /// No description provided for @processWorkOrderAssemblyDate.
  ///
  /// In en, this message translates to:
  /// **'Assembly date：'**
  String get processWorkOrderAssemblyDate;

  /// No description provided for @processWorkOrderShipDate.
  ///
  /// In en, this message translates to:
  /// **'Ship date：'**
  String get processWorkOrderShipDate;

  /// No description provided for @processWorkOrderBuyNo.
  ///
  /// In en, this message translates to:
  /// **'BUY'**
  String get processWorkOrderBuyNo;

  /// No description provided for @processWorkOrderSKU.
  ///
  /// In en, this message translates to:
  /// **'SKU：'**
  String get processWorkOrderSKU;

  /// No description provided for @processWorkOrderLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Data loading error'**
  String get processWorkOrderLoadingError;

  /// No description provided for @processWorkOrderDispatchCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get processWorkOrderDispatchCycle;

  /// No description provided for @processWorkOrderDispatchSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get processWorkOrderDispatchSelectAll;

  /// No description provided for @processWorkOrderDispatchDispatch.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get processWorkOrderDispatchDispatch;

  /// No description provided for @processWorkOrderDispatchDialogNotSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get processWorkOrderDispatchDialogNotSelectTitle;

  /// No description provided for @processWorkOrderDispatchDialogNotSelectContent.
  ///
  /// In en, this message translates to:
  /// **'Please select an item'**
  String get processWorkOrderDispatchDialogNotSelectContent;

  /// No description provided for @processWorkOrderDispatchDialogConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get processWorkOrderDispatchDialogConfirmTitle;

  /// No description provided for @processWorkOrderDispatchDialogConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to generate the work order?'**
  String get processWorkOrderDispatchDialogConfirmContent;

  /// No description provided for @processWorkOrderDispatchDialogGeneratingTitle.
  ///
  /// In en, this message translates to:
  /// **'Generating'**
  String get processWorkOrderDispatchDialogGeneratingTitle;

  /// No description provided for @processWorkOrderDispatchDialogSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get processWorkOrderDispatchDialogSuccessTitle;

  /// No description provided for @processWorkOrderDispatchDialogSuccessContent.
  ///
  /// In en, this message translates to:
  /// **'Work order successfully created'**
  String get processWorkOrderDispatchDialogSuccessContent;

  /// No description provided for @processWorkOrderDispatchDialogFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get processWorkOrderDispatchDialogFailedTitle;

  /// No description provided for @processWorkOrderDispatchDialogFailedContent.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while generating the work order'**
  String get processWorkOrderDispatchDialogFailedContent;

  /// No description provided for @processWorkOrderMergeChartConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get processWorkOrderMergeChartConfirmTitle;

  /// No description provided for @processWorkOrderMergeChartConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to generate the work order?'**
  String get processWorkOrderMergeChartConfirmContent;

  /// No description provided for @processWorkOrderMergeChartAllDispatched.
  ///
  /// In en, this message translates to:
  /// **'This section has already been assigned'**
  String get processWorkOrderMergeChartAllDispatched;

  /// No description provided for @processWorkOrderMergeDispatchSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get processWorkOrderMergeDispatchSuccessTitle;

  /// No description provided for @processWorkOrderMergeDispatchSuccessContent.
  ///
  /// In en, this message translates to:
  /// **'Work order successfully created'**
  String get processWorkOrderMergeDispatchSuccessContent;

  /// No description provided for @processWorkOrderMergeDispatchFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get processWorkOrderMergeDispatchFailedTitle;

  /// No description provided for @processWorkOrderMergeDispatchFailedContent.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while generating the work order'**
  String get processWorkOrderMergeDispatchFailedContent;

  /// No description provided for @processProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Processing Progress Reporting'**
  String get processProgressTitle;

  /// No description provided for @processProgressNoDispatchedOrder.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get processProgressNoDispatchedOrder;

  /// No description provided for @processProgressFilterDate.
  ///
  /// In en, this message translates to:
  /// **'Date：'**
  String get processProgressFilterDate;

  /// No description provided for @processProgressFilterFactory.
  ///
  /// In en, this message translates to:
  /// **'Building：'**
  String get processProgressFilterFactory;

  /// No description provided for @processProgressFilterLean.
  ///
  /// In en, this message translates to:
  /// **'Lean：'**
  String get processProgressFilterLean;

  /// No description provided for @processProgressInProduction.
  ///
  /// In en, this message translates to:
  /// **'In production'**
  String get processProgressInProduction;

  /// No description provided for @processProgressCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get processProgressCompleted;

  /// No description provided for @processProgressAssemblyDate.
  ///
  /// In en, this message translates to:
  /// **'Assembly date：'**
  String get processProgressAssemblyDate;

  /// No description provided for @processProgressShipDate.
  ///
  /// In en, this message translates to:
  /// **'Ship date：'**
  String get processProgressShipDate;

  /// No description provided for @processProgressBuyNo.
  ///
  /// In en, this message translates to:
  /// **'BUY'**
  String get processProgressBuyNo;

  /// No description provided for @processProgressSKU.
  ///
  /// In en, this message translates to:
  /// **'SKU：'**
  String get processProgressSKU;

  /// No description provided for @processProgressLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Data loading error'**
  String get processProgressLoadingError;

  /// No description provided for @processProgressReportingNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get processProgressReportingNoData;

  /// No description provided for @processProgressReportingCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get processProgressReportingCycle;

  /// No description provided for @processProgressReportingSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get processProgressReportingSelectAll;

  /// No description provided for @processProgressReportingDispatch.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get processProgressReportingDispatch;

  /// No description provided for @processProgressReportingDialogNotSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get processProgressReportingDialogNotSelectTitle;

  /// No description provided for @processProgressReportingDialogNotSelectContent.
  ///
  /// In en, this message translates to:
  /// **'Please select an item'**
  String get processProgressReportingDialogNotSelectContent;

  /// No description provided for @processProgressReportingDialogConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get processProgressReportingDialogConfirmTitle;

  /// No description provided for @processProgressReportingDialogConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to submit?'**
  String get processProgressReportingDialogConfirmContent;

  /// No description provided for @processProgressReportingDialogGeneratingTitle.
  ///
  /// In en, this message translates to:
  /// **'Submitting'**
  String get processProgressReportingDialogGeneratingTitle;

  /// No description provided for @processProgressReportingDialogSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get processProgressReportingDialogSuccessTitle;

  /// No description provided for @processProgressReportingDialogSuccessContent.
  ///
  /// In en, this message translates to:
  /// **'Report successfully submitted'**
  String get processProgressReportingDialogSuccessContent;

  /// No description provided for @processProgressReportingDialogFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get processProgressReportingDialogFailedTitle;

  /// No description provided for @processProgressReportingDialogFailedContent.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while submitting'**
  String get processProgressReportingDialogFailedContent;

  /// No description provided for @stitchingWorkOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Stitching Work Orders'**
  String get stitchingWorkOrderTitle;

  /// No description provided for @stitchingWorkOrderNoScheduleOrder.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get stitchingWorkOrderNoScheduleOrder;

  /// No description provided for @stitchingWorkOrderFilterIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get stitchingWorkOrderFilterIncomplete;

  /// No description provided for @stitchingWorkOrderFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get stitchingWorkOrderFilterAll;

  /// No description provided for @stitchingWorkOrderFilterDate.
  ///
  /// In en, this message translates to:
  /// **'Assembly Month：'**
  String get stitchingWorkOrderFilterDate;

  /// No description provided for @stitchingWorkOrderFilterFactory.
  ///
  /// In en, this message translates to:
  /// **'Building：'**
  String get stitchingWorkOrderFilterFactory;

  /// No description provided for @stitchingWorkOrderFilterLean.
  ///
  /// In en, this message translates to:
  /// **'Lean：'**
  String get stitchingWorkOrderFilterLean;

  /// No description provided for @stitchingWorkOrderNoCuttingData.
  ///
  /// In en, this message translates to:
  /// **'No cycle data'**
  String get stitchingWorkOrderNoCuttingData;

  /// No description provided for @stitchingWorkOrderNotDispatch.
  ///
  /// In en, this message translates to:
  /// **'Not dispatch'**
  String get stitchingWorkOrderNotDispatch;

  /// No description provided for @stitchingWorkOrderInProduction.
  ///
  /// In en, this message translates to:
  /// **'In production'**
  String get stitchingWorkOrderInProduction;

  /// No description provided for @stitchingWorkOrderCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get stitchingWorkOrderCompleted;

  /// No description provided for @stitchingWorkOrderAssemblyDate.
  ///
  /// In en, this message translates to:
  /// **'Assembly date：'**
  String get stitchingWorkOrderAssemblyDate;

  /// No description provided for @stitchingWorkOrderShipDate.
  ///
  /// In en, this message translates to:
  /// **'Ship date：'**
  String get stitchingWorkOrderShipDate;

  /// No description provided for @stitchingWorkOrderBuyNo.
  ///
  /// In en, this message translates to:
  /// **'BUY'**
  String get stitchingWorkOrderBuyNo;

  /// No description provided for @stitchingWorkOrderSKU.
  ///
  /// In en, this message translates to:
  /// **'SKU：'**
  String get stitchingWorkOrderSKU;

  /// No description provided for @stitchingWorkOrderLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Data loading error'**
  String get stitchingWorkOrderLoadingError;

  /// No description provided for @stitchingWorkOrderDispatchDispatching.
  ///
  /// In en, this message translates to:
  /// **'Dispatching'**
  String get stitchingWorkOrderDispatchDispatching;

  /// No description provided for @stitchingWorkOrderDispatchNotSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get stitchingWorkOrderDispatchNotSelectTitle;

  /// No description provided for @stitchingWorkOrderDispatchDispatchingNotSelectContent.
  ///
  /// In en, this message translates to:
  /// **'Please select an item'**
  String get stitchingWorkOrderDispatchDispatchingNotSelectContent;

  /// No description provided for @stitchingWorkOrderDispatchDispatchingConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to generate the work order?'**
  String get stitchingWorkOrderDispatchDispatchingConfirmContent;

  /// No description provided for @assemblyWorkOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Assembly Work Orders'**
  String get assemblyWorkOrderTitle;

  /// No description provided for @assemblyWorkOrderNoScheduleOrder.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get assemblyWorkOrderNoScheduleOrder;

  /// No description provided for @assemblyWorkOrderFilterIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get assemblyWorkOrderFilterIncomplete;

  /// No description provided for @assemblyWorkOrderFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get assemblyWorkOrderFilterAll;

  /// No description provided for @assemblyWorkOrderFilterDate.
  ///
  /// In en, this message translates to:
  /// **'Assembly Month：'**
  String get assemblyWorkOrderFilterDate;

  /// No description provided for @assemblyWorkOrderFilterFactory.
  ///
  /// In en, this message translates to:
  /// **'Building：'**
  String get assemblyWorkOrderFilterFactory;

  /// No description provided for @assemblyWorkOrderFilterLean.
  ///
  /// In en, this message translates to:
  /// **'Lean：'**
  String get assemblyWorkOrderFilterLean;

  /// No description provided for @assemblyWorkOrderNoCuttingData.
  ///
  /// In en, this message translates to:
  /// **'No cycle data'**
  String get assemblyWorkOrderNoCuttingData;

  /// No description provided for @assemblyWorkOrderNotDispatch.
  ///
  /// In en, this message translates to:
  /// **'Not dispatch'**
  String get assemblyWorkOrderNotDispatch;

  /// No description provided for @assemblyWorkOrderInProduction.
  ///
  /// In en, this message translates to:
  /// **'In production'**
  String get assemblyWorkOrderInProduction;

  /// No description provided for @assemblyWorkOrderCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get assemblyWorkOrderCompleted;

  /// No description provided for @assemblyWorkOrderAssemblyDate.
  ///
  /// In en, this message translates to:
  /// **'Assembly date：'**
  String get assemblyWorkOrderAssemblyDate;

  /// No description provided for @assemblyWorkOrderShipDate.
  ///
  /// In en, this message translates to:
  /// **'Ship date：'**
  String get assemblyWorkOrderShipDate;

  /// No description provided for @assemblyWorkOrderBuyNo.
  ///
  /// In en, this message translates to:
  /// **'BUY'**
  String get assemblyWorkOrderBuyNo;

  /// No description provided for @assemblyWorkOrderSKU.
  ///
  /// In en, this message translates to:
  /// **'SKU：'**
  String get assemblyWorkOrderSKU;

  /// No description provided for @assemblyWorkOrderLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Data loading error'**
  String get assemblyWorkOrderLoadingError;

  /// No description provided for @assemblyWorkOrderDispatchDispatching.
  ///
  /// In en, this message translates to:
  /// **'Dispatching'**
  String get assemblyWorkOrderDispatchDispatching;

  /// No description provided for @assemblyWorkOrderDispatchNotSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get assemblyWorkOrderDispatchNotSelectTitle;

  /// No description provided for @assemblyWorkOrderDispatchDispatchingNotSelectContent.
  ///
  /// In en, this message translates to:
  /// **'Please select an item'**
  String get assemblyWorkOrderDispatchDispatchingNotSelectContent;

  /// No description provided for @assemblyWorkOrderDispatchDispatchingConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to generate the work order?'**
  String get assemblyWorkOrderDispatchDispatchingConfirmContent;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get settingsTitle;

  /// No description provided for @settingsPassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsPassword;

  /// No description provided for @settingsPasswordOldPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get settingsPasswordOldPassword;

  /// No description provided for @settingsPasswordNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get settingsPasswordNewPassword;

  /// No description provided for @settingsPasswordConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get settingsPasswordConfirmPassword;

  /// No description provided for @settingsPasswordCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get settingsPasswordCheckFailed;

  /// No description provided for @settingsPasswordConfirmFailed.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get settingsPasswordConfirmFailed;

  /// No description provided for @settingsPasswordRuleCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'The password length must be at least 8 characters and include uppercase and lowercase letters, special symbols'**
  String get settingsPasswordRuleCheckFailed;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsUpgrade.
  ///
  /// In en, this message translates to:
  /// **'System Upgrade'**
  String get settingsUpgrade;

  /// No description provided for @settingsVersionCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get settingsVersionCheckTitle;

  /// No description provided for @settingsVersionCheckContent.
  ///
  /// In en, this message translates to:
  /// **'Detected new version [%], please proceed with the update'**
  String get settingsVersionCheckContent;

  /// No description provided for @settingsVersionUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get settingsVersionUpgradeTitle;

  /// No description provided for @settingsVersionUpgradeConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get settingsVersionUpgradeConnecting;

  /// No description provided for @settingsVersionUpgradeFailed.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during the download process'**
  String get settingsVersionUpgradeFailed;

  /// No description provided for @settingsVersionIsLatest.
  ///
  /// In en, this message translates to:
  /// **'The latest version is already installed'**
  String get settingsVersionIsLatest;

  /// No description provided for @settingsServerSetting.
  ///
  /// In en, this message translates to:
  /// **'Server Settings'**
  String get settingsServerSetting;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to logout?'**
  String get settingsLogoutConfirm;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'vi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'vi': return AppLocalizationsVi();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
