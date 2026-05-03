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
  String get map_my_location => 'Mening joyim';

  @override
  String get map_eraser_tooltip => 'O‘chirish';

  @override
  String get map_redo_tooltip => 'Oldinga';

  @override
  String get map_eraser_hint =>
      'O‘chirish rejimi: chiziqni bosing — o‘chadi. Qaytadan rejimdan chiqish uchun tugmani qayta bosing.';

  @override
  String get map_search_hint => 'Shahar, hudud yoki manzil...';

  @override
  String get map_search_empty => 'Hech narsa topilmadi';

  @override
  String get map_search_searching => 'Qidirilmoqda...';

  @override
  String get map_search_error =>
      'Qidirishda xatolik: internet yo‘qmi yoki server javob bermadi';

  @override
  String get map_search_locations_hint => 'Joylashuvlarni qidirish…';

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
  String get ai_lithology_verify_type_prefix =>
      'AI tavsiya qilgan tosh turi (tekshiring):';

  @override
  String get actions_label => 'Amallar';

  @override
  String get active_point_label => 'Faol geologik nuqta';

  @override
  String get add_first_station => 'Birinchi stansiyani yaratish';

  @override
  String get add_gallery => '+ Galereya';

  @override
  String get admin => 'Ma\'muriyat';

  @override
  String get admin_full_title => 'Admin & Sozlamalar';

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
  String get analysis_circular_mean_strike => 'Doira bo‘yicha o‘rtacha strike';

  @override
  String get analysis_dip_direction => 'Dip yo‘nalishi';

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
  String get analysis_strike_std => 'Strike standart chetlanishi (σ)';

  @override
  String get analysis_with_gps => 'GPS bilan';

  @override
  String get analysis_tab_rose => 'Rose diagrammasi';

  @override
  String get analysis_tab_stereonet => 'Stereonet';

  @override
  String get analysis_tab_trends => 'Trendlar';

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
  String get camera_azimuth_short => 'Azimut';

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
  String get camera_focus_mode_title => 'Geologik Kamera — Focus Mode';

  @override
  String get camera_guide_button => 'Yo\'riqnoma';

  @override
  String get camera_voice_record_label => 'Ovozli eslatma yozish';

  @override
  String get camera_torch_label => 'Chiroq';

  @override
  String get camera_scale_label => 'Masshtab';

  @override
  String get camera_close_label => 'Yopish';

  @override
  String get camera_heading_info_line => 'GPS aniqligi va sensor';

  @override
  String get camera_azimuth_subtitle =>
      'Telefon ustki cheti — shimolga nisbatan (soat yo‘nalishi)';

  @override
  String get camera_plane_attitude_subtitle =>
      'Strike/Dip: ekranni qatlam tekisligiga parallel ushlang';

  @override
  String get camera_voice_mic_hint =>
      'Mikrofon: bosib ovozli eslatma yozing (surat saqlanganda qo‘shiladi).';

  @override
  String get viewer_3d_legend =>
      'Oq nuqta: stansiya joyi. Sariq/orange: strike/dip bo‘yicha qatlam tekisligi. Barmoq bilan aylantiring, +/− yaqinlashtiring. To‘q ro‘ng ≈ qalinroq dip.';

  @override
  String get viewer_3d_no_data =>
      'Stansiya yo‘q — dala stansiyalari qo‘shilganda 3D tekisliklar ko‘rinadi.';

  @override
  String get viewer_3d_nothing_visible =>
      'Chizimlar ekran tashqarisida bo‘lishi mumkin. Barmoq bilan aylantiring, +/- bosing.';

  @override
  String get map_draw_undo_caption => 'Oxirgi nuqta';

  @override
  String get map_gesture_undo_hint =>
      'So‘nggi nuqta: pastdagi ↩, xaritada uzoq bosish yoki ikkinchi barmoq teginishi.';

  @override
  String get map_tap_line_delete_message =>
      'Ushbu chizma butunlay o‘chiriladi. Qayta tiklab bo‘lmaydi.';

  @override
  String get map_line_deleted_snack => 'Chizma o‘chirildi';

  @override
  String get map_structure_mode_tooltip => 'Xaritaga strike/dip belgisi';

  @override
  String get map_structure_mode_hint =>
      'Belgi qo‘yish uchun xaritani bosing. O‘chirish — belgini bosing.';

  @override
  String get map_structure_add_title => 'Do‘rtlama / pasayish';

  @override
  String get map_structure_strike_label => 'Do‘rtlama (°)';

  @override
  String get map_structure_dip_label => 'Pasayish (°)';

  @override
  String get map_structure_type_label => 'Struktur turi';

  @override
  String get map_structure_deleted_snack => 'Struktur belgisi o‘chirildi';

  @override
  String get map_structure_delete_body =>
      'Ushbu struktur belgisi butunlay o‘chiriladi. Qayta tiklab bo‘lmaydi.';

  @override
  String get ai_vertex_disabled_title => 'AI (Vertex) backend o‘chiq';

  @override
  String get ai_vertex_disabled_body =>
      'Hujjat tahlili Google Cloud (Firebase AI Logic / Vertex AI) orqali ishlaydi. Loyiha adminidan ushbu Firebase loyihasi uchun API ni yoqishni so‘rang, 2–5 daqiqa kuting, so‘ng «Qayta urinish» bosing.';

  @override
  String get ai_vertex_open_console => 'Google Cloud API sahifasini ochish';

  @override
  String get ai_vertex_quota_billing_title => 'AI limiti yoki to‘lov (billing)';

  @override
  String get ai_vertex_quota_billing_body =>
      'Vertex / Gemini bepul limitdan keyin Google Cloud hisobi talab qilinishi mumkin. Google Cloud’da billing, kvotalar va API ishlatishni tekshiring yoki keyinroq qayta urinib ko‘ring.';

  @override
  String get draw_first_point_hint =>
      'Birinchi nuqta qo‘yildi. Chiziqni davom etirish uchun yana bosing.';

  @override
  String get notifications_screen_title => 'Bildirishnomalar';

  @override
  String get notifications_empty_hint =>
      'Hozircha e’lon yo‘q. Jamoa `geofield_broadcasts` kolleksiyasiga (kirgan foydalanuvchilar o‘qishi) yozganda shu yerda paydo bo‘ladi.';

  @override
  String get notifications_open_chats => 'Chatlar';

  @override
  String get sync_purpose_tooltip =>
      'Internet bo‘lmasa ma’lumot telefonda saqlanadi, tarmoq paydo bo‘lganda yuboriladi. Kim nimani ko‘rishi — Firestore qoidalari va loyiha sozlamalariga bog‘liq.';

  @override
  String get map_layer_import_gis => 'GIS import: KML, DXF, GeoJSON, SHP, GPKG';

  @override
  String get map_layer_export_data => 'Ma’lumot eksport (arxiv)';

  @override
  String get field_workshop_title => 'Pro maydon (field workshop)';

  @override
  String get field_workshop_fab_tooltip =>
      'Pro maydon: qatlam, KML/DXF, chizim, struktura';

  @override
  String get field_workshop_banner =>
      'Qatlam, GIS import, chizim va dala vositalari bitta oynada.';

  @override
  String get map_measure_mode => 'O‘lchash (masofa va maydon)';

  @override
  String get map_measure_hint =>
      'Xaritani bosing: 2 nuqta = masofa, 3+ = poligon maydoni.';

  @override
  String get map_measure_clear => 'O‘lchovni tozalash';

  @override
  String get map_measure_bearing => 'Bearing (azimut)';

  @override
  String get map_measure_angle => 'Oxirgi nuqtadagi burchak (°)';

  @override
  String get map_export_geojson => 'Xaritani GeoJSONga eksport';

  @override
  String get field_workshop_stereonet => 'Stereonet / tahlil';

  @override
  String get field_utm_tap => 'Xarita markazi UTM (vaqtinchalik xotira)';

  @override
  String get line_action_edit => 'Chiziq xususiyatlari';

  @override
  String get line_property_title => 'Chiziq xususiyatlari';

  @override
  String get line_property_name => 'Nomi';

  @override
  String get line_property_notes => 'Izoh';

  @override
  String get field_workshop_checklist => 'Dala ro‘yxati (belgilash)';

  @override
  String get field_workshop_ch1 => 'Fon xarita va GIS qatlamlar';

  @override
  String get field_workshop_ch2 => 'KML, DXF, GeoJSON, Shapefile, GeoPackage';

  @override
  String get field_workshop_ch3 => 'Chizim, o‘lchov, kerak bo‘lsa eksport';

  @override
  String get map_offline_tiles_hint =>
      'Fon xarita plitalari harakatlanishda keshga yoziladi. Oflaynga chiqquncha xaritani kerakli hududga yaqinlashtiring. Bitta yirik hududni birlashtirib yuklab olish — rejadagi vazifa.';

  @override
  String get camera_header_document => 'HUJJAT SINXRON';

  @override
  String get camera_header_geology => 'GEOLOGIYA';

  @override
  String get camera_mode_document => 'Hisobot';

  @override
  String get camera_mode_geology => 'Geologik';

  @override
  String get camera_pro_sheet_hint =>
      'Chiziq, gorizontal, ekspert o‘lchamlari, HUD (geologiya rejimi).';

  @override
  String get camera_ar_geology_title => 'AR qatlam (bedding)';

  @override
  String get camera_ar_geology_subtitle =>
      'Tajribaviy. ARCore/ARKit: ba’zi qurilmalarda qora ekran, surat ololmaslik yoki fonar ishlamasligi bo‘lishi mumkin — barqaror ishlash uchun o‘chiq qoldiring, oddiy kameradan foydalaning. Birinchi yurishda belgi modeli uchun tarmoq kerak bo‘lishi mumkin.';

  @override
  String get camera_ar_session_stalled =>
      'AR vaqtida ishga tushmadi. Geologik AR avtomatik o‘chirildi. Oddiy kameradan foydalaning yoki qurilma qo‘llab-quvvatlasa PRO da AR ni qayta yoqing.';

  @override
  String get camera_ar_tap_plane_hint =>
      'Telefonni siljiting — panjara (grid) paydo bo‘lguncha; keyin tekislikka teging — belgi shu yerda qotadi. Qayta tegish — boshqa joyga ko‘chirish.';

  @override
  String get camera_ar_no_plane_hit =>
      'Bu nuqtada tekislik topilmadi. Kuzatiladigan tekislik (panjara) ustida qayta urinib ko‘ring.';

  @override
  String get camera_ar_anchor_failed =>
      'Yuzaga bog‘lab bo‘lmadi. Qayta urinib ko‘ring.';

  @override
  String get camera_ar_node_failed =>
      'Belgini qo‘yib bo‘lmadi. Qayta urinib ko‘ring.';

  @override
  String get camera_ar_snapshot_failed =>
      'AR surati olinmadi. Sahnani kuting yoki PRO da AR ni o‘chirib oddiy kameradan foydalaning.';

  @override
  String get camera_ar_torch_unavailable =>
      'Bu yerda fonar ishlamasligi mumkin (ba’zi qurilmalarda AR kamerani band qiladi). Fonar uchun PRO da AR ni o‘ching.';

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
  String get dashboard_hero_title => 'Pro geologik bosh sahifa';

  @override
  String get dashboard_view_all => 'Barchasi';

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
      'DXF: faqat ASCII matnli DXF; koordinatalar WGS-84 da bo‘lishi kerak (X = uzoqlik/boylam°, Y = kenglik/enlem°). UTM yoki lokal metrda chizilgan fayl xaritada noto‘g‘ri turadi — avval CAD/GIS da WGS-84 ga qayta proyeksiyalang yoki eksport qiling.';

  @override
  String get dxf_notice_title => 'DXF haqida';

  @override
  String get gis_import_precheck_title => 'GIS import — formatlar va DXF';

  @override
  String get gis_import_precheck_body =>
      '«Fayl tanlash» dan so‘ng faylni tanlaysiz.\n\n• Qo‘llaniladi: KML, GeoJSON (.geojson yoki .json), DXF, Shapefile (.shp), GeoPackage (.gpkg).\n• Brauzer (web): .gpkg ishlamaydi (SQLite yo‘q).\n\nDXF (muhim):\n• Fayl ASCII DXF bo‘lishi kerak (Binary DXF emas). AutoCAD da bo‘lsa «Save As» orqali ASCII DXF tanlang (mavjud bo‘lsa).\n• Koordinatalar WGS-84 geografik darajada: X = boylam (longitude), Y = enlem (latitude). UTM yoki mahalliy metr — xaritada joy noto‘g‘ri bo‘ladi; importdan oldin WGS-84 ga qaytaring.\n\nBulut: login yoki Firebase bo‘lmasa, import qilingan qatlam faqat ushbu qurilmada saqlanadi.';

  @override
  String get gis_import_choose_file => 'Fayl tanlash';

  @override
  String get gis_import_empty_result =>
      'Hech qanday GIS qatlam import qilinmadi. Faylni tekshiring yoki ASCII DXF (WGS-84, boylam/enlem) ishlating. Tez tekshiruv uchun KML/GeoJSON qulay.';

  @override
  String get gis_import_normalized_hint =>
      'Ba\'zi nuqtalar avtomatik enlem/boylam sifatida tuzatildi — xaritada joylashuvni tekshiring.';

  @override
  String gis_import_skipped_stats(int invalid, int few) {
    return 'O\'tkazib yuborilgan: $invalid yaroqsiz koordinata (masalan UTM, WGS-84 emas), $few kam nuqta.';
  }

  @override
  String gis_import_all_skipped_result(int invalid, int few) {
    return 'Import bo\'lmadi: $invalid yaroqsiz koordinata, $few kam nuqta. WGS-84 yoki KML/GeoJSON ishlating.';
  }

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
  String get expert_mode => 'Professional rejim';

  @override
  String get general_settings_section => 'Umumiy sozlamalar';

  @override
  String get export_csv => 'CSV eksport';

  @override
  String get export_actions_section => 'Eksport & amallar';

  @override
  String get export_stations_excel => 'Stansiyalar (Excel) eksport';

  @override
  String get export_geojson => 'GeoJSON eksport';

  @override
  String get map_elevation_center_tooltip =>
      'Xarita markazidagi balandlik (DEM, onlayn)';

  @override
  String get elevation_lookup_progress => 'Balandlik so‘ralmoqda…';

  @override
  String get elevation_lookup_failed => 'Balandlik olinmadi (tarmoq).';

  @override
  String elevation_meters_result(String m) {
    return 'Taxminiy balandlik: $m m (DEM)';
  }

  @override
  String get snap_to_grid_label =>
      'Chizishda yopishish: lokal panjara (m, 0 = o‘chiq)';

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
  String get firebase_local_only_banner =>
      'Mahalliy rejim: Firebase yo‘q. Dala ma’lumotlari qurilmada saqlanadi; tarmoq va sozlamalar tuzilguncha kirish hamda bulut sinxroni ishlamaydi.';

  @override
  String get fisher_dispersion => 'YUQORI DISPERSIYA ⚠️';

  @override
  String get fisher_reliability => 'FISHER ISHONCHLILIGI';

  @override
  String get fisher_stable => 'BARQAROR TREND ✅';

  @override
  String get fisher_gauge_high => 'Yuqori ishonchlilik';

  @override
  String get fisher_stats => 'Fisher statistikasi';

  @override
  String get fisher_reliability_help =>
      'α₉₅ — barcha stansiyalar strike’lari bo‘yicha 95% ishonch konusi (Fisher). Burchak kichik bo‘lsa, strike’lar bitta yo‘nalishga to‘planadi; katta bo‘lsa, sochilgan. Yashil/turunc holat: odatdagi qoida — ishonchli, agar n ≥ 5 va o‘rtacha vektor uzunligi R > 0.5 bo‘lsa.';

  @override
  String get dashboard_data_export => 'Eksport (arxiv)';

  @override
  String get dashboard_gis_import => 'KML/DXF import';

  @override
  String get voice_open_camera_hint =>
      'Kamera ochildi. Ovozli eslatma uchun kamera ekranidagi mikrofonni bosing; stansiya surat olish va saqlash bosqichida saqlanadi.';

  @override
  String get map_slice_tooltip =>
      'Kesim (qaychi): xaritada 2 nuqta belgilang — shu chiziq bo‘yicha profil (cross-section) ochiladi.';

  @override
  String get map_3d_tooltip =>
      '3D: xarita markazi atrofida relyef va stansiyalar. Boshqa hududni ko‘rish uchun avval xaritani siljiting.';

  @override
  String get map_track_fab_aria => 'Marshrut (GPS) yozish';

  @override
  String get map_ultra_pro_tooltip => 'Ultra Pro ko‘p funksiyali vosita';

  @override
  String get map_start_stop_tracking => 'Trekni boshlash / to‘xtatish';

  @override
  String get map_radial_strike_dip => 'Qo‘lda strike/dip';

  @override
  String get map_radial_sampling => 'Namuna olish';

  @override
  String get map_radial_field_notes => 'Dala qaydlari';

  @override
  String get map_radial_project_layers => 'Loyiha qatlamlari';

  @override
  String get track_start_failed =>
      'Marshrut boshlanmadi. GPSni yoqing va tizimda joylashuv ruxsatini bering.';

  @override
  String gis_import_done(int imported, int skipped) {
    return 'GIS import: $imported qo‘shildi, $skipped o‘tkazib yuborildi.';
  }

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
  String get mag_decl_short => 'MAGN. OG‘ISH';

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
  String get map_style_osm => 'OpenStreetMap (standart)';

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
  String get power_saver => 'Quvvatdan tejamkor rejim';

  @override
  String get professional_tag => 'KASBIY';

  @override
  String get profile_section_label => 'Profil';

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
  String get role_geologist_admin => 'Geolog-administrator';

  @override
  String get rock_classification => 'Tosh tasnifi';

  @override
  String get rock_type => 'Jins turi';

  @override
  String get rose_diagram_subtitle =>
      'Har bir sektor = 22.5° | Uzunlik ~ stansiya soni';

  @override
  String get rose_diagram_title => 'ROSE DIAGRAMMA (STRIKE)';

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
  String get satellites => 'UYDU';

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
  String get session_pause_tooltip => 'Marshrutni pauza';

  @override
  String get settings => 'Sozlamalar';

  @override
  String get share => 'Ulashish';

  @override
  String get signal_searching => 'SIGNAL QIDIRILMOQDA';

  @override
  String get sos_sent => 'SOS signal yuborildi! Jamoa ogohlantirildi.';

  @override
  String get sos_gps_unavailable =>
      'GPS olinmadi. Ochiq osmonda yoki biroz kutib, qayta urining.';

  @override
  String get sos_cancel => 'SOS ni tugatish';

  @override
  String get sos_cancelled => 'SOS yopildi';

  @override
  String get sos_login_required =>
      'SOS yuborish uchun tizimga kiring. Hisobsiz signal yuborilmaydi.';

  @override
  String get sos_queue_cancel => 'Navbatdagi SOS (offline) — bekor';

  @override
  String get sos_queue_cleared => 'Offline SOS navbati tozalandi';

  @override
  String get map_follow_gps =>
      'Men bilan yur: xaritani GPS bo‘yicha ushlab turadi';

  @override
  String get map_pro_tools_title => 'Pro vositalar (xarita)';

  @override
  String get map_pro_tools_subtitle =>
      'Qatlam, GIS, o‘lchov, kesim, 3D, eksport — bittasini tanlang, keyin xaritaga qayting.';

  @override
  String get nav_messages => 'Xabarlar';

  @override
  String get nav_more => 'Yana';

  @override
  String get camera_pro_short_label => 'Pro';

  @override
  String get messages_hub_title => 'Aloqa markazi';

  @override
  String get messages_sync_tooltip => 'Bulut bilan sinxronlash';

  @override
  String get messages_sync_started => 'Sinxronizatsiya boshlandi';

  @override
  String get messages_no_groups => 'Guruhlar topilmadi';

  @override
  String get sos_cancel_failed =>
      'SOS to‘liq o‘chmadi (tarmoq yoki ruxsat). Internetni tekshiring yoki qayta urining.';

  @override
  String get photo_saved_limited_gps =>
      'Rasm saqlandi. GPS topilmadi — stansiya joyini keyinroq to‘g‘irlang.';

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
  String station_deleted_snack(String name) {
    return '«$name» o‘chirildi.';
  }

  @override
  String get snackbar_undo_restore => 'Qaytarish';

  @override
  String get splash_error_local_db =>
      'Mahalliy baza ochilmadi. Ilovani qayta ishga tushiring.';

  @override
  String get splash_status_firebase => 'Bulutni ishga tushirish…';

  @override
  String get splash_status_local_db => 'Mahalliy baza…';

  @override
  String get splash_status_offline_tiles => 'Oflayn xaritalar…';

  @override
  String get splash_status_profile => 'Profil…';

  @override
  String get splash_status_ready => 'Tayyor';

  @override
  String get splash_status_session => 'Sessiya tiklanmoqda…';

  @override
  String get splash_status_wmm => 'Magnetik model…';

  @override
  String get route_not_found_title => 'Sahifa topilmadi';

  @override
  String get route_not_found_body => 'Bu ekran yo‘q yoki havola yaroqsiz.';

  @override
  String get route_not_found_back => 'Asosiyga qaytish';

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
  String get today_only => 'Faqat bugun';

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

  @override
  String get admin_diagnostics_section => 'DIAGNOSTIKA VA SUPPORT';

  @override
  String get admin_diagnostics_view_logs => 'Tizim loglarini ko\'rish';

  @override
  String get admin_diagnostics_view_logs_desc => 'Ilova ichki jarayonlari va xatolar tarixi';

  @override
  String get admin_diagnostics_share_logs => 'Loglarni yuborish';

  @override
  String get admin_diagnostics_clear_logs => 'Loglarni tozalash';

  @override
  String get admin_diagnostics_clear_success => 'Loglar tozalandi';

  @override
  String get admin_diagnostics_not_found => 'Log fayli topilmadi';

  @override
  String get admin_diagnostics_close => 'Yopish';
}
