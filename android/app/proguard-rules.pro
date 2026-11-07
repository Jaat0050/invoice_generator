# Flutter Engine & Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Suppress Play Core SplitInstall warnings for Flutter deferred components
-dontwarn com.google.android.play.core.**

# Flutter Secure Storage & Jetpack Security
-keep class androidx.security.crypto.** { *; }

# PDF & Printing Plugin
-keep class net.nfet.flutter.printing.** { *; }
