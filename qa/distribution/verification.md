# Distribution verification — 20 October 2026

- Cevşen: 1.1.3+12. All 16 Flutter tests passed; static analysis clean. Final release installed over the existing app on the Wi-Fi phone. App opens and last read chapter 40 remains available. Android preferences backend pinned to 2.4.28 to avoid JNI release startup failures.
- KuranApp: 1.0.41+56. All 182 Flutter tests passed; static analysis clean. Three locales tested at phone portrait, phone landscape and tablet dimensions with enlarged text.
- KuranApp APK sharing opened the Android chooser with the installed version, WhatsApp and Gmail available; no file was sent to any contact.
- KuranApp update fetched release metadata from GitHub without opening a browser. A new-code test build numbered 55 was used to exercise an actual upgrade to public release 56.
- Download confirmation displayed 80.44 MB over Wi-Fi. Cancel returned to a retryable state; retry downloaded the APK, checked SHA-256/package/version/signature, and opened Android's installer. Play Protect scan completed and the system installation was confirmed. Installed version 1.0.41 / build 56 verified with PackageManager.
- Final KuranApp APK restored to the standard Flutter output path after the temporary lower-build test. Public GitHub asset digest matched the local final APK.
- Mobile-data confirmation branches use the 2 MiB threshold: explicit mobile-data approval at or below the threshold; Wi-Fi recommendation and explicit approval above it. The physical phone test used Wi-Fi; cellular download was not exercised.
- Android's installation permission, confirmation and Play Protect screens are controlled by Android and are not suppressed by either app.
- Cevşen final APK chooser displayed Cevsen-1.1.3.apk with WhatsApp and Gmail targets. Final update check displayed installed version 1.1.3 as current. Cevşen 1.1.3+12 published; unsuccessful intermediate releases hidden as drafts.
