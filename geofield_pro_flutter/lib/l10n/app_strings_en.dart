// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_strings.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class GeoFieldStringsEn extends GeoFieldStrings {
  GeoFieldStringsEn([String locale = 'en']) : super(locale);

  @override
  String get about_app => 'About App';

  @override
  String get map_my_location => 'My location';

  @override
  String get map_eraser_tooltip => 'Eraser';

  @override
  String get map_redo_tooltip => 'Redo';

  @override
  String get map_eraser_hint =>
      'Eraser mode: tap a line to remove it. Tap the button again to exit.';

  @override
  String get map_search_hint => 'City, region or address...';

  @override
  String get map_search_empty => 'Nothing found';

  @override
  String get map_search_searching => 'Searching...';

  @override
  String get map_search_error =>
      'Search failed: no internet or server did not respond';

  @override
  String get map_search_locations_hint => 'Search Locations...';

  @override
  String get acc_label => 'ACC';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get ai_lithology_applied_hint =>
      'AI draft applied. Verify all fields in the field.';

  @override
  String get ai_lithology_btn => 'AI lithology';

  @override
  String get ai_lithology_error => 'AI error';

  @override
  String get ai_lithology_minerals_prefix => 'Minerals:';

  @override
  String get ai_lithology_need_photo =>
      'Add a station photo first (camera or gallery) for AI analysis.';

  @override
  String get ai_lithology_verify_type_prefix =>
      'AI suggested rock type (verify):';

  @override
  String get actions_label => 'Actions';

  @override
  String get active_point_label => 'Active geological point';

  @override
  String get add_first_station => 'Create First Station';

  @override
  String get add_gallery => '+ Gallery';

  @override
  String get admin => 'Admin';

  @override
  String get admin_full_title => 'Admin & Settings';

  @override
  String get all_projects => 'All Projects';

  @override
  String get all_stations => 'All (All stations)';

  @override
  String get altitude => 'Altitude';

  @override
  String get altitude_offset_desc => 'Altitude offset (meters)';

  @override
  String get analysis_alt_range => 'Altitude range';

  @override
  String get analysis_avg_dip => 'Average Dip';

  @override
  String get analysis_circular_mean_strike => 'Circular Mean Strike';

  @override
  String get analysis_dip_direction => 'Dip Direction';

  @override
  String get analysis_extra_measurements => 'Additional measurements';

  @override
  String get analysis_fisher_stats => 'FISHER STATISTICS (STRIKE)';

  @override
  String get analysis_general => 'GENERAL';

  @override
  String get analysis_measure_types => 'BY MEASUREMENT TYPE';

  @override
  String get analysis_orientation_mean => 'MEAN ORIENTATION (VECTOR)';

  @override
  String get analysis_primary_measurement => 'Primary measurement';

  @override
  String get analysis_project_count => 'Project count';

  @override
  String get analysis_projects => 'BY PROJECT';

  @override
  String get analysis_rock_type => 'Rock type';

  @override
  String get analysis_rocks => 'BY ROCK TYPE';

  @override
  String get analysis_stat_reliable => 'Statistics are reliable (n≥5, R>0.5)';

  @override
  String get analysis_stat_unreliable =>
      'More measurements needed (n≥5 and R>0.5)';

  @override
  String get analysis_station_count => 'Station count';

  @override
  String get analysis_strike_std => 'Strike Std Dev (σ)';

  @override
  String get analysis_with_gps => 'With GPS';

  @override
  String get analysis_tab_rose => 'Rose';

  @override
  String get analysis_tab_stereonet => 'Stereonet';

  @override
  String get analysis_tab_trends => 'Trends';

  @override
  String get analytics_weekly => 'ANALYTICS (7 DAYS)';

  @override
  String get app_description =>
      'GeoField Pro N is a complete geological field system: GPS/UTM coordinates, strike/dip/azimuth measurements, photo and audio notes, offline maps and routes, KML/DXF import, CSV/GeoJSON/KML/GPX/PDF export, stereonet and statistical analysis, real-time chat, cloud sync, security, and multilingual operation.';

  @override
  String get app_look_label => 'App Appearance';

  @override
  String get app_title => 'GeoField Pro N';

  @override
  String get apparent_dip_calc_title => 'APPARENT DIP CALCULATOR';

  @override
  String get apparent_dip_direction => 'Dip Direction:';

  @override
  String get apparent_dip_formula_hint =>
      'tan(α) = tan(δ) × |cos(β)|\nwhere β = angle between dip direction and section azimuth';

  @override
  String get apparent_dip_title => 'APPARENT DIP';

  @override
  String get apparent_note_body =>
      '• If section direction is parallel to dip direction (β≈0°) → apparent dip = true dip\n• If section direction is perpendicular to dip direction (β≈90°) → apparent dip = 0°\n• Used in geological sections and map thickness estimations';

  @override
  String apparent_result_hint(String trueDip, String apparent) {
    return 'True dip: $trueDip°  →  Apparent: $apparent°';
  }

  @override
  String get apparent_section_azimuth => 'Section Azimuth:';

  @override
  String get apparent_true_dip => 'True Dip (δ):';

  @override
  String get archive => 'Archive';

  @override
  String get area_label => 'Area';

  @override
  String get auto_recommendation => 'AUTOMATIC RECOMMENDATION';

  @override
  String get azimuth_label => 'Heading (Azimuth)';

  @override
  String get camera_azimuth_short => 'Azimuth';

  @override
  String get bedding => 'Bedding';

  @override
  String get by_project => 'By Project';

  @override
  String get by_rock_type => 'By Rock Type';

  @override
  String get calculate => 'Calculate';

  @override
  String get calibration_instruction =>
      'Place a physical ruler on screen and match 1 cm.';

  @override
  String get camera => 'Camera';

  @override
  String get camera_error => 'Camera Error';

  @override
  String get camera_focus_mode_title => 'Geological Camera — Focus Mode';

  @override
  String get camera_guide_button => 'Guide';

  @override
  String get camera_voice_record_label => 'Record voice note';

  @override
  String get camera_torch_label => 'Light';

  @override
  String get camera_scale_label => 'Zoom';

  @override
  String get camera_close_label => 'Close';

  @override
  String get camera_heading_info_line => 'GPS accuracy & sensor info';

  @override
  String get camera_voice_mic_hint =>
      'Mic: tap to record a voice note for this station (saved when you save the shot).';

  @override
  String get viewer_3d_legend =>
      'Each point: station location. Orange fill: bedding plane from strike/dip. Drag to rotate the view, use +/− to zoom. Darker orange ≈ steeper dip.';

  @override
  String get viewer_3d_no_data =>
      'No stations yet — add field stations to see 3D planes.';

  @override
  String get viewer_3d_nothing_visible =>
      'Content may be off-screen. Pinch/rotate, use +/-, or move the view.';

  @override
  String get map_draw_undo_caption => 'Last point';

  @override
  String get map_gesture_undo_hint =>
      'Remove last point: ↩ below, long-press the map, or two-finger tap / secondary click.';

  @override
  String get map_tap_line_delete_message =>
      'This linework will be permanently removed. This cannot be undone.';

  @override
  String get map_line_deleted_snack => 'Linework removed';

  @override
  String get map_structure_mode_tooltip => 'Place strike/dip on map';

  @override
  String get map_structure_mode_hint =>
      'Tap the map to add a strike/dip symbol. Tap an existing symbol to delete it.';

  @override
  String get map_structure_add_title => 'Strike / dip';

  @override
  String get map_structure_strike_label => 'Strike (°)';

  @override
  String get map_structure_dip_label => 'Dip (°)';

  @override
  String get map_structure_type_label => 'Structure type';

  @override
  String get map_structure_deleted_snack => 'Structure marker removed';

  @override
  String get map_structure_delete_body =>
      'This structure marker will be permanently removed. This cannot be undone.';

  @override
  String get ai_vertex_disabled_title => 'AI backend (Vertex) is not enabled';

  @override
  String get ai_vertex_disabled_body =>
      'Document analysis uses Google Cloud (Firebase AI Logic / Vertex AI). Ask the project admin to enable the API for this Firebase project, wait 2–5 minutes, then tap Retry.';

  @override
  String get ai_vertex_open_console => 'Open Google Cloud API page';

  @override
  String get ai_vertex_quota_billing_title => 'AI limit or billing';

  @override
  String get ai_vertex_quota_billing_body =>
      'Vertex / Gemini has a free tier with limits, then Cloud Billing applies. In Google Cloud Console, check Billing, quotas, and Generative Language / Vertex API usage, or try again later.';

  @override
  String get draw_first_point_hint =>
      'First point placed. Keep tapping to draw the line.';

  @override
  String get notifications_screen_title => 'Notifications';

  @override
  String get notifications_empty_hint =>
      'No announcements yet. Broadcasts appear here when your team writes documents to the Firestore collection \"geofield_broadcasts\" (read access for signed-in users).';

  @override
  String get notifications_open_chats => 'Open chats';

  @override
  String get sync_purpose_tooltip =>
      'Offline: data is stored on the device and uploads when the internet is back. Who-sees-what on the server depends on your Firestore rules and features enabled for the project.';

  @override
  String get map_layer_import_gis => 'Import GIS: KML, DXF, GeoJSON, SHP, GPKG';

  @override
  String get map_layer_export_data => 'Export data (archive)';

  @override
  String get field_workshop_title => 'Field workshop';

  @override
  String get field_workshop_fab_tooltip =>
      'Pro workshop: layers, KML/DXF, linework, structure';

  @override
  String get field_workshop_banner =>
      'Layers, GIS import, drawing and field tools in one place.';

  @override
  String get map_measure_mode => 'Measure (distance & area)';

  @override
  String get map_measure_hint =>
      'Tap the map: 2 points = distance, 3+ = area of polygon.';

  @override
  String get map_measure_clear => 'Clear measure';

  @override
  String get map_measure_bearing => 'Bearing';

  @override
  String get map_measure_angle => 'Angle at last point (°)';

  @override
  String get map_export_geojson => 'Export map as GeoJSON';

  @override
  String get field_workshop_stereonet => 'Stereonet / analysis';

  @override
  String get field_utm_tap => 'UTM of map center (clipboard)';

  @override
  String get line_action_edit => 'Edit line properties';

  @override
  String get line_property_title => 'Line properties';

  @override
  String get line_property_name => 'Name';

  @override
  String get line_property_notes => 'Notes';

  @override
  String get field_workshop_checklist => 'Field checklist (tap to check)';

  @override
  String get field_workshop_ch1 => 'Base map and GIS layers';

  @override
  String get field_workshop_ch2 => 'KML, DXF, GeoJSON, Shapefile, GeoPackage';

  @override
  String get field_workshop_ch3 => 'Drawings, measure, then export if needed';

  @override
  String get map_offline_tiles_hint =>
      'Base map tiles cache as you pan. Pre-load an area by zooming/panning before going offline. Full “merge & download region” is on the roadmap.';

  @override
  String get camera_header_document => 'DOCUMENT SYNC';

  @override
  String get camera_header_geology => 'GEOLOGY';

  @override
  String get camera_mode_document => 'Report';

  @override
  String get camera_mode_geology => 'Geological';

  @override
  String get camera_pro_sheet_hint =>
      'Ruler, horizon gain, expert overlays, and HUD (geology mode).';

  @override
  String get cancel => 'Cancel';

  @override
  String get cleavage => 'Cleavage';

  @override
  String get close => 'Close';

  @override
  String get color => 'Color';

  @override
  String get color_chart_title => 'MUNSELL COLOR CHART';

  @override
  String get compass => 'Compass';

  @override
  String get compass_8_motion => 'ROTATE IN \"8\" PATTERN TO CALIBRATE COMPASS';

  @override
  String get compass_calibration => 'Calibration Guide';

  @override
  String get compass_calibration_long =>
      'To ensure azimuth and dip accuracy, move your device in a \"figure 8\" pattern several times.';

  @override
  String get compass_unreliable_warn =>
      'WARNING: Compass is unreliable! Move your phone in a figure-8 first.';

  @override
  String get confidence => 'Confidence';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirm_delete => 'Confirm Delete?';

  @override
  String get confirm_delete_all =>
      'All local station data will be deleted. Do you want to continue?';

  @override
  String get confirm_delete_all_tracks => 'Delete all tracks?';

  @override
  String get contact => 'Contact';

  @override
  String get coordinate_sync => 'Update Coordinates';

  @override
  String get count_suffix => 'units';

  @override
  String get create_btn => 'Create';

  @override
  String get custom_input => 'Custom Input';

  @override
  String get dark_grey => 'Dark Grey';

  @override
  String get dashboard => 'Main';

  @override
  String get dashboard_hero_title => 'Pro Geological Home';

  @override
  String get dashboard_view_all => 'All';

  @override
  String get delete => 'Delete';

  @override
  String get delete_all_label => 'Delete All';

  @override
  String get delete_confirm_btn => 'Yes, delete';

  @override
  String get delete_photo => 'Delete Photo';

  @override
  String get delete_project_title => 'Delete Project';

  @override
  String get delete_project_warn =>
      'Delete this project? All stations inside will be moved to the \"Default\" project.';

  @override
  String get density_heatmap => 'Density heatmap';

  @override
  String get description => 'Description';

  @override
  String get description_hint =>
      'Record rock composition, minerals, contacts, and strike/dip variations here...';

  @override
  String get dip => 'Dip';

  @override
  String get dip_direction => 'Dip Direction';

  @override
  String get dip_distribution => 'DIP DISTRIBUTION';

  @override
  String get dip_label => 'Dip';

  @override
  String get distance_label => 'DISTANCE';

  @override
  String get distance_warning => 'WARNING! Distance difference.';

  @override
  String get document_align_hint => 'Align the document within the frame';

  @override
  String get dominant_direction => 'Dominant direction';

  @override
  String get download_confirm => 'Continue downloading?';

  @override
  String get download_pdf => 'Download PDF Report';

  @override
  String get download_region_tooltip => 'Download visible region';

  @override
  String get draw_on_photo => 'Draw on photo';

  @override
  String get drawing_name => 'Drawing name';

  @override
  String get drawing_saved => 'Geological drawing saved';

  @override
  String get dxf_notice_body =>
      'For DXF import use ASCII (text) DXF, not binary. Coordinates must be WGS-84 geographic decimal degrees: X = longitude, Y = latitude. UTM/local meter drawings will be misplaced — reproject to WGS84 in CAD/GIS first.';

  @override
  String get dxf_notice_title => 'About DXF import';

  @override
  String get gis_import_precheck_title => 'GIS import — formats & DXF';

  @override
  String get gis_import_precheck_body =>
      'After Choose file you will pick a file from your device.\n\n• Supported: KML, GeoJSON (.geojson or .json), DXF, Shapefile (.shp), GeoPackage (.gpkg).\n• Web browser: .gpkg is not supported (no SQLite).\n\nDXF (important):\n• File must be ASCII DXF (not Binary DXF). In AutoCAD, use Save As and select ASCII DXF if offered.\n• Coordinates must be WGS-84 geographic (decimal degrees): X = longitude, Y = latitude. UTM or local meters will appear wrong — reproject to WGS84 before import.\n\nCloud: without login or if Firebase is unavailable, imported layers stay on this device only.';

  @override
  String get gis_import_choose_file => 'Choose file';

  @override
  String get gis_import_empty_result =>
      'No GIS layers were imported. Check the file, or use ASCII DXF in WGS-84 (longitude/latitude). KML/GeoJSON are often easier for a quick test.';

  @override
  String get gis_import_normalized_hint =>
      'Some vertex coordinates were auto-swapped to valid latitude/longitude — check placement on the map.';

  @override
  String get echo_mode_on => 'POWER SAVER: ACTIVE';

  @override
  String get eco_mode => 'Eco Mode';

  @override
  String get edit_coordinates => 'Edit Coordinates (Lat / Lon)';

  @override
  String get edit_disable => 'DISABLE EDIT';

  @override
  String get edit_enable => 'ENABLE EDIT';

  @override
  String get edit_project => 'Edit Project';

  @override
  String get expert_mode => 'Professional mode';

  @override
  String get general_settings_section => 'General settings';

  @override
  String get export_csv => 'Export CSV';

  @override
  String get export_actions_section => 'Export & actions';

  @override
  String get export_stations_excel => 'Export stations (Excel)';

  @override
  String get export_geojson => 'Export GeoJSON';

  @override
  String get map_elevation_center_tooltip =>
      'Elevation at map center (DEM, online)';

  @override
  String get elevation_lookup_progress => 'Requesting elevation…';

  @override
  String get elevation_lookup_failed =>
      'Could not get elevation (check network).';

  @override
  String elevation_meters_result(String m) {
    return 'Approx. elevation: $m m (DEM)';
  }

  @override
  String get snap_to_grid_label => 'Draw snap: local grid (m, 0 = off)';

  @override
  String get export_kml => 'KML (Google Earth)';

  @override
  String get export_no_stations => 'No stations to export.';

  @override
  String get export_pdf => 'PDF Report';

  @override
  String get export_select_project => 'Which project to export?';

  @override
  String get export_title => 'Choose Export Format';

  @override
  String get field_assets => 'Field Assets (Photo & Audio)';

  @override
  String get filter => 'Filter';

  @override
  String get firebase_local_only_banner =>
      'Local mode: Firebase did not start. Field data is saved on device; sign-in and cloud sync are unavailable until the network and configuration are fixed.';

  @override
  String get fisher_dispersion => 'HIGH DISPERSION ⚠️';

  @override
  String get fisher_reliability => 'FISHER RELIABILITY';

  @override
  String get fisher_stable => 'STABLE TREND ✅';

  @override
  String get fisher_gauge_high => 'High reliability';

  @override
  String get fisher_stats => 'Fisher statistics';

  @override
  String get fisher_reliability_help =>
      'α₉₅ is the 95% confidence cone (Fisher) for all station strikes. A smaller angle means strikes cluster in one direction; a larger angle means more scatter. The green/orange status uses the usual field rule: reliable when n ≥ 5 and the mean vector length R > 0.5.';

  @override
  String get dashboard_data_export => 'Export data';

  @override
  String get dashboard_gis_import => 'Import KML/DXF';

  @override
  String get voice_open_camera_hint =>
      'Camera is open. Use the microphone in the camera to add a voice note; the station is saved when you finish the photo and save step.';

  @override
  String get map_slice_tooltip =>
      'Profile line (scissors): tap two points on the map to build a line and open a cross-section along it.';

  @override
  String get map_3d_tooltip =>
      '3D: terrain and stations around the current map center. Move the map first if you need another area.';

  @override
  String get map_track_fab_aria => 'Record GPS route (track)';

  @override
  String get map_ultra_pro_tooltip => 'Ultra Pro Multi-Tool';

  @override
  String get map_start_stop_tracking => 'Start/Stop Tracking';

  @override
  String get map_radial_strike_dip => 'Manual Strike/Dip';

  @override
  String get map_radial_sampling => 'Sampling';

  @override
  String get map_radial_field_notes => 'Field Notes';

  @override
  String get map_radial_project_layers => 'Project Layers';

  @override
  String get track_start_failed =>
      'Could not start the route. Turn on GPS and allow location in system settings.';

  @override
  String gis_import_done(int imported, int skipped) {
    return 'GIS import: $imported added, $skipped skipped.';
  }

  @override
  String get foliated => 'Foliated';

  @override
  String get geoloc_header => 'GEOLOCATION';

  @override
  String get gis_monitoring_active => 'GIS Monitoring Active';

  @override
  String get gps_error => 'GPS Error';

  @override
  String get gps_locked => 'GPS Locked';

  @override
  String get gps_not_locked => 'GPS not locked';

  @override
  String get gps_off_alert =>
      'WARNING: GPS is off. Please enable for field work.';

  @override
  String get gps_performance => 'GPS PERFORMANCE';

  @override
  String get gps_status_good => 'High Accuracy (Good)';

  @override
  String get gps_status_medium => 'Medium Accuracy';

  @override
  String get gps_status_medium_short => 'GPS (Medium)';

  @override
  String get gps_status_off => 'GPS Off';

  @override
  String get gps_status_poor => 'Low Accuracy';

  @override
  String get gps_status_poor_short => 'GPS (Poor)';

  @override
  String get gps_status_searching => 'Searching...';

  @override
  String get gpx_export_unavailable => 'GPX Export is temporarily unavailable';

  @override
  String get grade_dist => 'GRADE DISTRIBUTION';

  @override
  String get ground_area_label => 'REAL AREA ON PAPER';

  @override
  String get hdop => 'HDOP';

  @override
  String get height_cm => 'HEIGHT (CM)';

  @override
  String get high_accuracy_good => 'High Accuracy';

  @override
  String get hold => 'HOLD';

  @override
  String get horizon_level => 'HORIZON LEVEL';

  @override
  String get hud_toggle => 'Interface (HUD)';

  @override
  String get input_data => 'INPUT DATA';

  @override
  String get joint => 'Joint';

  @override
  String get language => 'Language';

  @override
  String get last_update => 'Last Update';

  @override
  String get lat_label => 'Latitude (North/South)';

  @override
  String get lat_lon_error => 'Invalid Lat/Lon';

  @override
  String get layer_base_map => 'Base map';

  @override
  String get layer_drawings => 'Drawings';

  @override
  String get layer_gis_kml => 'GIS layer (KML)';

  @override
  String get layer_management => 'LAYER MANAGEMENT';

  @override
  String get layered => 'Layered';

  @override
  String get layout_explanation =>
      'The ground area that fits on the chosen paper.';

  @override
  String get layout_planner => 'LAYOUT (PAPER PLANNER)';

  @override
  String get light_grey => 'Light Grey';

  @override
  String get light_toggle => 'Flash / Torch';

  @override
  String get lineation => 'Lineation';

  @override
  String get lithology_data => 'Lithology & Station Data';

  @override
  String get lng_label => 'Longitude (East/West)';

  @override
  String get loading => 'Loading...';

  @override
  String get location_denied_alert =>
      'Location permission denied. Enable in settings.';

  @override
  String get mag_decl_short => 'MAG. DEC';

  @override
  String get magmatic => 'Magmatic';

  @override
  String get magnetic_declination => 'Magnetic Declination';

  @override
  String get magnetic_declination_desc => 'East (+), West (-) in degrees';

  @override
  String get mandatory_step_label => 'MANDATORY STEP';

  @override
  String get map => 'Map';

  @override
  String get map_error_prefix => 'An error occurred';

  @override
  String get map_style_osm => 'OpenStreetMap Standard';

  @override
  String get map_style_satellite => 'Satellite (Esri)';

  @override
  String get map_style_topo => 'OpenTopoMap';

  @override
  String get massive => 'Massive';

  @override
  String get measurement_error_high => 'Warning! Measurement error is high';

  @override
  String get measurement_label => 'Measurement Type';

  @override
  String get measurements_count => 'MEASUREMENTS';

  @override
  String get medium_accuracy_warn => 'Medium Accuracy';

  @override
  String get metamorphic => 'Metamorphic';

  @override
  String get mic_error => 'Microphone permission denied';

  @override
  String get millimetrovka_calc => 'MILLIMETROVKA CALCULATOR';

  @override
  String get munsell_color => 'Munsell Color';

  @override
  String get new_project_hint => 'e.g., Mount Everest 2026';

  @override
  String get new_project_title => 'New Project';

  @override
  String get new_station_btn => 'NEW STATION';

  @override
  String get next_station => '+ Next';

  @override
  String get no_data => 'No data found';

  @override
  String get no_local_data => 'No local data found';

  @override
  String get no_stations_in_project => 'No stations in the selected project.';

  @override
  String get note => 'NOTE';

  @override
  String get note_saved => 'Note Saved';

  @override
  String get observation_area_label => 'Observation area';

  @override
  String get offline_download => 'Offline Download';

  @override
  String get open_map => 'OPEN MAP';

  @override
  String get other => 'Other';

  @override
  String get paper_distance => 'ON PAPER';

  @override
  String get paper_format_label => 'CHOOSE PAPER FORMAT:';

  @override
  String get pdf_report => 'PDF Report';

  @override
  String get perimeter_label => 'Perimeter';

  @override
  String get photo_added => 'Photo added successfully';

  @override
  String get photo_deleted_snack => 'Photo deleted';

  @override
  String get poor_accuracy_warn => 'Poor Accuracy';

  @override
  String get power_saver => 'Power saver mode';

  @override
  String get professional_tag => 'PROFESSIONAL';

  @override
  String get profile_section_label => 'Profile';

  @override
  String get project => 'Project';

  @override
  String get project_and_archive => 'PROJECT & ARCHIVE';

  @override
  String get project_label => 'Project';

  @override
  String get project_stats => 'PROJECT STATISTICS';

  @override
  String get projection_depth => 'PROJECTION DEPTH';

  @override
  String get projects_count => 'Projects Count';

  @override
  String get real_distance => 'REAL DISTANCE';

  @override
  String get record_error => 'Audio recording error';

  @override
  String get recording_started => 'Recording Started';

  @override
  String get records_count => 'records';

  @override
  String get red_ochre => 'Red/Ochre';

  @override
  String get reliability_index => 'Reliability index';

  @override
  String get rename => 'Rename';

  @override
  String get rename_route => 'Rename Route';

  @override
  String get results_count => 'results';

  @override
  String get role_geologist_admin => 'Geologist-Administrator';

  @override
  String get rock_classification => 'Rock Classification';

  @override
  String get rock_type => 'Rock Type';

  @override
  String get rose_diagram_subtitle =>
      'Each sector = 22.5° | Length ~ station count';

  @override
  String get rose_diagram_title => 'ROSE DIAGRAM (STRIKE)';

  @override
  String get route_name_prefix => 'Route';

  @override
  String get route_saved_snack =>
      'Route saved. You can find it in the Archive.';

  @override
  String get routes => 'Routes';

  @override
  String get rtk_fixed => 'RTK FIXED STATUS';

  @override
  String get ruler_calibration_title => 'DIGITAL RULER & CALIBRATION';

  @override
  String get ruler_label => 'RULER';

  @override
  String get sample_id => 'Sample ID';

  @override
  String get sample_type => 'Sample Type';

  @override
  String get satellites => 'SATS';

  @override
  String get save => 'Save';

  @override
  String get save_drawing_title => 'Save drawing';

  @override
  String get save_first_hint => 'Save station or capture from camera first';

  @override
  String get save_label => 'Save';

  @override
  String get scale_assistant_help_content =>
      '1. Millimetrovka Calculator: Converts real distance to mm on paper.\n2. Layout: Calculates area fitting on chosen paper format.\n3. Calibration: Adjust ruler DPI using a physical ruler.';

  @override
  String get scale_assistant_help_title => 'Help';

  @override
  String get scale_assistant_title => 'SCALE ASSISTANT';

  @override
  String get scale_short => 'Scale';

  @override
  String get search => 'Search';

  @override
  String get searching_gps => 'Searching GPS...';

  @override
  String get sedimentary => 'Sedimentary';

  @override
  String get select_two_points => 'Select 2 points on the map (section line)';

  @override
  String get selected_label => 'selected';

  @override
  String get selected_scale => 'SELECTED SCALE';

  @override
  String get session => 'Session';

  @override
  String get session_pause_tooltip => 'Pause route';

  @override
  String get settings => 'Settings';

  @override
  String get share => 'Share';

  @override
  String get signal_searching => 'SIGNAL SEARCHING';

  @override
  String get sos_sent => 'SOS signal sent! Team has been alerted.';

  @override
  String get sos_gps_unavailable =>
      'Could not get GPS. Go outdoors or wait for a fix, then try again.';

  @override
  String get sos_cancel => 'End SOS';

  @override
  String get sos_cancelled => 'SOS ended';

  @override
  String get sos_login_required =>
      'Sign in to send SOS. Without an account the signal is not sent.';

  @override
  String get sos_queue_cancel => 'Cancel queued SOS (offline queue)';

  @override
  String get sos_queue_cleared => 'Offline SOS queue cleared';

  @override
  String get map_follow_gps => 'Follow my position (keeps the map on GPS)';

  @override
  String get map_pro_tools_title => 'Pro tools (map)';

  @override
  String get map_pro_tools_subtitle =>
      'Dala va GIS: qatlamlar, o‘lchov, kesim, 3D, eksport — bittadan tanlang, xaritaga qaytasiz.';

  @override
  String get nav_messages => 'Messages';

  @override
  String get nav_more => 'More';

  @override
  String get camera_pro_short_label => 'Pro';

  @override
  String get messages_hub_title => 'Messages hub';

  @override
  String get messages_sync_tooltip => 'Sync with cloud';

  @override
  String get messages_sync_started => 'Sync started';

  @override
  String get messages_no_groups => 'No groups yet';

  @override
  String get sos_cancel_failed =>
      'Could not end SOS (network or rules). Check connection and try again.';

  @override
  String get photo_saved_limited_gps =>
      'Photo saved. GPS was not available — you can correct the station position later.';

  @override
  String get start => 'Start';

  @override
  String get station_project_label => 'Project';

  @override
  String get station_saved => 'Station Saved';

  @override
  String get stations => 'Stations';

  @override
  String get stations_count => 'STATIONS';

  @override
  String get stations_suffix => 'stations';

  @override
  String get statistics_label => 'Statistics';

  @override
  String get stereonet_density_hint_label => 'Density heatmap';

  @override
  String get stereonet_density_hint_value => 'thicker zone means more points';

  @override
  String get stereonet_mean => 'Mean Pole';

  @override
  String get stereonet_no_data => 'Stereonet: No Data';

  @override
  String get stereonet_planes => 'Planes';

  @override
  String get stereonet_schmidt => 'STEREONET (SCHMIDT NET)';

  @override
  String get stereonet_schmidt_desc =>
      'Equal-area projection — lower hemisphere';

  @override
  String get stereonet_summary => 'STEREONET SUMMARY';

  @override
  String get stereonet_wulff => 'STEREONET (WULFF NET)';

  @override
  String get stereonet_wulff_desc =>
      'Equal-angle projection — lower hemisphere';

  @override
  String get stop => 'Stop';

  @override
  String get strike => 'Strike';

  @override
  String get strike_label => 'Strike';

  @override
  String get structural_measurements => 'Structural Measurements';

  @override
  String get structure => 'Structure';

  @override
  String get structure_label => 'Structure / Texture';

  @override
  String get success_saved => 'Station Saved Successfully';

  @override
  String get sync => 'Sync';

  @override
  String get system_online => 'SYSTEM ONLINE';

  @override
  String get tahlil_label => 'Analysis';

  @override
  String get theme_dark => 'Dark';

  @override
  String get theme_light => 'Light';

  @override
  String get theme_system => 'System';

  @override
  String get three_d_structure => '3D STRUCTURE';

  @override
  String get time_label => 'TIME';

  @override
  String get today_only => 'Today only';

  @override
  String get total_stations => 'Total Stations';

  @override
  String get total_stations_short => 'Total stations';

  @override
  String get tracking_started_snack => 'Tracking started!';

  @override
  String get trend_analysis => 'STATISTICAL TREND ANALYSIS';

  @override
  String get trend_density => 'Density level (κ)';

  @override
  String get trend_growth => 'Trend: +12% Growth';

  @override
  String get trend_orientation => 'Orientation';

  @override
  String trend_recommend_good(String dir) {
    return 'Main ore orientation follows $dir.';
  }

  @override
  String get trend_recommend_poor => 'Data dispersion is high, no clear trend.';

  @override
  String get trend_reliability => 'Reliability (α₉₅)';

  @override
  String get understood => 'Understood';

  @override
  String get undo => 'Undo';

  @override
  String get unknown => 'Unknown';

  @override
  String get unsaved_changes => 'Unsaved Changes';

  @override
  String get unsaved_changes_desc =>
      'Unsaved changes will be lost. Do you really want to leave?';

  @override
  String get utm_coordinates => 'UTM COORDINATES';

  @override
  String get version => 'Version';

  @override
  String get voice_note => 'Voice Note';

  @override
  String get voice_record => 'Voice record';

  @override
  String get warning_label => 'Warning';

  @override
  String get welcome_text => 'Welcome, ';

  @override
  String get width_cm => 'WIDTH (CM)';

  @override
  String get zoom_label => 'Zoom';
}
