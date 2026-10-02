# Firebase rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep FCM classes
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }

# Keep your notification classes
-keep class com.example.bookify.** { *; }

# Don't warn about missing dependencies
-dontwarn com.google.firebase.**