import '../models/program.dart';
import '../models/article.dart';
import '../models/live_stream.dart';
import '../models/schedule_entry.dart';

/// All static data for the app — no network needed.
class StaticData {
  // ─── Live stream ─────────────────────────────────────────────────────────
  static final LiveStream liveStream = LiveStream.fallback;

  // ─── Programs ────────────────────────────────────────────────────────────
  static final List<Program> programs = [
    Program(
      id: 1,
      nameAr: 'البث المباشر',
      descriptionAr: 'البث المباشر على مدار الساعة من المسجد الحرام والمسجد النبوي الشريف — تابع الصلوات والتلاوات مباشرة.',
      scheduleTime: '٢٤/٧',
      presenterAr: 'فريق البث',
      localImage: 'assets/episode/hqdefault.webp',
      imageUrl: 'https://makkahlive.net/images/MakkahLiveCover.jpg',
      youtubeUrl: 'https://www.youtube.com/watch?v=ccV974FRPI8&list=PLSG0qi3h4n37Q_TYX51GDk691TqaRvHHV',
      episodeCount: 0,
    ),
    Program(
      id: 2,
      nameAr: 'نور على نور',
      descriptionAr: 'برنامج ديني تثقيفي يستعرض أبرز المواضيع الإسلامية بأسلوب مبسّط ومحبّب يومياً بعد صلاة العشاء.',
      scheduleTime: 'يومياً بعد العشاء',
      presenterAr: 'الشيخ عبدالله المطرودي',
      localImage: 'assets/episode/post1.png',
      imageUrl: 'https://img.youtube.com/vi/ccV974FRPI8/hqdefault.jpg',
      youtubeUrl: 'https://www.youtube.com/watch?v=ccV974FRPI8&list=PLSG0qi3h4n37Q_TYX51GDk691TqaRvHHV',
      episodeCount: 45,
    ),
    Program(
      id: 3,
      nameAr: 'خواطر رمضانية',
      descriptionAr: 'تأملات وخواطر روحية في رحاب القرآن الكريم خلال شهر رمضان المبارك مع نخبة من العلماء.',
      scheduleTime: 'رمضان — بعد السحور',
      presenterAr: 'الشيخ سعد الغامدي',
      localImage: 'assets/episode/poste2.png',
      imageUrl: 'https://img.youtube.com/vi/qKS9sC3nl_c/hqdefault.jpg',
      youtubeUrl: 'https://www.youtube.com/watch?v=qKS9sC3nl_c&list=PLSG0qi3h4n36JTbcxMZVpxW-GPyb1dLhI',
      episodeCount: 30,
    ),
    Program(
      id: 4,
      nameAr: 'معالم الحج والعمرة',
      descriptionAr: 'دليل شامل لأداء مناسك الحج والعمرة بطريقة صحيحة وفق السنة النبوية الشريفة.',
      scheduleTime: 'موسم الحج',
      presenterAr: 'الدكتور صالح الفوزان',
      localImage: 'assets/episode/poste3.png',
      imageUrl: 'https://img.youtube.com/vi/TKUcUAecRtI/hqdefault.jpg',
      youtubeUrl: 'https://www.youtube.com/watch?v=TKUcUAecRtI',
      episodeCount: 15,
    ),
    Program(
      id: 5,
      nameAr: 'تلاوات من الحرم',
      descriptionAr: 'تلاوات قرآنية خاشعة مباشرة من المسجد الحرام بأصوات كبار القراء في العالم الإسلامي.',
      scheduleTime: 'يومياً',
      presenterAr: 'نخبة من القراء',
      localImage: 'assets/episode/poste4.png',
      imageUrl: 'https://img.youtube.com/vi/5j1Vt9M2eo0/hqdefault.jpg',
      youtubeUrl: 'https://www.youtube.com/watch?v=5j1Vt9M2eo0',
      episodeCount: 120,
    ),
    Program(
      id: 6,
      nameAr: 'الدروس العلمية',
      descriptionAr: 'دروس علمية في الفقه والعقيدة والحديث تُقدّم من رحاب المسجد الحرام كل أسبوع.',
      scheduleTime: 'الثلاثاء والخميس',
      presenterAr: 'نخبة من العلماء',
      localImage: 'assets/episode/post5.png',
      imageUrl: 'https://img.youtube.com/vi/kdZVmYqdN-M/hqdefault.jpg',
      youtubeUrl: 'https://www.youtube.com/watch?v=kdZVmYqdN-M&list=PLSG0qi3h4n342_0h_gSjHvUzQAmnpD2Ik&index=1',
      episodeCount: 80,
    ),
    Program(
      id: 7,
      nameAr: 'أخبار القناة',
      descriptionAr: 'نشرة أخبار قناة مكة الفضائية ومستجدات العالم الإسلامي كل مساء.',
      scheduleTime: 'يومياً الساعة ٩م',
      presenterAr: 'فريق الأخبار',
      localImage: 'assets/episode/resize1.png',
      imageUrl: 'https://img.youtube.com/vi/lhwurDCEss4/hqdefault.jpg',
      youtubeUrl: 'https://www.youtube.com/watch?v=lhwurDCEss4',
      episodeCount: 0,
    ),
    Program(
      id: 8,
      nameAr: 'ضيف الحرم',
      descriptionAr: 'لقاءات مع ضيوف الرحمن من شتى أرجاء العالم الإسلامي تحكي قصص إيمانية ملهمة.',
      scheduleTime: 'أسبوعي',
      presenterAr: 'فريق البرامج',
      localImage: 'assets/episode/hqdefault.webp',
      imageUrl: 'https://img.youtube.com/vi/vDs_ab_J96I/hqdefault.jpg',
      youtubeUrl: 'https://www.youtube.com/watch?v=vDs_ab_J96I',
      episodeCount: 22,
    ),
  ];

  // ─── Daily schedule ──────────────────────────────────────────────────────
  static const List<ScheduleEntry> dailySchedule = [
    ScheduleEntry(
      nameAr: 'مبرور',
      timeAr: '03:00 صباحاً',
      imageUrl: 'https://tse3.mm.bing.net/th/id/OIP.sY-EBs0KfTJsBgviGEjJ9QHaEo?rs=1&pid=ImgDetMain&o=7&rm=3',
      youtubeUrl: 'https://www.youtube.com/watch?v=lhwurDCEss4',
      sortMinutes: 180,
    ),
    ScheduleEntry(
      nameAr: 'قيم الزحام',
      timeAr: '03:30 صباحاً',
      imageUrl: 'https://th.bing.com/th/id/OIP.sXHhlD67I7ASj8gktNLwTQHaEK?rs=1&pid=ImgDetMain&o=7&rm=3',
      youtubeUrl: 'https://www.youtube.com/watch?v=vDs_ab_J96I',
      sortMinutes: 210,
    ),
    ScheduleEntry(
      nameAr: 'استكشاف حدود الحرم',
      timeAr: '08:15 صباحاً',
      imageUrl: 'https://tse2.mm.bing.net/th/id/OIP.hd3s6LoBEA09xi4AbTuw4wHaEJ?rs=1&pid=ImgDetMain&o=7&rm=3',
      youtubeUrl: 'https://www.youtube.com/watch?v=QlasJcax37k',
      sortMinutes: 495,
    ),
    ScheduleEntry(
      nameAr: 'إرث الخليلين',
      timeAr: '08:30 صباحاً',
      imageUrl: 'https://tse4.mm.bing.net/th/id/OIP.exvEBk30EIcc2X94UdWk5QHaEK?rs=1&pid=ImgDetMain&o=7&rm=3',
      youtubeUrl: 'https://www.youtube.com/watch?v=hE9VDhUDT-4',
      sortMinutes: 510,
    ),
    ScheduleEntry(
      nameAr: 'آيات الحج',
      timeAr: '09:15 صباحاً',
      imageUrl: 'https://img.youtube.com/vi/WIZ8I4pxqQA/hqdefault.jpg',
      localImage: 'assets/episode/program_makhtv.jpg',
      youtubeUrl: 'https://www.youtube.com/watch?v=WIZ8I4pxqQA',
      sortMinutes: 555,
    ),
    ScheduleEntry(
      nameAr: 'دروس الحرم',
      timeAr: '10:00 صباحاً',
      imageUrl: 'https://tse4.mm.bing.net/th/id/OIP.BtWWY5gn2oQlyf8lRBnCswHaHa?w=1000&h=1000&rs=1&pid=ImgDetMain&o=7&rm=3',
      youtubeUrl: 'https://www.youtube.com/watch?v=5j1Vt9M2eo0',
      sortMinutes: 600,
    ),
  ];

  // ─── Channel events (أحداثيات القناة) ────────────────────────────────────
  static final List<Article> channelEvents = [
    Article(
      id: 101,
      title: 'آية وتفسير 21 | قناة مكة',
      excerpt: 'برنامج قرآني يستعرض آيات الذكر الحكيم وتفسيرها بأسلوب مبسّط ومؤثر.',
      imageUrl: 'asset:assets/episode/chanel1.jpg',
      category: 'أحداثيات القناة',
      publishedAt: DateTime(2026, 3, 28),
      youtubeUrl: 'https://www.youtube.com/watch?v=BMz55PspzKg',
      body: 'برنامج آية وتفسير يستعرض آيات الذكر الحكيم ويقدم تفسيرها بأسلوب مبسّط ومؤثر يناسب جميع الأعمار.',
    ),
    Article(
      id: 102,
      title: 'وداعاً مكة | قناة مكة',
      excerpt: 'برنامج يرصد لحظات توديع ضيوف الرحمن لمكة المكرمة بعد أداء مناسك الحج والعمرة.',
      imageUrl: 'asset:assets/episode/chanel2.jpg',
      category: 'أحداثيات القناة',
      publishedAt: DateTime(2026, 3, 26),
      youtubeUrl: 'https://www.youtube.com/watch?v=VBddHbHXPkc',
      body: 'برنامج وداعاً مكة يرصد لحظات توديع ضيوف الرحمن للبقاع المقدسة، ويعكس المشاعر الصادقة لمن قضوا أياماً روحانية في رحاب الكعبة المشرفة.',
    ),
  ];

  // ─── Articles ────────────────────────────────────────────────────────────
  static final List<Article> articles = [
    Article(
      id: 1,
      title: 'انطلاق موسم الحج ١٤٤٧هـ بحضور ملايين الحجاج من أنحاء العالم',
      excerpt: 'توافد ملايين الحجاج إلى مكة المكرمة لأداء فريضة الحج بإشراف متكامل من الجهات السعودية.',
      imageUrl: 'https://live.staticflickr.com/65535/48564400691_9e5e9a2b8e_b.jpg',
      category: 'حج وعمرة',
      publishedAt: DateTime(2026, 4, 10),
      youtubeUrl: 'https://www.youtube.com/watch?v=TKUcUAecRtI',
      body: 'توافد ملايين الحجاج من مختلف أنحاء العالم إلى البقاع المقدسة لأداء فريضة الحج هذا العام، في مشهد إيماني مهيب يجسّد وحدة المسلمين.\n\nأشرفت الجهات السعودية المختصة على تنظيم جميع المشاعر المقدسة وتيسير وصول الحجاج إلى الكعبة المشرفة ومنى وعرفات ومزدلفة.\n\nأكدت الرئاسة العامة لشؤون المسجد الحرام توفير أعلى مستويات الخدمة لضيوف الرحمن طوال موسم الحج.',
    ),
    Article(
      id: 2,
      title: 'قناة مكة تطلق تطبيقها الجديد على منصات الهواتف الذكية',
      excerpt: 'أعلنت قناة مكة الفضائية عن إطلاق تطبيقها الجديد لنقل البث المباشر ومحتوياتها المتنوعة.',
      imageUrl: 'https://img.youtube.com/vi/ccV974FRPI8/hqdefault.jpg',
      category: 'أخبار القناة',
      publishedAt: DateTime(2026, 4, 11),
      youtubeUrl: 'https://www.youtube.com/watch?v=ccV974FRPI8',
      body: 'أعلنت قناة مكة الفضائية رسمياً عن إطلاق تطبيقها الجديد المتاح على منصتي iOS وAndroid.\n\nيوفر التطبيق البث المباشر من المسجد الحرام على مدار الساعة، إضافة إلى آخر البرامج والمقاطع المسجلة.\n\nيمكن تحميل التطبيق مجاناً من متجر App Store ومتجر Google Play.',
    ),
    Article(
      id: 3,
      title: 'إمام المسجد الحرام يؤم صلاة الجمعة بحضور مليوني مصلٍّ',
      excerpt: 'أمّ فضيلة إمام المسجد الحرام صلاة الجمعة للأسبوع الثاني على التوالي في رحاب الحرم الشريف.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b7/Masjid_Al_Haram.jpg/1280px-Masjid_Al_Haram.jpg',
      category: 'أخبار',
      publishedAt: DateTime(2026, 4, 9),
      body: 'أمّ فضيلة الشيخ صلاة الجمعة للأسبوع الثاني على التوالي في رحاب المسجد الحرام أمام ما يزيد على مليوني مصلٍّ من مختلف الجنسيات.\n\nتناولت خطبة الجمعة أهمية التوبة والاستغفار وعمارة المساجد بالصلاة والذكر.\n\nأشاد المصلون بالأجواء الروحانية الفريدة التي تسود الحرم المكي الشريف.',
    ),
    Article(
      id: 4,
      title: 'الهيئة العامة للإحصاء: ارتفاع أعداد المعتمرين ٣٠٪ خلال رمضان',
      excerpt: 'كشفت الهيئة العامة للإحصاء أن أعداد المعتمرين خلال شهر رمضان المبارك ارتفعت بنسبة ٣٠٪.',
      imageUrl: 'https://img.youtube.com/vi/vDs_ab_J96I/hqdefault.jpg',
      category: 'حج وعمرة',
      publishedAt: DateTime(2026, 4, 8),
      youtubeUrl: 'https://www.youtube.com/watch?v=vDs_ab_J96I',
      body: 'أصدرت الهيئة العامة للإحصاء تقريرها السنوي الذي يُظهر ارتفاعاً ملحوظاً في أعداد المعتمرين خلال شهر رمضان المبارك بنسبة ٣٠٪ مقارنةً بالعام الماضي.\n\nبلغ إجمالي عدد المعتمرين أكثر من ثمانية ملايين معتمر من مختلف دول العالم.\n\nواصف المسؤولون هذا الارتفاع بأنه مؤشر إيجابي يعكس نجاح الجهود السعودية في استقبال ضيوف الرحمن.',
    ),
    Article(
      id: 5,
      title: 'افتتاح مشاريع توسعة جديدة في المسجد الحرام لاستيعاب الأعداد المتزايدة',
      excerpt: 'أعلنت الرئاسة العامة لشؤون المسجد الحرام والمسجد النبوي عن افتتاح مراحل جديدة من التوسعة.',
      imageUrl: 'https://img.youtube.com/vi/QlasJcax37k/hqdefault.jpg',
      category: 'أخبار',
      publishedAt: DateTime(2026, 4, 7),
      youtubeUrl: 'https://www.youtube.com/watch?v=QlasJcax37k',
      body: 'أعلنت الرئاسة العامة لشؤون المسجد الحرام والمسجد النبوي عن الانتهاء من المرحلة الثالثة من مشاريع التوسعة الكبرى.\n\nتشمل المرحلة الجديدة إضافة أكثر من نصف مليون متر مربع من المساحات المغطاة وغير المغطاة.\n\nستُتيح هذه التوسعة استيعاب ما يزيد على مليوني مصلٍّ خلال أوقات الذروة.',
    ),
    Article(
      id: 6,
      title: 'انطلاق الدورة القرآنية الصيفية في المسجد الحرام',
      excerpt: 'تنطلق الدورة القرآنية الصيفية في رحاب المسجد الحرام بمشاركة آلاف الطلاب.',
      imageUrl: 'https://img.youtube.com/vi/lhwurDCEss4/hqdefault.jpg',
      category: 'أخبار',
      publishedAt: DateTime(2026, 4, 6),
      youtubeUrl: 'https://www.youtube.com/watch?v=lhwurDCEss4',
      body: 'انطلقت الدورة القرآنية الصيفية السنوية في المسجد الحرام بمشاركة آلاف الطلاب من مختلف الجنسيات.\n\nتستمر الدورة لمدة ثلاثة أشهر وتشمل حلقات التحفيظ والتجويد وعلوم القرآن الكريم.\n\nتُشرف على الدورة نخبة من كبار علماء القراءات القرآنية من داخل المملكة وخارجها.',
    ),
    Article(
      id: 7,
      title: 'خطبة الجمعة من المسجد النبوي — درس مؤثر عن الصبر والشكر',
      excerpt: 'خطبة جمعة مؤثرة من المسجد النبوي الشريف يتناول فيها الشيخ معاني الصبر والشكر.',
      imageUrl: 'https://img.youtube.com/vi/5j1Vt9M2eo0/hqdefault.jpg',
      category: 'أخبار',
      publishedAt: DateTime(2026, 4, 5),
      youtubeUrl: 'https://www.youtube.com/watch?v=5j1Vt9M2eo0',
      body: 'ألقى إمام المسجد النبوي الشريف خطبة جمعة مؤثرة تناول فيها معاني الصبر والشكر في حياة المسلم.\n\nأكد الشيخ في خطبته على أن الصبر والشكر هما ركيزتان أساسيتان لكل مؤمن، ولا يخلو حال المؤمن من إحداهما.\n\nاستقطبت الخطبة اهتماماً واسعاً وتداولها الملايين عبر منصات التواصل الاجتماعي.',
    ),
    Article(
      id: 8,
      title: 'تلاوة القرآن الكريم من المسجد الحرام — سورة الكهف',
      excerpt: 'تلاوة خاشعة لسورة الكهف من المسجد الحرام تنقلها قناة مكة مباشرة لجمهورها.',
      imageUrl: 'https://img.youtube.com/vi/kdZVmYqdN-M/hqdefault.jpg',
      category: 'أخبار القناة',
      publishedAt: DateTime(2026, 4, 4),
      youtubeUrl: 'https://www.youtube.com/watch?v=kdZVmYqdN-M',
      body: 'تبث قناة مكة الفضائية تلاوة خاشعة لسورة الكهف مباشرة من المسجد الحرام بصوت أحد كبار القراء.\n\nتحظى تلاوات القرآن الكريم من رحاب الحرمين الشريفين بمتابعة واسعة من المسلمين حول العالم.\n\nيطلب كثير من المستمعين إتاحة هذه التلاوات في صيغ قابلة للتحميل للاستماع إليها في أي وقت.',
    ),
  ];

  /// "الأكثر مشاهدة" — view counts come live from the YouTube API.
  static const List<({String title, String url})> mostViewed = [
    (title: 'أذكار المساء', url: 'https://www.youtube.com/watch?v=kM9qMU4b1T4'),
    (title: 'أذكار الصباح', url: 'https://www.youtube.com/watch?v=VcY_TiljhkU'),
    (title: 'مكة كلها حرم', url: 'https://www.youtube.com/watch?v=_6TbpUSNWT4'),
    (title: 'نشيد ( مكة الغراء )', url: 'https://www.youtube.com/watch?v=Bvnr3Tjbx5k'),
    (title: 'نشيد ( عهدٌ ومثابة )', url: 'https://www.youtube.com/watch?v=imK8V9aGPjQ'),
    (title: 'نشيد ( حسنة في الحرم )', url: 'https://www.youtube.com/watch?v=haP2D-3ZHsU'),
  ];
}