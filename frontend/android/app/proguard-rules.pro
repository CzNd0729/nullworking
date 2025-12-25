# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Huawei Push
-ignorewarnings
-keepattributes *Annotation*
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keep class com.huawei.hms.**{*;}
-keep class com.huawei.agconnect.**{*;}

# BouncyCastle (often used for crypto)
-keep class org.bouncycastle.** { *; }

# OpenInstall
-keep class com.fm.openinstall.** { *; }
