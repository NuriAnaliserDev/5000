// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_strings.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class GeoFieldStringsUz extends GeoFieldStrings {
  GeoFieldStringsUz([String locale = 'uz']) : super(locale);

  @override
  String get about_app => 'Ilova haqida';

  @override
  String get acc_label => 'ACC';

  @override
  String get accuracy => 'Aniqlik';

  @override
  String get ai_lithology_applied_hint =>
      'AI taxmini qo‘llandi. Barcha maydonlarni maydonda tekshiring.';

  @override
  String get ai_lithology_btn => 'AI litologiya';

  @override
  String get ai_lithology_error => 'AI xatosi';

  @override
  String get ai_lithology_minerals_prefix => 'Minerallar:';

  @override
  String get ai_lithology_need_photo =>
      'AI tahlil uchun avval stansiyaga rasm qo‘shing (kamera yoki galereya).';

  @override
  String get actions_label => 'Amallar';

  @override
  String get active_point_label => 'Faol geologik nuqta';

  @override
  String get add_first_station => 'Birinchi stansiyani yaratish';

  @override
  String get add_gallery => '+ Galereya';

  @override
  String get admin => 'Admin';

  @override
  String get all_projects => 'Barcha loyihalar';

  @override
  String get all_stations => 'Barchasi (Hamma stansiyalar)';

  @override
  String get altitude => 'Balandlik';

  @override
  String get altitude_offset_desc => 'Balandlikni to‘g‘rilash (metrda)';

  @override
  String get analysis_alt_range => 'Balandlik oralig‘i';

  @override
  String get analysis_avg_dip => 'O‘rtacha Dip';

  @override
  String get analysis_circular_mean_strike => 'Circular Mean Strike';

  @override
  String get analysis_dip_direction => 'Dip Direction';

  @override
  String get analysis_extra_measurements => 'Qo‘shimcha o‘lchovlar';

  @override
  String get analysis_fisher_stats => 'FISHER STATISTIKASI (STRIKE)';

  @override
  String get analysis_general => 'UMUMIY';

  @override
  String get analysis_measure_types => 'O‘LCHOV TURI BO‘YICHA';

  @override
  String get analysis_orientation_mean => 'O‘RTACHA YO‘NALISH (VEKTORIAL)';

  @override
  String get analysis_primary_measurement => 'Asosiy o‘lchov';

  @override
  String get analysis_project_count => 'Loyihalar soni';

  @override
  String get analysis_projects => 'LOYIHALAR BO‘YICHA';

  @override
  String get analysis_rock_type => 'Tosh turi';

  @override
  String get analysis_rocks => 'TOG‘ JINSI BO‘YICHA';

  @override
  String get analysis_stat_reliable => 'Statistika ishonchli (n≥5, R>0.5)';

  @override
  String get analysis_stat_unreliable =>
      'Ko‘proq o‘lchov kerak (n≥5 va R>0.5 bo‘lsin)';

  @override
  String get analysis_station_count => 'Stansiyalar soni';

  @override
  String get analysis_strike_std => 'Strike Std Dev (σ)';

  @override
  String get analysis_with_gps => 'GPS bilan';

  @override
  String get analytics_weekly => 'ANALITIKA (7 KUNLIK)';

  @override
  String get app_description =>
      'GeoField Pro N – geologik dala ishlari uchun to‘liq tizim: GPS/UTM koordinata, strike/dip/azimut o‘lchovlari, foto va audio qayd, oflayn xarita va marshrutlar, KML/DXF import, CSV/GeoJSON/KML/GPX/PDF eksport, stereonet va statistik tahlil, real-time chat, bulut sinxronizatsiya, xavfsizlik va ko‘p tilli boshqaruv.';

  @override
  String get app_look_label => 'Ilova ko‘rinishi';

  @override
  String get app_title => 'GeoField Pro N';

  @override
  String get apparent_dip_calc_title => 'APPARENT DIP KALKULYATORI';

  @override
  String get apparent_dip_direction => 'Dip Yo‘nalishi:';

  @override
  String get apparent_dip_formula_hint =>
      'tan(α) = tan(δ) × |cos(β)|\nbu yerda β = dip direction va kesim azimuti orasidagi burchak';

  @override
  String get apparent_dip_title => 'KO\'RINMA YOTISH (APPARENT DIP)';

  @override
  String get apparent_note_body =>
      '• Kesim yo‘nalishi dip yo‘nalishiga parallel bo‘lsa (β≈0°) → ko‘rinma dip = haqiqiy dip\n• Kesim yo‘nalishi dip yo‘nalishiga perpendikulyar (β≈90°) → ko‘rinma dip = 0°\n• Geologik kesimlar va xarita qalinligi hisob-kitobida ishlatiladi';

  @override
  String apparent_result_hint(String trueDip, String apparent) {
    return 'Haqiqiy dip: $trueDip°  →  Ko‘rinma: $apparent°';
  }

  @override
  String get apparent_section_azimuth => 'Kesim Azimuti:';

  @override
  String get apparent_true_dip => 'Haqiqiy Dip (δ):';

  @override
  String get archive => 'Arxiv';

  @override
  String get area_label => 'Maydoni';

  @override
  String get auto_recommendation => 'AVTOMATIK TAVSIYA';

  @override
  String get azimuth_label => 'Yo‘nalish (Azimut)';

  @override
  String get bedding => 'Qatlamlanish (Bedding)';

  @override
  String get by_project => 'Loyihalar bo‘yicha';

  @override
  String get by_rock_type => 'Tosh turlari bo‘yicha';

  @override
  String get calculate => 'Hisoblash';

  @override
  String get calibration_instruction =>
      'Haqiqiy lineykani ekranga qo‘ying va 1 sm ni moslang.';

  @override
  String get camera => 'Kamera';

  @override
  String get camera_error => 'Kamera xatosi';

  @override
  String get camera_header_document => 'HUJJAT SINXRON';

  @override
  String get camera_header_geology => 'GEOLOGIYA';

  @override
  String get camera_mode_document => 'Hisobot';

  @override
  String get camera_mode_geology => 'Geologik';

  @override
  String get cancel => 'Bekor qilish';

  @override
  String get cleavage => 'Klivaj (Cleavage)';

  @override
  String get close => 'Yopish';

  @override
  String get color => 'Rangi';

  @override
  String get color_chart_title => 'MUNSELL COLOR CHART (RANG CHISMASI)';

  @override
  String get compass => 'Kompas';

  @override
  String get compass_8_motion =>
      'KOMPASNI SOZLASH UCHUN \"8\" SHAKLIDA AYLANTIRING';

  @override
  String get compass_calibration => 'Yo‘riqnoma';

  @override
  String get compass_calibration_long =>
      'Azimut va qiyalik (strike/dip) aniq bo‘lishi uchun telefonni havoda \"8\" shaklida bir necha marta aylantiring.';

  @override
  String get compass_unreliable_warn =>
      'DIQQAT: Kompas ishonchsiz! Avval telefonni 8 raqami shaklida aylantiring.';

  @override
  String get confidence => 'Ishonchlilik (Confidence)';

  @override
  String get confirm => 'Tasdiqlash';

  @override
  String get confirm_delete => 'O‘chirilsinmi?';

  @override
  String get confirm_delete_all =>
      'Barcha mahalliy stansiya ma’lumotlari o‘chiriladi. Davom etishni xohlaysizmi?';

  @override
  String get confirm_delete_all_tracks => 'Barcha marshrutlar o‘chirilsinmi?';

  @override
  String get contact => 'Kontakt (Contact)';

  @override
  String get coordinate_sync => 'Koordinatalarni yangilash';

  @override
  String get count_suffix => 'ta';

  @override
  String get create_btn => 'Yaratish';

  @override
  String get custom_input => 'Qo‘lda kiritish';

  @override
  String get dark_grey => 'To‘q kulrang';

  @override
  String get dashboard => 'Asosiy';

  @override
  String get delete => 'O‘chirish';

  @override
  String get delete_all_label => 'Hammasini o‘chirish';

  @override
  String get delete_confirm_btn => 'Ha, o‘chirish';

  @override
  String get delete_photo => 'Fotoni o‘chirish';

  @override
  String get delete_project_title => 'Loyihani o‘chirish';

  @override
  String get delete_project_warn =>
      'Ushbu loyiha o‘chirilsinmi? Ichidagi stansiyalar \"Default\" loyihasiga o‘tkaziladi.';

  @override
  String get density_heatmap => 'Zichlik issiqlik xaritasi';

  @override
  String get description => 'Dala tavsifi';

  @override
  String get description_hint =>
      'Bu yerda tosh tarkibi, minerallari, kontaktlar va strike/dip o‘zgarishlarini yozib boring...';

  @override
  String get dip => 'Yotish (Dip)';

  @override
  String get dip_direction => 'Yotish Azimuti';

  @override
  String get dip_distribution => 'DIP (ENISH) TAQSIMOTI';

  @override
  String get dip_label => 'Yotish (Dip)';

  @override
  String get distance_label => 'MASOFA';

  @override
  String get distance_warning => 'DIQQAT! Masofada farq bor.';

  @override
  String get document_align_hint => 'Hujjatni ramkaga to‘g‘rilang';

  @override
  String get dominant_direction => 'Dominant yo‘nalish';

  @override
  String get download_confirm => 'Davom etamizmi?';

  @override
  String get download_pdf => 'PDF Hisobot Yuklab Olish';

  @override
  String get download_region_tooltip => 'Ekranda ko‘ringan hududni yuklash';

  @override
  String get draw_on_photo => 'Rasmga chizish';

  @override
  String get drawing_name => 'Chizma nomi';

  @override
  String get drawing_saved => 'Geologik chizma saqlandi';

  @override
  String get dxf_notice_body =>
      'DXF importida chizma GPS geografik proyeksiyasida (WGS-84 Lat/Lng) bo‘lishi kerak. Aks holda chizma xaritada noto‘g‘ri joylashadi.';

  @override
  String get dxf_notice_title => 'DXF eslatmasi';

  @override
  String get echo_mode_on => 'TEJAMKOR REJIM: FAOL';

  @override
  String get eco_mode => 'Tejamkor rejim';

  @override
  String get edit_coordinates => 'Koordinatalarni tahrirlash (Lat / Lon)';

  @override
  String get edit_disable => 'TAHRIRNI YOPISH';

  @override
  String get edit_enable => 'TAHRIRLASH (EDIT)';

  @override
  String get edit_project => 'Loyihani tahrirlash';

  @override
  String get expert_mode => 'Ekspert rejimi';

  @override
  String get export_csv => 'CSV eksport';

  @override
  String get export_geojson => 'GeoJSON eksport';

  @override
  String get export_kml => 'KML (Google Earth)';

  @override
  String get export_no_stations => 'Eksport qilish uchun stansiya yo‘q.';

  @override
  String get export_pdf => 'PDF hisobot';

  @override
  String get export_select_project => 'Qaysi loyihani eksport qilasiz?';

  @override
  String get export_title => 'Eksport turini tanlang';

  @override
  String get field_assets => 'Maydon aktivlari (foto va ma’lumotlar)';

  @override
  String get filter => 'Filtrlash';

  @override
  String get fisher_dispersion => 'YUQORI DISPERSIYA ⚠️';

  @override
  String get fisher_reliability => 'FISHER ISHONCHLILIGI';

  @override
  String get fisher_stable => 'BARQAROR TREND ✅';

  @override
  String get fisher_stats => 'Fisher statistikasi';

  @override
  String get foliated => 'Folyatsiyalangan';

  @override
  String get geoloc_header => 'GEOLOKATSIYA';

  @override
  String get gis_monitoring_active => 'GIS monitoringi faol';

  @override
  String get gps_error => 'GPS xatosi';

  @override
  String get gps_locked => 'GPS faol';

  @override
  String get gps_not_locked => 'GPS lock bo‘lmadi';

  @override
  String get gps_off_alert => 'DIQQAT: GPS o‘chiq. Yoqish tavsiya etiladi.';

  @override
  String get gps_performance => 'GPS KO‘RSATKICHLARI';

  @override
  String get gps_status_good => 'Aniq GPS (Yaxshi)';

  @override
  String get gps_status_medium => 'O‘rtacha aniqlik';

  @override
  String get gps_status_medium_short => 'GPS (O‘rtacha)';

  @override
  String get gps_status_off => 'GPS o‘chiq';

  @override
  String get gps_status_poor => 'Past aniqlik';

  @override
  String get gps_status_poor_short => 'GPS (Past aniqlik)';

  @override
  String get gps_status_searching => 'Qidirilmoqda...';

  @override
  String get gpx_export_unavailable => 'GPX eksport vaqtincha faol emas';

  @override
  String get grade_dist => 'RUDA SIFATI TAQSIMOTI';

  @override
  String get ground_area_label => 'QOG‘OZGA SIG‘ADIGAN HAQIQIY HUDUD';

  @override
  String get hdop => 'HDOP';

  @override
  String get height_cm => 'BO‘YI (SM)';

  @override
  String get high_accuracy_good => 'Yuqori aniqlik';

  @override
  String get hold => 'USHLA';

  @override
  String get horizon_level => 'HORIZONT TO‘G‘RI';

  @override
  String get hud_toggle => 'Natijalar (HUD)';

  @override
  String get input_data => 'KIRISH MA\'LUMOTLARI';

  @override
  String get joint => 'Yoriq (Joint)';

  @override
  String get language => 'Til';

  @override
  String get last_update => 'Oxirgi yangilanish';

  @override
  String get lat_label => 'Kenglik (Shimoliy/Janubiy)';

  @override
  String get lat_lon_error => 'Lat/Lon noto‘g‘ri';

  @override
  String get layer_base_map => 'Xarita (asosiy)';

  @override
  String get layer_drawings => 'Chizmalar';

  @override
  String get layer_gis_kml => 'GIS qatlam (KML)';

  @override
  String get layer_management => 'QATLAM BOSHQARUVI';

  @override
  String get layered => 'Qatlamli';

  @override
  String get layout_explanation =>
      'Tanlangan qog‘ozga sig‘adigan hudud o‘lchami.';

  @override
  String get layout_planner => 'LAYOUT (QOG‘OZGA JOYLASHTIRISH)';

  @override
  String get light_grey => 'Och kulrang';

  @override
  String get light_toggle => 'Yoritish (Flash)';

  @override
  String get lineation => 'Lineatsiya (Lineation)';

  @override
  String get lithology_data => 'Litolojiya va Punkt ma’lumotlari';

  @override
  String get lng_label => 'Uzoqlik (Sharqiy/G‘arbiy)';

  @override
  String get loading => 'Yuklanmoqda...';

  @override
  String get location_denied_alert =>
      'Lokatsiya ruxsati berilmagan. Sozlamalardan yoqing.';

  @override
  String get mag_decl_short => 'MAG. DEC';

  @override
  String get magmatic => 'Magmatik';

  @override
  String get magnetic_declination => 'Magnit og‘ishi';

  @override
  String get magnetic_declination_desc => 'Sharq (+), G‘arb (-) darajalarda';

  @override
  String get mandatory_step_label => 'MAJBURIY QADAM';

  @override
  String get map => 'Xarita';

  @override
  String get map_error_prefix => 'Xato yuz berdi';

  @override
  String get map_style_osm => 'OpenStreetMap Standard';

  @override
  String get map_style_satellite => 'Sun’iy yo‘ldosh (Esri)';

  @override
  String get map_style_topo => 'OpenTopoMap';

  @override
  String get massive => 'Massiv';

  @override
  String get measurement_error_high => 'Diqqat! O‘lchov xatosi katta';

  @override
  String get measurement_label => 'O\'lchov Turi (Measurement Type)';

  @override
  String get measurements_count => 'O‘LCHOVLAR';

  @override
  String get medium_accuracy_warn => 'O‘rtacha aniqlik';

  @override
  String get metamorphic => 'Metamorfik';

  @override
  String get mic_error => 'Mikrofon ruxsati yo‘q';

  @override
  String get millimetrovka_calc => 'MILLIMETROVKA KALKULYATORI';

  @override
  String get munsell_color => 'Munsell Rangi';

  @override
  String get new_project_hint => 'Masalan: Chatqol 2026';

  @override
  String get new_project_title => 'Yangi loyiha';

  @override
  String get new_station_btn => 'YANGI STANSIYA';

  @override
  String get next_station => '+ Keyingisi';

  @override
  String get no_data => 'Ma\'lumot topilmadi';

  @override
  String get no_local_data => 'Mahalliy ma’lumotlar yo‘q';

  @override
  String get no_stations_in_project => 'Tanlangan loyihada stansiyalar yo‘q.';

  @override
  String get note => 'IZOH';

  @override
  String get note_saved => 'Eslatma saqlandi';

  @override
  String get observation_area_label => 'Kuzatuv hududi';

  @override
  String get offline_download => 'Oflayn yuklash';

  @override
  String get open_map => 'XARITANI OCHISH';

  @override
  String get other => 'Boshqa (Other)';

  @override
  String get paper_distance => 'QOG‘OZDA';

  @override
  String get paper_format_label => 'QOG‘OZ FORMATINI TANLANG:';

  @override
  String get pdf_report => 'PDF Hisobot';

  @override
  String get perimeter_label => 'Perimetr';

  @override
  String get photo_added => 'Foto muvaffaqiyatli qo‘shildi';

  @override
  String get photo_deleted_snack => 'Foto o‘chirildi';

  @override
  String get poor_accuracy_warn => 'Past aniqlik';

  @override
  String get power_saver => 'Tejamkor rejim (Power Saver)';

  @override
  String get professional_tag => 'PROFESSIONAL';

  @override
  String get project => 'Loyiha';

  @override
  String get project_and_archive => 'LOYIHA VA ARXIV';

  @override
  String get project_label => 'Loyiha';

  @override
  String get project_stats => 'LOYIHA STATISTIKASI';

  @override
  String get projection_depth => 'PROYEKSIYA CHUQURLIGI';

  @override
  String get projects_count => 'Loyihalar soni';

  @override
  String get real_distance => 'HAQIQIY MASOFA';

  @override
  String get record_error => 'Ovoz yozishda xatolik';

  @override
  String get recording_started => 'Yozish boshlandi';

  @override
  String get records_count => 'ta yozuv';

  @override
  String get red_ochre => 'Qizil/Oxra';

  @override
  String get reliability_index => 'Ishonchlilik ko‘rsatkichi';

  @override
  String get rename => 'Nomini o‘zgartirish';

  @override
  String get rename_route => 'Marshrut nomini o‘zgartirish';

  @override
  String get results_count => 'natija';

  @override
  String get rock_classification => 'Tosh tasnifi';

  @override
  String get rock_type => 'Jins turi';

  @override
  String get rose_diagram_subtitle =>
      'Har bir sektor = 22.5° | Uzunlik ~ stansiya soni';

  @override
  String get rose_diagram_title => 'ROSE DIAGRAM (STRIKE)';

  @override
  String get route_name_prefix => 'Marshrut';

  @override
  String get route_saved_snack =>
      'Marshrut saqlandi. Arxivda ko‘rishingiz mumkin.';

  @override
  String get routes => 'Marshrutlar';

  @override
  String get rtk_fixed => 'RTK ANIQ (FIXED) HOLATI';

  @override
  String get ruler_calibration_title => 'RAQAMLI CHIZG‘ICH VA KALIBRLESH';

  @override
  String get ruler_label => 'O‘LCHAGICH';

  @override
  String get sample_id => 'Namuna ID (Sample ID)';

  @override
  String get sample_type => 'Namuna turi';

  @override
  String get satellites => 'SATS';

  @override
  String get save => 'Saqlash';

  @override
  String get save_drawing_title => 'Chizmani saqlash';

  @override
  String get save_first_hint =>
      'Avval stansiyani saqlang yoki kameradan yarating';

  @override
  String get save_label => 'Saqlash';

  @override
  String get scale_assistant_help_content =>
      '1. Millimetrovka kalkulyatori: Haqiqiy masofani qog‘ozdagi mm ga o‘tkazadi.\n2. Layout: Tanlangan masshtabda qog‘ozga sig‘adigan hududni hisoblaydi.\n3. Kalibrlash: Chizg‘ichni oddiy lineyka yordamida DPI ni to‘g‘rilang.';

  @override
  String get scale_assistant_help_title => 'Yordam';

  @override
  String get scale_assistant_title => 'MASSHTAB YORDAMCHISI';

  @override
  String get scale_short => 'Masshtab';

  @override
  String get search => 'Qidirish';

  @override
  String get searching_gps => 'GPS qidirilmoqda...';

  @override
  String get sedimentary => 'Cho‘kindi';

  @override
  String get select_two_points =>
      'Xaritada 2 ta nuqtani tanlang (Kesim chizig\'i)';

  @override
  String get selected_label => 'ta tanlandi';

  @override
  String get selected_scale => 'TANLANGAN MASSHTAB';

  @override
  String get session => 'Sessiya';

  @override
  String get settings => 'Sozlamalar';

  @override
  String get share => 'Ulashish';

  @override
  String get signal_searching => 'SIGNAL QIDIRILMOQDA';

  @override
  String get sos_sent => 'SOS signal yuborildi! Jamoa ogohlantirildi.';

  @override
  String get start => 'Boshlash';

  @override
  String get station_project_label => 'Loyihasi';

  @override
  String get station_saved => 'Stansiya muvaffaqiyatli saqlandi';

  @override
  String get stations => 'Stansiyalar';

  @override
  String get stations_count => 'STANSIYALAR';

  @override
  String get stations_suffix => 'stansiya';

  @override
  String get statistics_label => 'Statistika';

  @override
  String get stereonet_density_hint_label => 'Kamb issiqlik xaritasi';

  @override
  String get stereonet_density_hint_value => 'qalin mintaqada nuqtalar ko‘p';

  @override
  String get stereonet_mean => 'O‘rtacha (Mean)';

  @override
  String get stereonet_no_data => 'Stereonet: Ma’lumot yo‘q';

  @override
  String get stereonet_planes => 'Tekisliklar (Planes)';

  @override
  String get stereonet_schmidt => 'STEREONET (SCHMIDT TO‘RI)';

  @override
  String get stereonet_schmidt_desc =>
      'Teng maydon proyeksiyasi — quyi yarim shar';

  @override
  String get stereonet_summary => 'STEREONET TAHLILI';

  @override
  String get stereonet_wulff => 'STEREONET (WULFF TO‘RI)';

  @override
  String get stereonet_wulff_desc =>
      'Teng burchak proyeksiyasi — quyi yarim shar';

  @override
  String get stop => 'To‘xtatish';

  @override
  String get strike => 'Urilish (Strike)';

  @override
  String get strike_label => 'Urilish (Strike)';

  @override
  String get structural_measurements => 'Strukturaviy o\'lchovlar';

  @override
  String get structure => 'Tuzilishi';

  @override
  String get structure_label => 'Tuzilishi / Struktura';

  @override
  String get success_saved => 'Muvaffaqiyatli saqlandi';

  @override
  String get sync => 'Sinxronizatsiya';

  @override
  String get system_online => 'TIZIM ONLAYN';

  @override
  String get tahlil_label => 'Tahlil';

  @override
  String get theme_dark => 'Qorong‘u';

  @override
  String get theme_light => 'Yorug‘';

  @override
  String get theme_system => 'Tizim';

  @override
  String get three_d_structure => '3D STRUKTURA';

  @override
  String get time_label => 'VAQT';

  @override
  String get today_only => 'Faqat bugungi (Today)';

  @override
  String get total_stations => 'Jami stansiyalar';

  @override
  String get total_stations_short => 'Jami stansiyalar';

  @override
  String get tracking_started_snack => 'Marshrut yozish boshlandi!';

  @override
  String get trend_analysis => 'STATISTIK TREND TAHLILI';

  @override
  String get trend_density => 'Zichlik darajasi (κ)';

  @override
  String get trend_growth => 'Trend: +12% o‘sish';

  @override
  String get trend_orientation => 'Orientatsiya';

  @override
  String trend_recommend_good(String dir) {
    return 'Konning asosiy yo‘nalishi $dir bo‘ylab shakllangan.';
  }

  @override
  String get trend_recommend_poor => 'Ma’lumotlar tarqoq, aniq trend yo‘q.';

  @override
  String get trend_reliability => 'Ishonchlilik (α₉₅)';

  @override
  String get understood => 'Tushunarli';

  @override
  String get undo => 'Bekor qilish';

  @override
  String get unknown => 'Noma\'lum';

  @override
  String get unsaved_changes => 'O‘zgarishlar saqlanmadi';

  @override
  String get unsaved_changes_desc =>
      'Kiritilgan ma’lumotlar saqlanmadi. Haqiqatan ham chiqmoqchimisiz?';

  @override
  String get utm_coordinates => 'UTM KOORDINATALARI';

  @override
  String get version => 'Versiya';

  @override
  String get voice_note => 'Ovozli eslatma';

  @override
  String get voice_record => 'Ovozli qayd';

  @override
  String get warning_label => 'Ogohlantirish';

  @override
  String get welcome_text => 'Xush kelibsiz, ';

  @override
  String get width_cm => 'ENI (SM)';

  @override
  String get zoom_label => 'Masshtab';
}
