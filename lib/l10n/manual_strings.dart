import 'package:flutter/material.dart';

import '../models/user.dart';

/// One numbered section inside the user manual (icon + title + steps).
class ManualSection {
  const ManualSection({
    required this.icon,
    required this.title,
    required this.steps,
  });

  final IconData icon;
  final String title;
  final List<String> steps;
}

/// User manual content in the three app languages. The manual shown from
/// Profile follows the language selected on the login screen.
class ManualStrings {
  const ManualStrings({
    required this.appBarTitle,
    required this.citizenManual,
    required this.workerManual,
    required this.headManual,
    required this.subtitle,
    required this.citizenSections,
    required this.workerSections,
    required this.headSections,
  });

  final String appBarTitle;
  final String citizenManual;
  final String workerManual;
  final String headManual;
  final String subtitle;

  final List<ManualSection> citizenSections;
  final List<ManualSection> workerSections;
  final List<ManualSection> headSections;

  /// Strings for the language currently active in [context].
  static ManualStrings of(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'hi':
        return hindi;
      case 'gu':
        return gujarati;
      default:
        return english;
    }
  }

  /// The manual sections for a role in the active language.
  List<ManualSection> sectionsFor(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        return citizenSections;
      case UserRole.worker:
        return workerSections;
      case UserRole.head:
        return headSections;
    }
  }

  /// The "X Manual" header title for a role in the active language.
  String manualTitleFor(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        return citizenManual;
      case UserRole.worker:
        return workerManual;
      case UserRole.head:
        return headManual;
    }
  }

  static const ManualStrings english = ManualStrings(
    appBarTitle: 'User Manual',
    citizenManual: 'Citizen Manual',
    workerManual: 'Worker Manual',
    headManual: 'Head Manual',
    subtitle: 'Step-by-step guide to using Safai Setu',
    citizenSections: [
      ManualSection(
        icon: Icons.report_problem_outlined,
        title: 'File a Complaint',
        steps: [
          'Go to the Home tab and tap "Report a Complaint".',
          'Pick the waste category, add a photo (optional) and a short description.',
          'Your current location is attached automatically — you can also move the pin on the map.',
          'Submit — your complaint is sent to the Head for approval.',
        ],
      ),
      ManualSection(
        icon: Icons.track_changes_outlined,
        title: 'Monitor Complaint Status',
        steps: [
          'Open Profile → "My Complaints" to see every complaint you filed.',
          'Follow the progress line: Pending → Approved → Worker Assigned → In Progress → Resolved.',
          'Each status change is reflected in real time from the database.',
        ],
      ),
      ManualSection(
        icon: Icons.call_outlined,
        title: 'Call Your Assigned Worker',
        steps: [
          'When a worker is assigned to your complaint, their name appears on the complaint.',
          'Tap the call icon next to the worker\'s name to reach them directly for any solution.',
        ],
      ),
      ManualSection(
        icon: Icons.local_shipping_outlined,
        title: 'Track Collection Vehicles',
        steps: [
          'Open the Map tab and tap "Track Collection Vehicle".',
          'See all online workers as truck markers on the map with their status.',
          'Cards below show the worker name and whether they are On Duty or Off Duty.',
        ],
      ),
      ManualSection(
        icon: Icons.circle_outlined,
        title: 'See Garbage Hotspots Nearby',
        steps: [
          'In the Map tab, open the Waste Hotspots page.',
          'Hotspot circles show areas with many complaints in the last 7 days.',
          'Color shows severity — LOW, MEDIUM and HIGH — so you know problem zones near you.',
        ],
      ),
      ManualSection(
        icon: Icons.notifications_active_outlined,
        title: 'Stay Notified',
        steps: [
          'You get a push notification whenever your complaint status changes.',
          'Open Profile → "Notifications" to see your full notification history.',
          'Tap any notification to open the related complaint, and clear history with the trash icon.',
        ],
      ),
    ],
    workerSections: [
      ManualSection(
        icon: Icons.assignment_outlined,
        title: 'Check & Accept Collection Tasks',
        steps: [
          'Open the Tasks tab — all tasks assigned to you by the Head appear here.',
          'Tap a task to see the location, waste category and citizen details.',
          'Tap "Start" (Go En Route) once you leave — the task moves to In Progress.',
        ],
      ),
      ManualSection(
        icon: Icons.map_outlined,
        title: 'Navigate & Complete the Task',
        steps: [
          'The task detail shows the exact GPS location on the map.',
          'Reach the spot, collect the waste, and tap "Complete" to submit.',
          'Take a proof photo — it is sent to the Head for review.',
        ],
      ),
      ManualSection(
        icon: Icons.my_location_outlined,
        title: 'Share Live Location & Duty Status',
        steps: [
          'Use the Live Map tab to turn location sharing ON — the Head can see your position live.',
          'Your status shows On Duty while sharing, and Off Duty when stopped.',
          'The Head can always track your vehicle from their dashboard.',
        ],
      ),
      ManualSection(
        icon: Icons.route_outlined,
        title: 'Optimize Your Route',
        steps: [
          'On the Live Map tab, tap "Optimize Route".',
          'Your active assigned tasks are numbered 1-2-3… in the best visiting order from your position.',
          'A line connects the stops with approximate distances, so you always know which is nearest.',
        ],
      ),
    ],
    headSections: [
      ManualSection(
        icon: Icons.verified_outlined,
        title: 'Approve Citizen Complaints',
        steps: [
          'Open the Complaints section — new citizen complaints arrive here with the waste category.',
          'Review each complaint: Approve it for collection, or Reject it with a reason.',
          'Approved complaints are ready for worker assignment.',
        ],
      ),
      ManualSection(
        icon: Icons.badge_outlined,
        title: 'Generate Worker IDs',
        steps: [
          'Open the Workers tab and tap "Add / Generate Worker".',
          'Enter the worker\'s details — the system issues a unique Worker ID (e.g. WK-1002).',
          'Share the ID with the worker to log in on their device.',
        ],
      ),
      ManualSection(
        icon: Icons.local_shipping_outlined,
        title: 'Monitor Workers & Call Them',
        steps: [
          'The Workers tab shows every worker with their live On Duty / Off Duty status.',
          'Open a worker\'s profile to see their live location on the map.',
          'Tap the call icon in the worker profile to contact them directly.',
        ],
      ),
      ManualSection(
        icon: Icons.task_alt_outlined,
        title: 'Assign & Revoke Collection Tasks',
        steps: [
          'From an approved complaint, assign the task to a worker — they get a push notification.',
          'You can Revoke the task anytime until the worker starts (Go En Route).',
          'Once the worker is en route, the task can no longer be revoked.',
        ],
      ),
      ManualSection(
        icon: Icons.image_outlined,
        title: 'Review Proof Photos',
        steps: [
          'When a worker submits a proof photo, you get a notification — open Proofs.',
          'Approve the proof to mark the complaint Resolved, or send it back to the worker.',
          'Approving notifies the citizen that their complaint is resolved.',
        ],
      ),
      ManualSection(
        icon: Icons.campaign_outlined,
        title: 'Broadcast to All Citizens',
        steps: [
          'Open Profile → "Send Notification".',
          'Type the title and message and press Send.',
          'Every signed-in citizen receives your broadcast as a push notification.',
        ],
      ),
    ],
  );

  static const ManualStrings hindi = ManualStrings(
    appBarTitle: 'उपयोगकर्ता मैनुअल',
    citizenManual: 'नागरिक मैनुअल',
    workerManual: 'कार्यकर्ता मैनुअल',
    headManual: 'प्रमुख मैनुअल',
    subtitle: 'सफाई सेतु उपयोग करने की चरण-दर-चरण मार्गदर्शिका',
    citizenSections: [
      ManualSection(
        icon: Icons.report_problem_outlined,
        title: 'शिकायत दर्ज करें',
        steps: [
          'होम टैब पर जाएं और "शिकायत दर्ज करें" पर टैप करें।',
          'कचरे की श्रेणी चुनें, फोटो (वैकल्पिक) और छोटा विवरण जोड़ें।',
          'आपका वर्तमान स्थान स्वतः जुड़ जाता है — आप मानचित्र पर पिन भी हिला सकते हैं।',
          'सबमिट करें — आपकी शिकायत अनुमोदन के लिए प्रमुख के पास भेज दी जाती है।',
        ],
      ),
      ManualSection(
        icon: Icons.track_changes_outlined,
        title: 'शिकायत की स्थिति देखें',
        steps: [
          'प्रोफ़ाइल → "मेरी शिकायतें" खोलें और अपनी सभी शिकायतें देखें।',
          'प्रगति लाइन का पालन करें: लंबित → स्वीकृत → कार्यकर्ता नियुक्त → प्रगति पर → हल।',
          'हर स्थिति बदलाव डेटाबेस से वास्तविक समय में दिखाई देता है।',
        ],
      ),
      ManualSection(
        icon: Icons.call_outlined,
        title: 'नियुक्त कार्यकर्ता को कॉल करें',
        steps: [
          'जब आपकी शिकायत पर कार्यकर्ता नियुक्त होता है, तो उसका नाम शिकायत पर दिखाई देता है।',
          'किसी भी समाधान के लिए कार्यकर्ता के नाम के बगल में कॉल आइकन पर टैप करें।',
        ],
      ),
      ManualSection(
        icon: Icons.local_shipping_outlined,
        title: 'कचरा संग्रह वाहन ट्रैक करें',
        steps: [
          'मैप टैब खोलें और "कचरा संग्रह वाहन ट्रैक करें" पर टैप करें।',
          'सभी ऑनलाइन कार्यकर्ताओं को मानचित्र पर ट्रक मार्कर के रूप में उनकी स्थिति के साथ देखें।',
          'नीचे कार्ड में कार्यकर्ता का नाम और ड्यूटी पर / ड्यूटी से बाहर दिखता है।',
        ],
      ),
      ManualSection(
        icon: Icons.circle_outlined,
        title: 'आस-पास के कचरा हॉटस्पॉट देखें',
        steps: [
          'मैप टैब में, वेस्ट हॉटस्पॉट पेज खोलें।',
          'हॉटस्पॉट सर्कल पिछले 7 दिनों में कई शिकायतों वाले क्षेत्र दिखाते हैं।',
          'रंग गंभीरता दर्शाता है — कम, मध्यम और उच्च — ताकि आप अपने आस-पास के समस्या क्षेत्रों को जान सकें।',
        ],
      ),
      ManualSection(
        icon: Icons.notifications_active_outlined,
        title: 'सूचनाएं पाएं',
        steps: [
          'जब भी आपकी शिकायत की स्थिति बदलती है, आपको पुश सूचना मिलती है।',
          'अपना पूरा सूचना इतिहास देखने के लिए प्रोफ़ाइल → "सूचनाएं" खोलें।',
          'किसी भी सूचना पर टैप करके संबंधित शिकायत खोलें, और कचरा आइकन से इतिहास साफ़ करें।',
        ],
      ),
    ],
    workerSections: [
      ManualSection(
        icon: Icons.assignment_outlined,
        title: 'कलेक्शन कार्य देखें और स्वीकार करें',
        steps: [
          'टास्क टैब खोलें — प्रमुख द्वारा आपको सौंपे गए सभी कार्य यहाँ दिखाई देते हैं।',
          'स्थान, कचरा श्रेणी और नागरिक विवरण देखने के लिए कार्य पर टैप करें।',
          'निकलते समय "स्टार्ट" (गो एन रूट) पर टैप करें — कार्य प्रगति पर चला जाता है।',
        ],
      ),
      ManualSection(
        icon: Icons.map_outlined,
        title: 'कार्य पर नेविगेट करें और पूरा करें',
        steps: [
          'कार्य विवरण में मानचित्र पर सटीक GPS स्थान दिखता है।',
          'जगह पर पहुंचें, कचरा इकट्ठा करें और सबमिट करने के लिए "पूरा करें" पर टैप करें।',
          'प्रूफ फोटो लें — यह समीक्षा के लिए प्रमुख के पास भेजी जाती है।',
        ],
      ),
      ManualSection(
        icon: Icons.my_location_outlined,
        title: 'लाइव लोकेशन और ड्यूटी स्थिति साझा करें',
        steps: [
          'लाइव मैप टैब का उपयोग करके लोकेशन शेयरिंग चालू करें — प्रमुख आपकी स्थिति लाइव देख सकते हैं।',
          'शेयरिंग के दौरान आपकी स्थिति ड्यूटी पर दिखती है, और रुकने पर ड्यूटी से बाहर।',
          'प्रमुख हमेशा अपने डैशबोर्ड से आपके वाहन को ट्रैक कर सकते हैं।',
        ],
      ),
      ManualSection(
        icon: Icons.route_outlined,
        title: 'अपना मार्ग अनुकूलित करें',
        steps: [
          'लाइव मैप टैब पर "मार्ग अनुकूलित करें" पर टैप करें।',
          'आपके सक्रिय कार्य आपकी स्थिति से सबसे अच्छे क्रम में 1-2-3… क्रमांकित होते हैं।',
          'एक लाइन स्टॉप्स को अनुमानित दूरी के साथ जोड़ती है, ताकि आप जान सकें कि कौन सा सबसे नजदीक है।',
        ],
      ),
    ],
    headSections: [
      ManualSection(
        icon: Icons.verified_outlined,
        title: 'नागरिक शिकायतें स्वीकृत करें',
        steps: [
          'शिकायत अनुभाग खोलें — नई नागरिक शिकायतें कचरा श्रेणी के साथ यहाँ आती हैं।',
          'प्रत्येक शिकायत की समीक्षा करें: संग्रह के लिए स्वीकृत करें, या कारण के साथ अस्वीकार करें।',
          'स्वीकृत शिकायतें कार्यकर्ता नियुक्ति के लिए तैयार होती हैं।',
        ],
      ),
      ManualSection(
        icon: Icons.badge_outlined,
        title: 'कार्यकर्ता आईडी बनाएं',
        steps: [
          'वर्कर्स टैब खोलें और "कार्यकर्ता जोड़ें / बनाएं" पर टैप करें।',
          'कार्यकर्ता का विवरण दर्ज करें — सिस्टम एक अद्वितीय वर्कर आईडी जारी करता है (जैसे WK-1002)।',
          'कार्यकर्ता के साथ आईडी साझा करें ताकि वह अपने डिवाइस पर लॉगिन कर सके।',
        ],
      ),
      ManualSection(
        icon: Icons.local_shipping_outlined,
        title: 'कार्यकर्ताओं की निगरानी करें और उन्हें कॉल करें',
        steps: [
          'वर्कर्स टैब हर कार्यकर्ता को उनकी लाइव ड्यूटी पर / ड्यूटी से बाहर स्थिति के साथ दिखाता है।',
          'कार्यकर्ता की प्रोफ़ाइल खोलकर मानचित्र पर उनकी लाइव लोकेशन देखें।',
          'सीधे संपर्क के लिए कार्यकर्ता प्रोफ़ाइल में कॉल आइकन पर टैप करें।',
        ],
      ),
      ManualSection(
        icon: Icons.task_alt_outlined,
        title: 'कलेक्शन कार्य नियुक्त और रद्द करें',
        steps: [
          'स्वीकृत शिकायत से, कार्यकर्ता को कार्य नियुक्त करें — उन्हें पुश सूचना मिलती है।',
          'कार्यकर्ता शुरू (गो एन रूट) होने तक आप कार्य कभी भी रद्द कर सकते हैं।',
          'कार्यकर्ता के रूट पर जाने के बाद कार्य रद्द नहीं किया जा सकता।',
        ],
      ),
      ManualSection(
        icon: Icons.image_outlined,
        title: 'प्रूफ फोटो की समीक्षा करें',
        steps: [
          'जब कार्यकर्ता प्रूफ फोटो जमा करता है, आपको सूचना मिलती है — प्रूफ्स खोलें।',
          'प्रूफ स्वीकृत करके शिकायत को हल चिह्नित करें, या कार्यकर्ता को वापस भेजें।',
          'स्वीकृति पर नागरिक को सूचित किया जाता है कि उनकी शिकायत हल हो गई है।',
        ],
      ),
      ManualSection(
        icon: Icons.campaign_outlined,
        title: 'सभी नागरिकों को प्रसारण भेजें',
        steps: [
          'प्रोफ़ाइल → "सूचना भेजें" खोलें।',
          'शीर्षक और संदेश लिखें और भेजें दबाएं।',
          'हर साइन इन नागरिक को आपका प्रसारण पुश सूचना के रूप में मिलता है।',
        ],
      ),
    ],
  );

  static const ManualStrings gujarati = ManualStrings(
    appBarTitle: 'વપરાશકર્તા મેન્યુઅલ',
    citizenManual: 'નાગરિક મેન્યુઅલ',
    workerManual: 'કામદાર મેન્યુઅલ',
    headManual: 'વડા મેન્યુઅલ',
    subtitle: 'સફાઈ સેતુ વાપરવા માટે પગલું-દર-પગલું માર્ગદર્શિકા',
    citizenSections: [
      ManualSection(
        icon: Icons.report_problem_outlined,
        title: 'ફરિયાદ નોંધાવો',
        steps: [
          'હોમ ટેબ પર જાઓ અને "ફરિયાદ નોંધાવો" પર ટૅપ કરો.',
          'કચરાની શ્રેણી પસંદ કરો, ફોટો (વૈકલ્પિક) અને ટૂંકું વર્ણન ઉમેરો.',
          'તમારું વર્તમાન સ્થાન આપમેળે જોડાય છે — તમે નકશા પર પિન પણ ખસેડી શકો છો.',
          'સબમિટ કરો — તમારી ફરિયાદ મંજૂરી માટે વડા પાસે મોકલાય છે.',
        ],
      ),
      ManualSection(
        icon: Icons.track_changes_outlined,
        title: 'ફરિયાદની સ્થિતિ જુઓ',
        steps: [
          'પ્રોફાઇલ → "મારી ફરિયાદો" ખોલો અને તમારી બધી ફરિયાદો જુઓ.',
          'પ્રગતિ રેખા અનુસરો: બાકી → મંજૂર → કામદાર સોંપાયેલ → પ્રગતિમાં → ઉકેલાયેલ.',
          'દરેક સ્થિતિ ફેરફાર ડેટાબેઝથી રીઅલ-ટાઇમમાં દેખાય છે.',
        ],
      ),
      ManualSection(
        icon: Icons.call_outlined,
        title: 'સોંપાયેલ કામદારને કૉલ કરો',
        steps: [
          'જ્યારે તમારી ફરિયાદ પર કામદાર સોંપાય છે, ત્યારે તેનું નામ ફરિયાદ પર દેખાય છે.',
          'કોઈપણ ઉકેલ માટે કામદારના નામની બાજુના કૉલ આઇકન પર ટૅપ કરો.',
        ],
      ),
      ManualSection(
        icon: Icons.local_shipping_outlined,
        title: 'કચરા સંગ્રહ વાહનો ટ્રૅક કરો',
        steps: [
          'મેપ ટેબ ખોલો અને "કચરા સંગ્રહ વાહન ટ્રૅક કરો" પર ટૅપ કરો.',
          'બધા ઑનલાઇન કામદારોને તેમની સ્થિતિ સાથે નકશા પર ટ્રક માર્કર તરીકે જુઓ.',
          'નીચેના કાર્ડ કામદારનું નામ અને ડ્યુટી પર / ડ્યુટી બંધ દર્શાવે છે.',
        ],
      ),
      ManualSection(
        icon: Icons.circle_outlined,
        title: 'નજીકના કચરા હોટસ્પોટ્સ જુઓ',
        steps: [
          'મેપ ટેબમાં, વેસ્ટ હોટસ્પોટ્સ પેજ ખોલો.',
          'હોટસ્પોટ વર્તુળો છેલ્લા 7 દિવસમાં ઘણી ફરિયાદોવાળા વિસ્તારો દર્શાવે છે.',
          'રંગ ગંભીરતા દર્શાવે છે — ઓછી, મધ્યમ અને ઉચ્ચ — જેથી તમે તમારી નજીકના સમસ્યા વિસ્તારો જાણી શકો.',
        ],
      ),
      ManualSection(
        icon: Icons.notifications_active_outlined,
        title: 'સૂચનાઓ મેળવો',
        steps: [
          'જ્યારે પણ તમારી ફરિયાદની સ્થિતિ બદલાય, ત્યારે તમને પુશ સૂચના મળે છે.',
          'તમારો સંપૂર્ણ સૂચના ઇતિહાસ જોવા પ્રોફાઇલ → "સૂચનાઓ" ખોલો.',
          'કોઈપણ સૂચના પર ટૅપ કરીને સંબંધિત ફરિયાદ ખોલો, અને કચરાપેટી આઇકનથી ઇતિહાસ સાફ કરો.',
        ],
      ),
    ],
    workerSections: [
      ManualSection(
        icon: Icons.assignment_outlined,
        title: 'કલેક્શન કાર્યો જુઓ અને સ્વીકારો',
        steps: [
          'ટાસ્ક ટેબ ખોલો — વડા દ્વારા તમને સોંપાયેલા બધા કાર્યો અહીં દેખાય છે.',
          'સ્થાન, કચરાની શ્રેણી અને નાગરિક વિગતો જોવા કાર્ય પર ટૅપ કરો.',
          'નીકળતી વખતે "સ્ટાર્ટ" (ગો એન રૂટ) પર ટૅપ કરો — કાર્ય પ્રગતિમાં જાય છે.',
        ],
      ),
      ManualSection(
        icon: Icons.map_outlined,
        title: 'કાર્ય પર નેવિગેટ કરો અને પૂર્ણ કરો',
        steps: [
          'કાર્યની વિગત નકશા પર ચોક્કસ GPS સ્થાન બતાવે છે.',
          'સ્થળે પહોંચો, કચરો એકત્રિત કરો અને સબમિટ કરવા "પૂર્ણ કરો" પર ટૅપ કરો.',
          'પ્રૂફ ફોટો લો — તે સમીક્ષા માટે વડા પાસે મોકલાય છે.',
        ],
      ),
      ManualSection(
        icon: Icons.my_location_outlined,
        title: 'લાઇવ લોકેશન અને ડ્યુટી સ્થિતિ શેર કરો',
        steps: [
          'લાઇવ મેપ ટેબ વાપરીને લોકેશન શેરિંગ ચાલુ કરો — વડા તમારી સ્થિતિ લાઇવ જોઈ શકે છે.',
          'શેરિંગ દરમિયાન તમારી સ્થિતિ ડ્યુટી પર અને રોકાયા પછી ડ્યુટી બંધ દેખાય છે.',
          'વડા હંમેશા તેમના ડેશબોર્ડથી તમારું વાહન ટ્રૅક કરી શકે છે.',
        ],
      ),
      ManualSection(
        icon: Icons.route_outlined,
        title: 'તમારો રૂટ ઑપ્ટિમાઇઝ કરો',
        steps: [
          'લાઇવ મેપ ટેબ પર "રૂટ ઑપ્ટિમાઇઝ કરો" પર ટૅપ કરો.',
          'તમારા સક્રિય કાર્યો તમારી સ્થિતિથી શ્રેષ્ઠ ક્રમમાં 1-2-3… નંબરિત થાય છે.',
          'એક લાઇન સ્ટોપ્સને અંદાજિત અંતર સાથે જોડે છે, જેથી તમે જાણો કે કયું સૌથી નજીક છે.',
        ],
      ),
    ],
    headSections: [
      ManualSection(
        icon: Icons.verified_outlined,
        title: 'નાગરિક ફરિયાદો મંજૂર કરો',
        steps: [
          'ફરિયાદ વિભાગ ખોલો — નવી નાગરિક ફરિયાદો કચરાની શ્રેણી સાથે અહીં આવે છે.',
          'દરેક ફરિયાદની સમીક્ષા કરો: સંગ્રહ માટે મંજૂર કરો, અથવા કારણ સાથે નકારો.',
          'મંજૂર ફરિયાદો કામદાર સોંપણી માટે તૈયાર હોય છે.',
        ],
      ),
      ManualSection(
        icon: Icons.badge_outlined,
        title: 'કામદાર ID બનાવો',
        steps: [
          'વર્કર્સ ટેબ ખોલો અને "કામદાર ઉમેરો / બનાવો" પર ટૅપ કરો.',
          'કામદારની વિગતો દાખલ કરો — સિસ્ટમ અનન્ય વર્કર ID જારી કરે છે (દા.ત. WK-1002).',
          'કામદાર તેમના ઉપકરણ પર લૉગિન કરે તે માટે ID શેર કરો.',
        ],
      ),
      ManualSection(
        icon: Icons.local_shipping_outlined,
        title: 'કામદારોનું નિરીક્ષણ કરો અને તેમને કૉલ કરો',
        steps: [
          'વર્કર્સ ટેબ દરેક કામદારને તેમની લાઇવ ડ્યુટી પર / ડ્યુટી બંધ સ્થિતિ સાથે બતાવે છે.',
          'કામદારની પ્રોફાઇલ ખોલીને નકશા પર તેમનું લાઇવ સ્થાન જુઓ.',
          'સીધો સંપર્ક કરવા કામદાર પ્રોફાઇલમાં કૉલ આઇકન પર ટૅપ કરો.',
        ],
      ),
      ManualSection(
        icon: Icons.task_alt_outlined,
        title: 'કલેક્શન કાર્યો સોંપો અને રદ કરો',
        steps: [
          'મંજૂર ફરિયાદમાંથી, કાર્ય કામદારને સોંપો — તેમને પુશ સૂચના મળે છે.',
          'કામદાર શરૂ (ગો એન રૂટ) ન કરે ત્યાં સુધી તમે કાર્ય કોઈપણ સમયે રદ કરી શકો છો.',
          'કામદાર એન રૂટ થઈ જાય પછી કાર્ય રદ કરી શકાતું નથી.',
        ],
      ),
      ManualSection(
        icon: Icons.image_outlined,
        title: 'પ્રૂફ ફોટા સમીક્ષા કરો',
        steps: [
          'જ્યારે કામદાર પ્રૂફ ફોટો સબમિટ કરે, ત્યારે તમને સૂચના મળે છે — પ્રૂફ્સ ખોલો.',
          'પ્રૂફ મંજૂર કરીને ફરિયાદ ઉકેલાયેલ ચિહ્નિત કરો, અથવા કામદારને પાછી મોકલો.',
          'મંજૂરી પર નાગરિકને સૂચિત કરવામાં આવે છે કે તેમની ફરિયાદ ઉકેલાઈ ગઈ છે.',
        ],
      ),
      ManualSection(
        icon: Icons.campaign_outlined,
        title: 'બધા નાગરિકોને પ્રસારણ મોકલો',
        steps: [
          'પ્રોફાઇલ → "સૂચના મોકલો" ખોલો.',
          'શીર્ષક અને સંદેશ લખો અને મોકલો દબાવો.',
          'દરેક સાઇન ઇન નાગરિકને તમારું પ્રસારણ પુશ સૂચના તરીકે મળે છે.',
        ],
      ),
    ],
  );
}
