// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Dairy Partner';

  @override
  String get partnerShell => 'Partner';

  @override
  String get deliveryShell => 'Delivery';

  @override
  String get switchRole => 'Switch role';

  @override
  String get switchToDelivery => 'Switch to Delivery';

  @override
  String get switchToPartner => 'Switch to Partner';

  @override
  String get activeRole => 'Active role';

  @override
  String get noOtherRoleAvailable => 'This account has only one role.';

  @override
  String get navHome => 'Home';

  @override
  String get navOrders => 'Orders';

  @override
  String get navSubscriptions => 'Subscriptions';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navProducts => 'Products';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navDrivers => 'Drivers';

  @override
  String get navRuns => 'Runs';

  @override
  String get navEarnings => 'Earnings';

  @override
  String get navAccount => 'Account';

  @override
  String get navManifest => 'Manifest';

  @override
  String get checkingDriverApproval => 'Checking driver approvalâ€¦';

  @override
  String get approvalStatusUnavailable => 'Approval status unavailable';

  @override
  String get applicationNotApproved => 'Application not approved';

  @override
  String get deliveryAccessPaused => 'Delivery access paused';

  @override
  String get waitingOutletApproval => 'Waiting for outlet approval';

  @override
  String get contactOutletOwner =>
      'Contact the outlet owner if you need more information.';

  @override
  String contactOutletToRestore(String outlet) {
    return 'Contact $outlet to restore delivery access.';
  }

  @override
  String profileSubmittedToOutlet(String outlet) {
    return 'Your profile was submitted to $outlet. You can use delivery tools after the owner approves it.';
  }

  @override
  String get checkAgain => 'Check again';

  @override
  String get navScan => 'Scan';

  @override
  String get navRunHistory => 'History';

  @override
  String get todayRuns => 'Today\'s runs';

  @override
  String get noRunAssigned => 'No run assigned for today';

  @override
  String get noRunAssignedHint =>
      'Runs are published nightly from active subscriptions.';

  @override
  String get stop => 'Stop';

  @override
  String get stops => 'Stops';

  @override
  String get sequence => 'Sequence';

  @override
  String get customer => 'Customer';

  @override
  String get slotWindow => 'Slot';

  @override
  String get cans => 'Cans';

  @override
  String get cansToDeliver => 'Cans to deliver';

  @override
  String get items => 'ArtÃƒÂ­culos';

  @override
  String get cansDelivered => 'Envases entregados';

  @override
  String get shortfallReason => 'Motivo del faltante';

  @override
  String get shortfallReasonRequired => 'Ingresa el motivo del faltante.';

  @override
  String get emptyCansToCollect => 'Empty cans to collect';

  @override
  String get amountDue => 'Amount due';

  @override
  String get amountCollected => 'Amount collected';

  @override
  String get paymentMode => 'Payment';

  @override
  String get prepaid => 'Prepaid';

  @override
  String get cashOnDelivery => 'Cash';

  @override
  String get arrived => 'Arrived';

  @override
  String get delivered => 'Delivered';

  @override
  String get skipped => 'Skipped';

  @override
  String get failed => 'Failed';

  @override
  String get pending => 'Pending';

  @override
  String get startRun => 'Start run';

  @override
  String get driverRunLoadHint =>
      'Confirma la cantidad de bidones antes de salir del local.';

  @override
  String get driverCansLoaded => 'Bidones cargados';

  @override
  String get driverEmptyCansForReturn => 'Envases vacÃƒÂ­os para devolver';

  @override
  String get driverEnterValidCanCounts =>
      'Introduce cantidades de envases vÃƒÂ¡lidas y no negativas.';

  @override
  String get driverLoadAtLeastManifest =>
      'Carga al menos la cantidad de envases indicada en esta ruta.';

  @override
  String get driverRunStarted => 'Ruta iniciada';

  @override
  String get driverCouldNotLoadRun => 'No se pudo cargar la ruta de hoy.';

  @override
  String get driverArrivalRecorded => 'Llegada registrada';

  @override
  String get driverMarkArrived => 'Marcar llegada';

  @override
  String get driverDeliveryRecorded => 'Entrega registrada';

  @override
  String get driverStartRunBeforeStops =>
      'Inicia la ruta antes de actualizar sus paradas.';

  @override
  String get driverEmptyCansCollected => 'Envases vacÃƒÂ­os recogidos';

  @override
  String get driverReasonRequired => 'Motivo (obligatorio)';

  @override
  String get driverNavigate => 'Navegar';

  @override
  String get driverAddressUnavailable =>
      'Esta parada no tiene una direcciÃƒÂ³n para navegar.';

  @override
  String get completeRun => 'Complete run';

  @override
  String get nextStop => 'PrÃƒÂ³xima parada';

  @override
  String get openStop => 'Abrir parada';

  @override
  String get allStopsResolved => 'Todas las paradas resueltas';

  @override
  String get callCustomer => 'Llamar';

  @override
  String get amountExceedsDue =>
      'El importe cobrado no puede superar el importe pendiente.';

  @override
  String get captureProof => 'Agregar foto de prueba';

  @override
  String get proofAttached => 'Foto de prueba adjunta';

  @override
  String get proofNotAttached => 'Foto de prueba no adjunta. Reintenta.';

  @override
  String get pickupScan => 'Pickup scan';

  @override
  String get canScanActiveRunRequired =>
      'Start todayâ€™s run from Manifest before scanning cans.';

  @override
  String get canScanSelectStop => 'Select an active customer stop first.';

  @override
  String get canScanAddCode => 'Scan or enter at least one can code.';

  @override
  String get canScanBatchLimit =>
      'Add up to 20 cans, then submit this scan batch.';

  @override
  String get canScanSubmit => 'Save can movements';

  @override
  String canAlreadyScanned(String code) {
    return '$code is already in this batch.';
  }

  @override
  String get canScannerOpen => 'Scan can label';

  @override
  String get canScannerTorch => 'Toggle flashlight';

  @override
  String get canScannerPermission =>
      'Allow camera access in device settings to scan can labels.';

  @override
  String get canScannerUnavailable =>
      'The camera scanner is unavailable on this device.';

  @override
  String get canScannerHint =>
      'Align the canâ€™s QR code or barcode inside the frame.';

  @override
  String get depotReconciliation => 'Depot reconciliation';

  @override
  String get reconciliationBalanced => 'Cans balanced';

  @override
  String get reconciliationShort => 'Cans short';

  @override
  String get reconciliationOver => 'Cans over';

  @override
  String get adjustmentReason => 'Adjustment reason';

  @override
  String get adjustmentReasonHint =>
      'Explain the mismatch before closing the shift.';

  @override
  String syncPending(Object count) {
    return '$count scans waiting to sync';
  }

  @override
  String get syncComplete => 'All scans synced';

  @override
  String get offlineMode => 'Offline';

  @override
  String get commissions => 'Commission';

  @override
  String get settlements => 'Settlements';

  @override
  String get canDeposit => 'Can & deposit';

  @override
  String get reconcile => 'Reconcile';

  @override
  String get inviteDriver => 'Invite driver';

  @override
  String get approve => 'Approve';

  @override
  String get remove => 'Remove';

  @override
  String get loginWithMobile => 'Login with mobile';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get logout => 'Logout';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get serverError => 'Server error';

  @override
  String get notFound => 'Page not found';

  @override
  String get noInternet => 'No internet connection';

  @override
  String get retry => 'Retry';

  @override
  String get verticalPickerTitle => 'Choose your business';

  @override
  String get verticalPickerSubtitle =>
      'You work with more than one business. Pick one to continue.';

  @override
  String get realEstateVendorShell => 'Property vendor';

  @override
  String get realEstateExecutiveShell => 'Property executive';

  @override
  String get realEstateSwitchBusiness => 'Switch business';

  @override
  String get realEstateNavDashboard => 'Dashboard';

  @override
  String get realEstateDashActiveListings => 'Active listings';

  @override
  String get realEstateDashTotalLeads => 'Total leads';

  @override
  String get realEstateDashVisits => 'Visits';

  @override
  String get realEstateDashLiveHolds => 'Live holds';

  @override
  String get realEstateDashSales => 'Sales';

  @override
  String get realEstateDashListingsLeft => 'Listings left';

  @override
  String get realEstateDashUnlimited => 'Unlimited';

  @override
  String get realEstateDashVerificationPending =>
      'Verification pending â€” listings cannot be published yet';

  @override
  String get realEstateNavListings => 'Listings';

  @override
  String get realEstateListingsEmpty => 'No listings here yet';

  @override
  String get realEstateFormNewListing => 'New listing';

  @override
  String get realEstateFormEditListing => 'Edit listing';

  @override
  String get realEstateFormTitle => 'Title';

  @override
  String get realEstateFormDescription => 'Description';

  @override
  String get realEstateFormTransaction => 'Transaction';

  @override
  String get realEstateFormBuy => 'Buy';

  @override
  String get realEstateFormRent => 'Rent';

  @override
  String get realEstateFormPrice => 'Price';

  @override
  String get realEstateFormPriceOnRequest => 'Price on request';

  @override
  String get realEstateFormCategory => 'Category';

  @override
  String get realEstateFormCity => 'City';

  @override
  String get realEstateFormLocality => 'Locality';

  @override
  String get realEstateFormAddress => 'Address';

  @override
  String get realEstateFormPincode => 'Pincode';

  @override
  String get realEstateFormLandmark => 'Landmark';

  @override
  String get realEstateFormLatitude => 'Latitude';

  @override
  String get realEstateFormLongitude => 'Longitude';

  @override
  String get realEstateFormUseMyLocation => 'Use my location';

  @override
  String get realEstateFormSpecs => 'Details';

  @override
  String get realEstateFormAmenities => 'Amenities';

  @override
  String get realEstateFormMedia => 'Photos';

  @override
  String get realEstateFormAddPhotos => 'Add photos';

  @override
  String get realEstateFormCover => 'Cover';

  @override
  String get realEstateFormSave => 'Save listing';

  @override
  String get realEstateFormProject => 'Project';

  @override
  String get realEstateFormBuilder => 'Builder';

  @override
  String get realEstateDetailSubmit => 'Submit for review';

  @override
  String get realEstateDetailResubmit => 'Resubmit for review';

  @override
  String get realEstateDetailWithdraw => 'Withdraw';

  @override
  String get realEstateDetailArchive => 'Archive listing';

  @override
  String get realEstateDetailEdit => 'Edit';

  @override
  String get realEstateDetailDocuments => 'Documents';

  @override
  String get realEstateDetailTimeline => 'Timeline';

  @override
  String get realEstateDetailConfirm => 'Confirm';

  @override
  String get realEstateDetailCancel => 'Cancel';

  @override
  String get realEstateDetailSubmitNote =>
      'Submitting consumes one listing entitlement.';

  @override
  String get realEstateNavLeads => 'Leads';

  @override
  String get realEstateLeadsEmpty => 'No leads here yet';

  @override
  String get realEstateLeadDetailCustomer => 'Customer';

  @override
  String get realEstateLeadDetailProperty => 'Property';

  @override
  String get realEstateLeadDetailExecutive => 'Executive';

  @override
  String get realEstateLeadDetailAssigned => 'Assigned';

  @override
  String get realEstateLeadDetailUnassigned => 'Unassigned';

  @override
  String get realEstateLeadDetailFollowUps => 'Follow-ups';

  @override
  String get realEstateLeadDetailHold => 'Hold';

  @override
  String get realEstateLeadDetailSale => 'Sale';

  @override
  String get realEstateLeadDetailLoan => 'Loan';

  @override
  String get realEstateLeadDetailNoLoan => 'No loan request';

  @override
  String get realEstateLeadDetailActivity => 'Activity';

  @override
  String get realEstateLeadDetailSource => 'Source';

  @override
  String get realEstateNavVisits => 'Visits';

  @override
  String get realEstateVisitsEmpty => 'No visits scheduled yet';

  @override
  String get realEstateCustomersEmpty => 'No customers yet';

  @override
  String get realEstateNavPackages => 'Packages';

  @override
  String get realEstatePackagesEmpty => 'No packages available right now';

  @override
  String get realEstatePackagesPopular => 'Popular';

  @override
  String get realEstatePackagesBuy => 'Buy';

  @override
  String get realEstatePackagesUnlimited => 'Unlimited listings';

  @override
  String get realEstatePackagesActiveCount => 'Active packages';

  @override
  String get realEstateCheckoutTitle => 'Checkout';

  @override
  String get realEstateCheckoutConfirm => 'Confirm purchase';

  @override
  String get realEstateCheckoutOrderPlaced => 'Order placed';

  @override
  String get realEstateCheckoutPending =>
      'Complete payment to activate this package';

  @override
  String get realEstateCheckoutPayNow => 'Pay now';

  @override
  String get realEstateCheckoutPaid => 'Payment successful';

  @override
  String get realEstateCheckoutStatus => 'Status';

  @override
  String get realEstateCheckoutDone => 'Done';

  @override
  String get realEstateNavPayments => 'Payments';

  @override
  String get realEstatePaymentsEmpty => 'No payments yet';

  @override
  String get realEstatePaymentsCancel => 'Cancel order';

  @override
  String get realEstateNavDocuments => 'Documents';

  @override
  String get realEstateNavAnalytics => 'Analytics';

  @override
  String get realEstateNavCommissions => 'Commissions';

  @override
  String get realEstateDocumentsProperty => 'Property';

  @override
  String get realEstateDocumentsPickHint =>
      'Select a property to see its documents';

  @override
  String get realEstateDocumentsEmpty => 'No documents for this property';

  @override
  String get realEstateCommissionsEmpty => 'No commissions yet';

  @override
  String get realEstateFilterAll => 'All';

  @override
  String get realEstateNavSupport => 'Support';

  @override
  String get realEstateNavProfile => 'Profile';

  @override
  String get realEstateProfileVerification => 'Verification';

  @override
  String get realEstateProfileSubmit => 'Submit for review';

  @override
  String get realEstateSupportT1 => 'Publishing a listing';

  @override
  String get realEstateSupportB1 =>
      'Submit your KYC, buy a package, create the listing and submit it for review.';

  @override
  String get realEstateSupportT2 => 'Payment issues';

  @override
  String get realEstateSupportB2 =>
      'Pending package orders can be cancelled from Payments. Paid orders grant entitlements instantly.';

  @override
  String get realEstateSupportT3 => 'Verification rejected?';

  @override
  String get realEstateSupportB3 =>
      'Check the reason on your Profile, fix the documents and submit again.';

  @override
  String get storesNavHome => 'Inicio';

  @override
  String get storesNavOrders => 'Pedidos';

  @override
  String get storesNavStock => 'Inventario';

  @override
  String get storesNavCatalogue => 'CatÃƒÂ¡logo';

  @override
  String get storesNavDrivers => 'Repartidores';

  @override
  String get storesNavPostsale => 'Posventa';

  @override
  String get storesNavAccount => 'Cuenta';

  @override
  String get storesNavDeliveries => 'Entregas';

  @override
  String get storesNavEarnings => 'Ganancias';

  @override
  String get storesTitleStore => 'Tienda';

  @override
  String get storesTitleOrders => 'Pedidos';

  @override
  String get storesTitleStock => 'Inventario';

  @override
  String get storesTitleCatalogue => 'CatÃƒÂ¡logo';

  @override
  String get storesTitleDrivers => 'Repartidores';

  @override
  String get storesTitlePostsale => 'Posventa';

  @override
  String get storesTitleSubscription => 'SuscripciÃƒÂ³n';

  @override
  String get storesTitleSupport => 'Soporte';

  @override
  String get storesTitleFeatured => 'Destacados';

  @override
  String get storesTitleTeam => 'Equipo';

  @override
  String get storesTitlePromotions => 'Promociones';

  @override
  String get storesTitleWarranty => 'GarantÃƒÂ­a';

  @override
  String get storesTitleDeliveries => 'Entregas';

  @override
  String get storesTitleEarnings => 'Ganancias';

  @override
  String get storesTitleOutlets => 'Tus puntos de venta';

  @override
  String get storesTitleOnboarding => 'Nueva tienda';

  @override
  String get storesTabReturns => 'Devoluciones';

  @override
  String get storesTabSettlements => 'Liquidaciones';

  @override
  String get storesTitleNewStore => 'Nueva tienda';

  @override
  String get storesTitlePickList => 'Lista de picking';

  @override
  String get storesTitleAdvance => 'Adelanto';

  @override
  String get storesActionSave => 'Guardar';

  @override
  String get storesActionCancel => 'Cancelar';

  @override
  String get storesActionSubmit => 'Enviar';

  @override
  String get storesActionRefresh => 'Actualizar';

  @override
  String get storesActionClose => 'Cerrar';

  @override
  String get storesActionEdit => 'Editar';

  @override
  String get storesActionAdd => 'AÃƒÂ±adir';

  @override
  String get storesActionVerify => 'Verificar';

  @override
  String get storesActionReject => 'Rechazar';

  @override
  String get storesActionNext => 'Siguiente';

  @override
  String get storesActionBack => 'AtrÃƒÂ¡s';

  @override
  String get storesActionApply => 'Aplicar';

  @override
  String get storesActionCreate => 'Crear';

  @override
  String get storesActionRetry => 'Reintentar';

  @override
  String get storesFieldSearchProducts => 'Buscar productos';

  @override
  String get storesFieldCartAmount => 'Importe del carrito';

  @override
  String get storesFieldCode => 'CÃƒÂ³digo';

  @override
  String get storesFieldCodeOptional => 'CÃƒÂ³digo (opcional)';

  @override
  String get storesFieldNameRequired => 'Nombre (obligatorio)';

  @override
  String get storesFieldOtp => 'OTP';

  @override
  String get storesFieldPackageCount => 'NÃƒÂºmero de paquetes';

  @override
  String get storesFieldQuantity => 'Cantidad';

  @override
  String get storesFieldReason => 'Motivo';

  @override
  String get storesFieldReasonRequired => 'Motivo (obligatorio)';

  @override
  String get storesFieldSubstituteVariant => 'ID de variante sustituta';

  @override
  String get storesFieldWeightGrams => 'Peso total (gramos)';

  @override
  String get storesFieldValueRequired => 'Valor (obligatorio)';

  @override
  String get storesDialogAdjustStock => 'Ajustar stock';

  @override
  String get storesDialogCustomerHandover => 'Entrega al cliente';

  @override
  String get storesDialogCompletePacking => 'Completar empaque';

  @override
  String get storesDialogNewPromotion => 'Nueva promociÃƒÂ³n';

  @override
  String get storesDialogRejectPlacement => 'Rechazar ubicaciÃƒÂ³n';

  @override
  String get storesDialogReportFailure => 'Informar de un fallo';

  @override
  String get storesDialogSubstituteItem => 'ArtÃƒÂ­culo sustituto';

  @override
  String storesOrderNumber(String number) {
    return 'Pedido nÃ‚Âº $number';
  }

  @override
  String storesSettlementNumber(String number) {
    return 'LiquidaciÃƒÂ³n nÃ‚Âº $number';
  }

  @override
  String storesWizardStep(int current, int total, String label) {
    return 'Paso $current de $total: $label';
  }

  @override
  String storesNowWorkingIn(String name) {
    return 'Ahora trabaja en $name';
  }

  @override
  String storesVariantAxes(String axes, int limit) {
    return 'Ejes de variantes: $axes (mÃƒÂ¡x. $limit combinaciones)';
  }

  @override
  String get storesFallbackProduct => 'Producto';

  @override
  String get storesFallbackDriver => 'Repartidor';

  @override
  String get storesFallbackMember => 'Miembro';

  @override
  String get storesFallbackClaim => 'ReclamaciÃƒÂ³n';

  @override
  String get storesFallbackComplaint => 'Queja';

  @override
  String get storesFallbackOutlet => 'Punto de venta';

  @override
  String get storesFallbackReturn => 'DevoluciÃƒÂ³n';

  @override
  String get storesFallbackItem => 'ArtÃƒÂ­culo';

  @override
  String get storesFallbackPlacement => 'UbicaciÃƒÂ³n';

  @override
  String get storesNavMore => 'MÃƒÂ¡s';

  @override
  String get storesTitlePayments => 'Pagos';

  @override
  String get storesTitleManualOrder => 'Venta en mostrador';

  @override
  String get storesManualEntryDisabled =>
      'Los pedidos nuevos estÃƒÂ¡n en pausa para este estado de suscripciÃƒÂ³n.';

  @override
  String get storesActionPlaceOrder => 'Realizar pedido';

  @override
  String get storesBannerSubscriptionPastDue =>
      'El pago de la suscripciÃƒÂ³n estÃƒÂ¡ vencido Ã¢â‚¬â€ liquide para seguir recibiendo pedidos nuevos.';

  @override
  String get storesBannerSubscriptionGracePeriod =>
      'La suscripciÃƒÂ³n estÃƒÂ¡ en periodo de gracia Ã¢â‚¬â€ los pedidos nuevos quedarÃƒÂ¡n pausados hasta reanudar el pago.';

  @override
  String get storesBannerSubscriptionSuspended =>
      'SuscripciÃƒÂ³n suspendida Ã¢â‚¬â€ atienda los pedidos existentes y liquide; los pedidos nuevos estÃƒÂ¡n bloqueados.';

  @override
  String get realEstateExecAccept => 'Accept';

  @override
  String get realEstateExecAccepted => 'Accepted';

  @override
  String get realEstateExecActiveLeads => 'Active leads';

  @override
  String get realEstateExecAddNotes => 'Add notes';

  @override
  String get realEstateExecAllowedRadius => 'Allowed radius';

  @override
  String get realEstateExecApplications => 'Applications';

  @override
  String get realEstateExecAssigned => 'Assigned';

  @override
  String get realEstateExecAvailable => 'Available';

  @override
  String get realEstateExecBaseAmount => 'Base amount';

  @override
  String get realEstateExecCancellationReason => 'Cancellation reason';

  @override
  String get realEstateExecCancelled => 'Cancelled';

  @override
  String get realEstateExecCancelVisitReason =>
      'Cancel visit â€” reason required';

  @override
  String get realEstateExecCheckedIn => 'Checked in';

  @override
  String get realEstateExecCheckIn => 'Check in';

  @override
  String get realEstateExecClose => 'Close';

  @override
  String get realEstateExecCommissions => 'Commissions';

  @override
  String get realEstateExecCommissionsEmpty => 'No commissions yet';

  @override
  String get realEstateExecComplete => 'Complete';

  @override
  String get realEstateExecCompleted => 'Completed';

  @override
  String get realEstateExecCompleteVisit => 'Complete visit';

  @override
  String get realEstateExecCouldNotMarkRead => 'Could not mark read';

  @override
  String get realEstateExecCustomers => 'Customers';

  @override
  String get realEstateExecDate => 'Date';

  @override
  String get realEstateExecDisbursedAmount => 'Disbursed amount';

  @override
  String get realEstateExecDistance => 'Distance';

  @override
  String get realEstateExecDone => 'Done';

  @override
  String get realEstateExecEarnings => 'Earnings';

  @override
  String get realEstateExecEmployment => 'Employment';

  @override
  String get realEstateExecFollowUp => 'Follow-up';

  @override
  String get realEstateExecGross => 'Gross';

  @override
  String get realEstateExecHoldPrincipal => 'Hold principal applied';

  @override
  String get realEstateExecInProgress => 'In progress';

  @override
  String get realEstateExecInterestRate => 'Interest rate';

  @override
  String get realEstateExecLatestEarnings => 'Latest earnings';

  @override
  String get realEstateExecLatestHolds => 'Latest holds on my leads';

  @override
  String get realEstateExecLatestLoan => 'Latest loan';

  @override
  String realEstateExecLeadCount(int count) {
    return 'Leads: $count';
  }

  @override
  String get realEstateExecLeadNotFound => 'Lead not found.';

  @override
  String realEstateExecLeadSummary(int visits, int followUps) {
    return 'Visits: $visits Â· Follow-ups: $followUps';
  }

  @override
  String get realEstateExecLoanNotFound => 'Loan not found.';

  @override
  String get realEstateExecLoans => 'Loans';

  @override
  String get realEstateExecLoansEmpty => 'No loans yet';

  @override
  String get realEstateExecLocating => 'Locatingâ€¦';

  @override
  String get realEstateExecLocationPermissionCheckIn =>
      'Location permission is required for check-in.';

  @override
  String get realEstateExecLocationPermissionRequired =>
      'Location permission is required.';

  @override
  String get realEstateExecLocationUnavailable =>
      'Location unavailable. Move to an open area and try again.';

  @override
  String get realEstateExecLocationUpdated => 'Location updated.';

  @override
  String get realEstateExecLocationUpdateFailed => 'Could not update location.';

  @override
  String get realEstateExecMarkRead => 'Mark read';

  @override
  String get realEstateExecMobile => 'Mobile';

  @override
  String get realEstateExecMonthlyIncome => 'Monthly income';

  @override
  String get realEstateExecName => 'Name';

  @override
  String get realEstateExecNo => 'No';

  @override
  String get realEstateExecNoApplications => 'No bank applications yet.';

  @override
  String get realEstateExecNoHolds => 'No holds yet.';

  @override
  String get realEstateExecNoLeadsAssigned => 'No leads assigned yet.';

  @override
  String get realEstateExecNoNotifications => 'No notifications.';

  @override
  String get realEstateExecNoPendingFollowUps => 'No pending follow-ups.';

  @override
  String get realEstateExecNotes => 'Notes';

  @override
  String get realEstateExecNotesOptional => 'Notes (optional)';

  @override
  String get realEstateExecNotification => 'Notification';

  @override
  String get realEstateExecNotifications => 'Notifications';

  @override
  String get realEstateExecNoVisitsAssigned => 'No visits assigned yet.';

  @override
  String get realEstateExecNoVisitsState => 'No visits in this state.';

  @override
  String get realEstateExecOffer => 'Offer';

  @override
  String get realEstateExecOffers => 'Offers';

  @override
  String get realEstateExecOutsideRadius =>
      'Move closer to the property to check in.';

  @override
  String get realEstateExecPayoutReference => 'Payout reference';

  @override
  String get realEstateExecPeriod => 'Period';

  @override
  String get realEstateExecQuickLinks => 'Quick links';

  @override
  String get realEstateExecRate => 'Rate';

  @override
  String get realEstateExecReasonDetailHint =>
      'Reason detail (required for OTHER)';

  @override
  String get realEstateExecReasonDetailRequired =>
      'Reason detail is required for OTHER.';

  @override
  String get realEstateExecReasonRequiredCancel =>
      'A reason is required to cancel.';

  @override
  String get realEstateExecRecord => 'Record';

  @override
  String get realEstateExecRecordInterest => 'Record interest';

  @override
  String get realEstateExecRejectionReason => 'Rejection reason';

  @override
  String get realEstateExecRequestedAmount => 'Requested amount';

  @override
  String get realEstateExecSaleNotFound => 'Sale not found.';

  @override
  String get realEstateExecSales => 'Sales';

  @override
  String get realEstateExecSalesEmpty => 'No sales yet';

  @override
  String get realEstateExecSaleValue => 'Sale value';

  @override
  String get realEstateExecSanctionedAmount => 'Sanctioned amount';

  @override
  String get realEstateExecSchedule => 'Schedule';

  @override
  String get realEstateExecScheduleFollowUp => 'Schedule follow-up';

  @override
  String get realEstateExecSettlements => 'Settlements';

  @override
  String get realEstateExecSettlementsEmpty => 'No settlements yet';

  @override
  String get realEstateExecSoldOn => 'Sold on';

  @override
  String get realEstateExecSubmit => 'Submit';

  @override
  String get realEstateExecTds => 'TDS';

  @override
  String get realEstateExecTenure => 'Tenure';

  @override
  String get realEstateExecTotalVisits => 'Total visits';

  @override
  String get realEstateExecTransaction => 'Transaction';

  @override
  String get realEstateExecTypeHere => 'Type here';

  @override
  String get realEstateExecUnscheduled => 'unscheduled';

  @override
  String get realEstateExecUpdateLocation => 'Update location';

  @override
  String get realEstateExecVisitsByStatus => 'Visits by status';

  @override
  String get realEstateExecWithinRadius =>
      'You are within the check-in radius.';

  @override
  String get realEstateExecYes => 'Yes';

  @override
  String get jhatkaDidNotGoThrough => 'That did not go through. Retry.';

  @override
  String get jhatkaRetryDidNotGoThrough => 'Retry did not go through.';

  @override
  String get jhatkaPhotoNotAttached => 'Photo not attached. Retry.';

  @override
  String get jhatkaWeighingFailed =>
      'Weighing failed. Check the scale and retry.';

  @override
  String get jhatkaSearchFailed => 'Search failed. Retry.';

  @override
  String get jhatkaRecallOpenFailed => 'Recall did not open. Retry.';

  @override
  String get jhatkaCloseFailed =>
      'Close failed â€” the fan-out may be incomplete. Retry.';

  @override
  String get jhatkaPodCaptureFailed => 'POD capture failed. Retry.';

  @override
  String get jhatkaPodCaptured => 'POD captured and persisted.';

  @override
  String get jhatkaCouldNotLoadDelivery => 'Could not load delivery.';

  @override
  String get jhatkaProofPhotoAttached => 'Proof photo attached.';

  @override
  String get jhatkaAlreadyWeighed =>
      'Already weighed â€” showing the saved confirmation';

  @override
  String get jhatkaReasonRequired => 'A reason is required.';

  @override
  String get jhatkaReasonRequiredCustomer =>
      'A reason is required â€” the customer reads it.';

  @override
  String get jhatkaClientRefRequired => 'Client ref is required.';

  @override
  String get jhatkaClientRefRequiredFirst => 'Client ref is required first.';

  @override
  String get jhatkaInvalidPaise => 'Enter a valid paise amount.';

  @override
  String get jhatkaBothDatesRequired => 'Both period dates are required.';

  @override
  String get jhatkaCodeNameValueRequired =>
      'Code, name and a numeric value are required.';

  @override
  String get jhatkaTypeAndBpsRequired => 'Type and a bps rate are required.';

  @override
  String get jhatkaTypeTwoChars => 'Type at least 2 characters.';

  @override
  String get jhatkaPickVariantAndPrice => 'Pick a variant and a valid price.';

  @override
  String get jhatkaPickAtLeastOneVariant => 'Pick at least one variant.';

  @override
  String get jhatkaPickCustomerFirst => 'Pick the customer from search first.';

  @override
  String get jhatkaLineMissingVariant =>
      'A line is missing its variant â€” cannot save.';

  @override
  String get jhatkaNothingToSave => 'Nothing to save.';

  @override
  String get jhatkaNavOrders => 'Jhatka orders';

  @override
  String get jhatkaNavCataloguePrices => 'Catalogue & prices';

  @override
  String get jhatkaNavProcurement => 'Procurement';

  @override
  String get jhatkaNavCompliance => 'Compliance';

  @override
  String get jhatkaNavFleet => 'Fleet';

  @override
  String get jhatkaNavLabels => 'Labels';

  @override
  String get jhatkaNavMoney => 'Money';

  @override
  String get jhatkaNavRider => 'Rider';

  @override
  String get jhatkaNavWastage => 'Wastage';

  @override
  String get jhatkaNavMyDeliveries => 'My deliveries';

  @override
  String get jhatkaCatalogueUnavailable => 'Catalogue unavailable';

  @override
  String get jhatkaComplianceUnavailable => 'Compliance unavailable';

  @override
  String get jhatkaDeliveriesUnavailable => 'Deliveries unavailable';

  @override
  String get jhatkaDeliveryUnavailable => 'Delivery unavailable';

  @override
  String get jhatkaEarningsUnavailable => 'Earnings unavailable';

  @override
  String get jhatkaFleetUnavailable => 'Fleet unavailable';

  @override
  String get jhatkaInventoryUnavailable => 'Inventory unavailable';

  @override
  String get jhatkaLabelsUnavailable => 'Labels unavailable';

  @override
  String get jhatkaMoneyUnavailable => 'Money unavailable';

  @override
  String get jhatkaOrderUnavailable => 'Order unavailable';

  @override
  String get jhatkaOrdersUnavailable => 'Orders unavailable';

  @override
  String get jhatkaProcurementUnavailable => 'Procurement unavailable';

  @override
  String get jhatkaSubscriptionsUnavailable => 'Subscriptions unavailable';

  @override
  String get jhatkaNoCounters => 'No counters on this login.';

  @override
  String get jhatkaNoLabels => 'No labels';

  @override
  String get jhatkaNoOrders => 'No orders';

  @override
  String get jhatkaNoSubscriptions => 'No subscriptions';

  @override
  String get jhatkaNoSubscribableVariants =>
      'No subscribable variants in the catalogue.';

  @override
  String get jhatkaNoVariantsToPrice => 'No variants to price yet.';

  @override
  String get jhatkaNothingAssigned => 'Nothing assigned';

  @override
  String get jhatkaNothingLeftToDo => 'Nothing left to do here.';

  @override
  String get jhatkaActionAddLine => 'Add line';

  @override
  String get jhatkaActionAdjust => 'Adjust';

  @override
  String get jhatkaActionApproveActivate => 'Approve & activate';

  @override
  String get jhatkaActionCancelSubscription => 'Cancel subscription';

  @override
  String get jhatkaActionCapturePod => 'Capture POD (persist)';

  @override
  String get jhatkaActionCreatePromotion => 'Create promotion';

  @override
  String get jhatkaActionCreateRule => 'Create rule';

  @override
  String get jhatkaActionDeliver => 'Deliver';

  @override
  String get jhatkaActionEditOutletProfile => 'Edit outlet profile';

  @override
  String get jhatkaActionEditQuantities => 'Edit quantities';

  @override
  String get jhatkaActionFailDelivery => 'Fail delivery';

  @override
  String get jhatkaActionGenerate => 'Generate';

  @override
  String get jhatkaActionGenerateLabels => 'Generate pack labels';

  @override
  String get jhatkaActionKeepIt => 'Keep it';

  @override
  String get jhatkaActionManagerOverride => 'Manager override';

  @override
  String get jhatkaActionMarkReady => 'Mark ready';

  @override
  String get jhatkaActionNewOverride => 'New price override';

  @override
  String get jhatkaActionNewReceipt => 'New receipt';

  @override
  String get jhatkaActionNewSubscription => 'New subscription';

  @override
  String get jhatkaActionOpenRecall => 'Open recall';

  @override
  String get jhatkaActionPackDispatch => 'Pack & dispatch';

  @override
  String get jhatkaActionPause => 'Pause';

  @override
  String get jhatkaActionPauseSubscription => 'Pause subscription';

  @override
  String get jhatkaActionPay => 'Pay';

  @override
  String get jhatkaActionPlace => 'Place';

  @override
  String get jhatkaActionPost => 'Post';

  @override
  String get jhatkaActionPrint => 'Print';

  @override
  String get jhatkaActionQuarantine => 'Quarantine';

  @override
  String get jhatkaActionQuarantineBatch =>
      'Quarantine batch â€” reason required';

  @override
  String get jhatkaActionRecallNotify => 'Recall â€” notify customers';

  @override
  String get jhatkaActionRecordAdjustWastage => 'Record adjust / wastage';

  @override
  String get jhatkaActionRecordStockMove => 'Record stock move';

  @override
  String get jhatkaActionRejectOrder => 'Reject order';

  @override
  String get jhatkaActionRejectWithReason => 'Reject with reason';

  @override
  String get jhatkaActionRelease => 'Release';

  @override
  String get jhatkaActionReleaseBatch => 'Release batch â€” reason required';

  @override
  String get jhatkaActionRemoveLine => 'Remove line';

  @override
  String get jhatkaActionReset => 'Reset';

  @override
  String get jhatkaActionRespond => 'Respond';

  @override
  String get jhatkaActionRespondComplaint => 'Respond to complaint';

  @override
  String get jhatkaActionRespondReview => 'Respond to review (once only)';

  @override
  String get jhatkaActionRetryCharge => 'Retry charge';

  @override
  String get jhatkaActionRevoke => 'Revoke';

  @override
  String get jhatkaActionSaveQuantities => 'Save quantities';

  @override
  String get jhatkaActionSearch => 'Search';

  @override
  String get jhatkaActionSend => 'Send';

  @override
  String get jhatkaActionSet => 'Set';

  @override
  String get jhatkaActionSkipNext => 'Skip next';

  @override
  String get jhatkaActionSubmitForApproval => 'Submit for approval';

  @override
  String get jhatkaActionSwitchCounter => 'Switch counter';

  @override
  String get jhatkaActionVoid => 'Void';

  @override
  String get jhatkaActionVoidLabel => 'Void label';

  @override
  String get jhatkaActionWeighOrder => 'Weigh order';

  @override
  String get jhatkaFieldActualWeightGrams => 'Actual weight (grams)';

  @override
  String get jhatkaFieldAmountPaise => 'Amount (paise)';

  @override
  String get jhatkaFieldCodCollectedPaise => 'COD collected (paise)';

  @override
  String get jhatkaFieldCause => 'Cause';

  @override
  String get jhatkaFieldClientRef => 'Client ref (required, idempotency key)';

  @override
  String get jhatkaFieldCode => 'Code (unique per outlet)';

  @override
  String get jhatkaFieldDeliveredTemp => 'Delivered temp Â°C';

  @override
  String get jhatkaFieldEmail => 'Email';

  @override
  String get jhatkaFieldExpiryDate => 'Expiry (yyyy-mm-dd)';

  @override
  String get jhatkaFieldFromDate => 'From (yyyy-mm-dd)';

  @override
  String get jhatkaFieldLicenceNumber => 'Licence number';

  @override
  String get jhatkaFieldMessageRequired => 'Message (required)';

  @override
  String get jhatkaFieldMovementType => 'Movement type';

  @override
  String get jhatkaFieldNameOrPhone =>
      'Name or phone (this outletâ€™s customers)';

  @override
  String get jhatkaFieldNoteOptional => 'Note (optional)';

  @override
  String get jhatkaFieldOtpOptional => 'OTP (if required)';

  @override
  String get jhatkaFieldOutletName => 'Outlet name';

  @override
  String get jhatkaFieldPackingTemp => 'Packing temp Â°C (optional)';

  @override
  String get jhatkaFieldPeriodEnd => 'Period end (yyyy-mm-dd)';

  @override
  String get jhatkaFieldPeriodStart => 'Period start (yyyy-mm-dd)';

  @override
  String get jhatkaFieldPhone => 'Phone';

  @override
  String get jhatkaFieldPoOptional => 'Purchase order (optional)';

  @override
  String get jhatkaFieldPricePerUnit => 'Price per unit (Rs)';

  @override
  String get jhatkaFieldRateBps => 'Rate (basis points)';

  @override
  String get jhatkaFieldRawSku => 'Raw SKU';

  @override
  String get jhatkaFieldReasonOptional => 'Reason (optional)';

  @override
  String get jhatkaFieldReasonCustomer =>
      'Reason (required â€” the customer reads this)';

  @override
  String get jhatkaFieldReasonOutlet =>
      'Reason (required â€” the outlet reads this)';

  @override
  String get jhatkaFieldReasonShown => 'Reason (shown to the customer)';

  @override
  String get jhatkaFieldReasonMin10 => 'Reason, at least 10 characters';

  @override
  String get jhatkaFieldReceivedQty => 'Received qty';

  @override
  String get jhatkaFieldReceiverName => 'Receiver name';

  @override
  String get jhatkaFieldRepeats => 'Repeats';

  @override
  String get jhatkaFieldSeverity => 'Severity';

  @override
  String get jhatkaFieldSupplier => 'Supplier';

  @override
  String get jhatkaFieldSupplierInvoiceRef => 'Supplier invoice ref (optional)';

  @override
  String get jhatkaFieldToDate => 'To (yyyy-mm-dd)';

  @override
  String get jhatkaFieldType => 'Type';

  @override
  String get jhatkaFieldUnit => 'Unit';

  @override
  String get jhatkaFieldUnitPriceFrozen => 'Unit price (Rs, frozen at intake)';

  @override
  String get jhatkaFieldVariant => 'Variant';

  @override
  String get jhatkaFieldVehicleNo => 'Vehicle no (optional)';

  @override
  String get jhatkaSeverityAdvisory => 'Advisory â€” in-house';

  @override
  String get jhatkaSeverityWithdraw => 'Withdraw â€” pull from sale';

  @override
  String get jhatkaAwaitingResponse => 'Awaiting response â€” one only';

  @override
  String get jhatkaBlankUnchanged => 'Blank fields are left unchanged.';

  @override
  String get jhatkaDraftOverride => 'Draft override';

  @override
  String get jhatkaFlatAmountOff => 'Flat amount off';

  @override
  String get jhatkaPercentOff => 'Percent off';

  @override
  String get jhatkaFragile => 'Fragile';

  @override
  String get jhatkaGrossCollected => 'Gross collected';

  @override
  String get jhatkaLowStockOnly => 'Low stock only';

  @override
  String get jhatkaStockLine => 'Stock line';

  @override
  String get jhatkaToday => 'Today';

  @override
  String get jhatkaWalkInNoPo => 'Walk-in, no PO';

  @override
  String get jhatkaRefunded => 'Refunded';

  @override
  String get jhatkaResponded => 'Responded';

  @override
  String get jhatkaEstimatedMinusRefunds => 'estimated minus refunds';

  @override
  String get jhatkaEveryRefundIsDocument => 'every refund is a document';

  @override
  String get jhatkaInWindow => 'in the window';

  @override
  String get jhatkaStatusActive => 'active';

  @override
  String get jhatkaStatusInactive => 'inactive';

  @override
  String get jhatkaStatusSuspended => 'suspended';

  @override
  String get jhatkaStatusExpired => 'expired';

  @override
  String get jhatkaStatusPaid => 'paid';

  @override
  String get jhatkaStatusAwaitingPayment => 'awaiting payment';

  @override
  String get jhatkaStatusLow => 'low';

  @override
  String get jhatkaStatusSkippedCredited => 'skipped Â· credited';

  @override
  String jhatkaVariantCount(Object count) {
    return '$count variant(s)';
  }

  @override
  String jhatkaResponsesOnRecord(Object count) {
    return '$count response(s) on record';
  }

  @override
  String jhatkaStageLabel(Object value) {
    return 'Stage: $value';
  }

  @override
  String jhatkaFssaiLabel(Object value) {
    return 'FSSAI: $value';
  }

  @override
  String jhatkaForLabel(Object value) {
    return 'For: $value';
  }

  @override
  String jhatkaWastageRecords(Object count) {
    return '$count record(s)';
  }

  @override
  String jhatkaDeliveryNo(Object value) {
    return 'Delivery $value';
  }

  @override
  String get jhatkaActionResume => 'Resume';

  @override
  String get jhatkaFieldStarts => 'Starts';

  @override
  String jhatkaCollectCollected(Object collect, Object collected) {
    return 'Collect $collect Â· collected ${collect}ed';
  }

  @override
  String jhatkaReceiverLabel(Object value) {
    return 'Receiver $value';
  }

  @override
  String jhatkaDeliveryStatus(Object no, Object status) {
    return 'Delivery $no Â· $status';
  }

  @override
  String jhatkaCodLabel(Object value) {
    return 'COD: $value';
  }

  @override
  String jhatkaOrderNoLabel(Object no) {
    return 'Order #$no';
  }

  @override
  String jhatkaLabelNo(Object no) {
    return 'Label $no';
  }

  @override
  String get jhatkaFieldPack => 'Pack';

  @override
  String get jhatkaFieldNet => 'Net';

  @override
  String get jhatkaFieldPackedOn => 'Packed on';

  @override
  String get jhatkaFieldUseBy => 'Use by';

  @override
  String get jhatkaActionHandOver => 'Hand over at counter';

  @override
  String get jhatkaPickupOrderNote =>
      'Pickup order â€” the customer collects here. No rider is dispatched.';

  @override
  String get jhatkaSupplyTitle => 'Request stock';

  @override
  String get jhatkaSupplyLoadFailed => 'Could not load supply. Retry.';

  @override
  String get jhatkaSupplyPickItems => 'Enter at least one quantity.';

  @override
  String get jhatkaSupplySubmitFailed =>
      'The request did not go through. Retry.';

  @override
  String get jhatkaSupplySubmitted =>
      'Request sent â€” LocalWala will approve and deliver.';

  @override
  String get jhatkaSupplyPayFailed => 'Payment could not start. Retry.';

  @override
  String get jhatkaSupplyModePrepaid => 'Prepay now';

  @override
  String get jhatkaSupplyModeOnDelivery => 'Pay on delivery';

  @override
  String get jhatkaSupplyModeDeduct => 'Deduct from payout';

  @override
  String get jhatkaSupplyLedgerBalance => 'Prepaid balance';

  @override
  String get jhatkaSupplyNewRequest => 'New stock request';

  @override
  String get jhatkaSupplyQtyKg => 'kg';

  @override
  String get jhatkaSupplyPaymentMode => 'Payment mode';

  @override
  String get jhatkaSupplyNeededBy => 'Needed by';

  @override
  String get jhatkaSupplySubmit => 'Submit request';

  @override
  String get jhatkaSupplyHistory => 'My requests';

  @override
  String get jhatkaSupplyNoRequests => 'No stock requests yet.';

  @override
  String get jhatkaSupplyPay => 'Pay';

  @override
  String get jhatkaAreaTitle => 'Delivery area';

  @override
  String get jhatkaAreaCeiling => 'Platform ceiling:';

  @override
  String get jhatkaAreaFreeRing => 'Free within';

  @override
  String get jhatkaAreaPaidRing => 'Paid band';

  @override
  String get jhatkaAreaNoOuterBand => 'No paid band';

  @override
  String get jhatkaAreaFee => 'Flat fee (â‚¹)';

  @override
  String get jhatkaAreaReason => 'Why this change?';

  @override
  String get jhatkaAreaSubmit => 'Request area change';

  @override
  String get jhatkaAreaSubmitted =>
      'Area change requested â€” LocalWala will review.';

  @override
  String get jhatkaAreaSubmitFailed =>
      'That did not go through. Check the ceiling and retry.';

  @override
  String get jhatkaAreaPending => 'Awaiting approval';

  @override
  String get jhatkaAreaWithdraw => 'Withdraw';

  @override
  String get jhatkaAreaWithdrawn => 'Request withdrawn.';

  @override
  String get jhatkaAreaDirect =>
      'Your delivery area is configured by LocalWala.';

  @override
  String get jhatkaAreaInvalidNumbers =>
      'Enter valid numbers for the rings and the fee.';

  @override
  String get jhatkaAreaFeeRequired => 'A paid band needs a fee above zero.';

  @override
  String get jhatkaAreaReasonRequired => 'Say why â€” the admin reads it.';

  @override
  String get earningsToday => 'Today';

  @override
  String get earningsThisWeek => 'This week';

  @override
  String get earningsCansMoved => 'Cans moved';

  @override
  String get earningsDeliveredStops => 'Delivered stops';

  @override
  String get earningsRate => 'Rate';

  @override
  String get earningsPerCan => 'per can';

  @override
  String get earningsPerLitre => 'per litre';

  @override
  String get earningsSalary => 'salary';

  @override
  String get earningsPerLitreUnsupported =>
      'Per-litre payout is not available yet';

  @override
  String get earningsPerLitreHint =>
      'The dairy ledger does not record litres per stop, so this figure cannot be computed.';

  @override
  String get earningsCashInHand => 'Cash in hand';

  @override
  String get earningsCashStops => 'Cash stops';

  @override
  String get earningsCashCollected => 'Collected';

  @override
  String get earningsCashDeposited => 'Deposited';

  @override
  String get earningsCashOutstanding => 'Outstanding';

  @override
  String get earningsRecordDeposit => 'Record deposit';

  @override
  String get earningsDepositAmount => 'Amount';

  @override
  String get earningsDepositReference => 'Reference (optional)';

  @override
  String get earningsDepositSaved => 'Deposit recorded';

  @override
  String get earningsUnavailable => 'Earnings unavailable';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get runLabel => 'Run';

  @override
  String get dateLabel => 'Date';

  @override
  String get runStatusPlanned => 'Planned';

  @override
  String get runStatusDispatched => 'Dispatched';

  @override
  String get runStatusInProgress => 'In progress';

  @override
  String get runStatusCompleted => 'Completed';

  @override
  String get runStatusCancelled => 'Cancelled';

  @override
  String get runsUnavailable => 'Runs unavailable';

  @override
  String get noPastRuns => 'No past runs yet';

  @override
  String get noPastRunsHint =>
      'Completed routes appear here once the depot reconciliation is closed.';

  @override
  String get loadMore => 'Load more';

  @override
  String get runId => 'Run id';

  @override
  String get stopIdOptional => 'Stop id (optional)';

  @override
  String get canCode => 'Can code';

  @override
  String get runIdAndCanRequired => 'Run id and can code are required';

  @override
  String canSynced(String code) {
    return 'Can $code synced';
  }

  @override
  String canQueuedOffline(String code) {
    return 'Can $code queued offline';
  }

  @override
  String get issuedToCustomers => 'Issued to customers';

  @override
  String get expectedReturn => 'Expected return';

  @override
  String get actualReturn => 'Actual return';

  @override
  String get cansReturned => 'Cans returned';

  @override
  String get runIdRequired => 'Run id is required';

  @override
  String get adjustmentReasonRequired =>
      'Adjustment reason is required while cans are unbalanced';

  @override
  String get runCompleted => 'Run completed';

  @override
  String get couldNotCompleteRun => 'Could not complete run';

  @override
  String get runBalanceUnavailable => 'Could not load the run\'s can balance.';

  @override
  String get noActiveRun => 'No run assigned for today';

  @override
  String get dashboardUnavailable => 'Dashboard unavailable';

  @override
  String get couldNotLoadDashboard => 'Could not load the dashboard.';

  @override
  String get noDataReturned => 'No data returned.';

  @override
  String get somePanelsFailed => 'Some panels could not load';

  @override
  String get temporarilyUnavailable => 'temporarily unavailable';

  @override
  String get revenueToday => 'Revenue today';

  @override
  String get runsInProgress => 'Runs in progress';

  @override
  String get fssaiLicence => 'FSSAI licence';

  @override
  String get supplierPayables => 'Supplier payables';

  @override
  String get noLicenceRecorded => 'No licence recorded';

  @override
  String get unknownStatus => 'Unknown';

  @override
  String get unavailable => 'Unavailable';

  @override
  String lowStockSummary(int count, int threshold) {
    return '$count items at or below $threshold';
  }

  @override
  String quantityLeft(int count) {
    return '$count left';
  }

  @override
  String daysToExpiry(int days) {
    return 'Expires in $days days';
  }

  @override
  String approvedStatements(int count) {
    return '$count approved statements';
  }

  @override
  String stopsPendingCount(int count) {
    return '$count stops pending';
  }

  @override
  String get compliancePending => 'Pending';

  @override
  String get complianceValid => 'Valid';

  @override
  String get complianceExpiring => 'Expiring';

  @override
  String get complianceExpired => 'Expired';

  @override
  String get statusActive => 'Active';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusRefunded => 'Refunded';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusPreparing => 'Preparing';

  @override
  String get statusOutForDelivery => 'Out for delivery';

  @override
  String get statusPendingPayments => 'Awaiting payment';

  @override
  String get settlementStatusPaid => 'Paid';

  @override
  String get settlementStatusApproved => 'Approved';

  @override
  String get settlementStatusSubmitted => 'Submitted';

  @override
  String get settlementStatusVoid => 'Void';

  @override
  String get settlementStatusDisputed => 'Disputed';

  @override
  String get couldNotCompleteAction => 'Could not complete that action.';

  @override
  String get couldNotLoadRiders => 'Could not load riders.';

  @override
  String get inviteRider => 'Invite a rider';

  @override
  String get inviteRiderHint =>
      'They join this outlet when they register with the number you enter.';

  @override
  String get mobileNumber => 'Mobile number';

  @override
  String get tenDigitNumber => '10-digit number';

  @override
  String get inviteAction => 'Invite';

  @override
  String get invalidMobile => 'That is not a valid mobile number.';

  @override
  String get payAction => 'Pay';

  @override
  String get amount => 'Amount';

  @override
  String removeRiderNamed(String name) {
    return 'Remove $name?';
  }

  @override
  String get removeRiderHint =>
      'They leave this outlet\'s fleet and stop appearing on the roster. Their delivery history is kept.';

  @override
  String get revoke => 'Revoke';

  @override
  String get noOwnRiders => 'No own riders';

  @override
  String get noOwnRidersHint =>
      'This outlet has no riders on its own fleet yet. Invite one above.';

  @override
  String get ridersUnavailable => 'Riders unavailable';

  @override
  String get pendingInvitations => 'Pending invitations';

  @override
  String get waitingForRegistration => 'Waiting for the rider to register';

  @override
  String get riderFallback => 'Rider';

  @override
  String get blocked => 'Blocked';

  @override
  String get onFleet => 'On fleet';

  @override
  String get block => 'Block';

  @override
  String get couldNotLoadRuns => 'Could not load runs.';

  @override
  String get noRunsYet => 'No runs yet';

  @override
  String get noRunsYetHint =>
      'Runs appear once the nightly manifest builds tomorrow\'s deliveries, or you create one manually.';

  @override
  String get couldNotLoadEarnings => 'Could not load earnings.';

  @override
  String livePreSettlementSummary(int count) {
    return '$count delivered orders Â· live, pre-settlement';
  }

  @override
  String get youKeep => 'You keep';

  @override
  String get noPartnerAgreement => 'No partner agreement';

  @override
  String get noPartnerAgreementHint =>
      'This outlet has no commission agreement on file, so nothing is deducted. The platform settles it directly.';

  @override
  String commissionRate(String rate) {
    return '$rate% commission';
  }

  @override
  String get commissionOnProductAndDelivery => 'Product + delivery charges';

  @override
  String get commissionOnProductOnly => 'Product sales only';

  @override
  String get closedStatements => 'Closed statements for this outlet';

  @override
  String get nothingSettledYet => 'Nothing settled yet';

  @override
  String get nothingSettledYetHint =>
      'Settlement statements appear here once a period is closed and paid.';

  @override
  String get couldNotLoadStock => 'Could not load stock.';

  @override
  String get stockUnavailable => 'Stock unavailable';

  @override
  String get noStockRecords => 'No stock records';

  @override
  String get noStockRecordsHint =>
      'Products added to this outlet appear here with pack size and available quantity.';

  @override
  String get outOfStock => 'Out';

  @override
  String get couldNotLoadOrders => 'Could not load orders.';

  @override
  String get orderActionFailed => 'Could not update that order.';

  @override
  String get ordersUnavailable => 'Orders unavailable';

  @override
  String get noOrders => 'No orders';

  @override
  String get noOrdersHint =>
      'One-time dairy orders for this outlet appear here.';

  @override
  String get orderLabel => 'Order';

  @override
  String get markReady => 'Mark ready';

  @override
  String get couldNotLoadPlans => 'Could not load subscriptions.';

  @override
  String get couldNotUpdatePlan => 'Could not update this plan.';

  @override
  String get subscriptionsUnavailable => 'Subscriptions unavailable';

  @override
  String get noSubscriptions => 'No subscriptions';

  @override
  String get noSubscriptionsHint =>
      'Daily, alternate-day, weekly and custom-day milk plans for this outlet appear here.';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get scheduleDaily => 'Daily';

  @override
  String get scheduleAlternateDays => 'Alternate days';

  @override
  String get scheduleWeekly => 'Weekly';

  @override
  String get scheduleCustomDays => 'Custom days';

  @override
  String get planFallback => 'Plan';

  @override
  String get quantityLabel => 'Qty';

  @override
  String get storesTitleCustomerSubscriptions => 'Suscripciones de clientes';

  @override
  String get storesTitleRecurringPlans => 'Planes recurrentes';

  @override
  String get storesTitleAnalytics => 'AnalÃƒÂ­ticas';

  @override
  String get storesTitlePolicies => 'PolÃƒÂ­ticas';

  @override
  String get storesTitleReviews => 'ReseÃƒÂ±as';

  @override
  String get storesTitleStoreProfile => 'Perfil de tienda';

  @override
  String get storesTitleCategories => 'CategorÃƒÂ­as';

  @override
  String get storesTitleProducts => 'Productos';

  @override
  String get storesTitleDispatch => 'Despacho';

  @override
  String get storesTitleExchanges => 'Cambios';

  @override
  String get storesMoney => 'Dinero';

  @override
  String get storesOperations => 'Operaciones';

  @override
  String get storesAccount => 'Cuenta';

  @override
  String get storesSubscribers => 'Suscriptores';

  @override
  String get storesNext7Days => 'PrÃƒÂ³ximos 7 dÃƒÂ­as';

  @override
  String get storesSkipped => 'Omitidos';

  @override
  String get storesNoCategories => 'AÃƒÂºn no hay categorÃƒÂ­as.';

  @override
  String get storesNoProducts => 'AÃƒÂºn no hay productos.';

  @override
  String get storesNoPolicies => 'AÃƒÂºn no hay polÃƒÂ­ticas.';

  @override
  String get storesNoReviews => 'AÃƒÂºn no hay reseÃƒÂ±as.';

  @override
  String get storesNoExchanges => 'AÃƒÂºn no hay cambios.';

  @override
  String get storesNoDispatch => 'No hay pedidos listos para despacho.';

  @override
  String get storesNoOutlet => 'Sin punto de venta';

  @override
  String get storesNoSkipped =>
      'No hay entregas omitidas en los prÃƒÂ³ximos 7 dÃƒÂ­as.';

  @override
  String get storesNoUpcoming =>
      'No hay entregas prÃƒÂ³ximas en los prÃƒÂ³ximos 7 dÃƒÂ­as.';

  @override
  String get storesLoadMore => 'Cargar mÃƒÂ¡s';

  @override
  String get storesRetry => 'Reintentar';

  @override
  String get storesPause => 'Pausar';

  @override
  String get storesResume => 'Reanudar';

  @override
  String get storesActivate => 'Activar';

  @override
  String get storesReview => 'ReseÃƒÂ±a';

  @override
  String get storesNoRecurringPlans => 'AÃƒÂºn no hay planes recurrentes.';

  @override
  String get storesMsgBrandCertSubmitted =>
      'Brand certification submitted for Admin review.';

  @override
  String get storesActionRequestBrand => 'Request a brand';

  @override
  String get storesTitleMyBrandRequests => 'My brand requests';

  @override
  String get storesActionCertifyBrand => 'Certify brand';

  @override
  String get storesLabelOrganicProduct => 'Organic product';

  @override
  String get storesLabelProductHasVariants => 'This product has variants';

  @override
  String get storesMsgChooseCategoryVariants =>
      'Choose a category with variant attributes to generate variants.';

  @override
  String get storesActionSubmitRequest => 'Submit request';

  @override
  String storesMsgCouldNotLoadRequests(Object error) {
    return 'Could not load requests: $error';
  }

  @override
  String get storesNoBrandRequests => 'No brand requests yet.';

  @override
  String get storesFallbackBrand => 'Brand';

  @override
  String get storesNoDrivers => 'No drivers yet.';

  @override
  String get storesFallbackDelivery => 'Delivery';

  @override
  String get storesFallbackExchange => 'Exchange';

  @override
  String get storesFallbackCustomer => 'Customer';

  @override
  String storesMsgCustomerOrders(Object orderCount, Object totalSpent) {
    return '$orderCount orders, $totalSpent';
  }

  @override
  String get storesTitleSettlement => 'Settlement';

  @override
  String get storesMsgNoLineItems => 'No line items on this statement.';

  @override
  String get storesActionSuspend => 'Suspend';

  @override
  String get storesActionReactivate => 'Reactivate';

  @override
  String get storesMsgDriverSuspended => 'Driver suspended';

  @override
  String get storesMsgDriverReactivated => 'Driver reactivated';

  @override
  String get storesFallbackUnknownStep => 'Unknown step';

  @override
  String get storesLabelAmount => 'Amount';

  @override
  String get storesLabelNextPaymentDue => 'Next payment due';

  @override
  String get storesLabelTrialEnds => 'Trial ends';

  @override
  String get storesLabelGracePeriodEnds => 'Grace period ends';

  @override
  String get storesLabelStatus => 'Status';

  @override
  String get storesFallbackPlan => 'Plan';

  @override
  String get storesFallbackCategory => 'Category';

  @override
  String get storesFallbackPolicy => 'Policy';

  @override
  String get storesNoSubscriptions => 'No subscriptions yet.';

  @override
  String get storesLabelItems => 'items';

  @override
  String get storesFallbackVariant => 'Variant';

  @override
  String get storesTitleNewCoupon => 'New coupon';

  @override
  String get storesTitleTestCode => 'Test a code';

  @override
  String get storesMsgReturnRefunded => 'Return refunded';

  @override
  String get storesActionRefund => 'Refund';

  @override
  String get storesMsgNoVariantToAdjust => 'This row has no variant to adjust.';

  @override
  String get storesMsgQuantityPositive => 'Quantity must be a positive number.';

  @override
  String get storesMsgReasonRequired =>
      'A reason is required for every stock movement.';

  @override
  String get storesMsgStockUpdated => 'Stock updated';

  @override
  String get storesActionNewSale => 'New sale';

  @override
  String get storesActionWorkOrder => 'Work the order';

  @override
  String get storesMsgNoOrderableVariant =>
      'This product has no orderable variant.';

  @override
  String get storesTitleCounterSalePlaced => 'Counter sale placed';

  @override
  String get storesMsgCashSaleHint =>
      'Cash sale â€” add items from the list above';

  @override
  String storesMsgCashDue(Object orderNo, Object total) {
    return 'Order #$orderNo â€” cash due $total';
  }

  @override
  String get storesTitleOutlet => 'Outlet';

  @override
  String get storesTitleChain => 'Chain';

  @override
  String get storesActionRecord => 'Record';

  @override
  String get storesLabelFragile => 'Fragile';

  @override
  String get storesActionComplete => 'Complete';

  @override
  String get storesActionKeepOrder => 'Keep order';

  @override
  String get storesActionAcceptOrder => 'Accept order';

  @override
  String get storesActionCompletePacking => 'Complete packing';

  @override
  String get storesActionMarkReady => 'Mark ready';

  @override
  String get storesActionAssignDriver => 'Assign driver';

  @override
  String get storesActionCancelOrder => 'Cancel order';

  @override
  String get storesLabelPicked => 'Picked';

  @override
  String get storesLabelUnavailable => 'Unavailable';

  @override
  String get storesActionSubstitute => 'Substitute';

  @override
  String get storesMsgNoActionAvailable => 'No action available at this stage.';

  @override
  String get storesTitleEditProduct => 'Edit product';

  @override
  String get storesTitleNewProduct => 'New product';

  @override
  String get storesTitleReturns => 'Returns';

  @override
  String get storesTitleCustomers => 'Customers';

  @override
  String get storesTitleSettings => 'Settings';

  @override
  String get storesTitleDeliveryTracking => 'Delivery tracking';

  @override
  String get storesNoReturns => 'No returns yet.';

  @override
  String get storesNoCustomers => 'No customers yet.';

  @override
  String get storesNoDeliveries => 'No deliveries yet.';

  @override
  String get storesLabelStoreProfile => 'Store profile';

  @override
  String get storesLabelCategories => 'Categories';

  @override
  String get storesLabelProducts => 'Products';

  @override
  String get storesLabelDispatch => 'Dispatch';

  @override
  String get storesLabelAnalytics => 'Analytics';

  @override
  String get storesLabelPolicies => 'Policies';

  @override
  String get storesLabelReviews => 'Reviews';

  @override
  String get ls_documents_title => 'Documents';

  @override
  String get ls_upload_document => 'Upload document';

  @override
  String get ls_choose_file => 'Choose file';

  @override
  String get ls_cancel => 'Cancel';

  @override
  String get ls_upload => 'Upload';

  @override
  String get ls_document_submitted => 'Document submitted for verification';

  @override
  String ls_upload_failed(Object error) {
    return 'Upload failed: $error';
  }

  @override
  String get ls_no_documents => 'No documents uploaded yet';

  @override
  String get ls_retry => 'Retry';

  @override
  String get ls_settlements_title => 'Settlements';

  @override
  String get ls_no_settlements => 'No settlements yet.';

  @override
  String get ls_quotes_title => 'Quotes';

  @override
  String get ls_no_quotes => 'No quotes yet.';

  @override
  String get ls_agreement_name_price_required =>
      'Agreement name and price required';

  @override
  String get ls_create_agreement => 'Create Agreement';

  @override
  String get ls_no_recurring_agreements => 'No recurring agreements yet.';

  @override
  String ls_failed_error(Object error) {
    return 'Failed: $error';
  }

  @override
  String get ls_no_jobs => 'No jobs yet';

  @override
  String get ls_choose_service => 'Choose a service';

  @override
  String get ls_choose_service_to_see_addons =>
      'Choose a service to see add-ons';

  @override
  String get ls_no_addons => 'This service has no add-ons';

  @override
  String get ls_choose_service_to_see_variants =>
      'Choose a service to see variants';

  @override
  String get ls_no_variants => 'This service has no variants';

  @override
  String get ls_add_staff => 'Add staff';

  @override
  String get ls_save => 'Save';

  @override
  String get ls_add_resource => 'Add resource';

  @override
  String get ls_room => 'Room';

  @override
  String get ls_vehicle => 'Vehicle';

  @override
  String get ls_equipment => 'Equipment';

  @override
  String get ls_other => 'Other';

  @override
  String get ls_team_resources => 'Team & resources';

  @override
  String get ls_no_staff => 'No staff';

  @override
  String get ls_no_resources => 'No resources found';

  @override
  String get ls_staff => 'Staff';

  @override
  String get ls_resource => 'Resource';

  @override
  String get ls_leads_awaiting_qualification => 'Leads awaiting qualification';

  @override
  String get ls_no_leads => 'No leads found';

  @override
  String get ls_lead_creation_deferred => 'Lead creation deferred';

  @override
  String get ls_create_lead => 'Create Lead';

  @override
  String get ls_coverage => 'Coverage';

  @override
  String get ls_save_coverage => 'Save coverage';

  @override
  String get ls_save_today_hours => 'Save today hours';

  @override
  String get ls_kind_file_url_required => 'Kind and file URL required';

  @override
  String get ls_register => 'Register';

  @override
  String get ls_step_under_construction => 'Step under construction';

  @override
  String get ls_next_business_details => 'Next: Business Details';

  @override
  String get ls_next_documents => 'Next: Documents';

  @override
  String get ls_upload_verification_documents =>
      'Upload verification documents:';

  @override
  String get ls_submit_for_admin_review => 'Submit for Admin review';

  @override
  String get ls_status => 'Status';

  @override
  String get ls_bookable => 'Bookable';

  @override
  String get ls_yes => 'Yes';

  @override
  String get ls_no => 'No';

  @override
  String get ls_submitted_review =>
      'Submitted. LocalWala will review your documents.';

  @override
  String get ls_refresh_status => 'Refresh status';

  @override
  String get ls_back => 'Back';

  @override
  String get ls_labour_parts_required => 'Labour and parts amounts required';

  @override
  String get ls_enter_revised_amounts => 'Enter revised amounts first';

  @override
  String get ls_not_found => 'Not found';

  @override
  String get ls_no_resource => 'No resource';

  @override
  String get ls_assign => 'Assign';

  @override
  String get ls_release => 'Release';

  @override
  String get ls_choose_from_gallery => 'Choose from gallery';

  @override
  String get ls_take_a_photo => 'Take a photo';

  @override
  String get ls_edit_offering => 'Edit offering';

  @override
  String get ls_remove_photo => 'Remove photo';

  @override
  String get ls_add_photo => 'Add photo';

  @override
  String get ls_no_offerings => 'No offerings yet';

  @override
  String get ls_submit => 'Submit';

  @override
  String get ls_choose_variant => 'Choose a variant';

  @override
  String get ls_add => 'Add';

  @override
  String get ls_earnings_detail => 'Earnings Detail';

  @override
  String get ls_no_bookings_period => 'No bookings in period';

  @override
  String get ls_revenue_summary => 'Revenue summary';

  @override
  String get ls_gross_booking_value => 'Gross booking value';

  @override
  String get ls_booking_fees => 'Booking fees';

  @override
  String get ls_commission => 'Commission';

  @override
  String get ls_provider_payable => 'Provider payable';

  @override
  String get ls_reversals => 'Reversals';

  @override
  String get ls_net_payable => 'Net payable';

  @override
  String get ls_total_bookings => 'Total bookings';

  @override
  String get ls_completed => 'Completed';

  @override
  String get ls_cancelled => 'Cancelled';

  @override
  String get ls_conversion_rate => 'Conversion rate';

  @override
  String get ls_lead_board => 'Lead board';

  @override
  String get ls_qualify => 'Qualify';

  @override
  String get ls_invalid => 'Invalid';

  @override
  String get ls_no_leads_board => 'No leads on the board';

  @override
  String get ls_upcoming_occurrences => 'Upcoming occurrences';

  @override
  String get ls_none_scheduled => 'None scheduled';

  @override
  String get ls_subscribed => 'Subscribed';

  @override
  String get ls_marketing => 'Marketing';

  @override
  String get ls_marketing_packages => 'Marketing packages';

  @override
  String get ls_my_campaigns => 'My campaigns';

  @override
  String get ls_no_campaigns => 'No campaigns yet';

  @override
  String get ls_create_campaign => 'Create';

  @override
  String get ls_campaign_created => 'Campaign submitted for review';

  @override
  String get ls_payment_initiated => 'Payment initiated';

  @override
  String get ls_pay => 'Pay';

  @override
  String get ls_pause => 'Pause';

  @override
  String get ls_resume => 'Resume';

  @override
  String get ls_no_packages => 'No packages available';

  @override
  String get ls_more_marketing => 'Marketing';

  @override
  String get ls_current_subscription => 'Current subscription';

  @override
  String get ls_plan => 'Plan';

  @override
  String get ls_renews => 'Renews';

  @override
  String get ls_available_plans => 'Available plans';

  @override
  String get ls_subscribe => 'Subscribe';

  @override
  String get ls_no_plans => 'No plans available';

  @override
  String get ls_nav_home => 'Home';

  @override
  String get ls_nav_jobs => 'Jobs';

  @override
  String get ls_nav_catalogue => 'Catalogue';

  @override
  String get ls_nav_hours => 'Hours';

  @override
  String get ls_nav_earnings => 'Earnings';

  @override
  String get ls_nav_more => 'More';

  @override
  String get ls_more_entries => 'More';

  @override
  String get ls_more_statement => 'Statement';

  @override
  String get ls_more_growth => 'Growth';

  @override
  String get ls_more_leads => 'Leads';

  @override
  String get ls_more_quotes => 'Quotes';

  @override
  String get ls_more_recurring => 'Recurring';

  @override
  String get ls_more_settlements => 'Settlements';

  @override
  String get ls_more_staff => 'Staff';

  @override
  String get ls_more_documents => 'Documents';

  @override
  String get ls_more_variants => 'Variants';

  @override
  String get ls_more_addons => 'Addons';

  @override
  String get ls_more_onboarding => 'Onboarding';

  @override
  String get ls_more_account => 'Account';

  @override
  String get ls_more_subscriptions => 'Subscriptions';

  @override
  String get ls_revise => 'Revise';

  @override
  String get ls_booking => 'Booking';

  @override
  String get ls_settlement => 'Settlement';

  @override
  String get ls_recurring_agreements => 'Recurring Agreements';

  @override
  String get ls_existing_agreements => 'Existing Agreements';

  @override
  String get ls_agreement_name => 'Agreement name';

  @override
  String get ls_interval => 'Interval (e.g. weekly, monthly)';

  @override
  String get ls_occurrences => 'Occurrences';

  @override
  String get ls_price => 'Price';

  @override
  String get ls_agreement => 'Agreement';

  @override
  String get ls_service => 'Service';

  @override
  String get ls_variant => 'Variant';

  @override
  String get ls_variant_catalogue => 'Variant catalogue';

  @override
  String get ls_variants_localwala_note =>
      'Variants are set by LocalWala. Publish your price from Catalogue.';

  @override
  String get ls_not_offered => 'Not offered';

  @override
  String get ls_name => 'Name';

  @override
  String get ls_skills => 'Skills (comma separated)';

  @override
  String get ls_working_hours_hint =>
      'Working hours (HH:MM 24h). Leave blank for a day off.';

  @override
  String get ls_kind => 'Kind';

  @override
  String get ls_capacity => 'Capacity';

  @override
  String get ls_turnaround_minutes => 'Turnaround minutes';

  @override
  String get ls_register_provider => 'Register as a service provider';

  @override
  String get ls_business_name => 'Business name';

  @override
  String get ls_provider_type => 'Provider type';

  @override
  String get ls_business_details => 'Business details';

  @override
  String get ls_business_address => 'Business address';

  @override
  String get ls_service_areas => 'Service areas (comma-separated)';

  @override
  String get ls_document_kind => 'Document kind (e.g. license)';

  @override
  String get ls_file_url => 'File URL';

  @override
  String get ls_remove_subscription => 'Remove subscription';

  @override
  String get ls_add_subscription => 'Add subscription (optional)';

  @override
  String get ls_services_live =>
      'Your services are live and bookable by customers.';

  @override
  String get ls_account_final_checks =>
      'LocalWala will activate your account after final checks.';

  @override
  String get ls_duration_minutes => 'Duration (min)';

  @override
  String get ls_change_photo => 'Change photo';

  @override
  String get ls_saving_returns_draft =>
      'Saving changes returns this offering to draft for review.';

  @override
  String get ls_publish_offering => 'Publish an offering';

  @override
  String get ls_your_price => 'Your price';

  @override
  String get ls_edit_price => 'Edit price';

  @override
  String get ls_staff_name => 'Staff name';

  @override
  String get ls_locality_coverage => 'Locality (coverage)';

  @override
  String get ls_staff_load_failed => 'Staff load failed';

  @override
  String get ls_staff_name_required => 'Staff name required';

  @override
  String get ls_staff_added => 'Staff added';

  @override
  String get ls_coverage_saved => 'Coverage saved';

  @override
  String get ls_today_hours_saved => 'Today hours saved (09:00-20:00)';

  @override
  String get ls_gross_value => 'Gross Value';

  @override
  String get ls_booking_breakdown => 'Booking Breakdown';

  @override
  String get ls_need_action => 'Need action';

  @override
  String get ls_completed_value => 'Completed value';

  @override
  String get ls_open_leads => 'Open Leads';

  @override
  String get ls_manage_lead_claims => 'Manage lead claims and charges';

  @override
  String get ls_leads_list => 'Leads List';

  @override
  String get ls_lead_name => 'Lead name';

  @override
  String get ls_lead_value => 'Lead value';

  @override
  String get ls_document_type => 'Document type';

  @override
  String get ls_open_file => 'Open file';

  @override
  String get ls_could_not_open_photos =>
      'Could not open photos. Check app permissions and try again.';

  @override
  String get ls_upload_no_path => 'Upload returned no path';

  @override
  String get ls_image_upload_failed => 'Image upload failed';

  @override
  String get ls_choose_service_numeric_price =>
      'Choose a service and enter a numeric price';

  @override
  String get ls_choose_variant_service => 'Choose a variant for this service';

  @override
  String get ls_numeric_price_duration =>
      'Enter a numeric price and a duration above zero';

  @override
  String get ls_skills_label => 'Skills';

  @override
  String get ls_shifts => 'Shifts';

  @override
  String get ls_leave => 'Leave';

  @override
  String get ls_payable => 'Payable';

  @override
  String get ls_todays_jobs => 'Today\'s jobs';

  @override
  String get ls_documents => 'Documents';

  @override
  String get ls_review => 'Review';

  @override
  String get ls_active => 'Active';

  @override
  String get ls_active_published => 'Active & Published';

  @override
  String get ls_approved => 'Approved';

  @override
  String get ls_refresh => 'Refresh';

  @override
  String get ls_labour => 'Labour';

  @override
  String get ls_parts => 'Parts';

  @override
  String get ls_submit_quote => 'Submit quote';

  @override
  String get ls_addon_catalogue => 'Add-on catalogue';

  @override
  String get ls_addon_catalogue_note =>
      'Add-ons are set by LocalWala and selected by customers at booking.';

  @override
  String get ls_reason => 'Reason';

  @override
  String get ls_actions => 'Actions';

  @override
  String get ls_assignment => 'Assignment';

  @override
  String get ls_timeline => 'Timeline';

  @override
  String get ls_review_subscription => 'Review & Subscription';

  @override
  String get ls_more_areas => 'Areas';

  @override
  String get ls_more_policies => 'Policies';

  @override
  String get ls_more_reviews => 'Reviews';

  @override
  String get ls_more_support => 'Support';

  @override
  String get ls_areas_title => 'Service areas';

  @override
  String get ls_city => 'City';

  @override
  String get ls_radius_km => 'Radius (km)';

  @override
  String get ls_localities => 'Localities';

  @override
  String get ls_pincodes => 'Pincodes';

  @override
  String get ls_add_locality => 'Add locality';

  @override
  String get ls_add_pincode => 'Add pincode';

  @override
  String get ls_enter_value => 'Enter a value';

  @override
  String get ls_no_localities => 'No localities added yet';

  @override
  String get ls_no_pincodes => 'No pincodes added yet';

  @override
  String get ls_areas_saved => 'Service areas saved';

  @override
  String ls_save_failed(Object error) {
    return 'Could not save: $error';
  }

  @override
  String get ls_policies_title => 'Policies';

  @override
  String get ls_policies_note =>
      'These rules apply to your services. Contact support to request a change.';

  @override
  String get ls_no_policies => 'No active policies apply to your services';

  @override
  String get ls_scope => 'Scope';

  @override
  String get ls_scope_platform => 'Platform';

  @override
  String get ls_scope_category => 'Category';

  @override
  String get ls_scope_subcategory => 'Subcategory';

  @override
  String get ls_scope_service => 'Service';

  @override
  String get ls_scope_provider => 'Your business';

  @override
  String get ls_policy_cancellation => 'Cancellation';

  @override
  String get ls_policy_reschedule => 'Reschedule';

  @override
  String get ls_policy_quote_expiry => 'Quote expiry';

  @override
  String get ls_policy_booking_window => 'Booking window';

  @override
  String get ls_policy_deposit => 'Deposit';

  @override
  String get ls_policy_tax => 'Tax';

  @override
  String get ls_limit => 'Limit';

  @override
  String get ls_min_notice => 'Min notice';

  @override
  String get ls_reviews_title => 'Reviews';

  @override
  String get ls_no_reviews => 'No reviews yet';

  @override
  String get ls_support_title => 'Support';

  @override
  String get ls_no_complaints => 'No support tickets yet';

  @override
  String get ls_new_ticket => 'New ticket';

  @override
  String get ls_ticket_reason => 'Describe the issue';

  @override
  String get ls_ticket_booking_id => 'Booking ID (optional)';

  @override
  String get ls_ticket_submitted => 'Ticket submitted';

  @override
  String get ls_ticket_required => 'Please describe the issue';

  @override
  String ls_ticket_failed(Object error) {
    return 'Could not submit: $error';
  }

  @override
  String get ls_open => 'Open';

  @override
  String get ls_resolved => 'Resolved';

  @override
  String get ls_setup_publish => 'Set up & publish services';
}
