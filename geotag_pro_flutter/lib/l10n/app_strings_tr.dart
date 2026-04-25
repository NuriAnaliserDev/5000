// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_strings.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class GeoFieldStringsTr extends GeoFieldStrings {
  GeoFieldStringsTr([String locale = 'tr']) : super(locale);

  @override
  String get about_app => 'Uygulama Hakkında';

  @override
  String get fab_reset_title => 'Buton konumlarını sıfırla';

  @override
  String get fab_reset_desc =>
      'Harita ve kamera ekranlarında sürüklenen butonları varsayılan konumlarına döndür';

  @override
  String get fab_reset_prompt =>
      'Hangi ekrandaki buton düzenini sıfırlamak istersiniz?';

  @override
  String get fab_reset_map => 'Harita';

  @override
  String get fab_reset_camera => 'Kamera';

  @override
  String get fab_reset_all => 'Tümü';

  @override
  String get fab_reset_done => 'Buton konumları sıfırlandı';

  @override
  String get map_my_location => 'Konumum';

  @override
  String get map_eraser_tooltip => 'Silgi';

  @override
  String get map_redo_tooltip => 'İleri';

  @override
  String get map_eraser_hint =>
      'Silgi modu: çizgiye dokunun — silinir. Çıkmak için butona tekrar dokunun.';

  @override
  String get map_search_hint => 'Şehir, bölge veya adres...';

  @override
  String get map_search_empty => 'Sonuç bulunamadı';

  @override
  String get map_search_searching => 'Aranıyor...';

  @override
  String get map_search_error =>
      'Arama başarısız: internet yok veya sunucu yanıt vermedi';

  @override
  String get map_drag_mode_hint =>
      'Sürükleme modu: butonu yeni konumuna kaydırın (6 saniye)';

  @override
  String get acc_label => 'ACC';

  @override
  String get accuracy => 'Doğruluk';

  @override
  String get ai_lithology_applied_hint =>
      'AI taslağı uygulandı. Tüm alanları sahada doğrulayın.';

  @override
  String get ai_lithology_btn => 'AI litoloji';

  @override
  String get ai_lithology_error => 'AI hatası';

  @override
  String get ai_lithology_minerals_prefix => 'Mineraller:';

  @override
  String get ai_lithology_need_photo =>
      'AI analizi için önce istasyona fotoğraf ekleyin (kamera veya galeri).';

  @override
  String get ai_lithology_verify_type_prefix =>
      'AI önerilen kaya tipi (doğrulayın):';

  @override
  String get actions_label => 'İşlemler';

  @override
  String get active_point_label => 'Aktif jeolojik nokta';

  @override
  String get add_first_station => 'İlk İstasyonu Oluştur';

  @override
  String get add_gallery => '+ Galeri';

  @override
  String get admin => 'Yönetici';

  @override
  String get all_projects => 'Tüm Projeler';

  @override
  String get all_stations => 'All (All stations)';

  @override
  String get altitude => 'Rakım';

  @override
  String get altitude_offset_desc => 'Altitude offset (meters)';

  @override
  String get analysis_alt_range => 'Rakım aralığı';

  @override
  String get analysis_avg_dip => 'Ortalama Dip';

  @override
  String get analysis_circular_mean_strike => 'Dairesel Ortalama Strike';

  @override
  String get analysis_dip_direction => 'Dip Yönü';

  @override
  String get analysis_extra_measurements => 'Ek ölçümler';

  @override
  String get analysis_fisher_stats => 'FISHER İSTATİSTİKLERİ (STRIKE)';

  @override
  String get analysis_general => 'GENEL';

  @override
  String get analysis_measure_types => 'ÖLÇÜM TÜRÜNE GÖRE';

  @override
  String get analysis_orientation_mean => 'ORTALAMA YÖNELİM (VEKTÖREL)';

  @override
  String get analysis_primary_measurement => 'Birincil ölçüm';

  @override
  String get analysis_project_count => 'Proje sayısı';

  @override
  String get analysis_projects => 'PROJELERE GÖRE';

  @override
  String get analysis_rock_type => 'Kaya türü';

  @override
  String get analysis_rocks => 'KAYA TÜRÜNE GÖRE';

  @override
  String get analysis_stat_reliable => 'İstatistik güvenilir (n≥5, R>0.5)';

  @override
  String get analysis_stat_unreliable =>
      'Daha fazla ölçüm gerekli (n≥5 ve R>0.5)';

  @override
  String get analysis_station_count => 'İstasyon sayısı';

  @override
  String get analysis_strike_std => 'Strike Std Sapma (σ)';

  @override
  String get analysis_with_gps => 'GPS ile';

  @override
  String get analytics_weekly => 'ANALYTICS (7 DAYS)';

  @override
  String get app_description =>
      'GeoField Pro N, jeolojik saha çalışmaları için tam bir sistemdir: GPS/UTM koordinatları, strike/dip/azimut ölçümleri, fotoğraf ve ses kayıtları, çevrimdışı harita ve rota, KML/DXF içe aktarma, CSV/GeoJSON/KML/GPX/PDF dışa aktarma, stereonet ve istatistik analizi, gerçek zamanlı sohbet, bulut senkronizasyonu, güvenlik ve çok dilli kullanım.';

  @override
  String get app_look_label => 'Uygulama Görünümü';

  @override
  String get app_title => 'GeoField Pro N';

  @override
  String get apparent_dip_calc_title => 'GÖRÜNÜR DİP HESAPLAYICI';

  @override
  String get apparent_dip_direction => 'Dip Yönü:';

  @override
  String get apparent_dip_formula_hint =>
      'tan(α) = tan(δ) × |cos(β)|\nβ = dip yönü ile kesit azimutu arasındaki açı';

  @override
  String get apparent_dip_title => 'GÖRÜNÜR DİP';

  @override
  String get apparent_note_body =>
      '• Kesit yönü dip yönüne paralelse (β≈0°) → görünür dip = gerçek dip\n• Kesit yönü dip yönüne dikse (β≈90°) → görünür dip = 0°\n• Jeolojik kesit ve harita kalınlığı hesaplarında kullanılır';

  @override
  String apparent_result_hint(String trueDip, String apparent) {
    return 'Gerçek dip: $trueDip°  →  Görünür: $apparent°';
  }

  @override
  String get apparent_section_azimuth => 'Kesit Azimutu:';

  @override
  String get apparent_true_dip => 'Gerçek Dip (δ):';

  @override
  String get archive => 'Arşiv';

  @override
  String get area_label => 'Alan';

  @override
  String get auto_recommendation => 'OTOMATİK ÖNERİ';

  @override
  String get azimuth_label => 'Başlık (Azimut)';

  @override
  String get bedding => 'Tabakalaşma';

  @override
  String get by_project => 'Projeye Göre';

  @override
  String get by_rock_type => 'Kaya Türüne Göre';

  @override
  String get calculate => 'Hesapla';

  @override
  String get calibration_instruction =>
      'Ekrana fiziksel bir cetvel yerleştirin ve 1 cm ile eşleştirin.';

  @override
  String get camera => 'Kamera';

  @override
  String get camera_error => 'Kamera Hatası';

  @override
  String get camera_voice_mic_hint =>
      'Mikrofon: Bu istasyon için ses notu kaydedin (kaydet ile birlikte saklanır).';

  @override
  String get viewer_3d_legend =>
      'Nokta: istasyon konumu. Turuncu: strike/dip düzlemi. Sürükleyerek döndürün, +/− ile yakınlaştırın. Koyu turuncu ≈ daha dik dip.';

  @override
  String get viewer_3d_no_data =>
      'İstasyon yok — 3D için saha istasyonu ekleyin.';

  @override
  String get viewer_3d_nothing_visible =>
      'Çizimler ekran dışında olabilir. Döndürün, +/- kullanın.';

  @override
  String get map_draw_undo_caption => 'Son nokta';

  @override
  String get map_gesture_undo_hint =>
      'Son noktayı: ↩, haritada uzun basma veya iki parmakla dokunma / ikincil tık.';

  @override
  String get map_tap_line_delete_message =>
      'Bu çizim kalıcı olarak silinir. Geri alınamaz.';

  @override
  String get map_line_deleted_snack => 'Çizim silindi';

  @override
  String get map_structure_mode_tooltip => 'Strike/dip işareti yerleştir';

  @override
  String get map_structure_mode_hint =>
      'Eklemek için haritaya dokunun. Silmek için işarete dokunun.';

  @override
  String get map_structure_add_title => 'Strike / dip';

  @override
  String get map_structure_strike_label => 'Strike (°)';

  @override
  String get map_structure_dip_label => 'Dip (°)';

  @override
  String get map_structure_type_label => 'Yapı tipi';

  @override
  String get map_structure_deleted_snack => 'Yapı işareti silindi';

  @override
  String get map_structure_delete_body =>
      'Bu işaret kalıcı olarak silinir. Geri alınamaz.';

  @override
  String get ai_vertex_disabled_title => 'AI (Vertex) arka uç etkin değil';

  @override
  String get ai_vertex_disabled_body =>
      'Belge analizi Google Cloud (Firebase AI Logic / Vertex AI) gerektirir. Yöneticiden bu Firebase projesi için API’yi açmasını isteyin, 2–5 dakika bekleyin ve Yeniden dene deyin.';

  @override
  String get ai_vertex_open_console => 'Google Cloud API sayfasını aç';

  @override
  String get draw_first_point_hint =>
      'İlk nokta eklendi. Çizgiye devam için tekrar dokunun.';

  @override
  String get notifications_screen_title => 'Bildirimler';

  @override
  String get notifications_empty_hint =>
      'Henüz duyuru yok. Ekip, Firestore’daki `geofield_broadcasts` koleksiyonuna (oturum açmış kullanıcılar) yazdığında burada görünür.';

  @override
  String get notifications_open_chats => 'Sohbetler';

  @override
  String get sync_purpose_tooltip =>
      'Çevrimdışı: veri cihazda kalır; internet gelince yüklenir. Kimin ne göreceği Firestore kurallarına ve projeye bağlıdır.';

  @override
  String get map_layer_import_gis => 'KML/DXF içe aktar (GIS)';

  @override
  String get map_layer_export_data => 'Dışa aktar (arşiv)';

  @override
  String get field_workshop_title => 'Saha atölyesi (field workshop)';

  @override
  String get field_workshop_fab_tooltip =>
      'Pro atölye: katman, KML/DXF, çizim, yapı';

  @override
  String get field_workshop_banner =>
      'Katman, GIS içe aktarma, çizim ve saha araçları tek ekranda.';

  @override
  String get map_offline_tiles_hint =>
      'Harita karoları dolaşırken önbelleğe alınır. Çevrimdışı gitmeden önce alanı yakınlaştırın. Birleşik bölge indirme yol haritasında.';

  @override
  String get camera_header_document => 'BELGE SENKRON';

  @override
  String get camera_header_geology => 'JEOLOJİ';

  @override
  String get camera_mode_document => 'Rapor';

  @override
  String get camera_mode_geology => 'Jeolojik';

  @override
  String get cancel => 'İptal';

  @override
  String get cleavage => 'Dilinim';

  @override
  String get close => 'Kapat';

  @override
  String get color => 'Renk';

  @override
  String get color_chart_title => 'MUNSELL RENK ŞEMASI';

  @override
  String get compass => 'Pusula';

  @override
  String get compass_8_motion =>
      'PUSULAYI KALİBRE ETMEK İÇİN \"8\" ŞEKLİNDE DÖNDÜRÜN';

  @override
  String get compass_calibration => 'Kalibrasyon Rehberi';

  @override
  String get compass_calibration_long =>
      'Azimut ve eğim hassasiyeti için cihazınızı havada \"8\" şeklinde birkaç kez hareket ettirin.';

  @override
  String get compass_unreliable_warn =>
      'UYARI: Pusula güvenilmez! Önce telefonu 8 şeklinde hareket ettirin.';

  @override
  String get confidence => 'Güven';

  @override
  String get confirm => 'Onayla';

  @override
  String get confirm_delete => 'Silmeyi Onayla?';

  @override
  String get confirm_delete_all =>
      'Tüm yerel istasyon verileri silinecek. Devam etmek istiyor musunuz?';

  @override
  String get confirm_delete_all_tracks => 'Delete all tracks?';

  @override
  String get contact => 'Kontak';

  @override
  String get coordinate_sync => 'Koordinatları Güncelle';

  @override
  String get count_suffix => 'birim';

  @override
  String get create_btn => 'Oluştur';

  @override
  String get custom_input => 'Özel Giriş';

  @override
  String get dark_grey => 'Koyu Gri';

  @override
  String get dashboard => 'Ana Sayfa';

  @override
  String get delete => 'Sil';

  @override
  String get delete_all_label => 'Hepsini Sil';

  @override
  String get delete_confirm_btn => 'Evet, sil';

  @override
  String get delete_photo => 'Fotoğrafı Sil';

  @override
  String get delete_project_title => 'Projeyi Sil';

  @override
  String get delete_project_warn =>
      'Bu proje silinsin mi? İçindeki istasyonlar \"Default\" projesine taşınacaktır.';

  @override
  String get density_heatmap => 'Yoğunluk ısı haritası';

  @override
  String get description => 'Açıklama';

  @override
  String get description_hint =>
      'Kaya bileşimi, mineraller, kontaklar ve doğrultu/eğim değişimlerini buraya kaydedin...';

  @override
  String get dip => 'Eğim (Dip)';

  @override
  String get dip_direction => 'Eğim Yönü';

  @override
  String get dip_distribution => 'DIP DAĞILIMI';

  @override
  String get dip_label => 'Eğim (Dip)';

  @override
  String get distance_label => 'MESAFE';

  @override
  String get distance_warning => 'UYARI! Mesafe farkı.';

  @override
  String get document_align_hint => 'Belgeyi çerçeveye hizalayın';

  @override
  String get dominant_direction => 'Baskın yön';

  @override
  String get download_confirm => 'İndirmeye devam edilsin mi?';

  @override
  String get download_pdf => 'PDF Raporunu İndir';

  @override
  String get download_region_tooltip => 'Görünür bölgeyi indir';

  @override
  String get draw_on_photo => 'Fotoğraf üzerine çiz';

  @override
  String get drawing_name => 'Çizim adı';

  @override
  String get drawing_saved => 'Jeolojik çizim kaydedildi';

  @override
  String get dxf_notice_body =>
      'DXF içe aktarmada çizim GPS coğrafi projeksiyonunda (WGS-84 Enlem/Boylam) olmalıdır. Aksi halde haritada yanlış konumlanır.';

  @override
  String get dxf_notice_title => 'DXF Uyarısı';

  @override
  String get echo_mode_on => 'EKO MOD: AKTİF';

  @override
  String get eco_mode => 'Eko Mod';

  @override
  String get edit_coordinates => 'Koordinatları Düzenle (Enlem / Boylam)';

  @override
  String get edit_disable => 'DÜZENLEMEYİ KAPAT';

  @override
  String get edit_enable => 'DÜZENLEMEYİ AÇ';

  @override
  String get edit_project => 'Projeyi Düzenle';

  @override
  String get expert_mode => 'Profesyonel mod';

  @override
  String get export_csv => 'CSV Dışa Aktar';

  @override
  String get export_geojson => 'GeoJSON Dışa Aktar';

  @override
  String get export_kml => 'KML (Google Earth)';

  @override
  String get export_no_stations => 'Dışa aktarılacak istasyon yok.';

  @override
  String get export_pdf => 'PDF Raporu';

  @override
  String get export_select_project => 'Hangi proje dışa aktarılsın?';

  @override
  String get export_title => 'Dışa Aktarma Formatını Seçin';

  @override
  String get field_assets => 'Saha Varlıkları (Fotoğraf ve Ses)';

  @override
  String get filter => 'Filtrele';

  @override
  String get fisher_dispersion => 'HIGH DISPERSION ⚠️';

  @override
  String get fisher_reliability => 'FISHER RELIABILITY';

  @override
  String get fisher_stable => 'STABLE TREND ✅';

  @override
  String get fisher_stats => 'Fisher istatistikleri';

  @override
  String get fisher_reliability_help =>
      'α₉₅, tüm istasyon strike’ları için %95 güven koni (Fisher). Küçük açı: strike’lar tek yöne kümelenir; büyük açı: dağılım yüksektir. Yeşil/turuncu: genelde n ≥ 5 ve ortalama vektör uzunluğu R > 0.5 ise güvenilir kabul edilir.';

  @override
  String get dashboard_data_export => 'Veri dışa aktar';

  @override
  String get dashboard_gis_import => 'KML/DXF içe aktar';

  @override
  String get voice_open_camera_hint =>
      'Kamera açıldı. Ses notu için kamera ekranındaki mikrofona basın; istasyon Foto + kaydet adımında kaydedilir.';

  @override
  String get map_slice_tooltip =>
      'Profil çizgisi (makas): Haritada iki noktaya dokunun — en kesit (cross section) açılır.';

  @override
  String get map_3d_tooltip =>
      '3D: Harita merkezi çevresinde arazi ve istasyonlar. Başka bölge için önce haritayı kaydırın.';

  @override
  String get map_track_fab_aria => 'GPS rotası (iz) kaydet';

  @override
  String get track_start_failed =>
      'Rota başlatılamadı. GPS’i açın ve konum iznini verin.';

  @override
  String gis_import_done(int imported, int skipped) {
    return 'GIS içe aktarma: $imported eklendi, $skipped atlandı.';
  }

  @override
  String get foliated => 'Folyasyonlu';

  @override
  String get geoloc_header => 'COĞRAFİ KONUM';

  @override
  String get gis_monitoring_active => 'GIS Monitoring Active';

  @override
  String get gps_error => 'GPS Hatası';

  @override
  String get gps_locked => 'GPS kilitlendi';

  @override
  String get gps_not_locked => 'GPS kilitlenmedi';

  @override
  String get gps_off_alert =>
      'UYARI: GPS kapalı. Saha çalışması için lütfen etkinleştirin.';

  @override
  String get gps_performance => 'GPS PERFORMANCE';

  @override
  String get gps_status_good => 'Yüksek Doğruluk (İyi)';

  @override
  String get gps_status_medium => 'Orta Doğruluk';

  @override
  String get gps_status_medium_short => 'GPS (Orta)';

  @override
  String get gps_status_off => 'GPS Kapalı';

  @override
  String get gps_status_poor => 'Düşük Doğruluk';

  @override
  String get gps_status_poor_short => 'GPS (Düşük)';

  @override
  String get gps_status_searching => 'Aranıyor...';

  @override
  String get gpx_export_unavailable =>
      'GPX Dışa Aktarımı geçici olarak kullanılamıyor';

  @override
  String get grade_dist => 'GRADE DISTRIBUTION';

  @override
  String get ground_area_label => 'KAĞIT ÜZERİNDEKİ GERÇEK ALAN';

  @override
  String get hdop => 'HDOP';

  @override
  String get height_cm => 'YÜKSEKLİK (CM)';

  @override
  String get high_accuracy_good => 'Yüksek Doğruluk';

  @override
  String get hold => 'BEKLET';

  @override
  String get horizon_level => 'UFUK SEVİYESİ';

  @override
  String get hud_toggle => 'Arayüz (HUD)';

  @override
  String get input_data => 'GİRİŞ VERİLERİ';

  @override
  String get joint => 'Eklem';

  @override
  String get language => 'Dil';

  @override
  String get last_update => 'Son Güncelleme';

  @override
  String get lat_label => 'Enlem (Kuzey/Güney)';

  @override
  String get lat_lon_error => 'Geçersiz Lat/Lon';

  @override
  String get layer_base_map => 'Temel harita';

  @override
  String get layer_drawings => 'Çizimler';

  @override
  String get layer_gis_kml => 'GIS katmanı (KML)';

  @override
  String get layer_management => 'KATMAN YÖNETİMİ';

  @override
  String get layered => 'Tabakalı';

  @override
  String get layout_explanation => 'Seçilen kağıda sığan gerçek alan boyutu.';

  @override
  String get layout_planner => 'YERLEŞİM (KAĞIT PLANLAYICI)';

  @override
  String get light_grey => 'Açık Gri';

  @override
  String get light_toggle => 'Fener / Flaş';

  @override
  String get lineation => 'Lineasyon';

  @override
  String get lithology_data => 'Litoloji ve İstasyon Verileri';

  @override
  String get lng_label => 'Boylam (Doğu/Batı)';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get location_denied_alert =>
      'Konum izni reddedildi. Ayarlardan etkinleştirin.';

  @override
  String get mag_decl_short => 'MANY. SAPMA';

  @override
  String get magmatic => 'Magmatik';

  @override
  String get magnetic_declination => 'Manyetik Sapma';

  @override
  String get magnetic_declination_desc => 'East (+), West (-) in degrees';

  @override
  String get mandatory_step_label => 'ZORUNLU ADIM';

  @override
  String get map => 'Harita';

  @override
  String get map_error_prefix => 'Hata oluştu';

  @override
  String get map_style_osm => 'OpenStreetMap Standard';

  @override
  String get map_style_satellite => 'Uydu (Esri)';

  @override
  String get map_style_topo => 'OpenTopoMap';

  @override
  String get massive => 'Masif';

  @override
  String get measurement_error_high => 'Dikkat! Ölçüm hatası yüksek';

  @override
  String get measurement_label => 'Ölçüm Türü';

  @override
  String get measurements_count => 'MEASUREMENTS';

  @override
  String get medium_accuracy_warn => 'Orta Doğruluk';

  @override
  String get metamorphic => 'Metamorfik';

  @override
  String get mic_error => 'Mikrofon izni reddedildi';

  @override
  String get millimetrovka_calc => 'MİLLİMETROVKA HESAPLAYICI';

  @override
  String get munsell_color => 'Munsell Rengi';

  @override
  String get new_project_hint => 'Örn: Ağrı Dağı 2026';

  @override
  String get new_project_title => 'Yeni Proje';

  @override
  String get new_station_btn => 'NEW STATION';

  @override
  String get next_station => '+ Sonraki';

  @override
  String get no_data => 'Veri bulunamadı';

  @override
  String get no_local_data => 'Yerel veri bulunamadı';

  @override
  String get no_stations_in_project => 'No stations in the selected project.';

  @override
  String get note => 'NOT';

  @override
  String get note_saved => 'Not Kaydedildi';

  @override
  String get observation_area_label => 'Gözlem alanı';

  @override
  String get offline_download => 'Çevrimdışı İndirme';

  @override
  String get open_map => 'OPEN MAP';

  @override
  String get other => 'Diğer';

  @override
  String get paper_distance => 'KAĞIT ÜZERİNDE';

  @override
  String get paper_format_label => 'KAĞIT FORMATI SEÇİN:';

  @override
  String get pdf_report => 'PDF Raporu';

  @override
  String get perimeter_label => 'Çevre';

  @override
  String get photo_added => 'Fotoğraf başarıyla eklendi';

  @override
  String get photo_deleted_snack => 'Fotoğraf silindi';

  @override
  String get poor_accuracy_warn => 'Düşük Doğruluk';

  @override
  String get power_saver => 'Tejamkor rejim (Power Saver)';

  @override
  String get professional_tag => 'PROFESYONEL';

  @override
  String get project => 'Proje';

  @override
  String get project_and_archive => 'PROJECT & ARCHIVE';

  @override
  String get project_label => 'Proje';

  @override
  String get project_stats => 'PROJECT STATISTICS';

  @override
  String get projection_depth => 'PROJEKSİYON DERİNLİĞİ';

  @override
  String get projects_count => 'Proje Sayısı';

  @override
  String get real_distance => 'GERÇEK MESAFE';

  @override
  String get record_error => 'Ses kayıt hatası';

  @override
  String get recording_started => 'Kayıt Başladı';

  @override
  String get records_count => 'kayıt';

  @override
  String get red_ochre => 'Kırmızı/Oksit';

  @override
  String get reliability_index => 'Güvenilirlik endeksi';

  @override
  String get rename => 'Yeniden Adlandır';

  @override
  String get rename_route => 'Rotayı Yeniden Adlandır';

  @override
  String get results_count => 'sonuç';

  @override
  String get rock_classification => 'Kaya Sınıflandırması';

  @override
  String get rock_type => 'Kaya Türü';

  @override
  String get rose_diagram_subtitle =>
      'Her sektör = 22.5° | Uzunluk ~ istasyon sayısı';

  @override
  String get rose_diagram_title => 'ROSE DİYAGRAMI (STRIKE)';

  @override
  String get route_name_prefix => 'Rota';

  @override
  String get route_saved_snack => 'Rota kaydedildi. Arşivde bulabilirsiniz.';

  @override
  String get routes => 'Rotalar';

  @override
  String get rtk_fixed => 'RTK FIXED STATUS';

  @override
  String get ruler_calibration_title => 'DİJİTAL CETVEL VE KALİBRASYON';

  @override
  String get ruler_label => 'CETVEL';

  @override
  String get sample_id => 'Örnek ID';

  @override
  String get sample_type => 'Örnek Türü';

  @override
  String get satellites => 'SATS';

  @override
  String get save => 'Kaydet';

  @override
  String get save_drawing_title => 'Çizimi kaydet';

  @override
  String get save_first_hint => 'Save station or capture from camera first';

  @override
  String get save_label => 'Kaydet';

  @override
  String get scale_assistant_help_content =>
      '1. Millimetrovka Hesaplayıcı: Gerçek mesafeyi kağıt üzerindeki mm\'ye dönüştürür.\n2. Yerleşim: Seçilen kağıt formatına sığan alanı hesaplar.\n3. Kalibrasyon: Fiziksel bir cetvel kullanarak cetvel DPI ayarını yapın.';

  @override
  String get scale_assistant_help_title => 'Yardım';

  @override
  String get scale_assistant_title => 'ÖLÇEK YARDIMCISI';

  @override
  String get scale_short => 'Ölçek';

  @override
  String get search => 'Search';

  @override
  String get searching_gps => 'GPS aranıyor...';

  @override
  String get sedimentary => 'Sedimanter';

  @override
  String get select_two_points => 'Haritada 2 nokta seçin (Kesit çizgisi)';

  @override
  String get selected_label => 'seçildi';

  @override
  String get selected_scale => 'SEÇİLEN ÖLÇEK';

  @override
  String get session => 'Oturum';

  @override
  String get settings => 'Ayarlar';

  @override
  String get share => 'Share';

  @override
  String get signal_searching => 'SİNYAL ARANIYOR';

  @override
  String get sos_sent => 'SOS sinyali gönderildi! Ekip uyarıldı.';

  @override
  String get sos_gps_unavailable =>
      'GPS alınamadı. Açık havada veya sinyal gelene kadar bekleyin.';

  @override
  String get sos_cancel => 'SOS’u bitir';

  @override
  String get sos_cancelled => 'SOS sonlandı';

  @override
  String get map_follow_gps => 'Beni takip et: haritayı GPS’e kilitli tutar';

  @override
  String get photo_saved_limited_gps =>
      'Fotoğraf kaydedildi. GPS yok — istasyonu sonra düzeltin.';

  @override
  String get start => 'Başlat';

  @override
  String get station_project_label => 'Proje';

  @override
  String get station_saved => 'İstasyon Kaydedildi';

  @override
  String get stations => 'İstasyonlar';

  @override
  String get stations_count => 'STATIONS';

  @override
  String get stations_suffix => 'istasyon';

  @override
  String get statistics_label => 'İstatistikler';

  @override
  String get stereonet_density_hint_label => 'Yoğunluk ısı haritası';

  @override
  String get stereonet_density_hint_value =>
      'yoğun bölgede nokta daha fazladır';

  @override
  String get stereonet_mean => 'Mean Pole';

  @override
  String get stereonet_no_data => 'Stereonet: No Data';

  @override
  String get stereonet_planes => 'Planes';

  @override
  String get stereonet_schmidt => 'STEREONET (SCHMIDT AĞI)';

  @override
  String get stereonet_schmidt_desc => 'Eş alan projeksiyonu — alt yarımküre';

  @override
  String get stereonet_summary => 'STEREONET SUMMARY';

  @override
  String get stereonet_wulff => 'STEREONET (WULFF AĞI)';

  @override
  String get stereonet_wulff_desc => 'Eş açılı projeksiyon — alt yarımküre';

  @override
  String get stop => 'Durdur';

  @override
  String get strike => 'Doğrultu (Strike)';

  @override
  String get strike_label => 'Doğrultu (Strike)';

  @override
  String get structural_measurements => 'Yapısal Ölçümler';

  @override
  String get structure => 'Yapı';

  @override
  String get structure_label => 'Yapı / Doku';

  @override
  String get success_saved => 'Başarıyla kaydedildi';

  @override
  String get sync => 'Senkronize Et';

  @override
  String get system_online => 'SYSTEM ONLINE';

  @override
  String get tahlil_label => 'Analiz';

  @override
  String get theme_dark => 'Koyu';

  @override
  String get theme_light => 'Açık';

  @override
  String get theme_system => 'Sistem';

  @override
  String get three_d_structure => '3D STRUCTURE';

  @override
  String get time_label => 'ZAMAN';

  @override
  String get today_only => 'Today only';

  @override
  String get total_stations => 'Toplam İstasyon';

  @override
  String get total_stations_short => 'Toplam istasyon';

  @override
  String get tracking_started_snack => 'İzleme başladı!';

  @override
  String get trend_analysis => 'İSTATİSTİKSEL TREND ANALİZİ';

  @override
  String get trend_density => 'Yoğunluk seviyesi (κ)';

  @override
  String get trend_growth => 'Trend: +12% Growth';

  @override
  String get trend_orientation => 'Yönelim';

  @override
  String trend_recommend_good(String dir) {
    return 'Ana yönelim $dir doğrultusunda.';
  }

  @override
  String get trend_recommend_poor => 'Veri dağılımı yüksek, net trend yok.';

  @override
  String get trend_reliability => 'Güvenilirlik (α₉₅)';

  @override
  String get understood => 'Anladım';

  @override
  String get undo => 'Geri al';

  @override
  String get unknown => 'Bilinmiyor';

  @override
  String get unsaved_changes => 'Değişiklikler Kaydedilmedi';

  @override
  String get unsaved_changes_desc =>
      'Yapılan değişiklikler kaydedilmedi. Gerçekten çıkmak istiyor musunuz?';

  @override
  String get utm_coordinates => 'UTM COORDINATES';

  @override
  String get version => 'Sürüm';

  @override
  String get voice_note => 'Sesli Not';

  @override
  String get voice_record => 'Ses kaydı';

  @override
  String get warning_label => 'Uyarı';

  @override
  String get welcome_text => 'Welcome, ';

  @override
  String get width_cm => 'GENİŞLİK (CM)';

  @override
  String get zoom_label => 'Yakınlaştırma';
}
