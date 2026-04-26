-keep class com.revenuecat.purchases.** { *; }

# Google Sign-In / Play Services Auth.
# Keeps ApiException + signin client classes that R8 may otherwise strip
# in release/AAB builds, which silently breaks Google Sign-In on Play.
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-dontwarn com.google.android.gms.**

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
