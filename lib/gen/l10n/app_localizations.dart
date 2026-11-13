import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Dairy Partner'**
  String get appName;

  /// No description provided for @partnerShell.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get partnerShell;

  /// No description provided for @deliveryShell.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get deliveryShell;

  /// No description provided for @switchRole.
  ///
  /// In en, this message translates to:
  /// **'Switch role'**
  String get switchRole;

  /// No description provided for @switchToDelivery.
  ///
  /// In en, this message translates to:
  /// **'Switch to Delivery'**
  String get switchToDelivery;

  /// No description provided for @switchToPartner.
  ///
  /// In en, this message translates to:
  /// **'Switch to Partner'**
  String get switchToPartner;

  /// No description provided for @activeRole.
  ///
  /// In en, this message translates to:
  /// **'Active role'**
  String get activeRole;

  /// No description provided for @noOtherRoleAvailable.
  ///
  /// In en, this message translates to:
  /// **'This account has only one role.'**
  String get noOtherRoleAvailable;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @navSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get navSubscriptions;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// No description provided for @navDrivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get navDrivers;

  /// No description provided for @navRuns.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get navRuns;

  /// No description provided for @navEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get navEarnings;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @navManifest.
  ///
  /// In en, this message translates to:
  /// **'Manifest'**
  String get navManifest;

  /// No description provided for @checkingDriverApproval.
  ///
  /// In en, this message translates to:
  /// **'Checking driver approvalâ€¦'**
  String get checkingDriverApproval;

  /// No description provided for @approvalStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Approval status unavailable'**
  String get approvalStatusUnavailable;

  /// No description provided for @applicationNotApproved.
  ///
  /// In en, this message translates to:
  /// **'Application not approved'**
  String get applicationNotApproved;

  /// No description provided for @deliveryAccessPaused.
  ///
  /// In en, this message translates to:
  /// **'Delivery access paused'**
  String get deliveryAccessPaused;

  /// No description provided for @waitingOutletApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for outlet approval'**
  String get waitingOutletApproval;

  /// No description provided for @contactOutletOwner.
  ///
  /// In en, this message translates to:
  /// **'Contact the outlet owner if you need more information.'**
  String get contactOutletOwner;

  /// No description provided for @contactOutletToRestore.
  ///
  /// In en, this message translates to:
  /// **'Contact {outlet} to restore delivery access.'**
  String contactOutletToRestore(String outlet);

  /// No description provided for @profileSubmittedToOutlet.
  ///
  /// In en, this message translates to:
  /// **'Your profile was submitted to {outlet}. You can use delivery tools after the owner approves it.'**
  String profileSubmittedToOutlet(String outlet);

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @navScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get navScan;

  /// No description provided for @navRunHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navRunHistory;

  /// No description provided for @todayRuns.
  ///
  /// In en, this message translates to:
  /// **'Today\'s runs'**
  String get todayRuns;

  /// No description provided for @noRunAssigned.
  ///
  /// In en, this message translates to:
  /// **'No run assigned for today'**
  String get noRunAssigned;

  /// No description provided for @noRunAssignedHint.
  ///
  /// In en, this message translates to:
  /// **'Runs are published nightly from active subscriptions.'**
  String get noRunAssignedHint;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @stops.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get stops;

  /// No description provided for @sequence.
  ///
  /// In en, this message translates to:
  /// **'Sequence'**
  String get sequence;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @slotWindow.
  ///
  /// In en, this message translates to:
  /// **'Slot'**
  String get slotWindow;

  /// No description provided for @cans.
  ///
  /// In en, this message translates to:
  /// **'Cans'**
  String get cans;

  /// No description provided for @cansToDeliver.
  ///
  /// In en, this message translates to:
  /// **'Cans to deliver'**
  String get cansToDeliver;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @cansDelivered.
  ///
  /// In en, this message translates to:
  /// **'Cans delivered'**
  String get cansDelivered;

  /// No description provided for @shortfallReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for shortfall'**
  String get shortfallReason;

  /// No description provided for @shortfallReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a reason for the shortfall.'**
  String get shortfallReasonRequired;

  /// No description provided for @emptyCansToCollect.
  ///
  /// In en, this message translates to:
  /// **'Empty cans to collect'**
  String get emptyCansToCollect;

  /// No description provided for @amountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount due'**
  String get amountDue;

  /// No description provided for @amountCollected.
  ///
  /// In en, this message translates to:
  /// **'Amount collected'**
  String get amountCollected;

  /// No description provided for @paymentMode.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentMode;

  /// No description provided for @prepaid.
  ///
  /// In en, this message translates to:
  /// **'Prepaid'**
  String get prepaid;

  /// No description provided for @cashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cashOnDelivery;

  /// No description provided for @arrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get arrived;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @startRun.
  ///
  /// In en, this message translates to:
  /// **'Start run'**
  String get startRun;

  /// No description provided for @driverRunLoadHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm the can counts before leaving the outlet.'**
  String get driverRunLoadHint;

  /// No description provided for @driverCansLoaded.
  ///
  /// In en, this message translates to:
  /// **'Cans loaded'**
  String get driverCansLoaded;

  /// No description provided for @driverEmptyCansForReturn.
  ///
  /// In en, this message translates to:
  /// **'Empty cans taken for return'**
  String get driverEmptyCansForReturn;

  /// No description provided for @driverEnterValidCanCounts.
  ///
  /// In en, this message translates to:
  /// **'Enter valid non-negative can counts.'**
  String get driverEnterValidCanCounts;

  /// No description provided for @driverLoadAtLeastManifest.
  ///
  /// In en, this message translates to:
  /// **'Load at least the number of cans listed on this route.'**
  String get driverLoadAtLeastManifest;

  /// No description provided for @driverRunStarted.
  ///
  /// In en, this message translates to:
  /// **'Run started'**
  String get driverRunStarted;

  /// No description provided for @driverCouldNotLoadRun.
  ///
  /// In en, this message translates to:
  /// **'Could not load today\'s run.'**
  String get driverCouldNotLoadRun;

  /// No description provided for @driverArrivalRecorded.
  ///
  /// In en, this message translates to:
  /// **'Arrival recorded'**
  String get driverArrivalRecorded;

  /// No description provided for @driverMarkArrived.
  ///
  /// In en, this message translates to:
  /// **'Mark arrived'**
  String get driverMarkArrived;

  /// No description provided for @driverDeliveryRecorded.
  ///
  /// In en, this message translates to:
  /// **'Delivery recorded'**
  String get driverDeliveryRecorded;

  /// No description provided for @driverStartRunBeforeStops.
  ///
  /// In en, this message translates to:
  /// **'Start the run before updating its stops.'**
  String get driverStartRunBeforeStops;

  /// No description provided for @driverEmptyCansCollected.
  ///
  /// In en, this message translates to:
  /// **'Empty cans collected'**
  String get driverEmptyCansCollected;

  /// No description provided for @driverReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Reason (required)'**
  String get driverReasonRequired;

  /// No description provided for @driverNavigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get driverNavigate;

  /// No description provided for @driverAddressUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This stop has no address to navigate to.'**
  String get driverAddressUnavailable;

  /// No description provided for @completeRun.
  ///
  /// In en, this message translates to:
  /// **'Complete run'**
  String get completeRun;

  /// No description provided for @nextStop.
  ///
  /// In en, this message translates to:
  /// **'Next stop'**
  String get nextStop;

  /// No description provided for @openStop.
  ///
  /// In en, this message translates to:
  /// **'Open stop'**
  String get openStop;

  /// No description provided for @allStopsResolved.
  ///
  /// In en, this message translates to:
  /// **'All stops resolved'**
  String get allStopsResolved;

  /// No description provided for @callCustomer.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callCustomer;

  /// No description provided for @amountExceedsDue.
  ///
  /// In en, this message translates to:
  /// **'Collected amount cannot exceed the amount due.'**
  String get amountExceedsDue;

  /// No description provided for @captureProof.
  ///
  /// In en, this message translates to:
  /// **'Add proof photo'**
  String get captureProof;

  /// No description provided for @proofAttached.
  ///
  /// In en, this message translates to:
  /// **'Proof photo attached'**
  String get proofAttached;

  /// No description provided for @proofNotAttached.
  ///
  /// In en, this message translates to:
  /// **'Proof photo not attached. Retry.'**
  String get proofNotAttached;

  /// No description provided for @pickupScan.
  ///
  /// In en, this message translates to:
  /// **'Pickup scan'**
  String get pickupScan;

  /// No description provided for @canScanActiveRunRequired.
  ///
  /// In en, this message translates to:
  /// **'Start todayâ€™s run from Manifest before scanning cans.'**
  String get canScanActiveRunRequired;

  /// No description provided for @canScanSelectStop.
  ///
  /// In en, this message translates to:
  /// **'Select an active customer stop first.'**
  String get canScanSelectStop;

  /// No description provided for @canScanAddCode.
  ///
  /// In en, this message translates to:
  /// **'Scan or enter at least one can code.'**
  String get canScanAddCode;

  /// No description provided for @canScanBatchLimit.
  ///
  /// In en, this message translates to:
  /// **'Add up to 20 cans, then submit this scan batch.'**
  String get canScanBatchLimit;

  /// No description provided for @canScanSubmit.
  ///
  /// In en, this message translates to:
  /// **'Save can movements'**
  String get canScanSubmit;

  /// Shown when a rider tries to add a can code twice to the current scan batch.
  ///
  /// In en, this message translates to:
  /// **'{code} is already in this batch.'**
  String canAlreadyScanned(String code);

  /// No description provided for @canScannerOpen.
  ///
  /// In en, this message translates to:
  /// **'Scan can label'**
  String get canScannerOpen;

  /// No description provided for @canScannerTorch.
  ///
  /// In en, this message translates to:
  /// **'Toggle flashlight'**
  String get canScannerTorch;

  /// No description provided for @canScannerPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access in device settings to scan can labels.'**
  String get canScannerPermission;

  /// No description provided for @canScannerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The camera scanner is unavailable on this device.'**
  String get canScannerUnavailable;

  /// No description provided for @canScannerHint.
  ///
  /// In en, this message translates to:
  /// **'Align the canâ€™s QR code or barcode inside the frame.'**
  String get canScannerHint;

  /// No description provided for @depotReconciliation.
  ///
  /// In en, this message translates to:
  /// **'Depot reconciliation'**
  String get depotReconciliation;

  /// No description provided for @reconciliationBalanced.
  ///
  /// In en, this message translates to:
  /// **'Cans balanced'**
  String get reconciliationBalanced;

  /// No description provided for @reconciliationShort.
  ///
  /// In en, this message translates to:
  /// **'Cans short'**
  String get reconciliationShort;

  /// No description provided for @reconciliationOver.
  ///
  /// In en, this message translates to:
  /// **'Cans over'**
  String get reconciliationOver;

  /// No description provided for @adjustmentReason.
  ///
  /// In en, this message translates to:
  /// **'Adjustment reason'**
  String get adjustmentReason;

  /// No description provided for @adjustmentReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Explain the mismatch before closing the shift.'**
  String get adjustmentReasonHint;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count} scans waiting to sync'**
  String syncPending(Object count);

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'All scans synced'**
  String get syncComplete;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineMode;

  /// No description provided for @commissions.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get commissions;

  /// No description provided for @settlements.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get settlements;

  /// No description provided for @canDeposit.
  ///
  /// In en, this message translates to:
  /// **'Can & deposit'**
  String get canDeposit;

  /// No description provided for @reconcile.
  ///
  /// In en, this message translates to:
  /// **'Reconcile'**
  String get reconcile;

  /// No description provided for @inviteDriver.
  ///
  /// In en, this message translates to:
  /// **'Invite driver'**
  String get inviteDriver;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @loginWithMobile.
  ///
  /// In en, this message translates to:
  /// **'Login with mobile'**
  String get loginWithMobile;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get serverError;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFound;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternet;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @verticalPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your business'**
  String get verticalPickerTitle;

  /// No description provided for @verticalPickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You work with more than one business. Pick one to continue.'**
  String get verticalPickerSubtitle;

  /// No description provided for @realEstateVendorShell.
  ///
  /// In en, this message translates to:
  /// **'Property vendor'**
  String get realEstateVendorShell;

  /// No description provided for @realEstateExecutiveShell.
  ///
  /// In en, this message translates to:
  /// **'Property executive'**
  String get realEstateExecutiveShell;

  /// No description provided for @realEstateSwitchBusiness.
  ///
  /// In en, this message translates to:
  /// **'Switch business'**
  String get realEstateSwitchBusiness;

  /// No description provided for @realEstateNavDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get realEstateNavDashboard;

  /// No description provided for @realEstateDashActiveListings.
  ///
  /// In en, this message translates to:
  /// **'Active listings'**
  String get realEstateDashActiveListings;

  /// No description provided for @realEstateDashTotalLeads.
  ///
  /// In en, this message translates to:
  /// **'Total leads'**
  String get realEstateDashTotalLeads;

  /// No description provided for @realEstateDashVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get realEstateDashVisits;

  /// No description provided for @realEstateDashLiveHolds.
  ///
  /// In en, this message translates to:
  /// **'Live holds'**
  String get realEstateDashLiveHolds;

  /// No description provided for @realEstateDashSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get realEstateDashSales;

  /// No description provided for @realEstateDashListingsLeft.
  ///
  /// In en, this message translates to:
  /// **'Listings left'**
  String get realEstateDashListingsLeft;

  /// No description provided for @realEstateDashUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get realEstateDashUnlimited;

  /// No description provided for @realEstateDashVerificationPending.
  ///
  /// In en, this message translates to:
  /// **'Verification pending â€” listings cannot be published yet'**
  String get realEstateDashVerificationPending;

  /// No description provided for @realEstateNavListings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get realEstateNavListings;

  /// No description provided for @realEstateListingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No listings here yet'**
  String get realEstateListingsEmpty;

  /// No description provided for @realEstateFormNewListing.
  ///
  /// In en, this message translates to:
  /// **'New listing'**
  String get realEstateFormNewListing;

  /// No description provided for @realEstateFormEditListing.
  ///
  /// In en, this message translates to:
  /// **'Edit listing'**
  String get realEstateFormEditListing;

  /// No description provided for @realEstateFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get realEstateFormTitle;

  /// No description provided for @realEstateFormDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get realEstateFormDescription;

  /// No description provided for @realEstateFormTransaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get realEstateFormTransaction;

  /// No description provided for @realEstateFormBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get realEstateFormBuy;

  /// No description provided for @realEstateFormRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get realEstateFormRent;

  /// No description provided for @realEstateFormPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get realEstateFormPrice;

  /// No description provided for @realEstateFormPriceOnRequest.
  ///
  /// In en, this message translates to:
  /// **'Price on request'**
  String get realEstateFormPriceOnRequest;

  /// No description provided for @realEstateFormCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get realEstateFormCategory;

  /// No description provided for @realEstateFormCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get realEstateFormCity;

  /// No description provided for @realEstateFormLocality.
  ///
  /// In en, this message translates to:
  /// **'Locality'**
  String get realEstateFormLocality;

  /// No description provided for @realEstateFormAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get realEstateFormAddress;

  /// No description provided for @realEstateFormPincode.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get realEstateFormPincode;

  /// No description provided for @realEstateFormLandmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get realEstateFormLandmark;

  /// No description provided for @realEstateFormLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get realEstateFormLatitude;

  /// No description provided for @realEstateFormLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get realEstateFormLongitude;

  /// No description provided for @realEstateFormUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get realEstateFormUseMyLocation;

  /// No description provided for @realEstateFormSpecs.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get realEstateFormSpecs;

  /// No description provided for @realEstateFormAmenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get realEstateFormAmenities;

  /// No description provided for @realEstateFormMedia.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get realEstateFormMedia;

  /// No description provided for @realEstateFormAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get realEstateFormAddPhotos;

  /// No description provided for @realEstateFormCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get realEstateFormCover;

  /// No description provided for @realEstateFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save listing'**
  String get realEstateFormSave;

  /// No description provided for @realEstateFormProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get realEstateFormProject;

  /// No description provided for @realEstateFormBuilder.
  ///
  /// In en, this message translates to:
  /// **'Builder'**
  String get realEstateFormBuilder;

  /// No description provided for @realEstateDetailSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get realEstateDetailSubmit;

  /// No description provided for @realEstateDetailResubmit.
  ///
  /// In en, this message translates to:
  /// **'Resubmit for review'**
  String get realEstateDetailResubmit;

  /// No description provided for @realEstateDetailWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get realEstateDetailWithdraw;

  /// No description provided for @realEstateDetailArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive listing'**
  String get realEstateDetailArchive;

  /// No description provided for @realEstateDetailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get realEstateDetailEdit;

  /// No description provided for @realEstateDetailDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get realEstateDetailDocuments;

  /// No description provided for @realEstateDetailTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get realEstateDetailTimeline;

  /// No description provided for @realEstateDetailConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get realEstateDetailConfirm;

  /// No description provided for @realEstateDetailCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get realEstateDetailCancel;

  /// No description provided for @realEstateDetailSubmitNote.
  ///
  /// In en, this message translates to:
  /// **'Submitting consumes one listing entitlement.'**
  String get realEstateDetailSubmitNote;

  /// No description provided for @realEstateNavLeads.
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get realEstateNavLeads;

  /// No description provided for @realEstateLeadsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No leads here yet'**
  String get realEstateLeadsEmpty;

  /// No description provided for @realEstateLeadDetailCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get realEstateLeadDetailCustomer;

  /// No description provided for @realEstateLeadDetailProperty.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get realEstateLeadDetailProperty;

  /// No description provided for @realEstateLeadDetailExecutive.
  ///
  /// In en, this message translates to:
  /// **'Executive'**
  String get realEstateLeadDetailExecutive;

  /// No description provided for @realEstateLeadDetailAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get realEstateLeadDetailAssigned;

  /// No description provided for @realEstateLeadDetailUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get realEstateLeadDetailUnassigned;

  /// No description provided for @realEstateLeadDetailFollowUps.
  ///
  /// In en, this message translates to:
  /// **'Follow-ups'**
  String get realEstateLeadDetailFollowUps;

  /// No description provided for @realEstateLeadDetailHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get realEstateLeadDetailHold;

  /// No description provided for @realEstateLeadDetailSale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get realEstateLeadDetailSale;

  /// No description provided for @realEstateLeadDetailLoan.
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get realEstateLeadDetailLoan;

  /// No description provided for @realEstateLeadDetailNoLoan.
  ///
  /// In en, this message translates to:
  /// **'No loan request'**
  String get realEstateLeadDetailNoLoan;

  /// No description provided for @realEstateLeadDetailActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get realEstateLeadDetailActivity;

  /// No description provided for @realEstateLeadDetailSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get realEstateLeadDetailSource;

  /// No description provided for @realEstateNavVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get realEstateNavVisits;

  /// No description provided for @realEstateVisitsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No visits scheduled yet'**
  String get realEstateVisitsEmpty;

  /// No description provided for @realEstateCustomersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get realEstateCustomersEmpty;

  /// No description provided for @realEstateNavPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get realEstateNavPackages;

  /// No description provided for @realEstatePackagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No packages available right now'**
  String get realEstatePackagesEmpty;

  /// No description provided for @realEstatePackagesPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get realEstatePackagesPopular;

  /// No description provided for @realEstatePackagesBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get realEstatePackagesBuy;

  /// No description provided for @realEstatePackagesUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited listings'**
  String get realEstatePackagesUnlimited;

  /// No description provided for @realEstatePackagesActiveCount.
  ///
  /// In en, this message translates to:
  /// **'Active packages'**
  String get realEstatePackagesActiveCount;

  /// No description provided for @realEstateCheckoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get realEstateCheckoutTitle;

  /// No description provided for @realEstateCheckoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm purchase'**
  String get realEstateCheckoutConfirm;

  /// No description provided for @realEstateCheckoutOrderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed'**
  String get realEstateCheckoutOrderPlaced;

  /// No description provided for @realEstateCheckoutPending.
  ///
  /// In en, this message translates to:
  /// **'Complete payment to activate this package'**
  String get realEstateCheckoutPending;

  /// No description provided for @realEstateCheckoutPayNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get realEstateCheckoutPayNow;

  /// No description provided for @realEstateCheckoutPaid.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get realEstateCheckoutPaid;

  /// No description provided for @realEstateCheckoutStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get realEstateCheckoutStatus;

  /// No description provided for @realEstateCheckoutDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get realEstateCheckoutDone;

  /// No description provided for @realEstateNavPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get realEstateNavPayments;

  /// No description provided for @realEstatePaymentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get realEstatePaymentsEmpty;

  /// No description provided for @realEstatePaymentsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get realEstatePaymentsCancel;

  /// No description provided for @realEstateNavDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get realEstateNavDocuments;

  /// No description provided for @realEstateNavAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get realEstateNavAnalytics;

  /// No description provided for @realEstateNavCommissions.
  ///
  /// In en, this message translates to:
  /// **'Commissions'**
  String get realEstateNavCommissions;

  /// No description provided for @realEstateDocumentsProperty.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get realEstateDocumentsProperty;

  /// No description provided for @realEstateDocumentsPickHint.
  ///
  /// In en, this message translates to:
  /// **'Select a property to see its documents'**
  String get realEstateDocumentsPickHint;

  /// No description provided for @realEstateDocumentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No documents for this property'**
  String get realEstateDocumentsEmpty;

  /// No description provided for @realEstateCommissionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No commissions yet'**
  String get realEstateCommissionsEmpty;

  /// No description provided for @realEstateFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get realEstateFilterAll;

  /// No description provided for @realEstateNavSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get realEstateNavSupport;

  /// No description provided for @realEstateNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get realEstateNavProfile;

  /// No description provided for @realEstateProfileVerification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get realEstateProfileVerification;

  /// No description provided for @realEstateProfileSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get realEstateProfileSubmit;

  /// No description provided for @realEstateSupportT1.
  ///
  /// In en, this message translates to:
  /// **'Publishing a listing'**
  String get realEstateSupportT1;

  /// No description provided for @realEstateSupportB1.
  ///
  /// In en, this message translates to:
  /// **'Submit your KYC, buy a package, create the listing and submit it for review.'**
  String get realEstateSupportB1;

  /// No description provided for @realEstateSupportT2.
  ///
  /// In en, this message translates to:
  /// **'Payment issues'**
  String get realEstateSupportT2;

  /// No description provided for @realEstateSupportB2.
  ///
  /// In en, this message translates to:
  /// **'Pending package orders can be cancelled from Payments. Paid orders grant entitlements instantly.'**
  String get realEstateSupportB2;

  /// No description provided for @realEstateSupportT3.
  ///
  /// In en, this message translates to:
  /// **'Verification rejected?'**
  String get realEstateSupportT3;

  /// No description provided for @realEstateSupportB3.
  ///
  /// In en, this message translates to:
  /// **'Check the reason on your Profile, fix the documents and submit again.'**
  String get realEstateSupportB3;

  /// No description provided for @storesNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get storesNavHome;

  /// No description provided for @storesNavOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get storesNavOrders;

  /// No description provided for @storesNavStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get storesNavStock;

  /// No description provided for @storesNavCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Catalogue'**
  String get storesNavCatalogue;

  /// No description provided for @storesNavDrivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get storesNavDrivers;

  /// No description provided for @storesNavPostsale.
  ///
  /// In en, this message translates to:
  /// **'Post-sale'**
  String get storesNavPostsale;

  /// No description provided for @storesNavAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get storesNavAccount;

  /// No description provided for @storesNavDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get storesNavDeliveries;

  /// No description provided for @storesNavEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get storesNavEarnings;

  /// No description provided for @storesTitleStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get storesTitleStore;

  /// No description provided for @storesTitleOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get storesTitleOrders;

  /// No description provided for @storesTitleStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get storesTitleStock;

  /// No description provided for @storesTitleCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Catalogue'**
  String get storesTitleCatalogue;

  /// No description provided for @storesTitleDrivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get storesTitleDrivers;

  /// No description provided for @storesTitlePostsale.
  ///
  /// In en, this message translates to:
  /// **'Post-sale'**
  String get storesTitlePostsale;

  /// No description provided for @storesTitleSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get storesTitleSubscription;

  /// No description provided for @storesTitleSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get storesTitleSupport;

  /// No description provided for @storesTitleFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get storesTitleFeatured;

  /// No description provided for @storesTitleTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get storesTitleTeam;

  /// No description provided for @storesTitlePromotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get storesTitlePromotions;

  /// No description provided for @storesTitleWarranty.
  ///
  /// In en, this message translates to:
  /// **'Warranty'**
  String get storesTitleWarranty;

  /// No description provided for @storesTitleDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get storesTitleDeliveries;

  /// No description provided for @storesTitleEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get storesTitleEarnings;

  /// No description provided for @storesTitleOutlets.
  ///
  /// In en, this message translates to:
  /// **'Your outlets'**
  String get storesTitleOutlets;

  /// No description provided for @storesTitleOnboarding.
  ///
  /// In en, this message translates to:
  /// **'New store'**
  String get storesTitleOnboarding;

  /// No description provided for @storesTabReturns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get storesTabReturns;

  /// No description provided for @storesTabSettlements.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get storesTabSettlements;

  /// No description provided for @storesTitleNewStore.
  ///
  /// In en, this message translates to:
  /// **'New store'**
  String get storesTitleNewStore;

  /// No description provided for @storesTitlePickList.
  ///
  /// In en, this message translates to:
  /// **'Pick list'**
  String get storesTitlePickList;

  /// No description provided for @storesTitleAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get storesTitleAdvance;

  /// No description provided for @storesActionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get storesActionSave;

  /// No description provided for @storesActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get storesActionCancel;

  /// No description provided for @storesActionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get storesActionSubmit;

  /// No description provided for @storesActionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get storesActionRefresh;

  /// No description provided for @storesActionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get storesActionClose;

  /// No description provided for @storesActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get storesActionEdit;

  /// No description provided for @storesActionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get storesActionAdd;

  /// No description provided for @storesActionVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get storesActionVerify;

  /// No description provided for @storesActionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get storesActionReject;

  /// No description provided for @storesActionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get storesActionNext;

  /// No description provided for @storesActionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get storesActionBack;

  /// No description provided for @storesActionApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get storesActionApply;

  /// No description provided for @storesActionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get storesActionCreate;

  /// No description provided for @storesActionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get storesActionRetry;

  /// No description provided for @storesFieldSearchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get storesFieldSearchProducts;

  /// No description provided for @storesFieldCartAmount.
  ///
  /// In en, this message translates to:
  /// **'Cart amount'**
  String get storesFieldCartAmount;

  /// No description provided for @storesFieldCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get storesFieldCode;

  /// No description provided for @storesFieldCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Code (optional)'**
  String get storesFieldCodeOptional;

  /// No description provided for @storesFieldNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name (required)'**
  String get storesFieldNameRequired;

  /// No description provided for @storesFieldOtp.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get storesFieldOtp;

  /// No description provided for @storesFieldPackageCount.
  ///
  /// In en, this message translates to:
  /// **'Package count'**
  String get storesFieldPackageCount;

  /// No description provided for @storesFieldQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get storesFieldQuantity;

  /// No description provided for @storesFieldReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get storesFieldReason;

  /// No description provided for @storesFieldReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Reason (required)'**
  String get storesFieldReasonRequired;

  /// No description provided for @storesFieldSubstituteVariant.
  ///
  /// In en, this message translates to:
  /// **'Substitute variant id'**
  String get storesFieldSubstituteVariant;

  /// No description provided for @storesFieldWeightGrams.
  ///
  /// In en, this message translates to:
  /// **'Total weight (grams)'**
  String get storesFieldWeightGrams;

  /// No description provided for @storesFieldValueRequired.
  ///
  /// In en, this message translates to:
  /// **'Value (required)'**
  String get storesFieldValueRequired;

  /// No description provided for @storesDialogAdjustStock.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get storesDialogAdjustStock;

  /// No description provided for @storesDialogCustomerHandover.
  ///
  /// In en, this message translates to:
  /// **'Customer handover'**
  String get storesDialogCustomerHandover;

  /// No description provided for @storesDialogCompletePacking.
  ///
  /// In en, this message translates to:
  /// **'Complete packing'**
  String get storesDialogCompletePacking;

  /// No description provided for @storesDialogNewPromotion.
  ///
  /// In en, this message translates to:
  /// **'New promotion'**
  String get storesDialogNewPromotion;

  /// No description provided for @storesDialogRejectPlacement.
  ///
  /// In en, this message translates to:
  /// **'Reject placement'**
  String get storesDialogRejectPlacement;

  /// No description provided for @storesDialogReportFailure.
  ///
  /// In en, this message translates to:
  /// **'Report a failure'**
  String get storesDialogReportFailure;

  /// No description provided for @storesDialogSubstituteItem.
  ///
  /// In en, this message translates to:
  /// **'Substitute item'**
  String get storesDialogSubstituteItem;

  /// Order list row title, e.g. Order #1234
  ///
  /// In en, this message translates to:
  /// **'Order #{number}'**
  String storesOrderNumber(String number);

  /// Settlement row title
  ///
  /// In en, this message translates to:
  /// **'Settlement #{number}'**
  String storesSettlementNumber(String number);

  /// Onboarding wizard position header
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}: {label}'**
  String storesWizardStep(int current, int total, String label);

  /// Snackbar after switching outlet
  ///
  /// In en, this message translates to:
  /// **'Now working in {name}'**
  String storesNowWorkingIn(String name);

  /// Product-form info line
  ///
  /// In en, this message translates to:
  /// **'Variant axes: {axes} (max {limit} combinations)'**
  String storesVariantAxes(String axes, int limit);

  /// No description provided for @storesFallbackProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get storesFallbackProduct;

  /// No description provided for @storesFallbackDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get storesFallbackDriver;

  /// No description provided for @storesFallbackMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get storesFallbackMember;

  /// No description provided for @storesFallbackClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get storesFallbackClaim;

  /// No description provided for @storesFallbackComplaint.
  ///
  /// In en, this message translates to:
  /// **'Complaint'**
  String get storesFallbackComplaint;

  /// No description provided for @storesFallbackOutlet.
  ///
  /// In en, this message translates to:
  /// **'Outlet'**
  String get storesFallbackOutlet;

  /// No description provided for @storesFallbackReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get storesFallbackReturn;

  /// No description provided for @storesFallbackItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get storesFallbackItem;

  /// No description provided for @storesFallbackPlacement.
  ///
  /// In en, this message translates to:
  /// **'Placement'**
  String get storesFallbackPlacement;

  /// No description provided for @storesNavMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get storesNavMore;

  /// No description provided for @storesTitlePayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get storesTitlePayments;

  /// No description provided for @storesTitleManualOrder.
  ///
  /// In en, this message translates to:
  /// **'Counter sale'**
  String get storesTitleManualOrder;

  /// No description provided for @storesManualEntryDisabled.
  ///
  /// In en, this message translates to:
  /// **'New orders are paused for this subscription state.'**
  String get storesManualEntryDisabled;

  /// No description provided for @storesActionPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Place order'**
  String get storesActionPlaceOrder;

  /// No description provided for @storesBannerSubscriptionPastDue.
  ///
  /// In en, this message translates to:
  /// **'Subscription payment is past due â€” settle it to keep new orders flowing.'**
  String get storesBannerSubscriptionPastDue;

  /// No description provided for @storesBannerSubscriptionGracePeriod.
  ///
  /// In en, this message translates to:
  /// **'Subscription is in grace period â€” new orders are paused until payment resumes.'**
  String get storesBannerSubscriptionGracePeriod;

  /// No description provided for @storesBannerSubscriptionSuspended.
  ///
  /// In en, this message translates to:
  /// **'Subscription suspended â€” fulfil existing orders and settle; new orders are blocked.'**
  String get storesBannerSubscriptionSuspended;

  /// No description provided for @realEstateExecAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get realEstateExecAccept;

  /// No description provided for @realEstateExecAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get realEstateExecAccepted;

  /// No description provided for @realEstateExecActiveLeads.
  ///
  /// In en, this message translates to:
  /// **'Active leads'**
  String get realEstateExecActiveLeads;

  /// No description provided for @realEstateExecAddNotes.
  ///
  /// In en, this message translates to:
  /// **'Add notes'**
  String get realEstateExecAddNotes;

  /// No description provided for @realEstateExecAllowedRadius.
  ///
  /// In en, this message translates to:
  /// **'Allowed radius'**
  String get realEstateExecAllowedRadius;

  /// No description provided for @realEstateExecApplications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get realEstateExecApplications;

  /// No description provided for @realEstateExecAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get realEstateExecAssigned;

  /// No description provided for @realEstateExecAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get realEstateExecAvailable;

  /// No description provided for @realEstateExecBaseAmount.
  ///
  /// In en, this message translates to:
  /// **'Base amount'**
  String get realEstateExecBaseAmount;

  /// No description provided for @realEstateExecCancellationReason.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get realEstateExecCancellationReason;

  /// No description provided for @realEstateExecCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get realEstateExecCancelled;

  /// No description provided for @realEstateExecCancelVisitReason.
  ///
  /// In en, this message translates to:
  /// **'Cancel visit â€” reason required'**
  String get realEstateExecCancelVisitReason;

  /// No description provided for @realEstateExecCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get realEstateExecCheckedIn;

  /// No description provided for @realEstateExecCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get realEstateExecCheckIn;

  /// No description provided for @realEstateExecClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get realEstateExecClose;

  /// No description provided for @realEstateExecCommissions.
  ///
  /// In en, this message translates to:
  /// **'Commissions'**
  String get realEstateExecCommissions;

  /// No description provided for @realEstateExecCommissionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No commissions yet'**
  String get realEstateExecCommissionsEmpty;

  /// No description provided for @realEstateExecComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get realEstateExecComplete;

  /// No description provided for @realEstateExecCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get realEstateExecCompleted;

  /// No description provided for @realEstateExecCompleteVisit.
  ///
  /// In en, this message translates to:
  /// **'Complete visit'**
  String get realEstateExecCompleteVisit;

  /// No description provided for @realEstateExecCouldNotMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Could not mark read'**
  String get realEstateExecCouldNotMarkRead;

  /// No description provided for @realEstateExecCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get realEstateExecCustomers;

  /// No description provided for @realEstateExecDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get realEstateExecDate;

  /// No description provided for @realEstateExecDisbursedAmount.
  ///
  /// In en, this message translates to:
  /// **'Disbursed amount'**
  String get realEstateExecDisbursedAmount;

  /// No description provided for @realEstateExecDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get realEstateExecDistance;

  /// No description provided for @realEstateExecDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get realEstateExecDone;

  /// No description provided for @realEstateExecEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get realEstateExecEarnings;

  /// No description provided for @realEstateExecEmployment.
  ///
  /// In en, this message translates to:
  /// **'Employment'**
  String get realEstateExecEmployment;

  /// No description provided for @realEstateExecFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get realEstateExecFollowUp;

  /// No description provided for @realEstateExecGross.
  ///
  /// In en, this message translates to:
  /// **'Gross'**
  String get realEstateExecGross;

  /// No description provided for @realEstateExecHoldPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Hold principal applied'**
  String get realEstateExecHoldPrincipal;

  /// No description provided for @realEstateExecInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get realEstateExecInProgress;

  /// No description provided for @realEstateExecInterestRate.
  ///
  /// In en, this message translates to:
  /// **'Interest rate'**
  String get realEstateExecInterestRate;

  /// No description provided for @realEstateExecLatestEarnings.
  ///
  /// In en, this message translates to:
  /// **'Latest earnings'**
  String get realEstateExecLatestEarnings;

  /// No description provided for @realEstateExecLatestHolds.
  ///
  /// In en, this message translates to:
  /// **'Latest holds on my leads'**
  String get realEstateExecLatestHolds;

  /// No description provided for @realEstateExecLatestLoan.
  ///
  /// In en, this message translates to:
  /// **'Latest loan'**
  String get realEstateExecLatestLoan;

  /// No description provided for @realEstateExecLeadCount.
  ///
  /// In en, this message translates to:
  /// **'Leads: {count}'**
  String realEstateExecLeadCount(int count);

  /// No description provided for @realEstateExecLeadNotFound.
  ///
  /// In en, this message translates to:
  /// **'Lead not found.'**
  String get realEstateExecLeadNotFound;

  /// No description provided for @realEstateExecLeadSummary.
  ///
  /// In en, this message translates to:
  /// **'Visits: {visits} Â· Follow-ups: {followUps}'**
  String realEstateExecLeadSummary(int visits, int followUps);

  /// No description provided for @realEstateExecLoanNotFound.
  ///
  /// In en, this message translates to:
  /// **'Loan not found.'**
  String get realEstateExecLoanNotFound;

  /// No description provided for @realEstateExecLoans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get realEstateExecLoans;

  /// No description provided for @realEstateExecLoansEmpty.
  ///
  /// In en, this message translates to:
  /// **'No loans yet'**
  String get realEstateExecLoansEmpty;

  /// No description provided for @realEstateExecLocating.
  ///
  /// In en, this message translates to:
  /// **'Locatingâ€¦'**
  String get realEstateExecLocating;

  /// No description provided for @realEstateExecLocationPermissionCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required for check-in.'**
  String get realEstateExecLocationPermissionCheckIn;

  /// No description provided for @realEstateExecLocationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required.'**
  String get realEstateExecLocationPermissionRequired;

  /// No description provided for @realEstateExecLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable. Move to an open area and try again.'**
  String get realEstateExecLocationUnavailable;

  /// No description provided for @realEstateExecLocationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location updated.'**
  String get realEstateExecLocationUpdated;

  /// No description provided for @realEstateExecLocationUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update location.'**
  String get realEstateExecLocationUpdateFailed;

  /// No description provided for @realEstateExecMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark read'**
  String get realEstateExecMarkRead;

  /// No description provided for @realEstateExecMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get realEstateExecMobile;

  /// No description provided for @realEstateExecMonthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Monthly income'**
  String get realEstateExecMonthlyIncome;

  /// No description provided for @realEstateExecName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get realEstateExecName;

  /// No description provided for @realEstateExecNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get realEstateExecNo;

  /// No description provided for @realEstateExecNoApplications.
  ///
  /// In en, this message translates to:
  /// **'No bank applications yet.'**
  String get realEstateExecNoApplications;

  /// No description provided for @realEstateExecNoHolds.
  ///
  /// In en, this message translates to:
  /// **'No holds yet.'**
  String get realEstateExecNoHolds;

  /// No description provided for @realEstateExecNoLeadsAssigned.
  ///
  /// In en, this message translates to:
  /// **'No leads assigned yet.'**
  String get realEstateExecNoLeadsAssigned;

  /// No description provided for @realEstateExecNoNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications.'**
  String get realEstateExecNoNotifications;

  /// No description provided for @realEstateExecNoPendingFollowUps.
  ///
  /// In en, this message translates to:
  /// **'No pending follow-ups.'**
  String get realEstateExecNoPendingFollowUps;

  /// No description provided for @realEstateExecNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get realEstateExecNotes;

  /// No description provided for @realEstateExecNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get realEstateExecNotesOptional;

  /// No description provided for @realEstateExecNotification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get realEstateExecNotification;

  /// No description provided for @realEstateExecNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get realEstateExecNotifications;

  /// No description provided for @realEstateExecNoVisitsAssigned.
  ///
  /// In en, this message translates to:
  /// **'No visits assigned yet.'**
  String get realEstateExecNoVisitsAssigned;

  /// No description provided for @realEstateExecNoVisitsState.
  ///
  /// In en, this message translates to:
  /// **'No visits in this state.'**
  String get realEstateExecNoVisitsState;

  /// No description provided for @realEstateExecOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get realEstateExecOffer;

  /// No description provided for @realEstateExecOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get realEstateExecOffers;

  /// No description provided for @realEstateExecOutsideRadius.
  ///
  /// In en, this message translates to:
  /// **'Move closer to the property to check in.'**
  String get realEstateExecOutsideRadius;

  /// No description provided for @realEstateExecPayoutReference.
  ///
  /// In en, this message translates to:
  /// **'Payout reference'**
  String get realEstateExecPayoutReference;

  /// No description provided for @realEstateExecPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get realEstateExecPeriod;

  /// No description provided for @realEstateExecQuickLinks.
  ///
  /// In en, this message translates to:
  /// **'Quick links'**
  String get realEstateExecQuickLinks;

  /// No description provided for @realEstateExecRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get realEstateExecRate;

  /// No description provided for @realEstateExecReasonDetailHint.
  ///
  /// In en, this message translates to:
  /// **'Reason detail (required for OTHER)'**
  String get realEstateExecReasonDetailHint;

  /// No description provided for @realEstateExecReasonDetailRequired.
  ///
  /// In en, this message translates to:
  /// **'Reason detail is required for OTHER.'**
  String get realEstateExecReasonDetailRequired;

  /// No description provided for @realEstateExecReasonRequiredCancel.
  ///
  /// In en, this message translates to:
  /// **'A reason is required to cancel.'**
  String get realEstateExecReasonRequiredCancel;

  /// No description provided for @realEstateExecRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get realEstateExecRecord;

  /// No description provided for @realEstateExecRecordInterest.
  ///
  /// In en, this message translates to:
  /// **'Record interest'**
  String get realEstateExecRecordInterest;

  /// No description provided for @realEstateExecRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get realEstateExecRejectionReason;

  /// No description provided for @realEstateExecRequestedAmount.
  ///
  /// In en, this message translates to:
  /// **'Requested amount'**
  String get realEstateExecRequestedAmount;

  /// No description provided for @realEstateExecSaleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Sale not found.'**
  String get realEstateExecSaleNotFound;

  /// No description provided for @realEstateExecSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get realEstateExecSales;

  /// No description provided for @realEstateExecSalesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sales yet'**
  String get realEstateExecSalesEmpty;

  /// No description provided for @realEstateExecSaleValue.
  ///
  /// In en, this message translates to:
  /// **'Sale value'**
  String get realEstateExecSaleValue;

  /// No description provided for @realEstateExecSanctionedAmount.
  ///
  /// In en, this message translates to:
  /// **'Sanctioned amount'**
  String get realEstateExecSanctionedAmount;

  /// No description provided for @realEstateExecSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get realEstateExecSchedule;

  /// No description provided for @realEstateExecScheduleFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Schedule follow-up'**
  String get realEstateExecScheduleFollowUp;

  /// No description provided for @realEstateExecSettlements.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get realEstateExecSettlements;

  /// No description provided for @realEstateExecSettlementsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No settlements yet'**
  String get realEstateExecSettlementsEmpty;

  /// No description provided for @realEstateExecSoldOn.
  ///
  /// In en, this message translates to:
  /// **'Sold on'**
  String get realEstateExecSoldOn;

  /// No description provided for @realEstateExecSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get realEstateExecSubmit;

  /// No description provided for @realEstateExecTds.
  ///
  /// In en, this message translates to:
  /// **'TDS'**
  String get realEstateExecTds;

  /// No description provided for @realEstateExecTenure.
  ///
  /// In en, this message translates to:
  /// **'Tenure'**
  String get realEstateExecTenure;

  /// No description provided for @realEstateExecTotalVisits.
  ///
  /// In en, this message translates to:
  /// **'Total visits'**
  String get realEstateExecTotalVisits;

  /// No description provided for @realEstateExecTransaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get realEstateExecTransaction;

  /// No description provided for @realEstateExecTypeHere.
  ///
  /// In en, this message translates to:
  /// **'Type here'**
  String get realEstateExecTypeHere;

  /// No description provided for @realEstateExecUnscheduled.
  ///
  /// In en, this message translates to:
  /// **'unscheduled'**
  String get realEstateExecUnscheduled;

  /// No description provided for @realEstateExecUpdateLocation.
  ///
  /// In en, this message translates to:
  /// **'Update location'**
  String get realEstateExecUpdateLocation;

  /// No description provided for @realEstateExecVisitsByStatus.
  ///
  /// In en, this message translates to:
  /// **'Visits by status'**
  String get realEstateExecVisitsByStatus;

  /// No description provided for @realEstateExecWithinRadius.
  ///
  /// In en, this message translates to:
  /// **'You are within the check-in radius.'**
  String get realEstateExecWithinRadius;

  /// No description provided for @realEstateExecYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get realEstateExecYes;

  /// No description provided for @jhatkaDidNotGoThrough.
  ///
  /// In en, this message translates to:
  /// **'That did not go through. Retry.'**
  String get jhatkaDidNotGoThrough;

  /// No description provided for @jhatkaRetryDidNotGoThrough.
  ///
  /// In en, this message translates to:
  /// **'Retry did not go through.'**
  String get jhatkaRetryDidNotGoThrough;

  /// No description provided for @jhatkaPhotoNotAttached.
  ///
  /// In en, this message translates to:
  /// **'Photo not attached. Retry.'**
  String get jhatkaPhotoNotAttached;

  /// No description provided for @jhatkaWeighingFailed.
  ///
  /// In en, this message translates to:
  /// **'Weighing failed. Check the scale and retry.'**
  String get jhatkaWeighingFailed;

  /// No description provided for @jhatkaSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Retry.'**
  String get jhatkaSearchFailed;

  /// No description provided for @jhatkaRecallOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Recall did not open. Retry.'**
  String get jhatkaRecallOpenFailed;

  /// No description provided for @jhatkaCloseFailed.
  ///
  /// In en, this message translates to:
  /// **'Close failed â€” the fan-out may be incomplete. Retry.'**
  String get jhatkaCloseFailed;

  /// No description provided for @jhatkaPodCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'POD capture failed. Retry.'**
  String get jhatkaPodCaptureFailed;

  /// No description provided for @jhatkaPodCaptured.
  ///
  /// In en, this message translates to:
  /// **'POD captured and persisted.'**
  String get jhatkaPodCaptured;

  /// No description provided for @jhatkaCouldNotLoadDelivery.
  ///
  /// In en, this message translates to:
  /// **'Could not load delivery.'**
  String get jhatkaCouldNotLoadDelivery;

  /// No description provided for @jhatkaProofPhotoAttached.
  ///
  /// In en, this message translates to:
  /// **'Proof photo attached.'**
  String get jhatkaProofPhotoAttached;

  /// No description provided for @jhatkaAlreadyWeighed.
  ///
  /// In en, this message translates to:
  /// **'Already weighed â€” showing the saved confirmation'**
  String get jhatkaAlreadyWeighed;

  /// No description provided for @jhatkaReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is required.'**
  String get jhatkaReasonRequired;

  /// No description provided for @jhatkaReasonRequiredCustomer.
  ///
  /// In en, this message translates to:
  /// **'A reason is required â€” the customer reads it.'**
  String get jhatkaReasonRequiredCustomer;

  /// No description provided for @jhatkaClientRefRequired.
  ///
  /// In en, this message translates to:
  /// **'Client ref is required.'**
  String get jhatkaClientRefRequired;

  /// No description provided for @jhatkaClientRefRequiredFirst.
  ///
  /// In en, this message translates to:
  /// **'Client ref is required first.'**
  String get jhatkaClientRefRequiredFirst;

  /// No description provided for @jhatkaInvalidPaise.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid paise amount.'**
  String get jhatkaInvalidPaise;

  /// No description provided for @jhatkaBothDatesRequired.
  ///
  /// In en, this message translates to:
  /// **'Both period dates are required.'**
  String get jhatkaBothDatesRequired;

  /// No description provided for @jhatkaCodeNameValueRequired.
  ///
  /// In en, this message translates to:
  /// **'Code, name and a numeric value are required.'**
  String get jhatkaCodeNameValueRequired;

  /// No description provided for @jhatkaTypeAndBpsRequired.
  ///
  /// In en, this message translates to:
  /// **'Type and a bps rate are required.'**
  String get jhatkaTypeAndBpsRequired;

  /// No description provided for @jhatkaTypeTwoChars.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 characters.'**
  String get jhatkaTypeTwoChars;

  /// No description provided for @jhatkaPickVariantAndPrice.
  ///
  /// In en, this message translates to:
  /// **'Pick a variant and a valid price.'**
  String get jhatkaPickVariantAndPrice;

  /// No description provided for @jhatkaPickAtLeastOneVariant.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one variant.'**
  String get jhatkaPickAtLeastOneVariant;

  /// No description provided for @jhatkaPickCustomerFirst.
  ///
  /// In en, this message translates to:
  /// **'Pick the customer from search first.'**
  String get jhatkaPickCustomerFirst;

  /// No description provided for @jhatkaLineMissingVariant.
  ///
  /// In en, this message translates to:
  /// **'A line is missing its variant â€” cannot save.'**
  String get jhatkaLineMissingVariant;

  /// No description provided for @jhatkaNothingToSave.
  ///
  /// In en, this message translates to:
  /// **'Nothing to save.'**
  String get jhatkaNothingToSave;

  /// No description provided for @jhatkaNavOrders.
  ///
  /// In en, this message translates to:
  /// **'Jhatka orders'**
  String get jhatkaNavOrders;

  /// No description provided for @jhatkaNavCataloguePrices.
  ///
  /// In en, this message translates to:
  /// **'Catalogue & prices'**
  String get jhatkaNavCataloguePrices;

  /// No description provided for @jhatkaNavProcurement.
  ///
  /// In en, this message translates to:
  /// **'Procurement'**
  String get jhatkaNavProcurement;

  /// No description provided for @jhatkaNavCompliance.
  ///
  /// In en, this message translates to:
  /// **'Compliance'**
  String get jhatkaNavCompliance;

  /// No description provided for @jhatkaNavFleet.
  ///
  /// In en, this message translates to:
  /// **'Fleet'**
  String get jhatkaNavFleet;

  /// No description provided for @jhatkaNavLabels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get jhatkaNavLabels;

  /// No description provided for @jhatkaNavMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get jhatkaNavMoney;

  /// No description provided for @jhatkaNavRider.
  ///
  /// In en, this message translates to:
  /// **'Rider'**
  String get jhatkaNavRider;

  /// No description provided for @jhatkaNavWastage.
  ///
  /// In en, this message translates to:
  /// **'Wastage'**
  String get jhatkaNavWastage;

  /// No description provided for @jhatkaNavMyDeliveries.
  ///
  /// In en, this message translates to:
  /// **'My deliveries'**
  String get jhatkaNavMyDeliveries;

  /// No description provided for @jhatkaCatalogueUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Catalogue unavailable'**
  String get jhatkaCatalogueUnavailable;

  /// No description provided for @jhatkaComplianceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Compliance unavailable'**
  String get jhatkaComplianceUnavailable;

  /// No description provided for @jhatkaDeliveriesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Deliveries unavailable'**
  String get jhatkaDeliveriesUnavailable;

  /// No description provided for @jhatkaDeliveryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Delivery unavailable'**
  String get jhatkaDeliveryUnavailable;

  /// No description provided for @jhatkaEarningsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Earnings unavailable'**
  String get jhatkaEarningsUnavailable;

  /// No description provided for @jhatkaFleetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Fleet unavailable'**
  String get jhatkaFleetUnavailable;

  /// No description provided for @jhatkaInventoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Inventory unavailable'**
  String get jhatkaInventoryUnavailable;

  /// No description provided for @jhatkaLabelsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Labels unavailable'**
  String get jhatkaLabelsUnavailable;

  /// No description provided for @jhatkaMoneyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Money unavailable'**
  String get jhatkaMoneyUnavailable;

  /// No description provided for @jhatkaOrderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Order unavailable'**
  String get jhatkaOrderUnavailable;

  /// No description provided for @jhatkaOrdersUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Orders unavailable'**
  String get jhatkaOrdersUnavailable;

  /// No description provided for @jhatkaProcurementUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Procurement unavailable'**
  String get jhatkaProcurementUnavailable;

  /// No description provided for @jhatkaSubscriptionsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions unavailable'**
  String get jhatkaSubscriptionsUnavailable;

  /// No description provided for @jhatkaNoCounters.
  ///
  /// In en, this message translates to:
  /// **'No counters on this login.'**
  String get jhatkaNoCounters;

  /// No description provided for @jhatkaNoLabels.
  ///
  /// In en, this message translates to:
  /// **'No labels'**
  String get jhatkaNoLabels;

  /// No description provided for @jhatkaNoOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders'**
  String get jhatkaNoOrders;

  /// No description provided for @jhatkaNoSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions'**
  String get jhatkaNoSubscriptions;

  /// No description provided for @jhatkaNoSubscribableVariants.
  ///
  /// In en, this message translates to:
  /// **'No subscribable variants in the catalogue.'**
  String get jhatkaNoSubscribableVariants;

  /// No description provided for @jhatkaNoVariantsToPrice.
  ///
  /// In en, this message translates to:
  /// **'No variants to price yet.'**
  String get jhatkaNoVariantsToPrice;

  /// No description provided for @jhatkaNothingAssigned.
  ///
  /// In en, this message translates to:
  /// **'Nothing assigned'**
  String get jhatkaNothingAssigned;

  /// No description provided for @jhatkaNothingLeftToDo.
  ///
  /// In en, this message translates to:
  /// **'Nothing left to do here.'**
  String get jhatkaNothingLeftToDo;

  /// No description provided for @jhatkaActionAddLine.
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get jhatkaActionAddLine;

  /// No description provided for @jhatkaActionAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get jhatkaActionAdjust;

  /// No description provided for @jhatkaActionApproveActivate.
  ///
  /// In en, this message translates to:
  /// **'Approve & activate'**
  String get jhatkaActionApproveActivate;

  /// No description provided for @jhatkaActionCancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get jhatkaActionCancelSubscription;

  /// No description provided for @jhatkaActionCapturePod.
  ///
  /// In en, this message translates to:
  /// **'Capture POD (persist)'**
  String get jhatkaActionCapturePod;

  /// No description provided for @jhatkaActionCreatePromotion.
  ///
  /// In en, this message translates to:
  /// **'Create promotion'**
  String get jhatkaActionCreatePromotion;

  /// No description provided for @jhatkaActionCreateRule.
  ///
  /// In en, this message translates to:
  /// **'Create rule'**
  String get jhatkaActionCreateRule;

  /// No description provided for @jhatkaActionDeliver.
  ///
  /// In en, this message translates to:
  /// **'Deliver'**
  String get jhatkaActionDeliver;

  /// No description provided for @jhatkaActionEditOutletProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit outlet profile'**
  String get jhatkaActionEditOutletProfile;

  /// No description provided for @jhatkaActionEditQuantities.
  ///
  /// In en, this message translates to:
  /// **'Edit quantities'**
  String get jhatkaActionEditQuantities;

  /// No description provided for @jhatkaActionFailDelivery.
  ///
  /// In en, this message translates to:
  /// **'Fail delivery'**
  String get jhatkaActionFailDelivery;

  /// No description provided for @jhatkaActionGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get jhatkaActionGenerate;

  /// No description provided for @jhatkaActionGenerateLabels.
  ///
  /// In en, this message translates to:
  /// **'Generate pack labels'**
  String get jhatkaActionGenerateLabels;

  /// No description provided for @jhatkaActionKeepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get jhatkaActionKeepIt;

  /// No description provided for @jhatkaActionManagerOverride.
  ///
  /// In en, this message translates to:
  /// **'Manager override'**
  String get jhatkaActionManagerOverride;

  /// No description provided for @jhatkaActionMarkReady.
  ///
  /// In en, this message translates to:
  /// **'Mark ready'**
  String get jhatkaActionMarkReady;

  /// No description provided for @jhatkaActionNewOverride.
  ///
  /// In en, this message translates to:
  /// **'New price override'**
  String get jhatkaActionNewOverride;

  /// No description provided for @jhatkaActionNewReceipt.
  ///
  /// In en, this message translates to:
  /// **'New receipt'**
  String get jhatkaActionNewReceipt;

  /// No description provided for @jhatkaActionNewSubscription.
  ///
  /// In en, this message translates to:
  /// **'New subscription'**
  String get jhatkaActionNewSubscription;

  /// No description provided for @jhatkaActionOpenRecall.
  ///
  /// In en, this message translates to:
  /// **'Open recall'**
  String get jhatkaActionOpenRecall;

  /// No description provided for @jhatkaActionPackDispatch.
  ///
  /// In en, this message translates to:
  /// **'Pack & dispatch'**
  String get jhatkaActionPackDispatch;

  /// No description provided for @jhatkaActionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get jhatkaActionPause;

  /// No description provided for @jhatkaActionPauseSubscription.
  ///
  /// In en, this message translates to:
  /// **'Pause subscription'**
  String get jhatkaActionPauseSubscription;

  /// No description provided for @jhatkaActionPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get jhatkaActionPay;

  /// No description provided for @jhatkaActionPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get jhatkaActionPlace;

  /// No description provided for @jhatkaActionPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get jhatkaActionPost;

  /// No description provided for @jhatkaActionPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get jhatkaActionPrint;

  /// No description provided for @jhatkaActionQuarantine.
  ///
  /// In en, this message translates to:
  /// **'Quarantine'**
  String get jhatkaActionQuarantine;

  /// No description provided for @jhatkaActionQuarantineBatch.
  ///
  /// In en, this message translates to:
  /// **'Quarantine batch â€” reason required'**
  String get jhatkaActionQuarantineBatch;

  /// No description provided for @jhatkaActionRecallNotify.
  ///
  /// In en, this message translates to:
  /// **'Recall â€” notify customers'**
  String get jhatkaActionRecallNotify;

  /// No description provided for @jhatkaActionRecordAdjustWastage.
  ///
  /// In en, this message translates to:
  /// **'Record adjust / wastage'**
  String get jhatkaActionRecordAdjustWastage;

  /// No description provided for @jhatkaActionRecordStockMove.
  ///
  /// In en, this message translates to:
  /// **'Record stock move'**
  String get jhatkaActionRecordStockMove;

  /// No description provided for @jhatkaActionRejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Reject order'**
  String get jhatkaActionRejectOrder;

  /// No description provided for @jhatkaActionRejectWithReason.
  ///
  /// In en, this message translates to:
  /// **'Reject with reason'**
  String get jhatkaActionRejectWithReason;

  /// No description provided for @jhatkaActionRelease.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get jhatkaActionRelease;

  /// No description provided for @jhatkaActionReleaseBatch.
  ///
  /// In en, this message translates to:
  /// **'Release batch â€” reason required'**
  String get jhatkaActionReleaseBatch;

  /// No description provided for @jhatkaActionRemoveLine.
  ///
  /// In en, this message translates to:
  /// **'Remove line'**
  String get jhatkaActionRemoveLine;

  /// No description provided for @jhatkaActionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get jhatkaActionReset;

  /// No description provided for @jhatkaActionRespond.
  ///
  /// In en, this message translates to:
  /// **'Respond'**
  String get jhatkaActionRespond;

  /// No description provided for @jhatkaActionRespondComplaint.
  ///
  /// In en, this message translates to:
  /// **'Respond to complaint'**
  String get jhatkaActionRespondComplaint;

  /// No description provided for @jhatkaActionRespondReview.
  ///
  /// In en, this message translates to:
  /// **'Respond to review (once only)'**
  String get jhatkaActionRespondReview;

  /// No description provided for @jhatkaActionRetryCharge.
  ///
  /// In en, this message translates to:
  /// **'Retry charge'**
  String get jhatkaActionRetryCharge;

  /// No description provided for @jhatkaActionRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get jhatkaActionRevoke;

  /// No description provided for @jhatkaActionSaveQuantities.
  ///
  /// In en, this message translates to:
  /// **'Save quantities'**
  String get jhatkaActionSaveQuantities;

  /// No description provided for @jhatkaActionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get jhatkaActionSearch;

  /// No description provided for @jhatkaActionSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get jhatkaActionSend;

  /// No description provided for @jhatkaActionSet.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get jhatkaActionSet;

  /// No description provided for @jhatkaActionSkipNext.
  ///
  /// In en, this message translates to:
  /// **'Skip next'**
  String get jhatkaActionSkipNext;

  /// No description provided for @jhatkaActionSubmitForApproval.
  ///
  /// In en, this message translates to:
  /// **'Submit for approval'**
  String get jhatkaActionSubmitForApproval;

  /// No description provided for @jhatkaActionSwitchCounter.
  ///
  /// In en, this message translates to:
  /// **'Switch counter'**
  String get jhatkaActionSwitchCounter;

  /// No description provided for @jhatkaActionVoid.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get jhatkaActionVoid;

  /// No description provided for @jhatkaActionVoidLabel.
  ///
  /// In en, this message translates to:
  /// **'Void label'**
  String get jhatkaActionVoidLabel;

  /// No description provided for @jhatkaActionWeighOrder.
  ///
  /// In en, this message translates to:
  /// **'Weigh order'**
  String get jhatkaActionWeighOrder;

  /// No description provided for @jhatkaFieldActualWeightGrams.
  ///
  /// In en, this message translates to:
  /// **'Actual weight (grams)'**
  String get jhatkaFieldActualWeightGrams;

  /// No description provided for @jhatkaFieldAmountPaise.
  ///
  /// In en, this message translates to:
  /// **'Amount (paise)'**
  String get jhatkaFieldAmountPaise;

  /// No description provided for @jhatkaFieldCodCollectedPaise.
  ///
  /// In en, this message translates to:
  /// **'COD collected (paise)'**
  String get jhatkaFieldCodCollectedPaise;

  /// No description provided for @jhatkaFieldCause.
  ///
  /// In en, this message translates to:
  /// **'Cause'**
  String get jhatkaFieldCause;

  /// No description provided for @jhatkaFieldClientRef.
  ///
  /// In en, this message translates to:
  /// **'Client ref (required, idempotency key)'**
  String get jhatkaFieldClientRef;

  /// No description provided for @jhatkaFieldCode.
  ///
  /// In en, this message translates to:
  /// **'Code (unique per outlet)'**
  String get jhatkaFieldCode;

  /// No description provided for @jhatkaFieldDeliveredTemp.
  ///
  /// In en, this message translates to:
  /// **'Delivered temp Â°C'**
  String get jhatkaFieldDeliveredTemp;

  /// No description provided for @jhatkaFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get jhatkaFieldEmail;

  /// No description provided for @jhatkaFieldExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry (yyyy-mm-dd)'**
  String get jhatkaFieldExpiryDate;

  /// No description provided for @jhatkaFieldFromDate.
  ///
  /// In en, this message translates to:
  /// **'From (yyyy-mm-dd)'**
  String get jhatkaFieldFromDate;

  /// No description provided for @jhatkaFieldLicenceNumber.
  ///
  /// In en, this message translates to:
  /// **'Licence number'**
  String get jhatkaFieldLicenceNumber;

  /// No description provided for @jhatkaFieldMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Message (required)'**
  String get jhatkaFieldMessageRequired;

  /// No description provided for @jhatkaFieldMovementType.
  ///
  /// In en, this message translates to:
  /// **'Movement type'**
  String get jhatkaFieldMovementType;

  /// No description provided for @jhatkaFieldNameOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Name or phone (this outletâ€™s customers)'**
  String get jhatkaFieldNameOrPhone;

  /// No description provided for @jhatkaFieldNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get jhatkaFieldNoteOptional;

  /// No description provided for @jhatkaFieldOtpOptional.
  ///
  /// In en, this message translates to:
  /// **'OTP (if required)'**
  String get jhatkaFieldOtpOptional;

  /// No description provided for @jhatkaFieldOutletName.
  ///
  /// In en, this message translates to:
  /// **'Outlet name'**
  String get jhatkaFieldOutletName;

  /// No description provided for @jhatkaFieldPackingTemp.
  ///
  /// In en, this message translates to:
  /// **'Packing temp Â°C (optional)'**
  String get jhatkaFieldPackingTemp;

  /// No description provided for @jhatkaFieldPeriodEnd.
  ///
  /// In en, this message translates to:
  /// **'Period end (yyyy-mm-dd)'**
  String get jhatkaFieldPeriodEnd;

  /// No description provided for @jhatkaFieldPeriodStart.
  ///
  /// In en, this message translates to:
  /// **'Period start (yyyy-mm-dd)'**
  String get jhatkaFieldPeriodStart;

  /// No description provided for @jhatkaFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get jhatkaFieldPhone;

  /// No description provided for @jhatkaFieldPoOptional.
  ///
  /// In en, this message translates to:
  /// **'Purchase order (optional)'**
  String get jhatkaFieldPoOptional;

  /// No description provided for @jhatkaFieldPricePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Price per unit (Rs)'**
  String get jhatkaFieldPricePerUnit;

  /// No description provided for @jhatkaFieldRateBps.
  ///
  /// In en, this message translates to:
  /// **'Rate (basis points)'**
  String get jhatkaFieldRateBps;

  /// No description provided for @jhatkaFieldRawSku.
  ///
  /// In en, this message translates to:
  /// **'Raw SKU'**
  String get jhatkaFieldRawSku;

  /// No description provided for @jhatkaFieldReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get jhatkaFieldReasonOptional;

  /// No description provided for @jhatkaFieldReasonCustomer.
  ///
  /// In en, this message translates to:
  /// **'Reason (required â€” the customer reads this)'**
  String get jhatkaFieldReasonCustomer;

  /// No description provided for @jhatkaFieldReasonOutlet.
  ///
  /// In en, this message translates to:
  /// **'Reason (required â€” the outlet reads this)'**
  String get jhatkaFieldReasonOutlet;

  /// No description provided for @jhatkaFieldReasonShown.
  ///
  /// In en, this message translates to:
  /// **'Reason (shown to the customer)'**
  String get jhatkaFieldReasonShown;

  /// No description provided for @jhatkaFieldReasonMin10.
  ///
  /// In en, this message translates to:
  /// **'Reason, at least 10 characters'**
  String get jhatkaFieldReasonMin10;

  /// No description provided for @jhatkaFieldReceivedQty.
  ///
  /// In en, this message translates to:
  /// **'Received qty'**
  String get jhatkaFieldReceivedQty;

  /// No description provided for @jhatkaFieldReceiverName.
  ///
  /// In en, this message translates to:
  /// **'Receiver name'**
  String get jhatkaFieldReceiverName;

  /// No description provided for @jhatkaFieldRepeats.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get jhatkaFieldRepeats;

  /// No description provided for @jhatkaFieldSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get jhatkaFieldSeverity;

  /// No description provided for @jhatkaFieldSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get jhatkaFieldSupplier;

  /// No description provided for @jhatkaFieldSupplierInvoiceRef.
  ///
  /// In en, this message translates to:
  /// **'Supplier invoice ref (optional)'**
  String get jhatkaFieldSupplierInvoiceRef;

  /// No description provided for @jhatkaFieldToDate.
  ///
  /// In en, this message translates to:
  /// **'To (yyyy-mm-dd)'**
  String get jhatkaFieldToDate;

  /// No description provided for @jhatkaFieldType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get jhatkaFieldType;

  /// No description provided for @jhatkaFieldUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get jhatkaFieldUnit;

  /// No description provided for @jhatkaFieldUnitPriceFrozen.
  ///
  /// In en, this message translates to:
  /// **'Unit price (Rs, frozen at intake)'**
  String get jhatkaFieldUnitPriceFrozen;

  /// No description provided for @jhatkaFieldVariant.
  ///
  /// In en, this message translates to:
  /// **'Variant'**
  String get jhatkaFieldVariant;

  /// No description provided for @jhatkaFieldVehicleNo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle no (optional)'**
  String get jhatkaFieldVehicleNo;

  /// No description provided for @jhatkaSeverityAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Advisory â€” in-house'**
  String get jhatkaSeverityAdvisory;

  /// No description provided for @jhatkaSeverityWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw â€” pull from sale'**
  String get jhatkaSeverityWithdraw;

  /// No description provided for @jhatkaAwaitingResponse.
  ///
  /// In en, this message translates to:
  /// **'Awaiting response â€” one only'**
  String get jhatkaAwaitingResponse;

  /// No description provided for @jhatkaBlankUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Blank fields are left unchanged.'**
  String get jhatkaBlankUnchanged;

  /// No description provided for @jhatkaDraftOverride.
  ///
  /// In en, this message translates to:
  /// **'Draft override'**
  String get jhatkaDraftOverride;

  /// No description provided for @jhatkaFlatAmountOff.
  ///
  /// In en, this message translates to:
  /// **'Flat amount off'**
  String get jhatkaFlatAmountOff;

  /// No description provided for @jhatkaPercentOff.
  ///
  /// In en, this message translates to:
  /// **'Percent off'**
  String get jhatkaPercentOff;

  /// No description provided for @jhatkaFragile.
  ///
  /// In en, this message translates to:
  /// **'Fragile'**
  String get jhatkaFragile;

  /// No description provided for @jhatkaGrossCollected.
  ///
  /// In en, this message translates to:
  /// **'Gross collected'**
  String get jhatkaGrossCollected;

  /// No description provided for @jhatkaLowStockOnly.
  ///
  /// In en, this message translates to:
  /// **'Low stock only'**
  String get jhatkaLowStockOnly;

  /// No description provided for @jhatkaStockLine.
  ///
  /// In en, this message translates to:
  /// **'Stock line'**
  String get jhatkaStockLine;

  /// No description provided for @jhatkaToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get jhatkaToday;

  /// No description provided for @jhatkaWalkInNoPo.
  ///
  /// In en, this message translates to:
  /// **'Walk-in, no PO'**
  String get jhatkaWalkInNoPo;

  /// No description provided for @jhatkaRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get jhatkaRefunded;

  /// No description provided for @jhatkaResponded.
  ///
  /// In en, this message translates to:
  /// **'Responded'**
  String get jhatkaResponded;

  /// No description provided for @jhatkaEstimatedMinusRefunds.
  ///
  /// In en, this message translates to:
  /// **'estimated minus refunds'**
  String get jhatkaEstimatedMinusRefunds;

  /// No description provided for @jhatkaEveryRefundIsDocument.
  ///
  /// In en, this message translates to:
  /// **'every refund is a document'**
  String get jhatkaEveryRefundIsDocument;

  /// No description provided for @jhatkaInWindow.
  ///
  /// In en, this message translates to:
  /// **'in the window'**
  String get jhatkaInWindow;

  /// No description provided for @jhatkaStatusActive.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get jhatkaStatusActive;

  /// No description provided for @jhatkaStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'inactive'**
  String get jhatkaStatusInactive;

  /// No description provided for @jhatkaStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'suspended'**
  String get jhatkaStatusSuspended;

  /// No description provided for @jhatkaStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'expired'**
  String get jhatkaStatusExpired;

  /// No description provided for @jhatkaStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'paid'**
  String get jhatkaStatusPaid;

  /// No description provided for @jhatkaStatusAwaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'awaiting payment'**
  String get jhatkaStatusAwaitingPayment;

  /// No description provided for @jhatkaStatusLow.
  ///
  /// In en, this message translates to:
  /// **'low'**
  String get jhatkaStatusLow;

  /// No description provided for @jhatkaStatusSkippedCredited.
  ///
  /// In en, this message translates to:
  /// **'skipped Â· credited'**
  String get jhatkaStatusSkippedCredited;

  /// No description provided for @jhatkaVariantCount.
  ///
  /// In en, this message translates to:
  /// **'{count} variant(s)'**
  String jhatkaVariantCount(Object count);

  /// No description provided for @jhatkaResponsesOnRecord.
  ///
  /// In en, this message translates to:
  /// **'{count} response(s) on record'**
  String jhatkaResponsesOnRecord(Object count);

  /// No description provided for @jhatkaStageLabel.
  ///
  /// In en, this message translates to:
  /// **'Stage: {value}'**
  String jhatkaStageLabel(Object value);

  /// No description provided for @jhatkaFssaiLabel.
  ///
  /// In en, this message translates to:
  /// **'FSSAI: {value}'**
  String jhatkaFssaiLabel(Object value);

  /// No description provided for @jhatkaForLabel.
  ///
  /// In en, this message translates to:
  /// **'For: {value}'**
  String jhatkaForLabel(Object value);

  /// No description provided for @jhatkaWastageRecords.
  ///
  /// In en, this message translates to:
  /// **'{count} record(s)'**
  String jhatkaWastageRecords(Object count);

  /// No description provided for @jhatkaDeliveryNo.
  ///
  /// In en, this message translates to:
  /// **'Delivery {value}'**
  String jhatkaDeliveryNo(Object value);

  /// No description provided for @jhatkaActionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get jhatkaActionResume;

  /// No description provided for @jhatkaFieldStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get jhatkaFieldStarts;

  /// No description provided for @jhatkaCollectCollected.
  ///
  /// In en, this message translates to:
  /// **'Collect {collect} Â· collected {collected}'**
  String jhatkaCollectCollected(Object collect, Object collected);

  /// No description provided for @jhatkaReceiverLabel.
  ///
  /// In en, this message translates to:
  /// **'Receiver {value}'**
  String jhatkaReceiverLabel(Object value);

  /// No description provided for @jhatkaDeliveryStatus.
  ///
  /// In en, this message translates to:
  /// **'Delivery {no} Â· {status}'**
  String jhatkaDeliveryStatus(Object no, Object status);

  /// No description provided for @jhatkaCodLabel.
  ///
  /// In en, this message translates to:
  /// **'COD: {value}'**
  String jhatkaCodLabel(Object value);

  /// No description provided for @jhatkaOrderNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Order #{no}'**
  String jhatkaOrderNoLabel(Object no);

  /// No description provided for @jhatkaLabelNo.
  ///
  /// In en, this message translates to:
  /// **'Label {no}'**
  String jhatkaLabelNo(Object no);

  /// No description provided for @jhatkaFieldPack.
  ///
  /// In en, this message translates to:
  /// **'Pack'**
  String get jhatkaFieldPack;

  /// No description provided for @jhatkaFieldNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get jhatkaFieldNet;

  /// No description provided for @jhatkaFieldPackedOn.
  ///
  /// In en, this message translates to:
  /// **'Packed on'**
  String get jhatkaFieldPackedOn;

  /// No description provided for @jhatkaFieldUseBy.
  ///
  /// In en, this message translates to:
  /// **'Use by'**
  String get jhatkaFieldUseBy;

  /// No description provided for @jhatkaActionHandOver.
  ///
  /// In en, this message translates to:
  /// **'Hand over at counter'**
  String get jhatkaActionHandOver;

  /// No description provided for @jhatkaPickupOrderNote.
  ///
  /// In en, this message translates to:
  /// **'Pickup order â€” the customer collects here. No rider is dispatched.'**
  String get jhatkaPickupOrderNote;

  /// No description provided for @jhatkaSupplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Request stock'**
  String get jhatkaSupplyTitle;

  /// No description provided for @jhatkaSupplyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load supply. Retry.'**
  String get jhatkaSupplyLoadFailed;

  /// No description provided for @jhatkaSupplyPickItems.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one quantity.'**
  String get jhatkaSupplyPickItems;

  /// No description provided for @jhatkaSupplySubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'The request did not go through. Retry.'**
  String get jhatkaSupplySubmitFailed;

  /// No description provided for @jhatkaSupplySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request sent â€” LocalWala will approve and deliver.'**
  String get jhatkaSupplySubmitted;

  /// No description provided for @jhatkaSupplyPayFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment could not start. Retry.'**
  String get jhatkaSupplyPayFailed;

  /// No description provided for @jhatkaSupplyModePrepaid.
  ///
  /// In en, this message translates to:
  /// **'Prepay now'**
  String get jhatkaSupplyModePrepaid;

  /// No description provided for @jhatkaSupplyModeOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Pay on delivery'**
  String get jhatkaSupplyModeOnDelivery;

  /// No description provided for @jhatkaSupplyModeDeduct.
  ///
  /// In en, this message translates to:
  /// **'Deduct from payout'**
  String get jhatkaSupplyModeDeduct;

  /// No description provided for @jhatkaSupplyLedgerBalance.
  ///
  /// In en, this message translates to:
  /// **'Prepaid balance'**
  String get jhatkaSupplyLedgerBalance;

  /// No description provided for @jhatkaSupplyNewRequest.
  ///
  /// In en, this message translates to:
  /// **'New stock request'**
  String get jhatkaSupplyNewRequest;

  /// No description provided for @jhatkaSupplyQtyKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get jhatkaSupplyQtyKg;

  /// No description provided for @jhatkaSupplyPaymentMode.
  ///
  /// In en, this message translates to:
  /// **'Payment mode'**
  String get jhatkaSupplyPaymentMode;

  /// No description provided for @jhatkaSupplyNeededBy.
  ///
  /// In en, this message translates to:
  /// **'Needed by'**
  String get jhatkaSupplyNeededBy;

  /// No description provided for @jhatkaSupplySubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get jhatkaSupplySubmit;

  /// No description provided for @jhatkaSupplyHistory.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get jhatkaSupplyHistory;

  /// No description provided for @jhatkaSupplyNoRequests.
  ///
  /// In en, this message translates to:
  /// **'No stock requests yet.'**
  String get jhatkaSupplyNoRequests;

  /// No description provided for @jhatkaSupplyPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get jhatkaSupplyPay;

  /// No description provided for @jhatkaAreaTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery area'**
  String get jhatkaAreaTitle;

  /// No description provided for @jhatkaAreaCeiling.
  ///
  /// In en, this message translates to:
  /// **'Platform ceiling:'**
  String get jhatkaAreaCeiling;

  /// No description provided for @jhatkaAreaFreeRing.
  ///
  /// In en, this message translates to:
  /// **'Free within'**
  String get jhatkaAreaFreeRing;

  /// No description provided for @jhatkaAreaPaidRing.
  ///
  /// In en, this message translates to:
  /// **'Paid band'**
  String get jhatkaAreaPaidRing;

  /// No description provided for @jhatkaAreaNoOuterBand.
  ///
  /// In en, this message translates to:
  /// **'No paid band'**
  String get jhatkaAreaNoOuterBand;

  /// No description provided for @jhatkaAreaFee.
  ///
  /// In en, this message translates to:
  /// **'Flat fee (â‚¹)'**
  String get jhatkaAreaFee;

  /// No description provided for @jhatkaAreaReason.
  ///
  /// In en, this message translates to:
  /// **'Why this change?'**
  String get jhatkaAreaReason;

  /// No description provided for @jhatkaAreaSubmit.
  ///
  /// In en, this message translates to:
  /// **'Request area change'**
  String get jhatkaAreaSubmit;

  /// No description provided for @jhatkaAreaSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Area change requested â€” LocalWala will review.'**
  String get jhatkaAreaSubmitted;

  /// No description provided for @jhatkaAreaSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'That did not go through. Check the ceiling and retry.'**
  String get jhatkaAreaSubmitFailed;

  /// No description provided for @jhatkaAreaPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get jhatkaAreaPending;

  /// No description provided for @jhatkaAreaWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get jhatkaAreaWithdraw;

  /// No description provided for @jhatkaAreaWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Request withdrawn.'**
  String get jhatkaAreaWithdrawn;

  /// No description provided for @jhatkaAreaDirect.
  ///
  /// In en, this message translates to:
  /// **'Your delivery area is configured by LocalWala.'**
  String get jhatkaAreaDirect;

  /// No description provided for @jhatkaAreaInvalidNumbers.
  ///
  /// In en, this message translates to:
  /// **'Enter valid numbers for the rings and the fee.'**
  String get jhatkaAreaInvalidNumbers;

  /// No description provided for @jhatkaAreaFeeRequired.
  ///
  /// In en, this message translates to:
  /// **'A paid band needs a fee above zero.'**
  String get jhatkaAreaFeeRequired;

  /// No description provided for @jhatkaAreaReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Say why â€” the admin reads it.'**
  String get jhatkaAreaReasonRequired;

  /// No description provided for @earningsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get earningsToday;

  /// No description provided for @earningsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get earningsThisWeek;

  /// No description provided for @earningsCansMoved.
  ///
  /// In en, this message translates to:
  /// **'Cans moved'**
  String get earningsCansMoved;

  /// No description provided for @earningsDeliveredStops.
  ///
  /// In en, this message translates to:
  /// **'Delivered stops'**
  String get earningsDeliveredStops;

  /// No description provided for @earningsRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get earningsRate;

  /// No description provided for @earningsPerCan.
  ///
  /// In en, this message translates to:
  /// **'per can'**
  String get earningsPerCan;

  /// No description provided for @earningsPerLitre.
  ///
  /// In en, this message translates to:
  /// **'per litre'**
  String get earningsPerLitre;

  /// No description provided for @earningsSalary.
  ///
  /// In en, this message translates to:
  /// **'salary'**
  String get earningsSalary;

  /// No description provided for @earningsPerLitreUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Per-litre payout is not available yet'**
  String get earningsPerLitreUnsupported;

  /// No description provided for @earningsPerLitreHint.
  ///
  /// In en, this message translates to:
  /// **'The dairy ledger does not record litres per stop, so this figure cannot be computed.'**
  String get earningsPerLitreHint;

  /// No description provided for @earningsCashInHand.
  ///
  /// In en, this message translates to:
  /// **'Cash in hand'**
  String get earningsCashInHand;

  /// No description provided for @earningsCashStops.
  ///
  /// In en, this message translates to:
  /// **'Cash stops'**
  String get earningsCashStops;

  /// No description provided for @earningsCashCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get earningsCashCollected;

  /// No description provided for @earningsCashDeposited.
  ///
  /// In en, this message translates to:
  /// **'Deposited'**
  String get earningsCashDeposited;

  /// No description provided for @earningsCashOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get earningsCashOutstanding;

  /// No description provided for @earningsRecordDeposit.
  ///
  /// In en, this message translates to:
  /// **'Record deposit'**
  String get earningsRecordDeposit;

  /// No description provided for @earningsDepositAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get earningsDepositAmount;

  /// No description provided for @earningsDepositReference.
  ///
  /// In en, this message translates to:
  /// **'Reference (optional)'**
  String get earningsDepositReference;

  /// No description provided for @earningsDepositSaved.
  ///
  /// In en, this message translates to:
  /// **'Deposit recorded'**
  String get earningsDepositSaved;

  /// No description provided for @earningsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Earnings unavailable'**
  String get earningsUnavailable;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @runLabel.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get runLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @runStatusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get runStatusPlanned;

  /// No description provided for @runStatusDispatched.
  ///
  /// In en, this message translates to:
  /// **'Dispatched'**
  String get runStatusDispatched;

  /// No description provided for @runStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get runStatusInProgress;

  /// No description provided for @runStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get runStatusCompleted;

  /// No description provided for @runStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get runStatusCancelled;

  /// No description provided for @runsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Runs unavailable'**
  String get runsUnavailable;

  /// No description provided for @noPastRuns.
  ///
  /// In en, this message translates to:
  /// **'No past runs yet'**
  String get noPastRuns;

  /// No description provided for @noPastRunsHint.
  ///
  /// In en, this message translates to:
  /// **'Completed routes appear here once the depot reconciliation is closed.'**
  String get noPastRunsHint;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @runId.
  ///
  /// In en, this message translates to:
  /// **'Run id'**
  String get runId;

  /// No description provided for @stopIdOptional.
  ///
  /// In en, this message translates to:
  /// **'Stop id (optional)'**
  String get stopIdOptional;

  /// No description provided for @canCode.
  ///
  /// In en, this message translates to:
  /// **'Can code'**
  String get canCode;

  /// No description provided for @runIdAndCanRequired.
  ///
  /// In en, this message translates to:
  /// **'Run id and can code are required'**
  String get runIdAndCanRequired;

  /// No description provided for @canSynced.
  ///
  /// In en, this message translates to:
  /// **'Can {code} synced'**
  String canSynced(String code);

  /// No description provided for @canQueuedOffline.
  ///
  /// In en, this message translates to:
  /// **'Can {code} queued offline'**
  String canQueuedOffline(String code);

  /// No description provided for @issuedToCustomers.
  ///
  /// In en, this message translates to:
  /// **'Issued to customers'**
  String get issuedToCustomers;

  /// No description provided for @expectedReturn.
  ///
  /// In en, this message translates to:
  /// **'Expected return'**
  String get expectedReturn;

  /// No description provided for @actualReturn.
  ///
  /// In en, this message translates to:
  /// **'Actual return'**
  String get actualReturn;

  /// No description provided for @cansReturned.
  ///
  /// In en, this message translates to:
  /// **'Cans returned'**
  String get cansReturned;

  /// No description provided for @runIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Run id is required'**
  String get runIdRequired;

  /// No description provided for @adjustmentReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Adjustment reason is required while cans are unbalanced'**
  String get adjustmentReasonRequired;

  /// No description provided for @runCompleted.
  ///
  /// In en, this message translates to:
  /// **'Run completed'**
  String get runCompleted;

  /// No description provided for @couldNotCompleteRun.
  ///
  /// In en, this message translates to:
  /// **'Could not complete run'**
  String get couldNotCompleteRun;

  /// No description provided for @runBalanceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not load the run\'s can balance.'**
  String get runBalanceUnavailable;

  /// No description provided for @noActiveRun.
  ///
  /// In en, this message translates to:
  /// **'No run assigned for today'**
  String get noActiveRun;

  /// No description provided for @dashboardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Dashboard unavailable'**
  String get dashboardUnavailable;

  /// No description provided for @couldNotLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Could not load the dashboard.'**
  String get couldNotLoadDashboard;

  /// No description provided for @noDataReturned.
  ///
  /// In en, this message translates to:
  /// **'No data returned.'**
  String get noDataReturned;

  /// No description provided for @somePanelsFailed.
  ///
  /// In en, this message translates to:
  /// **'Some panels could not load'**
  String get somePanelsFailed;

  /// No description provided for @temporarilyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'temporarily unavailable'**
  String get temporarilyUnavailable;

  /// No description provided for @revenueToday.
  ///
  /// In en, this message translates to:
  /// **'Revenue today'**
  String get revenueToday;

  /// No description provided for @runsInProgress.
  ///
  /// In en, this message translates to:
  /// **'Runs in progress'**
  String get runsInProgress;

  /// No description provided for @fssaiLicence.
  ///
  /// In en, this message translates to:
  /// **'FSSAI licence'**
  String get fssaiLicence;

  /// No description provided for @supplierPayables.
  ///
  /// In en, this message translates to:
  /// **'Supplier payables'**
  String get supplierPayables;

  /// No description provided for @noLicenceRecorded.
  ///
  /// In en, this message translates to:
  /// **'No licence recorded'**
  String get noLicenceRecorded;

  /// No description provided for @unknownStatus.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownStatus;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @lowStockSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} items at or below {threshold}'**
  String lowStockSummary(int count, int threshold);

  /// No description provided for @quantityLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String quantityLeft(int count);

  /// No description provided for @daysToExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expires in {days} days'**
  String daysToExpiry(int days);

  /// No description provided for @approvedStatements.
  ///
  /// In en, this message translates to:
  /// **'{count} approved statements'**
  String approvedStatements(int count);

  /// No description provided for @stopsPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} stops pending'**
  String stopsPendingCount(int count);

  /// No description provided for @compliancePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get compliancePending;

  /// No description provided for @complianceValid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get complianceValid;

  /// No description provided for @complianceExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get complianceExpiring;

  /// No description provided for @complianceExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get complianceExpired;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get statusRefunded;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get statusPreparing;

  /// No description provided for @statusOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get statusOutForDelivery;

  /// No description provided for @statusPendingPayments.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get statusPendingPayments;

  /// No description provided for @settlementStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get settlementStatusPaid;

  /// No description provided for @settlementStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get settlementStatusApproved;

  /// No description provided for @settlementStatusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get settlementStatusSubmitted;

  /// No description provided for @settlementStatusVoid.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get settlementStatusVoid;

  /// No description provided for @settlementStatusDisputed.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get settlementStatusDisputed;

  /// No description provided for @couldNotCompleteAction.
  ///
  /// In en, this message translates to:
  /// **'Could not complete that action.'**
  String get couldNotCompleteAction;

  /// No description provided for @couldNotLoadRiders.
  ///
  /// In en, this message translates to:
  /// **'Could not load riders.'**
  String get couldNotLoadRiders;

  /// No description provided for @inviteRider.
  ///
  /// In en, this message translates to:
  /// **'Invite a rider'**
  String get inviteRider;

  /// No description provided for @inviteRiderHint.
  ///
  /// In en, this message translates to:
  /// **'They join this outlet when they register with the number you enter.'**
  String get inviteRiderHint;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumber;

  /// No description provided for @tenDigitNumber.
  ///
  /// In en, this message translates to:
  /// **'10-digit number'**
  String get tenDigitNumber;

  /// No description provided for @inviteAction.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get inviteAction;

  /// No description provided for @invalidMobile.
  ///
  /// In en, this message translates to:
  /// **'That is not a valid mobile number.'**
  String get invalidMobile;

  /// No description provided for @payAction.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get payAction;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @removeRiderNamed.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeRiderNamed(String name);

  /// No description provided for @removeRiderHint.
  ///
  /// In en, this message translates to:
  /// **'They leave this outlet\'s fleet and stop appearing on the roster. Their delivery history is kept.'**
  String get removeRiderHint;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @noOwnRiders.
  ///
  /// In en, this message translates to:
  /// **'No own riders'**
  String get noOwnRiders;

  /// No description provided for @noOwnRidersHint.
  ///
  /// In en, this message translates to:
  /// **'This outlet has no riders on its own fleet yet. Invite one above.'**
  String get noOwnRidersHint;

  /// No description provided for @ridersUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Riders unavailable'**
  String get ridersUnavailable;

  /// No description provided for @pendingInvitations.
  ///
  /// In en, this message translates to:
  /// **'Pending invitations'**
  String get pendingInvitations;

  /// No description provided for @waitingForRegistration.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the rider to register'**
  String get waitingForRegistration;

  /// No description provided for @riderFallback.
  ///
  /// In en, this message translates to:
  /// **'Rider'**
  String get riderFallback;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @onFleet.
  ///
  /// In en, this message translates to:
  /// **'On fleet'**
  String get onFleet;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @couldNotLoadRuns.
  ///
  /// In en, this message translates to:
  /// **'Could not load runs.'**
  String get couldNotLoadRuns;

  /// No description provided for @noRunsYet.
  ///
  /// In en, this message translates to:
  /// **'No runs yet'**
  String get noRunsYet;

  /// No description provided for @noRunsYetHint.
  ///
  /// In en, this message translates to:
  /// **'Runs appear once the nightly manifest builds tomorrow\'s deliveries, or you create one manually.'**
  String get noRunsYetHint;

  /// No description provided for @couldNotLoadEarnings.
  ///
  /// In en, this message translates to:
  /// **'Could not load earnings.'**
  String get couldNotLoadEarnings;

  /// No description provided for @livePreSettlementSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} delivered orders Â· live, pre-settlement'**
  String livePreSettlementSummary(int count);

  /// No description provided for @youKeep.
  ///
  /// In en, this message translates to:
  /// **'You keep'**
  String get youKeep;

  /// No description provided for @noPartnerAgreement.
  ///
  /// In en, this message translates to:
  /// **'No partner agreement'**
  String get noPartnerAgreement;

  /// No description provided for @noPartnerAgreementHint.
  ///
  /// In en, this message translates to:
  /// **'This outlet has no commission agreement on file, so nothing is deducted. The platform settles it directly.'**
  String get noPartnerAgreementHint;

  /// No description provided for @commissionRate.
  ///
  /// In en, this message translates to:
  /// **'{rate}% commission'**
  String commissionRate(String rate);

  /// No description provided for @commissionOnProductAndDelivery.
  ///
  /// In en, this message translates to:
  /// **'Product + delivery charges'**
  String get commissionOnProductAndDelivery;

  /// No description provided for @commissionOnProductOnly.
  ///
  /// In en, this message translates to:
  /// **'Product sales only'**
  String get commissionOnProductOnly;

  /// No description provided for @closedStatements.
  ///
  /// In en, this message translates to:
  /// **'Closed statements for this outlet'**
  String get closedStatements;

  /// No description provided for @nothingSettledYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing settled yet'**
  String get nothingSettledYet;

  /// No description provided for @nothingSettledYetHint.
  ///
  /// In en, this message translates to:
  /// **'Settlement statements appear here once a period is closed and paid.'**
  String get nothingSettledYetHint;

  /// No description provided for @couldNotLoadStock.
  ///
  /// In en, this message translates to:
  /// **'Could not load stock.'**
  String get couldNotLoadStock;

  /// No description provided for @stockUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Stock unavailable'**
  String get stockUnavailable;

  /// No description provided for @noStockRecords.
  ///
  /// In en, this message translates to:
  /// **'No stock records'**
  String get noStockRecords;

  /// No description provided for @noStockRecordsHint.
  ///
  /// In en, this message translates to:
  /// **'Products added to this outlet appear here with pack size and available quantity.'**
  String get noStockRecordsHint;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get outOfStock;

  /// No description provided for @couldNotLoadOrders.
  ///
  /// In en, this message translates to:
  /// **'Could not load orders.'**
  String get couldNotLoadOrders;

  /// No description provided for @orderActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update that order.'**
  String get orderActionFailed;

  /// No description provided for @ordersUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Orders unavailable'**
  String get ordersUnavailable;

  /// No description provided for @noOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders'**
  String get noOrders;

  /// No description provided for @noOrdersHint.
  ///
  /// In en, this message translates to:
  /// **'One-time dairy orders for this outlet appear here.'**
  String get noOrdersHint;

  /// No description provided for @orderLabel.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get orderLabel;

  /// No description provided for @markReady.
  ///
  /// In en, this message translates to:
  /// **'Mark ready'**
  String get markReady;

  /// No description provided for @couldNotLoadPlans.
  ///
  /// In en, this message translates to:
  /// **'Could not load subscriptions.'**
  String get couldNotLoadPlans;

  /// No description provided for @couldNotUpdatePlan.
  ///
  /// In en, this message translates to:
  /// **'Could not update this plan.'**
  String get couldNotUpdatePlan;

  /// No description provided for @subscriptionsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions unavailable'**
  String get subscriptionsUnavailable;

  /// No description provided for @noSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions'**
  String get noSubscriptions;

  /// No description provided for @noSubscriptionsHint.
  ///
  /// In en, this message translates to:
  /// **'Daily, alternate-day, weekly and custom-day milk plans for this outlet appear here.'**
  String get noSubscriptionsHint;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @scheduleDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get scheduleDaily;

  /// No description provided for @scheduleAlternateDays.
  ///
  /// In en, this message translates to:
  /// **'Alternate days'**
  String get scheduleAlternateDays;

  /// No description provided for @scheduleWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get scheduleWeekly;

  /// No description provided for @scheduleCustomDays.
  ///
  /// In en, this message translates to:
  /// **'Custom days'**
  String get scheduleCustomDays;

  /// No description provided for @planFallback.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planFallback;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get quantityLabel;

  /// No description provided for @storesTitleCustomerSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Customer subscriptions'**
  String get storesTitleCustomerSubscriptions;

  /// No description provided for @storesTitleRecurringPlans.
  ///
  /// In en, this message translates to:
  /// **'Recurring plans'**
  String get storesTitleRecurringPlans;

  /// No description provided for @storesTitleAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get storesTitleAnalytics;

  /// No description provided for @storesTitlePolicies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get storesTitlePolicies;

  /// No description provided for @storesTitleReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get storesTitleReviews;

  /// No description provided for @storesTitleStoreProfile.
  ///
  /// In en, this message translates to:
  /// **'Store profile'**
  String get storesTitleStoreProfile;

  /// No description provided for @storesTitleCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get storesTitleCategories;

  /// No description provided for @storesTitleProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get storesTitleProducts;

  /// No description provided for @storesTitleDispatch.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get storesTitleDispatch;

  /// No description provided for @storesTitleExchanges.
  ///
  /// In en, this message translates to:
  /// **'Exchanges'**
  String get storesTitleExchanges;

  /// No description provided for @storesMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get storesMoney;

  /// No description provided for @storesOperations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get storesOperations;

  /// No description provided for @storesAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get storesAccount;

  /// No description provided for @storesSubscribers.
  ///
  /// In en, this message translates to:
  /// **'Subscribers'**
  String get storesSubscribers;

  /// No description provided for @storesNext7Days.
  ///
  /// In en, this message translates to:
  /// **'Next 7 days'**
  String get storesNext7Days;

  /// No description provided for @storesSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get storesSkipped;

  /// No description provided for @storesNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet.'**
  String get storesNoCategories;

  /// No description provided for @storesNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products yet.'**
  String get storesNoProducts;

  /// No description provided for @storesNoPolicies.
  ///
  /// In en, this message translates to:
  /// **'No policies yet.'**
  String get storesNoPolicies;

  /// No description provided for @storesNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet.'**
  String get storesNoReviews;

  /// No description provided for @storesNoExchanges.
  ///
  /// In en, this message translates to:
  /// **'No exchanges yet.'**
  String get storesNoExchanges;

  /// No description provided for @storesNoDispatch.
  ///
  /// In en, this message translates to:
  /// **'No orders ready for dispatch.'**
  String get storesNoDispatch;

  /// No description provided for @storesNoOutlet.
  ///
  /// In en, this message translates to:
  /// **'No outlet'**
  String get storesNoOutlet;

  /// No description provided for @storesNoSkipped.
  ///
  /// In en, this message translates to:
  /// **'No skipped deliveries in the next 7 days.'**
  String get storesNoSkipped;

  /// No description provided for @storesNoUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming deliveries in the next 7 days.'**
  String get storesNoUpcoming;

  /// No description provided for @storesLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get storesLoadMore;

  /// No description provided for @storesRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get storesRetry;

  /// No description provided for @storesPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get storesPause;

  /// No description provided for @storesResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get storesResume;

  /// No description provided for @storesActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get storesActivate;

  /// No description provided for @storesReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get storesReview;

  /// No description provided for @storesNoRecurringPlans.
  ///
  /// In en, this message translates to:
  /// **'No recurring plans yet.'**
  String get storesNoRecurringPlans;

  /// No description provided for @storesMsgBrandCertSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Brand certification submitted for Admin review.'**
  String get storesMsgBrandCertSubmitted;

  /// No description provided for @storesActionRequestBrand.
  ///
  /// In en, this message translates to:
  /// **'Request a brand'**
  String get storesActionRequestBrand;

  /// No description provided for @storesTitleMyBrandRequests.
  ///
  /// In en, this message translates to:
  /// **'My brand requests'**
  String get storesTitleMyBrandRequests;

  /// No description provided for @storesActionCertifyBrand.
  ///
  /// In en, this message translates to:
  /// **'Certify brand'**
  String get storesActionCertifyBrand;

  /// No description provided for @storesLabelOrganicProduct.
  ///
  /// In en, this message translates to:
  /// **'Organic product'**
  String get storesLabelOrganicProduct;

  /// No description provided for @storesLabelProductHasVariants.
  ///
  /// In en, this message translates to:
  /// **'This product has variants'**
  String get storesLabelProductHasVariants;

  /// No description provided for @storesMsgChooseCategoryVariants.
  ///
  /// In en, this message translates to:
  /// **'Choose a category with variant attributes to generate variants.'**
  String get storesMsgChooseCategoryVariants;

  /// No description provided for @storesActionSubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get storesActionSubmitRequest;

  /// No description provided for @storesMsgCouldNotLoadRequests.
  ///
  /// In en, this message translates to:
  /// **'Could not load requests: {error}'**
  String storesMsgCouldNotLoadRequests(Object error);

  /// No description provided for @storesNoBrandRequests.
  ///
  /// In en, this message translates to:
  /// **'No brand requests yet.'**
  String get storesNoBrandRequests;

  /// No description provided for @storesFallbackBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get storesFallbackBrand;

  /// No description provided for @storesNoDrivers.
  ///
  /// In en, this message translates to:
  /// **'No drivers yet.'**
  String get storesNoDrivers;

  /// No description provided for @storesFallbackDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get storesFallbackDelivery;

  /// No description provided for @storesFallbackExchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get storesFallbackExchange;

  /// No description provided for @storesFallbackCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get storesFallbackCustomer;

  /// No description provided for @storesMsgCustomerOrders.
  ///
  /// In en, this message translates to:
  /// **'{orderCount} orders, {totalSpent}'**
  String storesMsgCustomerOrders(Object orderCount, Object totalSpent);

  /// No description provided for @storesTitleSettlement.
  ///
  /// In en, this message translates to:
  /// **'Settlement'**
  String get storesTitleSettlement;

  /// No description provided for @storesMsgNoLineItems.
  ///
  /// In en, this message translates to:
  /// **'No line items on this statement.'**
  String get storesMsgNoLineItems;

  /// No description provided for @storesActionSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get storesActionSuspend;

  /// No description provided for @storesActionReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get storesActionReactivate;

  /// No description provided for @storesMsgDriverSuspended.
  ///
  /// In en, this message translates to:
  /// **'Driver suspended'**
  String get storesMsgDriverSuspended;

  /// No description provided for @storesMsgDriverReactivated.
  ///
  /// In en, this message translates to:
  /// **'Driver reactivated'**
  String get storesMsgDriverReactivated;

  /// No description provided for @storesFallbackUnknownStep.
  ///
  /// In en, this message translates to:
  /// **'Unknown step'**
  String get storesFallbackUnknownStep;

  /// No description provided for @storesLabelAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get storesLabelAmount;

  /// No description provided for @storesLabelNextPaymentDue.
  ///
  /// In en, this message translates to:
  /// **'Next payment due'**
  String get storesLabelNextPaymentDue;

  /// No description provided for @storesLabelTrialEnds.
  ///
  /// In en, this message translates to:
  /// **'Trial ends'**
  String get storesLabelTrialEnds;

  /// No description provided for @storesLabelGracePeriodEnds.
  ///
  /// In en, this message translates to:
  /// **'Grace period ends'**
  String get storesLabelGracePeriodEnds;

  /// No description provided for @storesLabelStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get storesLabelStatus;

  /// No description provided for @storesFallbackPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get storesFallbackPlan;

  /// No description provided for @storesFallbackCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get storesFallbackCategory;

  /// No description provided for @storesFallbackPolicy.
  ///
  /// In en, this message translates to:
  /// **'Policy'**
  String get storesFallbackPolicy;

  /// No description provided for @storesNoSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions yet.'**
  String get storesNoSubscriptions;

  /// No description provided for @storesLabelItems.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get storesLabelItems;

  /// No description provided for @storesFallbackVariant.
  ///
  /// In en, this message translates to:
  /// **'Variant'**
  String get storesFallbackVariant;

  /// No description provided for @storesTitleNewCoupon.
  ///
  /// In en, this message translates to:
  /// **'New coupon'**
  String get storesTitleNewCoupon;

  /// No description provided for @storesTitleTestCode.
  ///
  /// In en, this message translates to:
  /// **'Test a code'**
  String get storesTitleTestCode;

  /// No description provided for @storesMsgReturnRefunded.
  ///
  /// In en, this message translates to:
  /// **'Return refunded'**
  String get storesMsgReturnRefunded;

  /// No description provided for @storesActionRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get storesActionRefund;

  /// No description provided for @storesMsgNoVariantToAdjust.
  ///
  /// In en, this message translates to:
  /// **'This row has no variant to adjust.'**
  String get storesMsgNoVariantToAdjust;

  /// No description provided for @storesMsgQuantityPositive.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be a positive number.'**
  String get storesMsgQuantityPositive;

  /// No description provided for @storesMsgReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is required for every stock movement.'**
  String get storesMsgReasonRequired;

  /// No description provided for @storesMsgStockUpdated.
  ///
  /// In en, this message translates to:
  /// **'Stock updated'**
  String get storesMsgStockUpdated;

  /// No description provided for @storesActionNewSale.
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get storesActionNewSale;

  /// No description provided for @storesActionWorkOrder.
  ///
  /// In en, this message translates to:
  /// **'Work the order'**
  String get storesActionWorkOrder;

  /// No description provided for @storesMsgNoOrderableVariant.
  ///
  /// In en, this message translates to:
  /// **'This product has no orderable variant.'**
  String get storesMsgNoOrderableVariant;

  /// No description provided for @storesTitleCounterSalePlaced.
  ///
  /// In en, this message translates to:
  /// **'Counter sale placed'**
  String get storesTitleCounterSalePlaced;

  /// No description provided for @storesMsgCashSaleHint.
  ///
  /// In en, this message translates to:
  /// **'Cash sale â€” add items from the list above'**
  String get storesMsgCashSaleHint;

  /// No description provided for @storesMsgCashDue.
  ///
  /// In en, this message translates to:
  /// **'Order #{orderNo} â€” cash due {total}'**
  String storesMsgCashDue(Object orderNo, Object total);

  /// No description provided for @storesTitleOutlet.
  ///
  /// In en, this message translates to:
  /// **'Outlet'**
  String get storesTitleOutlet;

  /// No description provided for @storesTitleChain.
  ///
  /// In en, this message translates to:
  /// **'Chain'**
  String get storesTitleChain;

  /// No description provided for @storesActionRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get storesActionRecord;

  /// No description provided for @storesLabelFragile.
  ///
  /// In en, this message translates to:
  /// **'Fragile'**
  String get storesLabelFragile;

  /// No description provided for @storesActionComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get storesActionComplete;

  /// No description provided for @storesActionKeepOrder.
  ///
  /// In en, this message translates to:
  /// **'Keep order'**
  String get storesActionKeepOrder;

  /// No description provided for @storesActionAcceptOrder.
  ///
  /// In en, this message translates to:
  /// **'Accept order'**
  String get storesActionAcceptOrder;

  /// No description provided for @storesActionCompletePacking.
  ///
  /// In en, this message translates to:
  /// **'Complete packing'**
  String get storesActionCompletePacking;

  /// No description provided for @storesActionMarkReady.
  ///
  /// In en, this message translates to:
  /// **'Mark ready'**
  String get storesActionMarkReady;

  /// No description provided for @storesActionAssignDriver.
  ///
  /// In en, this message translates to:
  /// **'Assign driver'**
  String get storesActionAssignDriver;

  /// No description provided for @storesActionCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get storesActionCancelOrder;

  /// No description provided for @storesLabelPicked.
  ///
  /// In en, this message translates to:
  /// **'Picked'**
  String get storesLabelPicked;

  /// No description provided for @storesLabelUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get storesLabelUnavailable;

  /// No description provided for @storesActionSubstitute.
  ///
  /// In en, this message translates to:
  /// **'Substitute'**
  String get storesActionSubstitute;

  /// No description provided for @storesMsgNoActionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No action available at this stage.'**
  String get storesMsgNoActionAvailable;

  /// No description provided for @storesTitleEditProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get storesTitleEditProduct;

  /// No description provided for @storesTitleNewProduct.
  ///
  /// In en, this message translates to:
  /// **'New product'**
  String get storesTitleNewProduct;

  /// No description provided for @storesTitleReturns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get storesTitleReturns;

  /// No description provided for @storesTitleCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get storesTitleCustomers;

  /// No description provided for @storesTitleSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get storesTitleSettings;

  /// No description provided for @storesTitleDeliveryTracking.
  ///
  /// In en, this message translates to:
  /// **'Delivery tracking'**
  String get storesTitleDeliveryTracking;

  /// No description provided for @storesNoReturns.
  ///
  /// In en, this message translates to:
  /// **'No returns yet.'**
  String get storesNoReturns;

  /// No description provided for @storesNoCustomers.
  ///
  /// In en, this message translates to:
  /// **'No customers yet.'**
  String get storesNoCustomers;

  /// No description provided for @storesNoDeliveries.
  ///
  /// In en, this message translates to:
  /// **'No deliveries yet.'**
  String get storesNoDeliveries;

  /// No description provided for @storesLabelStoreProfile.
  ///
  /// In en, this message translates to:
  /// **'Store profile'**
  String get storesLabelStoreProfile;

  /// No description provided for @storesLabelCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get storesLabelCategories;

  /// No description provided for @storesLabelProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get storesLabelProducts;

  /// No description provided for @storesLabelDispatch.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get storesLabelDispatch;

  /// No description provided for @storesLabelAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get storesLabelAnalytics;

  /// No description provided for @storesLabelPolicies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get storesLabelPolicies;

  /// No description provided for @storesLabelReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get storesLabelReviews;

  /// No description provided for @ls_documents_title.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get ls_documents_title;

  /// No description provided for @ls_upload_document.
  ///
  /// In en, this message translates to:
  /// **'Upload document'**
  String get ls_upload_document;

  /// No description provided for @ls_choose_file.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get ls_choose_file;

  /// No description provided for @ls_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get ls_cancel;

  /// No description provided for @ls_upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get ls_upload;

  /// No description provided for @ls_document_submitted.
  ///
  /// In en, this message translates to:
  /// **'Document submitted for verification'**
  String get ls_document_submitted;

  /// No description provided for @ls_upload_failed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String ls_upload_failed(Object error);

  /// No description provided for @ls_no_documents.
  ///
  /// In en, this message translates to:
  /// **'No documents uploaded yet'**
  String get ls_no_documents;

  /// No description provided for @ls_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get ls_retry;

  /// No description provided for @ls_settlements_title.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get ls_settlements_title;

  /// No description provided for @ls_no_settlements.
  ///
  /// In en, this message translates to:
  /// **'No settlements yet.'**
  String get ls_no_settlements;

  /// No description provided for @ls_quotes_title.
  ///
  /// In en, this message translates to:
  /// **'Quotes'**
  String get ls_quotes_title;

  /// No description provided for @ls_no_quotes.
  ///
  /// In en, this message translates to:
  /// **'No quotes yet.'**
  String get ls_no_quotes;

  /// No description provided for @ls_agreement_name_price_required.
  ///
  /// In en, this message translates to:
  /// **'Agreement name and price required'**
  String get ls_agreement_name_price_required;

  /// No description provided for @ls_create_agreement.
  ///
  /// In en, this message translates to:
  /// **'Create Agreement'**
  String get ls_create_agreement;

  /// No description provided for @ls_no_recurring_agreements.
  ///
  /// In en, this message translates to:
  /// **'No recurring agreements yet.'**
  String get ls_no_recurring_agreements;

  /// No description provided for @ls_failed_error.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String ls_failed_error(Object error);

  /// No description provided for @ls_no_jobs.
  ///
  /// In en, this message translates to:
  /// **'No jobs yet'**
  String get ls_no_jobs;

  /// No description provided for @ls_choose_service.
  ///
  /// In en, this message translates to:
  /// **'Choose a service'**
  String get ls_choose_service;

  /// No description provided for @ls_choose_service_to_see_addons.
  ///
  /// In en, this message translates to:
  /// **'Choose a service to see add-ons'**
  String get ls_choose_service_to_see_addons;

  /// No description provided for @ls_no_addons.
  ///
  /// In en, this message translates to:
  /// **'This service has no add-ons'**
  String get ls_no_addons;

  /// No description provided for @ls_choose_service_to_see_variants.
  ///
  /// In en, this message translates to:
  /// **'Choose a service to see variants'**
  String get ls_choose_service_to_see_variants;

  /// No description provided for @ls_no_variants.
  ///
  /// In en, this message translates to:
  /// **'This service has no variants'**
  String get ls_no_variants;

  /// No description provided for @ls_add_staff.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get ls_add_staff;

  /// No description provided for @ls_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get ls_save;

  /// No description provided for @ls_add_resource.
  ///
  /// In en, this message translates to:
  /// **'Add resource'**
  String get ls_add_resource;

  /// No description provided for @ls_room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get ls_room;

  /// No description provided for @ls_vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get ls_vehicle;

  /// No description provided for @ls_equipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get ls_equipment;

  /// No description provided for @ls_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get ls_other;

  /// No description provided for @ls_team_resources.
  ///
  /// In en, this message translates to:
  /// **'Team & resources'**
  String get ls_team_resources;

  /// No description provided for @ls_no_staff.
  ///
  /// In en, this message translates to:
  /// **'No staff'**
  String get ls_no_staff;

  /// No description provided for @ls_no_resources.
  ///
  /// In en, this message translates to:
  /// **'No resources found'**
  String get ls_no_resources;

  /// No description provided for @ls_staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get ls_staff;

  /// No description provided for @ls_resource.
  ///
  /// In en, this message translates to:
  /// **'Resource'**
  String get ls_resource;

  /// No description provided for @ls_leads_awaiting_qualification.
  ///
  /// In en, this message translates to:
  /// **'Leads awaiting qualification'**
  String get ls_leads_awaiting_qualification;

  /// No description provided for @ls_no_leads.
  ///
  /// In en, this message translates to:
  /// **'No leads found'**
  String get ls_no_leads;

  /// No description provided for @ls_lead_creation_deferred.
  ///
  /// In en, this message translates to:
  /// **'Lead creation deferred'**
  String get ls_lead_creation_deferred;

  /// No description provided for @ls_create_lead.
  ///
  /// In en, this message translates to:
  /// **'Create Lead'**
  String get ls_create_lead;

  /// No description provided for @ls_coverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get ls_coverage;

  /// No description provided for @ls_save_coverage.
  ///
  /// In en, this message translates to:
  /// **'Save coverage'**
  String get ls_save_coverage;

  /// No description provided for @ls_save_today_hours.
  ///
  /// In en, this message translates to:
  /// **'Save today hours'**
  String get ls_save_today_hours;

  /// No description provided for @ls_kind_file_url_required.
  ///
  /// In en, this message translates to:
  /// **'Kind and file URL required'**
  String get ls_kind_file_url_required;

  /// No description provided for @ls_register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get ls_register;

  /// No description provided for @ls_step_under_construction.
  ///
  /// In en, this message translates to:
  /// **'Step under construction'**
  String get ls_step_under_construction;

  /// No description provided for @ls_next_business_details.
  ///
  /// In en, this message translates to:
  /// **'Next: Business Details'**
  String get ls_next_business_details;

  /// No description provided for @ls_next_documents.
  ///
  /// In en, this message translates to:
  /// **'Next: Documents'**
  String get ls_next_documents;

  /// No description provided for @ls_upload_verification_documents.
  ///
  /// In en, this message translates to:
  /// **'Upload verification documents:'**
  String get ls_upload_verification_documents;

  /// No description provided for @ls_submit_for_admin_review.
  ///
  /// In en, this message translates to:
  /// **'Submit for Admin review'**
  String get ls_submit_for_admin_review;

  /// No description provided for @ls_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ls_status;

  /// No description provided for @ls_bookable.
  ///
  /// In en, this message translates to:
  /// **'Bookable'**
  String get ls_bookable;

  /// No description provided for @ls_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get ls_yes;

  /// No description provided for @ls_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get ls_no;

  /// No description provided for @ls_submitted_review.
  ///
  /// In en, this message translates to:
  /// **'Submitted. LocalWala will review your documents.'**
  String get ls_submitted_review;

  /// No description provided for @ls_refresh_status.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get ls_refresh_status;

  /// No description provided for @ls_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get ls_back;

  /// No description provided for @ls_labour_parts_required.
  ///
  /// In en, this message translates to:
  /// **'Labour and parts amounts required'**
  String get ls_labour_parts_required;

  /// No description provided for @ls_enter_revised_amounts.
  ///
  /// In en, this message translates to:
  /// **'Enter revised amounts first'**
  String get ls_enter_revised_amounts;

  /// No description provided for @ls_not_found.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get ls_not_found;

  /// No description provided for @ls_no_resource.
  ///
  /// In en, this message translates to:
  /// **'No resource'**
  String get ls_no_resource;

  /// No description provided for @ls_assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get ls_assign;

  /// No description provided for @ls_release.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get ls_release;

  /// No description provided for @ls_choose_from_gallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get ls_choose_from_gallery;

  /// No description provided for @ls_take_a_photo.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get ls_take_a_photo;

  /// No description provided for @ls_edit_offering.
  ///
  /// In en, this message translates to:
  /// **'Edit offering'**
  String get ls_edit_offering;

  /// No description provided for @ls_remove_photo.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get ls_remove_photo;

  /// No description provided for @ls_add_photo.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get ls_add_photo;

  /// No description provided for @ls_no_offerings.
  ///
  /// In en, this message translates to:
  /// **'No offerings yet'**
  String get ls_no_offerings;

  /// No description provided for @ls_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get ls_submit;

  /// No description provided for @ls_choose_variant.
  ///
  /// In en, this message translates to:
  /// **'Choose a variant'**
  String get ls_choose_variant;

  /// No description provided for @ls_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get ls_add;

  /// No description provided for @ls_earnings_detail.
  ///
  /// In en, this message translates to:
  /// **'Earnings Detail'**
  String get ls_earnings_detail;

  /// No description provided for @ls_no_bookings_period.
  ///
  /// In en, this message translates to:
  /// **'No bookings in period'**
  String get ls_no_bookings_period;

  /// No description provided for @ls_revenue_summary.
  ///
  /// In en, this message translates to:
  /// **'Revenue summary'**
  String get ls_revenue_summary;

  /// No description provided for @ls_gross_booking_value.
  ///
  /// In en, this message translates to:
  /// **'Gross booking value'**
  String get ls_gross_booking_value;

  /// No description provided for @ls_booking_fees.
  ///
  /// In en, this message translates to:
  /// **'Booking fees'**
  String get ls_booking_fees;

  /// No description provided for @ls_commission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get ls_commission;

  /// No description provided for @ls_provider_payable.
  ///
  /// In en, this message translates to:
  /// **'Provider payable'**
  String get ls_provider_payable;

  /// No description provided for @ls_reversals.
  ///
  /// In en, this message translates to:
  /// **'Reversals'**
  String get ls_reversals;

  /// No description provided for @ls_net_payable.
  ///
  /// In en, this message translates to:
  /// **'Net payable'**
  String get ls_net_payable;

  /// No description provided for @ls_total_bookings.
  ///
  /// In en, this message translates to:
  /// **'Total bookings'**
  String get ls_total_bookings;

  /// No description provided for @ls_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get ls_completed;

  /// No description provided for @ls_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get ls_cancelled;

  /// No description provided for @ls_conversion_rate.
  ///
  /// In en, this message translates to:
  /// **'Conversion rate'**
  String get ls_conversion_rate;

  /// No description provided for @ls_lead_board.
  ///
  /// In en, this message translates to:
  /// **'Lead board'**
  String get ls_lead_board;

  /// No description provided for @ls_qualify.
  ///
  /// In en, this message translates to:
  /// **'Qualify'**
  String get ls_qualify;

  /// No description provided for @ls_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get ls_invalid;

  /// No description provided for @ls_no_leads_board.
  ///
  /// In en, this message translates to:
  /// **'No leads on the board'**
  String get ls_no_leads_board;

  /// No description provided for @ls_upcoming_occurrences.
  ///
  /// In en, this message translates to:
  /// **'Upcoming occurrences'**
  String get ls_upcoming_occurrences;

  /// No description provided for @ls_none_scheduled.
  ///
  /// In en, this message translates to:
  /// **'None scheduled'**
  String get ls_none_scheduled;

  /// No description provided for @ls_subscribed.
  ///
  /// In en, this message translates to:
  /// **'Subscribed'**
  String get ls_subscribed;

  /// No description provided for @ls_marketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get ls_marketing;

  /// No description provided for @ls_marketing_packages.
  ///
  /// In en, this message translates to:
  /// **'Marketing packages'**
  String get ls_marketing_packages;

  /// No description provided for @ls_my_campaigns.
  ///
  /// In en, this message translates to:
  /// **'My campaigns'**
  String get ls_my_campaigns;

  /// No description provided for @ls_no_campaigns.
  ///
  /// In en, this message translates to:
  /// **'No campaigns yet'**
  String get ls_no_campaigns;

  /// No description provided for @ls_create_campaign.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get ls_create_campaign;

  /// No description provided for @ls_campaign_created.
  ///
  /// In en, this message translates to:
  /// **'Campaign submitted for review'**
  String get ls_campaign_created;

  /// No description provided for @ls_payment_initiated.
  ///
  /// In en, this message translates to:
  /// **'Payment initiated'**
  String get ls_payment_initiated;

  /// No description provided for @ls_pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get ls_pay;

  /// No description provided for @ls_pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get ls_pause;

  /// No description provided for @ls_resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get ls_resume;

  /// No description provided for @ls_no_packages.
  ///
  /// In en, this message translates to:
  /// **'No packages available'**
  String get ls_no_packages;

  /// No description provided for @ls_more_marketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get ls_more_marketing;

  /// No description provided for @ls_current_subscription.
  ///
  /// In en, this message translates to:
  /// **'Current subscription'**
  String get ls_current_subscription;

  /// No description provided for @ls_plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get ls_plan;

  /// No description provided for @ls_renews.
  ///
  /// In en, this message translates to:
  /// **'Renews'**
  String get ls_renews;

  /// No description provided for @ls_available_plans.
  ///
  /// In en, this message translates to:
  /// **'Available plans'**
  String get ls_available_plans;

  /// No description provided for @ls_subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get ls_subscribe;

  /// No description provided for @ls_no_plans.
  ///
  /// In en, this message translates to:
  /// **'No plans available'**
  String get ls_no_plans;

  /// No description provided for @ls_nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get ls_nav_home;

  /// No description provided for @ls_nav_jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get ls_nav_jobs;

  /// No description provided for @ls_nav_catalogue.
  ///
  /// In en, this message translates to:
  /// **'Catalogue'**
  String get ls_nav_catalogue;

  /// No description provided for @ls_nav_hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get ls_nav_hours;

  /// No description provided for @ls_nav_earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get ls_nav_earnings;

  /// No description provided for @ls_nav_more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get ls_nav_more;

  /// No description provided for @ls_more_entries.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get ls_more_entries;

  /// No description provided for @ls_more_statement.
  ///
  /// In en, this message translates to:
  /// **'Statement'**
  String get ls_more_statement;

  /// No description provided for @ls_more_growth.
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get ls_more_growth;

  /// No description provided for @ls_more_leads.
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get ls_more_leads;

  /// No description provided for @ls_more_quotes.
  ///
  /// In en, this message translates to:
  /// **'Quotes'**
  String get ls_more_quotes;

  /// No description provided for @ls_more_recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get ls_more_recurring;

  /// No description provided for @ls_more_settlements.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get ls_more_settlements;

  /// No description provided for @ls_more_staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get ls_more_staff;

  /// No description provided for @ls_more_documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get ls_more_documents;

  /// No description provided for @ls_more_variants.
  ///
  /// In en, this message translates to:
  /// **'Variants'**
  String get ls_more_variants;

  /// No description provided for @ls_more_addons.
  ///
  /// In en, this message translates to:
  /// **'Addons'**
  String get ls_more_addons;

  /// No description provided for @ls_more_onboarding.
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get ls_more_onboarding;

  /// No description provided for @ls_more_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get ls_more_account;

  /// No description provided for @ls_more_subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get ls_more_subscriptions;

  /// No description provided for @ls_revise.
  ///
  /// In en, this message translates to:
  /// **'Revise'**
  String get ls_revise;

  /// No description provided for @ls_booking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get ls_booking;

  /// No description provided for @ls_settlement.
  ///
  /// In en, this message translates to:
  /// **'Settlement'**
  String get ls_settlement;

  /// No description provided for @ls_recurring_agreements.
  ///
  /// In en, this message translates to:
  /// **'Recurring Agreements'**
  String get ls_recurring_agreements;

  /// No description provided for @ls_existing_agreements.
  ///
  /// In en, this message translates to:
  /// **'Existing Agreements'**
  String get ls_existing_agreements;

  /// No description provided for @ls_agreement_name.
  ///
  /// In en, this message translates to:
  /// **'Agreement name'**
  String get ls_agreement_name;

  /// No description provided for @ls_interval.
  ///
  /// In en, this message translates to:
  /// **'Interval (e.g. weekly, monthly)'**
  String get ls_interval;

  /// No description provided for @ls_occurrences.
  ///
  /// In en, this message translates to:
  /// **'Occurrences'**
  String get ls_occurrences;

  /// No description provided for @ls_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get ls_price;

  /// No description provided for @ls_agreement.
  ///
  /// In en, this message translates to:
  /// **'Agreement'**
  String get ls_agreement;

  /// No description provided for @ls_service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get ls_service;

  /// No description provided for @ls_variant.
  ///
  /// In en, this message translates to:
  /// **'Variant'**
  String get ls_variant;

  /// No description provided for @ls_variant_catalogue.
  ///
  /// In en, this message translates to:
  /// **'Variant catalogue'**
  String get ls_variant_catalogue;

  /// No description provided for @ls_variants_localwala_note.
  ///
  /// In en, this message translates to:
  /// **'Variants are set by LocalWala. Publish your price from Catalogue.'**
  String get ls_variants_localwala_note;

  /// No description provided for @ls_not_offered.
  ///
  /// In en, this message translates to:
  /// **'Not offered'**
  String get ls_not_offered;

  /// No description provided for @ls_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get ls_name;

  /// No description provided for @ls_skills.
  ///
  /// In en, this message translates to:
  /// **'Skills (comma separated)'**
  String get ls_skills;

  /// No description provided for @ls_working_hours_hint.
  ///
  /// In en, this message translates to:
  /// **'Working hours (HH:MM 24h). Leave blank for a day off.'**
  String get ls_working_hours_hint;

  /// No description provided for @ls_kind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get ls_kind;

  /// No description provided for @ls_capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get ls_capacity;

  /// No description provided for @ls_turnaround_minutes.
  ///
  /// In en, this message translates to:
  /// **'Turnaround minutes'**
  String get ls_turnaround_minutes;

  /// No description provided for @ls_register_provider.
  ///
  /// In en, this message translates to:
  /// **'Register as a service provider'**
  String get ls_register_provider;

  /// No description provided for @ls_business_name.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get ls_business_name;

  /// No description provided for @ls_provider_type.
  ///
  /// In en, this message translates to:
  /// **'Provider type'**
  String get ls_provider_type;

  /// No description provided for @ls_business_details.
  ///
  /// In en, this message translates to:
  /// **'Business details'**
  String get ls_business_details;

  /// No description provided for @ls_business_address.
  ///
  /// In en, this message translates to:
  /// **'Business address'**
  String get ls_business_address;

  /// No description provided for @ls_service_areas.
  ///
  /// In en, this message translates to:
  /// **'Service areas (comma-separated)'**
  String get ls_service_areas;

  /// No description provided for @ls_document_kind.
  ///
  /// In en, this message translates to:
  /// **'Document kind (e.g. license)'**
  String get ls_document_kind;

  /// No description provided for @ls_file_url.
  ///
  /// In en, this message translates to:
  /// **'File URL'**
  String get ls_file_url;

  /// No description provided for @ls_remove_subscription.
  ///
  /// In en, this message translates to:
  /// **'Remove subscription'**
  String get ls_remove_subscription;

  /// No description provided for @ls_add_subscription.
  ///
  /// In en, this message translates to:
  /// **'Add subscription (optional)'**
  String get ls_add_subscription;

  /// No description provided for @ls_services_live.
  ///
  /// In en, this message translates to:
  /// **'Your services are live and bookable by customers.'**
  String get ls_services_live;

  /// No description provided for @ls_account_final_checks.
  ///
  /// In en, this message translates to:
  /// **'LocalWala will activate your account after final checks.'**
  String get ls_account_final_checks;

  /// No description provided for @ls_duration_minutes.
  ///
  /// In en, this message translates to:
  /// **'Duration (min)'**
  String get ls_duration_minutes;

  /// No description provided for @ls_change_photo.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get ls_change_photo;

  /// No description provided for @ls_saving_returns_draft.
  ///
  /// In en, this message translates to:
  /// **'Saving changes returns this offering to draft for review.'**
  String get ls_saving_returns_draft;

  /// No description provided for @ls_publish_offering.
  ///
  /// In en, this message translates to:
  /// **'Publish an offering'**
  String get ls_publish_offering;

  /// No description provided for @ls_your_price.
  ///
  /// In en, this message translates to:
  /// **'Your price'**
  String get ls_your_price;

  /// No description provided for @ls_edit_price.
  ///
  /// In en, this message translates to:
  /// **'Edit price'**
  String get ls_edit_price;

  /// No description provided for @ls_staff_name.
  ///
  /// In en, this message translates to:
  /// **'Staff name'**
  String get ls_staff_name;

  /// No description provided for @ls_locality_coverage.
  ///
  /// In en, this message translates to:
  /// **'Locality (coverage)'**
  String get ls_locality_coverage;

  /// No description provided for @ls_staff_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Staff load failed'**
  String get ls_staff_load_failed;

  /// No description provided for @ls_staff_name_required.
  ///
  /// In en, this message translates to:
  /// **'Staff name required'**
  String get ls_staff_name_required;

  /// No description provided for @ls_staff_added.
  ///
  /// In en, this message translates to:
  /// **'Staff added'**
  String get ls_staff_added;

  /// No description provided for @ls_coverage_saved.
  ///
  /// In en, this message translates to:
  /// **'Coverage saved'**
  String get ls_coverage_saved;

  /// No description provided for @ls_today_hours_saved.
  ///
  /// In en, this message translates to:
  /// **'Today hours saved (09:00-20:00)'**
  String get ls_today_hours_saved;

  /// No description provided for @ls_gross_value.
  ///
  /// In en, this message translates to:
  /// **'Gross Value'**
  String get ls_gross_value;

  /// No description provided for @ls_booking_breakdown.
  ///
  /// In en, this message translates to:
  /// **'Booking Breakdown'**
  String get ls_booking_breakdown;

  /// No description provided for @ls_need_action.
  ///
  /// In en, this message translates to:
  /// **'Need action'**
  String get ls_need_action;

  /// No description provided for @ls_completed_value.
  ///
  /// In en, this message translates to:
  /// **'Completed value'**
  String get ls_completed_value;

  /// No description provided for @ls_open_leads.
  ///
  /// In en, this message translates to:
  /// **'Open Leads'**
  String get ls_open_leads;

  /// No description provided for @ls_manage_lead_claims.
  ///
  /// In en, this message translates to:
  /// **'Manage lead claims and charges'**
  String get ls_manage_lead_claims;

  /// No description provided for @ls_leads_list.
  ///
  /// In en, this message translates to:
  /// **'Leads List'**
  String get ls_leads_list;

  /// No description provided for @ls_lead_name.
  ///
  /// In en, this message translates to:
  /// **'Lead name'**
  String get ls_lead_name;

  /// No description provided for @ls_lead_value.
  ///
  /// In en, this message translates to:
  /// **'Lead value'**
  String get ls_lead_value;

  /// No description provided for @ls_document_type.
  ///
  /// In en, this message translates to:
  /// **'Document type'**
  String get ls_document_type;

  /// No description provided for @ls_open_file.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get ls_open_file;

  /// No description provided for @ls_could_not_open_photos.
  ///
  /// In en, this message translates to:
  /// **'Could not open photos. Check app permissions and try again.'**
  String get ls_could_not_open_photos;

  /// No description provided for @ls_upload_no_path.
  ///
  /// In en, this message translates to:
  /// **'Upload returned no path'**
  String get ls_upload_no_path;

  /// No description provided for @ls_image_upload_failed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed'**
  String get ls_image_upload_failed;

  /// No description provided for @ls_choose_service_numeric_price.
  ///
  /// In en, this message translates to:
  /// **'Choose a service and enter a numeric price'**
  String get ls_choose_service_numeric_price;

  /// No description provided for @ls_choose_variant_service.
  ///
  /// In en, this message translates to:
  /// **'Choose a variant for this service'**
  String get ls_choose_variant_service;

  /// No description provided for @ls_numeric_price_duration.
  ///
  /// In en, this message translates to:
  /// **'Enter a numeric price and a duration above zero'**
  String get ls_numeric_price_duration;

  /// No description provided for @ls_skills_label.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get ls_skills_label;

  /// No description provided for @ls_shifts.
  ///
  /// In en, this message translates to:
  /// **'Shifts'**
  String get ls_shifts;

  /// No description provided for @ls_leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get ls_leave;

  /// No description provided for @ls_payable.
  ///
  /// In en, this message translates to:
  /// **'Payable'**
  String get ls_payable;

  /// No description provided for @ls_todays_jobs.
  ///
  /// In en, this message translates to:
  /// **'Today\'s jobs'**
  String get ls_todays_jobs;

  /// No description provided for @ls_documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get ls_documents;

  /// No description provided for @ls_review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get ls_review;

  /// No description provided for @ls_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get ls_active;

  /// No description provided for @ls_active_published.
  ///
  /// In en, this message translates to:
  /// **'Active & Published'**
  String get ls_active_published;

  /// No description provided for @ls_approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get ls_approved;

  /// No description provided for @ls_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get ls_refresh;

  /// No description provided for @ls_labour.
  ///
  /// In en, this message translates to:
  /// **'Labour'**
  String get ls_labour;

  /// No description provided for @ls_parts.
  ///
  /// In en, this message translates to:
  /// **'Parts'**
  String get ls_parts;

  /// No description provided for @ls_submit_quote.
  ///
  /// In en, this message translates to:
  /// **'Submit quote'**
  String get ls_submit_quote;

  /// No description provided for @ls_addon_catalogue.
  ///
  /// In en, this message translates to:
  /// **'Add-on catalogue'**
  String get ls_addon_catalogue;

  /// No description provided for @ls_addon_catalogue_note.
  ///
  /// In en, this message translates to:
  /// **'Add-ons are set by LocalWala and selected by customers at booking.'**
  String get ls_addon_catalogue_note;

  /// No description provided for @ls_reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get ls_reason;

  /// No description provided for @ls_actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get ls_actions;

  /// No description provided for @ls_assignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get ls_assignment;

  /// No description provided for @ls_timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get ls_timeline;

  /// No description provided for @ls_review_subscription.
  ///
  /// In en, this message translates to:
  /// **'Review & Subscription'**
  String get ls_review_subscription;

  /// No description provided for @ls_more_areas.
  ///
  /// In en, this message translates to:
  /// **'Areas'**
  String get ls_more_areas;

  /// No description provided for @ls_more_policies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get ls_more_policies;

  /// No description provided for @ls_more_reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get ls_more_reviews;

  /// No description provided for @ls_more_support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get ls_more_support;

  /// No description provided for @ls_areas_title.
  ///
  /// In en, this message translates to:
  /// **'Service areas'**
  String get ls_areas_title;

  /// No description provided for @ls_city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get ls_city;

  /// No description provided for @ls_radius_km.
  ///
  /// In en, this message translates to:
  /// **'Radius (km)'**
  String get ls_radius_km;

  /// No description provided for @ls_localities.
  ///
  /// In en, this message translates to:
  /// **'Localities'**
  String get ls_localities;

  /// No description provided for @ls_pincodes.
  ///
  /// In en, this message translates to:
  /// **'Pincodes'**
  String get ls_pincodes;

  /// No description provided for @ls_add_locality.
  ///
  /// In en, this message translates to:
  /// **'Add locality'**
  String get ls_add_locality;

  /// No description provided for @ls_add_pincode.
  ///
  /// In en, this message translates to:
  /// **'Add pincode'**
  String get ls_add_pincode;

  /// No description provided for @ls_enter_value.
  ///
  /// In en, this message translates to:
  /// **'Enter a value'**
  String get ls_enter_value;

  /// No description provided for @ls_no_localities.
  ///
  /// In en, this message translates to:
  /// **'No localities added yet'**
  String get ls_no_localities;

  /// No description provided for @ls_no_pincodes.
  ///
  /// In en, this message translates to:
  /// **'No pincodes added yet'**
  String get ls_no_pincodes;

  /// No description provided for @ls_areas_saved.
  ///
  /// In en, this message translates to:
  /// **'Service areas saved'**
  String get ls_areas_saved;

  /// No description provided for @ls_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String ls_save_failed(Object error);

  /// No description provided for @ls_policies_title.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get ls_policies_title;

  /// No description provided for @ls_policies_note.
  ///
  /// In en, this message translates to:
  /// **'These rules apply to your services. Contact support to request a change.'**
  String get ls_policies_note;

  /// No description provided for @ls_no_policies.
  ///
  /// In en, this message translates to:
  /// **'No active policies apply to your services'**
  String get ls_no_policies;

  /// No description provided for @ls_scope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get ls_scope;

  /// No description provided for @ls_scope_platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get ls_scope_platform;

  /// No description provided for @ls_scope_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get ls_scope_category;

  /// No description provided for @ls_scope_subcategory.
  ///
  /// In en, this message translates to:
  /// **'Subcategory'**
  String get ls_scope_subcategory;

  /// No description provided for @ls_scope_service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get ls_scope_service;

  /// No description provided for @ls_scope_provider.
  ///
  /// In en, this message translates to:
  /// **'Your business'**
  String get ls_scope_provider;

  /// No description provided for @ls_policy_cancellation.
  ///
  /// In en, this message translates to:
  /// **'Cancellation'**
  String get ls_policy_cancellation;

  /// No description provided for @ls_policy_reschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get ls_policy_reschedule;

  /// No description provided for @ls_policy_quote_expiry.
  ///
  /// In en, this message translates to:
  /// **'Quote expiry'**
  String get ls_policy_quote_expiry;

  /// No description provided for @ls_policy_booking_window.
  ///
  /// In en, this message translates to:
  /// **'Booking window'**
  String get ls_policy_booking_window;

  /// No description provided for @ls_policy_deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get ls_policy_deposit;

  /// No description provided for @ls_policy_tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get ls_policy_tax;

  /// No description provided for @ls_limit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get ls_limit;

  /// No description provided for @ls_min_notice.
  ///
  /// In en, this message translates to:
  /// **'Min notice'**
  String get ls_min_notice;

  /// No description provided for @ls_reviews_title.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get ls_reviews_title;

  /// No description provided for @ls_no_reviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get ls_no_reviews;

  /// No description provided for @ls_support_title.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get ls_support_title;

  /// No description provided for @ls_no_complaints.
  ///
  /// In en, this message translates to:
  /// **'No support tickets yet'**
  String get ls_no_complaints;

  /// No description provided for @ls_new_ticket.
  ///
  /// In en, this message translates to:
  /// **'New ticket'**
  String get ls_new_ticket;

  /// No description provided for @ls_ticket_reason.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue'**
  String get ls_ticket_reason;

  /// No description provided for @ls_ticket_booking_id.
  ///
  /// In en, this message translates to:
  /// **'Booking ID (optional)'**
  String get ls_ticket_booking_id;

  /// No description provided for @ls_ticket_submitted.
  ///
  /// In en, this message translates to:
  /// **'Ticket submitted'**
  String get ls_ticket_submitted;

  /// No description provided for @ls_ticket_required.
  ///
  /// In en, this message translates to:
  /// **'Please describe the issue'**
  String get ls_ticket_required;

  /// No description provided for @ls_ticket_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit: {error}'**
  String ls_ticket_failed(Object error);

  /// No description provided for @ls_open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get ls_open;

  /// No description provided for @ls_resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get ls_resolved;

  /// No description provided for @ls_setup_publish.
  ///
  /// In en, this message translates to:
  /// **'Set up & publish services'**
  String get ls_setup_publish;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'es', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
