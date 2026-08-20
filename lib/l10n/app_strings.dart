import 'package:flutter/widgets.dart';

/// Central string catalog for the app's three languages (English, Hindi,
/// Gujarati). New screens should read their text from here so the whole app
/// follows the language picked on the login screen.
///
/// Usage: `AppStrings.of(context).login` — returns the strings for the
/// locale currently active in the MaterialApp.
class AppStrings {
  const AppStrings({
    required this.chooseLanguage,
    required this.selectLanguageHint,
    required this.cancel,
    required this.welcomeTitle,
    required this.loginSubtitle,
    required this.email,
    required this.emailHint,
    required this.password,
    required this.passwordHint,
    required this.login,
    required this.continueWithGoogle,
    required this.signingIn,
    required this.loginFooter,
    required this.poweredBy,
    required this.navHome,
    required this.navComplaints,
    required this.navMap,
    required this.navProfile,
    required this.navDashboard,
    required this.navTasks,
    required this.navLiveMap,
    required this.navWorkers,
    required this.navProofs,
    required this.appTagline,
    required this.hello,
    required this.myComplaints,
    required this.resolved,
    required this.inProgress,
    required this.nearbyIssues,
    required this.quickActions,
    required this.nearbyWasteIssues,
    required this.recentActivity,
    required this.reportWaste,
    required this.reportWasteSub,
    required this.trackYourIssues,
    required this.trackVehicle,
    required this.trackVehicleSub,
    required this.wasteHotspots,
    required this.wasteHotspotsSub,
    required this.noActivity,
  });

  // Language picker
  final String chooseLanguage;
  final String selectLanguageHint;
  final String cancel;

  // Login
  final String welcomeTitle;
  final String loginSubtitle;
  final String email;
  final String emailHint;
  final String password;
  final String passwordHint;
  final String login;
  final String continueWithGoogle;
  final String signingIn;
  final String loginFooter;

  // Splash
  final String poweredBy;

  // Bottom navigation labels
  final String navHome;
  final String navComplaints;
  final String navMap;
  final String navProfile;
  final String navDashboard;
  final String navTasks;
  final String navLiveMap;
  final String navWorkers;
  final String navProofs;

  // Home dashboard
  final String appTagline;
  final String hello;
  final String myComplaints;
  final String resolved;
  final String inProgress;
  final String nearbyIssues;
  final String quickActions;
  final String nearbyWasteIssues;
  final String recentActivity;
  final String reportWaste;
  final String reportWasteSub;
  final String trackYourIssues;
  final String trackVehicle;
  final String trackVehicleSub;
  final String wasteHotspots;
  final String wasteHotspotsSub;
  final String noActivity;

  /// Strings for the language currently active in [context].
  static AppStrings of(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'hi':
        return hindi;
      case 'gu':
        return gujarati;
      default:
        return english;
    }
  }

  static const AppStrings english = AppStrings(
    chooseLanguage: 'Choose Language',
    selectLanguageHint: 'Select your preferred language',
    cancel: 'Cancel',
    welcomeTitle: 'Welcome to Safai Setu',
    loginSubtitle:
        'Sign in to report waste, track complaints, and access your role-based dashboard.',
    email: 'Email',
    emailHint: 'you@example.com',
    password: 'Password',
    passwordHint: 'Enter your password',
    login: 'Login',
    continueWithGoogle: 'Continue with Google',
    signingIn: 'Signing in...',
    loginFooter:
        'Citizens sign in with Google. Workers and department heads sign in with the email and password issued by Safai Setu. Your access level is determined by your profile role in the database.',
    poweredBy: 'Powered by ',
    navHome: 'Home',
    navComplaints: 'Complaints',
    navMap: 'Map',
    navProfile: 'Profile',
    navDashboard: 'Dashboard',
    navTasks: 'Tasks',
    navLiveMap: 'Live Map',
    navWorkers: 'Workers',
    navProofs: 'Proofs',
    appTagline: 'Together for a Cleaner City',
    hello: 'Hello',
    myComplaints: 'My Complaints',
    resolved: 'Resolved',
    inProgress: 'In Progress',
    nearbyIssues: 'Nearby Issues',
    quickActions: 'Quick Actions',
    nearbyWasteIssues: 'Nearby Waste Issues',
    recentActivity: 'Recent Activity',
    reportWaste: 'Report Waste',
    reportWasteSub: 'Report garbage or cleanliness issues',
    trackYourIssues: 'Track your reported issues',
    trackVehicle: 'Track Vehicle',
    trackVehicleSub: 'View nearby waste collection vehicles',
    wasteHotspots: 'Waste Hotspots',
    wasteHotspotsSub: 'View areas with high waste accumulation',
    noActivity: 'No activity yet. Report a waste issue to get started!',
  );

  static const AppStrings hindi = AppStrings(
    chooseLanguage: 'भाषा चुनें',
    selectLanguageHint: 'अपनी पसंदीदा भाषा चुनें',
    cancel: 'रद्द करें',
    welcomeTitle: 'सफाई सेतु में आपका स्वागत है',
    loginSubtitle:
        'कचरा रिपोर्ट करने, शिकायतों को ट्रैक करने और अपने रोल-आधारित डैशबोर्ड तक पहुँचने के लिए साइन इन करें।',
    email: 'ईमेल',
    emailHint: 'you@example.com',
    password: 'पासवर्ड',
    passwordHint: 'अपना पासवर्ड दर्ज करें',
    login: 'लॉगिन',
    continueWithGoogle: 'Google से जारी रखें',
    signingIn: 'साइन इन हो रहा है...',
    loginFooter:
        'नागरिक Google से साइन इन करते हैं। कर्मचारी और विभाग प्रमुख सफाई सेतु द्वारा जारी ईमेल और पासवर्ड से साइन इन करते हैं। आपकी पहुँच आपकी प्रोफ़ाइल रोल से निर्धारित होती है।',
    poweredBy: 'द्वारा संचालित ',
    navHome: 'होम',
    navComplaints: 'शिकायतें',
    navMap: 'नक्शा',
    navProfile: 'प्रोफ़ाइल',
    navDashboard: 'डैशबोर्ड',
    navTasks: 'कार्य',
    navLiveMap: 'लाइव नक्शा',
    navWorkers: 'कर्मचारी',
    navProofs: 'सबूत',
    appTagline: 'एक स्वच्छ शहर के लिए साथ',
    hello: 'नमस्ते',
    myComplaints: 'मेरी शिकायतें',
    resolved: 'हल हो गईं',
    inProgress: 'प्रगति पर',
    nearbyIssues: 'आस-पास की समस्याएं',
    quickActions: 'त्वरित क्रियाएं',
    nearbyWasteIssues: 'आस-पास की कचरा समस्याएं',
    recentActivity: 'हाल की गतिविधि',
    reportWaste: 'कचरा रिपोर्ट करें',
    reportWasteSub: 'कचरा या सफाई समस्याएं रिपोर्ट करें',
    trackYourIssues: 'अपनी रिपोर्ट की गई समस्याएं ट्रैक करें',
    trackVehicle: 'वाहन ट्रैक करें',
    trackVehicleSub: 'आस-पास के कचरा संग्रह वाहन देखें',
    wasteHotspots: 'कचरा हॉटस्पॉट',
    wasteHotspotsSub: 'उच्च कचरा संचय वाले क्षेत्र देखें',
    noActivity: 'अभी कोई गतिविधि नहीं। शुरू करने के लिए कचरा समस्या रिपोर्ट करें!',
  );

  static const AppStrings gujarati = AppStrings(
    chooseLanguage: 'ભાષા પસંદ કરો',
    selectLanguageHint: 'તમારી પસંદીદા ભાષા પસંદ કરો',
    cancel: 'રદ કરો',
    welcomeTitle: 'સફાઈ સેતુમાં આપનું સ્વાગત છે',
    loginSubtitle:
        'કચરો રિપોર્ટ કરવા, ફરિયાદો ટ્રૅક કરવા અને તમારા રોલ-આધારિત ડેશબોર્ડ સુધી પહોંચવા માટે સાઇન ઇન કરો.',
    email: 'ઈમેલ',
    emailHint: 'you@example.com',
    password: 'પાસવર્ડ',
    passwordHint: 'તમારો પાસવર્ડ દાખલ કરો',
    login: 'લૉગિન',
    continueWithGoogle: 'Google સાથે ચાલુ રાખો',
    signingIn: 'સાઇન ઇન થઈ રહ્યું છે...',
    loginFooter:
        'નાગરિકો Google થી સાઇન ઇન કરે છે. કામદારો અને વિભાગ વડાઓ સફાઈ સેતુ દ્વારા આપેલા ઈમેલ અને પાસવર્ડથી સાઇન ઇન કરે છે. તમારી પહોંચ તમારી પ્રોફાઇલ રોલ દ્વારા નક્કી થાય છે.',
    poweredBy: 'દ્વારા સંચાલિત ',
    navHome: 'હોમ',
    navComplaints: 'ફરિયાદો',
    navMap: 'નકશો',
    navProfile: 'પ્રોફાઇલ',
    navDashboard: 'ડેશબોર્ડ',
    navTasks: 'કાર્યો',
    navLiveMap: 'લાઈવ નકશો',
    navWorkers: 'કામદારો',
    navProofs: 'પુરાવા',
    appTagline: 'સ્વચ્છ શહેર માટે સાથે',
    hello: 'નમસ્તે',
    myComplaints: 'મારી ફરિયાદો',
    resolved: 'ઉકેલાયેલ',
    inProgress: 'પ્રગતિમાં',
    nearbyIssues: 'નજીકની સમસ્યાઓ',
    quickActions: 'ઝડપી ક્રિયાઓ',
    nearbyWasteIssues: 'નજીકની કચરાની સમસ્યાઓ',
    recentActivity: 'તાજેતરની પ્રવૃત્તિ',
    reportWaste: 'કચરો રિપોર્ટ કરો',
    reportWasteSub: 'કચરો અથવા સ્વચ્છતા સમસ્યાઓ રિપોર્ટ કરો',
    trackYourIssues: 'તમારી રિપોર્ટ કરેલી સમસ્યાઓ ટ્રૅક કરો',
    trackVehicle: 'વાહન ટ્રૅક કરો',
    trackVehicleSub: 'નજીકના કચરા સંગ્રહ વાહનો જુઓ',
    wasteHotspots: 'કચરા હોટસ્પોટ્સ',
    wasteHotspotsSub: 'વધુ કચરો એકઠો થતા વિસ્તારો જુઓ',
    noActivity: 'હજી કોઈ પ્રવૃત્તિ નથી. શરૂ કરવા માટે કચરાની સમસ્યા રિપોર્ટ કરો!',
  );
}
