import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_strings_en.dart';
import 'app_strings_tr.dart';
import 'app_strings_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of GeoFieldStrings
/// returned by `GeoFieldStrings.of(context)`.
///
/// Applications need to include `GeoFieldStrings.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_strings.dart';
///
/// return MaterialApp(
///   localizationsDelegates: GeoFieldStrings.localizationsDelegates,
///   supportedLocales: GeoFieldStrings.supportedLocales,
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
/// be consistent with the languages listed in the GeoFieldStrings.supportedLocales
/// property.
abstract class GeoFieldStrings {
  GeoFieldStrings(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static GeoFieldStrings? of(BuildContext context) {
    return Localizations.of<GeoFieldStrings>(context, GeoFieldStrings);
  }

  static const LocalizationsDelegate<GeoFieldStrings> delegate =
      _GeoFieldStringsDelegate();

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
    Locale('en'),
    Locale('tr'),
    Locale('uz')
  ];

  /// No description provided for @about_app.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get about_app;

  /// No description provided for @acc_label.
  ///
  /// In en, this message translates to:
  /// **'ACC'**
  String get acc_label;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @ai_lithology_applied_hint.
  ///
  /// In en, this message translates to:
  /// **'AI draft applied. Verify all fields in the field.'**
  String get ai_lithology_applied_hint;

  /// No description provided for @ai_lithology_btn.
  ///
  /// In en, this message translates to:
  /// **'AI lithology'**
  String get ai_lithology_btn;

  /// No description provided for @ai_lithology_error.
  ///
  /// In en, this message translates to:
  /// **'AI error'**
  String get ai_lithology_error;

  /// No description provided for @ai_lithology_minerals_prefix.
  ///
  /// In en, this message translates to:
  /// **'Minerals:'**
  String get ai_lithology_minerals_prefix;

  /// No description provided for @ai_lithology_need_photo.
  ///
  /// In en, this message translates to:
  /// **'Add a station photo first (camera or gallery) for AI analysis.'**
  String get ai_lithology_need_photo;

  /// No description provided for @ai_lithology_verify_type_prefix.
  ///
  /// In en, this message translates to:
  /// **'AI suggested rock type (verify):'**
  String get ai_lithology_verify_type_prefix;

  /// No description provided for @actions_label.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions_label;

  /// No description provided for @active_point_label.
  ///
  /// In en, this message translates to:
  /// **'Active geological point'**
  String get active_point_label;

  /// No description provided for @add_first_station.
  ///
  /// In en, this message translates to:
  /// **'Create First Station'**
  String get add_first_station;

  /// No description provided for @add_gallery.
  ///
  /// In en, this message translates to:
  /// **'+ Gallery'**
  String get add_gallery;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @all_projects.
  ///
  /// In en, this message translates to:
  /// **'All Projects'**
  String get all_projects;

  /// No description provided for @all_stations.
  ///
  /// In en, this message translates to:
  /// **'All (All stations)'**
  String get all_stations;

  /// No description provided for @altitude.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get altitude;

  /// No description provided for @altitude_offset_desc.
  ///
  /// In en, this message translates to:
  /// **'Altitude offset (meters)'**
  String get altitude_offset_desc;

  /// No description provided for @analysis_alt_range.
  ///
  /// In en, this message translates to:
  /// **'Altitude range'**
  String get analysis_alt_range;

  /// No description provided for @analysis_avg_dip.
  ///
  /// In en, this message translates to:
  /// **'Average Dip'**
  String get analysis_avg_dip;

  /// No description provided for @analysis_circular_mean_strike.
  ///
  /// In en, this message translates to:
  /// **'Circular Mean Strike'**
  String get analysis_circular_mean_strike;

  /// No description provided for @analysis_dip_direction.
  ///
  /// In en, this message translates to:
  /// **'Dip Direction'**
  String get analysis_dip_direction;

  /// No description provided for @analysis_extra_measurements.
  ///
  /// In en, this message translates to:
  /// **'Additional measurements'**
  String get analysis_extra_measurements;

  /// No description provided for @analysis_fisher_stats.
  ///
  /// In en, this message translates to:
  /// **'FISHER STATISTICS (STRIKE)'**
  String get analysis_fisher_stats;

  /// No description provided for @analysis_general.
  ///
  /// In en, this message translates to:
  /// **'GENERAL'**
  String get analysis_general;

  /// No description provided for @analysis_measure_types.
  ///
  /// In en, this message translates to:
  /// **'BY MEASUREMENT TYPE'**
  String get analysis_measure_types;

  /// No description provided for @analysis_orientation_mean.
  ///
  /// In en, this message translates to:
  /// **'MEAN ORIENTATION (VECTOR)'**
  String get analysis_orientation_mean;

  /// No description provided for @analysis_primary_measurement.
  ///
  /// In en, this message translates to:
  /// **'Primary measurement'**
  String get analysis_primary_measurement;

  /// No description provided for @analysis_project_count.
  ///
  /// In en, this message translates to:
  /// **'Project count'**
  String get analysis_project_count;

  /// No description provided for @analysis_projects.
  ///
  /// In en, this message translates to:
  /// **'BY PROJECT'**
  String get analysis_projects;

  /// No description provided for @analysis_rock_type.
  ///
  /// In en, this message translates to:
  /// **'Rock type'**
  String get analysis_rock_type;

  /// No description provided for @analysis_rocks.
  ///
  /// In en, this message translates to:
  /// **'BY ROCK TYPE'**
  String get analysis_rocks;

  /// No description provided for @analysis_stat_reliable.
  ///
  /// In en, this message translates to:
  /// **'Statistics are reliable (n≥5, R>0.5)'**
  String get analysis_stat_reliable;

  /// No description provided for @analysis_stat_unreliable.
  ///
  /// In en, this message translates to:
  /// **'More measurements needed (n≥5 and R>0.5)'**
  String get analysis_stat_unreliable;

  /// No description provided for @analysis_station_count.
  ///
  /// In en, this message translates to:
  /// **'Station count'**
  String get analysis_station_count;

  /// No description provided for @analysis_strike_std.
  ///
  /// In en, this message translates to:
  /// **'Strike Std Dev (σ)'**
  String get analysis_strike_std;

  /// No description provided for @analysis_with_gps.
  ///
  /// In en, this message translates to:
  /// **'With GPS'**
  String get analysis_with_gps;

  /// No description provided for @analytics_weekly.
  ///
  /// In en, this message translates to:
  /// **'ANALYTICS (7 DAYS)'**
  String get analytics_weekly;

  /// No description provided for @app_description.
  ///
  /// In en, this message translates to:
  /// **'GeoField Pro N is a complete geological field system: GPS/UTM coordinates, strike/dip/azimuth measurements, photo and audio notes, offline maps and routes, KML/DXF import, CSV/GeoJSON/KML/GPX/PDF export, stereonet and statistical analysis, real-time chat, cloud sync, security, and multilingual operation.'**
  String get app_description;

  /// No description provided for @app_look_label.
  ///
  /// In en, this message translates to:
  /// **'App Appearance'**
  String get app_look_label;

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'GeoField Pro N'**
  String get app_title;

  /// No description provided for @apparent_dip_calc_title.
  ///
  /// In en, this message translates to:
  /// **'APPARENT DIP CALCULATOR'**
  String get apparent_dip_calc_title;

  /// No description provided for @apparent_dip_direction.
  ///
  /// In en, this message translates to:
  /// **'Dip Direction:'**
  String get apparent_dip_direction;

  /// No description provided for @apparent_dip_formula_hint.
  ///
  /// In en, this message translates to:
  /// **'tan(α) = tan(δ) × |cos(β)|\nwhere β = angle between dip direction and section azimuth'**
  String get apparent_dip_formula_hint;

  /// No description provided for @apparent_dip_title.
  ///
  /// In en, this message translates to:
  /// **'APPARENT DIP'**
  String get apparent_dip_title;

  /// No description provided for @apparent_note_body.
  ///
  /// In en, this message translates to:
  /// **'• If section direction is parallel to dip direction (β≈0°) → apparent dip = true dip\n• If section direction is perpendicular to dip direction (β≈90°) → apparent dip = 0°\n• Used in geological sections and map thickness estimations'**
  String get apparent_note_body;

  /// apparent_result_hint
  ///
  /// In en, this message translates to:
  /// **'True dip: {trueDip}°  →  Apparent: {apparent}°'**
  String apparent_result_hint(String trueDip, String apparent);

  /// No description provided for @apparent_section_azimuth.
  ///
  /// In en, this message translates to:
  /// **'Section Azimuth:'**
  String get apparent_section_azimuth;

  /// No description provided for @apparent_true_dip.
  ///
  /// In en, this message translates to:
  /// **'True Dip (δ):'**
  String get apparent_true_dip;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @area_label.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area_label;

  /// No description provided for @auto_recommendation.
  ///
  /// In en, this message translates to:
  /// **'AUTOMATIC RECOMMENDATION'**
  String get auto_recommendation;

  /// No description provided for @azimuth_label.
  ///
  /// In en, this message translates to:
  /// **'Heading (Azimuth)'**
  String get azimuth_label;

  /// No description provided for @bedding.
  ///
  /// In en, this message translates to:
  /// **'Bedding'**
  String get bedding;

  /// No description provided for @by_project.
  ///
  /// In en, this message translates to:
  /// **'By Project'**
  String get by_project;

  /// No description provided for @by_rock_type.
  ///
  /// In en, this message translates to:
  /// **'By Rock Type'**
  String get by_rock_type;

  /// No description provided for @calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// No description provided for @calibration_instruction.
  ///
  /// In en, this message translates to:
  /// **'Place a physical ruler on screen and match 1 cm.'**
  String get calibration_instruction;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @camera_error.
  ///
  /// In en, this message translates to:
  /// **'Camera Error'**
  String get camera_error;

  /// No description provided for @camera_header_document.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENT SYNC'**
  String get camera_header_document;

  /// No description provided for @camera_header_geology.
  ///
  /// In en, this message translates to:
  /// **'GEOLOGY'**
  String get camera_header_geology;

  /// No description provided for @camera_mode_document.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get camera_mode_document;

  /// No description provided for @camera_mode_geology.
  ///
  /// In en, this message translates to:
  /// **'Geological'**
  String get camera_mode_geology;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cleavage.
  ///
  /// In en, this message translates to:
  /// **'Cleavage'**
  String get cleavage;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @color_chart_title.
  ///
  /// In en, this message translates to:
  /// **'MUNSELL COLOR CHART'**
  String get color_chart_title;

  /// No description provided for @compass.
  ///
  /// In en, this message translates to:
  /// **'Compass'**
  String get compass;

  /// No description provided for @compass_8_motion.
  ///
  /// In en, this message translates to:
  /// **'ROTATE IN \"8\" PATTERN TO CALIBRATE COMPASS'**
  String get compass_8_motion;

  /// No description provided for @compass_calibration.
  ///
  /// In en, this message translates to:
  /// **'Calibration Guide'**
  String get compass_calibration;

  /// No description provided for @compass_calibration_long.
  ///
  /// In en, this message translates to:
  /// **'To ensure azimuth and dip accuracy, move your device in a \"figure 8\" pattern several times.'**
  String get compass_calibration_long;

  /// No description provided for @compass_unreliable_warn.
  ///
  /// In en, this message translates to:
  /// **'WARNING: Compass is unreliable! Move your phone in a figure-8 first.'**
  String get compass_unreliable_warn;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirm_delete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete?'**
  String get confirm_delete;

  /// No description provided for @confirm_delete_all.
  ///
  /// In en, this message translates to:
  /// **'All local station data will be deleted. Do you want to continue?'**
  String get confirm_delete_all;

  /// No description provided for @confirm_delete_all_tracks.
  ///
  /// In en, this message translates to:
  /// **'Delete all tracks?'**
  String get confirm_delete_all_tracks;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @coordinate_sync.
  ///
  /// In en, this message translates to:
  /// **'Update Coordinates'**
  String get coordinate_sync;

  /// No description provided for @count_suffix.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get count_suffix;

  /// No description provided for @create_btn.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create_btn;

  /// No description provided for @custom_input.
  ///
  /// In en, this message translates to:
  /// **'Custom Input'**
  String get custom_input;

  /// No description provided for @dark_grey.
  ///
  /// In en, this message translates to:
  /// **'Dark Grey'**
  String get dark_grey;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get dashboard;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @delete_all_label.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get delete_all_label;

  /// No description provided for @delete_confirm_btn.
  ///
  /// In en, this message translates to:
  /// **'Yes, delete'**
  String get delete_confirm_btn;

  /// No description provided for @delete_photo.
  ///
  /// In en, this message translates to:
  /// **'Delete Photo'**
  String get delete_photo;

  /// No description provided for @delete_project_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Project'**
  String get delete_project_title;

  /// No description provided for @delete_project_warn.
  ///
  /// In en, this message translates to:
  /// **'Delete this project? All stations inside will be moved to the \"Default\" project.'**
  String get delete_project_warn;

  /// No description provided for @density_heatmap.
  ///
  /// In en, this message translates to:
  /// **'Density heatmap'**
  String get density_heatmap;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @description_hint.
  ///
  /// In en, this message translates to:
  /// **'Record rock composition, minerals, contacts, and strike/dip variations here...'**
  String get description_hint;

  /// No description provided for @dip.
  ///
  /// In en, this message translates to:
  /// **'Dip'**
  String get dip;

  /// No description provided for @dip_direction.
  ///
  /// In en, this message translates to:
  /// **'Dip Direction'**
  String get dip_direction;

  /// No description provided for @dip_distribution.
  ///
  /// In en, this message translates to:
  /// **'DIP DISTRIBUTION'**
  String get dip_distribution;

  /// No description provided for @dip_label.
  ///
  /// In en, this message translates to:
  /// **'Dip'**
  String get dip_label;

  /// No description provided for @distance_label.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE'**
  String get distance_label;

  /// No description provided for @distance_warning.
  ///
  /// In en, this message translates to:
  /// **'WARNING! Distance difference.'**
  String get distance_warning;

  /// No description provided for @document_align_hint.
  ///
  /// In en, this message translates to:
  /// **'Align the document within the frame'**
  String get document_align_hint;

  /// No description provided for @dominant_direction.
  ///
  /// In en, this message translates to:
  /// **'Dominant direction'**
  String get dominant_direction;

  /// No description provided for @download_confirm.
  ///
  /// In en, this message translates to:
  /// **'Continue downloading?'**
  String get download_confirm;

  /// No description provided for @download_pdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF Report'**
  String get download_pdf;

  /// No description provided for @download_region_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Download visible region'**
  String get download_region_tooltip;

  /// No description provided for @draw_on_photo.
  ///
  /// In en, this message translates to:
  /// **'Draw on photo'**
  String get draw_on_photo;

  /// No description provided for @drawing_name.
  ///
  /// In en, this message translates to:
  /// **'Drawing name'**
  String get drawing_name;

  /// No description provided for @drawing_saved.
  ///
  /// In en, this message translates to:
  /// **'Geological drawing saved'**
  String get drawing_saved;

  /// No description provided for @dxf_notice_body.
  ///
  /// In en, this message translates to:
  /// **'For DXF import, the drawing must use GPS geographic projection (WGS-84 Lat/Lng). Otherwise, it can be placed incorrectly on the map.'**
  String get dxf_notice_body;

  /// No description provided for @dxf_notice_title.
  ///
  /// In en, this message translates to:
  /// **'DXF Notice'**
  String get dxf_notice_title;

  /// No description provided for @echo_mode_on.
  ///
  /// In en, this message translates to:
  /// **'POWER SAVER: ACTIVE'**
  String get echo_mode_on;

  /// No description provided for @eco_mode.
  ///
  /// In en, this message translates to:
  /// **'Eco Mode'**
  String get eco_mode;

  /// No description provided for @edit_coordinates.
  ///
  /// In en, this message translates to:
  /// **'Edit Coordinates (Lat / Lon)'**
  String get edit_coordinates;

  /// No description provided for @edit_disable.
  ///
  /// In en, this message translates to:
  /// **'DISABLE EDIT'**
  String get edit_disable;

  /// No description provided for @edit_enable.
  ///
  /// In en, this message translates to:
  /// **'ENABLE EDIT'**
  String get edit_enable;

  /// No description provided for @edit_project.
  ///
  /// In en, this message translates to:
  /// **'Edit Project'**
  String get edit_project;

  /// No description provided for @expert_mode.
  ///
  /// In en, this message translates to:
  /// **'Expert Mode'**
  String get expert_mode;

  /// No description provided for @export_csv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get export_csv;

  /// No description provided for @export_geojson.
  ///
  /// In en, this message translates to:
  /// **'Export GeoJSON'**
  String get export_geojson;

  /// No description provided for @export_kml.
  ///
  /// In en, this message translates to:
  /// **'KML (Google Earth)'**
  String get export_kml;

  /// No description provided for @export_no_stations.
  ///
  /// In en, this message translates to:
  /// **'No stations to export.'**
  String get export_no_stations;

  /// No description provided for @export_pdf.
  ///
  /// In en, this message translates to:
  /// **'PDF Report'**
  String get export_pdf;

  /// No description provided for @export_select_project.
  ///
  /// In en, this message translates to:
  /// **'Which project to export?'**
  String get export_select_project;

  /// No description provided for @export_title.
  ///
  /// In en, this message translates to:
  /// **'Choose Export Format'**
  String get export_title;

  /// No description provided for @field_assets.
  ///
  /// In en, this message translates to:
  /// **'Field Assets (Photo & Audio)'**
  String get field_assets;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @fisher_dispersion.
  ///
  /// In en, this message translates to:
  /// **'HIGH DISPERSION ⚠️'**
  String get fisher_dispersion;

  /// No description provided for @fisher_reliability.
  ///
  /// In en, this message translates to:
  /// **'FISHER RELIABILITY'**
  String get fisher_reliability;

  /// No description provided for @fisher_stable.
  ///
  /// In en, this message translates to:
  /// **'STABLE TREND ✅'**
  String get fisher_stable;

  /// No description provided for @fisher_stats.
  ///
  /// In en, this message translates to:
  /// **'Fisher statistics'**
  String get fisher_stats;

  /// No description provided for @foliated.
  ///
  /// In en, this message translates to:
  /// **'Foliated'**
  String get foliated;

  /// No description provided for @geoloc_header.
  ///
  /// In en, this message translates to:
  /// **'GEOLOCATION'**
  String get geoloc_header;

  /// No description provided for @gis_monitoring_active.
  ///
  /// In en, this message translates to:
  /// **'GIS Monitoring Active'**
  String get gis_monitoring_active;

  /// No description provided for @gps_error.
  ///
  /// In en, this message translates to:
  /// **'GPS Error'**
  String get gps_error;

  /// No description provided for @gps_locked.
  ///
  /// In en, this message translates to:
  /// **'GPS Locked'**
  String get gps_locked;

  /// No description provided for @gps_not_locked.
  ///
  /// In en, this message translates to:
  /// **'GPS not locked'**
  String get gps_not_locked;

  /// No description provided for @gps_off_alert.
  ///
  /// In en, this message translates to:
  /// **'WARNING: GPS is off. Please enable for field work.'**
  String get gps_off_alert;

  /// No description provided for @gps_performance.
  ///
  /// In en, this message translates to:
  /// **'GPS PERFORMANCE'**
  String get gps_performance;

  /// No description provided for @gps_status_good.
  ///
  /// In en, this message translates to:
  /// **'High Accuracy (Good)'**
  String get gps_status_good;

  /// No description provided for @gps_status_medium.
  ///
  /// In en, this message translates to:
  /// **'Medium Accuracy'**
  String get gps_status_medium;

  /// No description provided for @gps_status_medium_short.
  ///
  /// In en, this message translates to:
  /// **'GPS (Medium)'**
  String get gps_status_medium_short;

  /// No description provided for @gps_status_off.
  ///
  /// In en, this message translates to:
  /// **'GPS Off'**
  String get gps_status_off;

  /// No description provided for @gps_status_poor.
  ///
  /// In en, this message translates to:
  /// **'Low Accuracy'**
  String get gps_status_poor;

  /// No description provided for @gps_status_poor_short.
  ///
  /// In en, this message translates to:
  /// **'GPS (Poor)'**
  String get gps_status_poor_short;

  /// No description provided for @gps_status_searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get gps_status_searching;

  /// No description provided for @gpx_export_unavailable.
  ///
  /// In en, this message translates to:
  /// **'GPX Export is temporarily unavailable'**
  String get gpx_export_unavailable;

  /// No description provided for @grade_dist.
  ///
  /// In en, this message translates to:
  /// **'GRADE DISTRIBUTION'**
  String get grade_dist;

  /// No description provided for @ground_area_label.
  ///
  /// In en, this message translates to:
  /// **'REAL AREA ON PAPER'**
  String get ground_area_label;

  /// No description provided for @hdop.
  ///
  /// In en, this message translates to:
  /// **'HDOP'**
  String get hdop;

  /// No description provided for @height_cm.
  ///
  /// In en, this message translates to:
  /// **'HEIGHT (CM)'**
  String get height_cm;

  /// No description provided for @high_accuracy_good.
  ///
  /// In en, this message translates to:
  /// **'High Accuracy'**
  String get high_accuracy_good;

  /// No description provided for @hold.
  ///
  /// In en, this message translates to:
  /// **'HOLD'**
  String get hold;

  /// No description provided for @horizon_level.
  ///
  /// In en, this message translates to:
  /// **'HORIZON LEVEL'**
  String get horizon_level;

  /// No description provided for @hud_toggle.
  ///
  /// In en, this message translates to:
  /// **'Interface (HUD)'**
  String get hud_toggle;

  /// No description provided for @input_data.
  ///
  /// In en, this message translates to:
  /// **'INPUT DATA'**
  String get input_data;

  /// No description provided for @joint.
  ///
  /// In en, this message translates to:
  /// **'Joint'**
  String get joint;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @last_update.
  ///
  /// In en, this message translates to:
  /// **'Last Update'**
  String get last_update;

  /// No description provided for @lat_label.
  ///
  /// In en, this message translates to:
  /// **'Latitude (North/South)'**
  String get lat_label;

  /// No description provided for @lat_lon_error.
  ///
  /// In en, this message translates to:
  /// **'Invalid Lat/Lon'**
  String get lat_lon_error;

  /// No description provided for @layer_base_map.
  ///
  /// In en, this message translates to:
  /// **'Base map'**
  String get layer_base_map;

  /// No description provided for @layer_drawings.
  ///
  /// In en, this message translates to:
  /// **'Drawings'**
  String get layer_drawings;

  /// No description provided for @layer_gis_kml.
  ///
  /// In en, this message translates to:
  /// **'GIS layer (KML)'**
  String get layer_gis_kml;

  /// No description provided for @layer_management.
  ///
  /// In en, this message translates to:
  /// **'LAYER MANAGEMENT'**
  String get layer_management;

  /// No description provided for @layered.
  ///
  /// In en, this message translates to:
  /// **'Layered'**
  String get layered;

  /// No description provided for @layout_explanation.
  ///
  /// In en, this message translates to:
  /// **'The ground area that fits on the chosen paper.'**
  String get layout_explanation;

  /// No description provided for @layout_planner.
  ///
  /// In en, this message translates to:
  /// **'LAYOUT (PAPER PLANNER)'**
  String get layout_planner;

  /// No description provided for @light_grey.
  ///
  /// In en, this message translates to:
  /// **'Light Grey'**
  String get light_grey;

  /// No description provided for @light_toggle.
  ///
  /// In en, this message translates to:
  /// **'Flash / Torch'**
  String get light_toggle;

  /// No description provided for @lineation.
  ///
  /// In en, this message translates to:
  /// **'Lineation'**
  String get lineation;

  /// No description provided for @lithology_data.
  ///
  /// In en, this message translates to:
  /// **'Lithology & Station Data'**
  String get lithology_data;

  /// No description provided for @lng_label.
  ///
  /// In en, this message translates to:
  /// **'Longitude (East/West)'**
  String get lng_label;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @location_denied_alert.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Enable in settings.'**
  String get location_denied_alert;

  /// No description provided for @mag_decl_short.
  ///
  /// In en, this message translates to:
  /// **'MAG. DEC'**
  String get mag_decl_short;

  /// No description provided for @magmatic.
  ///
  /// In en, this message translates to:
  /// **'Magmatic'**
  String get magmatic;

  /// No description provided for @magnetic_declination.
  ///
  /// In en, this message translates to:
  /// **'Magnetic Declination'**
  String get magnetic_declination;

  /// No description provided for @magnetic_declination_desc.
  ///
  /// In en, this message translates to:
  /// **'East (+), West (-) in degrees'**
  String get magnetic_declination_desc;

  /// No description provided for @mandatory_step_label.
  ///
  /// In en, this message translates to:
  /// **'MANDATORY STEP'**
  String get mandatory_step_label;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @map_error_prefix.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get map_error_prefix;

  /// No description provided for @map_style_osm.
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap Standard'**
  String get map_style_osm;

  /// No description provided for @map_style_satellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite (Esri)'**
  String get map_style_satellite;

  /// No description provided for @map_style_topo.
  ///
  /// In en, this message translates to:
  /// **'OpenTopoMap'**
  String get map_style_topo;

  /// No description provided for @massive.
  ///
  /// In en, this message translates to:
  /// **'Massive'**
  String get massive;

  /// No description provided for @measurement_error_high.
  ///
  /// In en, this message translates to:
  /// **'Warning! Measurement error is high'**
  String get measurement_error_high;

  /// No description provided for @measurement_label.
  ///
  /// In en, this message translates to:
  /// **'Measurement Type'**
  String get measurement_label;

  /// No description provided for @measurements_count.
  ///
  /// In en, this message translates to:
  /// **'MEASUREMENTS'**
  String get measurements_count;

  /// No description provided for @medium_accuracy_warn.
  ///
  /// In en, this message translates to:
  /// **'Medium Accuracy'**
  String get medium_accuracy_warn;

  /// No description provided for @metamorphic.
  ///
  /// In en, this message translates to:
  /// **'Metamorphic'**
  String get metamorphic;

  /// No description provided for @mic_error.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied'**
  String get mic_error;

  /// No description provided for @millimetrovka_calc.
  ///
  /// In en, this message translates to:
  /// **'MILLIMETROVKA CALCULATOR'**
  String get millimetrovka_calc;

  /// No description provided for @munsell_color.
  ///
  /// In en, this message translates to:
  /// **'Munsell Color'**
  String get munsell_color;

  /// No description provided for @new_project_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Mount Everest 2026'**
  String get new_project_hint;

  /// No description provided for @new_project_title.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get new_project_title;

  /// No description provided for @new_station_btn.
  ///
  /// In en, this message translates to:
  /// **'NEW STATION'**
  String get new_station_btn;

  /// No description provided for @next_station.
  ///
  /// In en, this message translates to:
  /// **'+ Next'**
  String get next_station;

  /// No description provided for @no_data.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get no_data;

  /// No description provided for @no_local_data.
  ///
  /// In en, this message translates to:
  /// **'No local data found'**
  String get no_local_data;

  /// No description provided for @no_stations_in_project.
  ///
  /// In en, this message translates to:
  /// **'No stations in the selected project.'**
  String get no_stations_in_project;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'NOTE'**
  String get note;

  /// No description provided for @note_saved.
  ///
  /// In en, this message translates to:
  /// **'Note Saved'**
  String get note_saved;

  /// No description provided for @observation_area_label.
  ///
  /// In en, this message translates to:
  /// **'Observation area'**
  String get observation_area_label;

  /// No description provided for @offline_download.
  ///
  /// In en, this message translates to:
  /// **'Offline Download'**
  String get offline_download;

  /// No description provided for @open_map.
  ///
  /// In en, this message translates to:
  /// **'OPEN MAP'**
  String get open_map;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @paper_distance.
  ///
  /// In en, this message translates to:
  /// **'ON PAPER'**
  String get paper_distance;

  /// No description provided for @paper_format_label.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE PAPER FORMAT:'**
  String get paper_format_label;

  /// No description provided for @pdf_report.
  ///
  /// In en, this message translates to:
  /// **'PDF Report'**
  String get pdf_report;

  /// No description provided for @perimeter_label.
  ///
  /// In en, this message translates to:
  /// **'Perimeter'**
  String get perimeter_label;

  /// No description provided for @photo_added.
  ///
  /// In en, this message translates to:
  /// **'Photo added successfully'**
  String get photo_added;

  /// No description provided for @photo_deleted_snack.
  ///
  /// In en, this message translates to:
  /// **'Photo deleted'**
  String get photo_deleted_snack;

  /// No description provided for @poor_accuracy_warn.
  ///
  /// In en, this message translates to:
  /// **'Poor Accuracy'**
  String get poor_accuracy_warn;

  /// No description provided for @power_saver.
  ///
  /// In en, this message translates to:
  /// **'Tejamkor rejim (Power Saver)'**
  String get power_saver;

  /// No description provided for @professional_tag.
  ///
  /// In en, this message translates to:
  /// **'PROFESSIONAL'**
  String get professional_tag;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @project_and_archive.
  ///
  /// In en, this message translates to:
  /// **'PROJECT & ARCHIVE'**
  String get project_and_archive;

  /// No description provided for @project_label.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project_label;

  /// No description provided for @project_stats.
  ///
  /// In en, this message translates to:
  /// **'PROJECT STATISTICS'**
  String get project_stats;

  /// No description provided for @projection_depth.
  ///
  /// In en, this message translates to:
  /// **'PROJECTION DEPTH'**
  String get projection_depth;

  /// No description provided for @projects_count.
  ///
  /// In en, this message translates to:
  /// **'Projects Count'**
  String get projects_count;

  /// No description provided for @real_distance.
  ///
  /// In en, this message translates to:
  /// **'REAL DISTANCE'**
  String get real_distance;

  /// No description provided for @record_error.
  ///
  /// In en, this message translates to:
  /// **'Audio recording error'**
  String get record_error;

  /// No description provided for @recording_started.
  ///
  /// In en, this message translates to:
  /// **'Recording Started'**
  String get recording_started;

  /// No description provided for @records_count.
  ///
  /// In en, this message translates to:
  /// **'records'**
  String get records_count;

  /// No description provided for @red_ochre.
  ///
  /// In en, this message translates to:
  /// **'Red/Ochre'**
  String get red_ochre;

  /// No description provided for @reliability_index.
  ///
  /// In en, this message translates to:
  /// **'Reliability index'**
  String get reliability_index;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @rename_route.
  ///
  /// In en, this message translates to:
  /// **'Rename Route'**
  String get rename_route;

  /// No description provided for @results_count.
  ///
  /// In en, this message translates to:
  /// **'results'**
  String get results_count;

  /// No description provided for @rock_classification.
  ///
  /// In en, this message translates to:
  /// **'Rock Classification'**
  String get rock_classification;

  /// No description provided for @rock_type.
  ///
  /// In en, this message translates to:
  /// **'Rock Type'**
  String get rock_type;

  /// No description provided for @rose_diagram_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Each sector = 22.5° | Length ~ station count'**
  String get rose_diagram_subtitle;

  /// No description provided for @rose_diagram_title.
  ///
  /// In en, this message translates to:
  /// **'ROSE DIAGRAM (STRIKE)'**
  String get rose_diagram_title;

  /// No description provided for @route_name_prefix.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get route_name_prefix;

  /// No description provided for @route_saved_snack.
  ///
  /// In en, this message translates to:
  /// **'Route saved. You can find it in the Archive.'**
  String get route_saved_snack;

  /// No description provided for @routes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get routes;

  /// No description provided for @rtk_fixed.
  ///
  /// In en, this message translates to:
  /// **'RTK FIXED STATUS'**
  String get rtk_fixed;

  /// No description provided for @ruler_calibration_title.
  ///
  /// In en, this message translates to:
  /// **'DIGITAL RULER & CALIBRATION'**
  String get ruler_calibration_title;

  /// No description provided for @ruler_label.
  ///
  /// In en, this message translates to:
  /// **'RULER'**
  String get ruler_label;

  /// No description provided for @sample_id.
  ///
  /// In en, this message translates to:
  /// **'Sample ID'**
  String get sample_id;

  /// No description provided for @sample_type.
  ///
  /// In en, this message translates to:
  /// **'Sample Type'**
  String get sample_type;

  /// No description provided for @satellites.
  ///
  /// In en, this message translates to:
  /// **'SATS'**
  String get satellites;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @save_drawing_title.
  ///
  /// In en, this message translates to:
  /// **'Save drawing'**
  String get save_drawing_title;

  /// No description provided for @save_first_hint.
  ///
  /// In en, this message translates to:
  /// **'Save station or capture from camera first'**
  String get save_first_hint;

  /// No description provided for @save_label.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save_label;

  /// No description provided for @scale_assistant_help_content.
  ///
  /// In en, this message translates to:
  /// **'1. Millimetrovka Calculator: Converts real distance to mm on paper.\n2. Layout: Calculates area fitting on chosen paper format.\n3. Calibration: Adjust ruler DPI using a physical ruler.'**
  String get scale_assistant_help_content;

  /// No description provided for @scale_assistant_help_title.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get scale_assistant_help_title;

  /// No description provided for @scale_assistant_title.
  ///
  /// In en, this message translates to:
  /// **'SCALE ASSISTANT'**
  String get scale_assistant_title;

  /// No description provided for @scale_short.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get scale_short;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searching_gps.
  ///
  /// In en, this message translates to:
  /// **'Searching GPS...'**
  String get searching_gps;

  /// No description provided for @sedimentary.
  ///
  /// In en, this message translates to:
  /// **'Sedimentary'**
  String get sedimentary;

  /// No description provided for @select_two_points.
  ///
  /// In en, this message translates to:
  /// **'Select 2 points on the map (section line)'**
  String get select_two_points;

  /// No description provided for @selected_label.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selected_label;

  /// No description provided for @selected_scale.
  ///
  /// In en, this message translates to:
  /// **'SELECTED SCALE'**
  String get selected_scale;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @signal_searching.
  ///
  /// In en, this message translates to:
  /// **'SIGNAL SEARCHING'**
  String get signal_searching;

  /// No description provided for @sos_sent.
  ///
  /// In en, this message translates to:
  /// **'SOS signal sent! Team has been alerted.'**
  String get sos_sent;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @station_project_label.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get station_project_label;

  /// No description provided for @station_saved.
  ///
  /// In en, this message translates to:
  /// **'Station Saved'**
  String get station_saved;

  /// No description provided for @stations.
  ///
  /// In en, this message translates to:
  /// **'Stations'**
  String get stations;

  /// No description provided for @stations_count.
  ///
  /// In en, this message translates to:
  /// **'STATIONS'**
  String get stations_count;

  /// No description provided for @stations_suffix.
  ///
  /// In en, this message translates to:
  /// **'stations'**
  String get stations_suffix;

  /// No description provided for @statistics_label.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics_label;

  /// No description provided for @stereonet_density_hint_label.
  ///
  /// In en, this message translates to:
  /// **'Density heatmap'**
  String get stereonet_density_hint_label;

  /// No description provided for @stereonet_density_hint_value.
  ///
  /// In en, this message translates to:
  /// **'thicker zone means more points'**
  String get stereonet_density_hint_value;

  /// No description provided for @stereonet_mean.
  ///
  /// In en, this message translates to:
  /// **'Mean Pole'**
  String get stereonet_mean;

  /// No description provided for @stereonet_no_data.
  ///
  /// In en, this message translates to:
  /// **'Stereonet: No Data'**
  String get stereonet_no_data;

  /// No description provided for @stereonet_planes.
  ///
  /// In en, this message translates to:
  /// **'Planes'**
  String get stereonet_planes;

  /// No description provided for @stereonet_schmidt.
  ///
  /// In en, this message translates to:
  /// **'STEREONET (SCHMIDT NET)'**
  String get stereonet_schmidt;

  /// No description provided for @stereonet_schmidt_desc.
  ///
  /// In en, this message translates to:
  /// **'Equal-area projection — lower hemisphere'**
  String get stereonet_schmidt_desc;

  /// No description provided for @stereonet_summary.
  ///
  /// In en, this message translates to:
  /// **'STEREONET SUMMARY'**
  String get stereonet_summary;

  /// No description provided for @stereonet_wulff.
  ///
  /// In en, this message translates to:
  /// **'STEREONET (WULFF NET)'**
  String get stereonet_wulff;

  /// No description provided for @stereonet_wulff_desc.
  ///
  /// In en, this message translates to:
  /// **'Equal-angle projection — lower hemisphere'**
  String get stereonet_wulff_desc;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @strike.
  ///
  /// In en, this message translates to:
  /// **'Strike'**
  String get strike;

  /// No description provided for @strike_label.
  ///
  /// In en, this message translates to:
  /// **'Strike'**
  String get strike_label;

  /// No description provided for @structural_measurements.
  ///
  /// In en, this message translates to:
  /// **'Structural Measurements'**
  String get structural_measurements;

  /// No description provided for @structure.
  ///
  /// In en, this message translates to:
  /// **'Structure'**
  String get structure;

  /// No description provided for @structure_label.
  ///
  /// In en, this message translates to:
  /// **'Structure / Texture'**
  String get structure_label;

  /// No description provided for @success_saved.
  ///
  /// In en, this message translates to:
  /// **'Station Saved Successfully'**
  String get success_saved;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @system_online.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM ONLINE'**
  String get system_online;

  /// No description provided for @tahlil_label.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get tahlil_label;

  /// No description provided for @theme_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get theme_dark;

  /// No description provided for @theme_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get theme_light;

  /// No description provided for @theme_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get theme_system;

  /// No description provided for @three_d_structure.
  ///
  /// In en, this message translates to:
  /// **'3D STRUCTURE'**
  String get three_d_structure;

  /// No description provided for @time_label.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get time_label;

  /// No description provided for @today_only.
  ///
  /// In en, this message translates to:
  /// **'Today only'**
  String get today_only;

  /// No description provided for @total_stations.
  ///
  /// In en, this message translates to:
  /// **'Total Stations'**
  String get total_stations;

  /// No description provided for @total_stations_short.
  ///
  /// In en, this message translates to:
  /// **'Total stations'**
  String get total_stations_short;

  /// No description provided for @tracking_started_snack.
  ///
  /// In en, this message translates to:
  /// **'Tracking started!'**
  String get tracking_started_snack;

  /// No description provided for @trend_analysis.
  ///
  /// In en, this message translates to:
  /// **'STATISTICAL TREND ANALYSIS'**
  String get trend_analysis;

  /// No description provided for @trend_density.
  ///
  /// In en, this message translates to:
  /// **'Density level (κ)'**
  String get trend_density;

  /// No description provided for @trend_growth.
  ///
  /// In en, this message translates to:
  /// **'Trend: +12% Growth'**
  String get trend_growth;

  /// No description provided for @trend_orientation.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get trend_orientation;

  /// trend_recommend_good
  ///
  /// In en, this message translates to:
  /// **'Main ore orientation follows {dir}.'**
  String trend_recommend_good(String dir);

  /// No description provided for @trend_recommend_poor.
  ///
  /// In en, this message translates to:
  /// **'Data dispersion is high, no clear trend.'**
  String get trend_recommend_poor;

  /// No description provided for @trend_reliability.
  ///
  /// In en, this message translates to:
  /// **'Reliability (α₉₅)'**
  String get trend_reliability;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @unsaved_changes.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsaved_changes;

  /// No description provided for @unsaved_changes_desc.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes will be lost. Do you really want to leave?'**
  String get unsaved_changes_desc;

  /// No description provided for @utm_coordinates.
  ///
  /// In en, this message translates to:
  /// **'UTM COORDINATES'**
  String get utm_coordinates;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @voice_note.
  ///
  /// In en, this message translates to:
  /// **'Voice Note'**
  String get voice_note;

  /// No description provided for @voice_record.
  ///
  /// In en, this message translates to:
  /// **'Voice record'**
  String get voice_record;

  /// No description provided for @warning_label.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning_label;

  /// No description provided for @welcome_text.
  ///
  /// In en, this message translates to:
  /// **'Welcome, '**
  String get welcome_text;

  /// No description provided for @width_cm.
  ///
  /// In en, this message translates to:
  /// **'WIDTH (CM)'**
  String get width_cm;

  /// No description provided for @zoom_label.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get zoom_label;
}

class _GeoFieldStringsDelegate extends LocalizationsDelegate<GeoFieldStrings> {
  const _GeoFieldStringsDelegate();

  @override
  Future<GeoFieldStrings> load(Locale locale) {
    return SynchronousFuture<GeoFieldStrings>(lookupGeoFieldStrings(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_GeoFieldStringsDelegate old) => false;
}

GeoFieldStrings lookupGeoFieldStrings(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return GeoFieldStringsEn();
    case 'tr':
      return GeoFieldStringsTr();
    case 'uz':
      return GeoFieldStringsUz();
  }

  throw FlutterError(
      'GeoFieldStrings.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
