# Agora Chat SDK - Keep push classes
-keep class com.hyphenate.** { *; }
-keep class com.heytap.msp.push.** { *; }
-keep class com.meizu.cloud.pushsdk.** { *; }
-keep class com.vivo.push.** { *; }
-keep class com.xiaomi.mipush.** { *; }

# Agora Chat - Don't warn about missing push classes
-dontwarn com.heytap.msp.push.**
-dontwarn com.meizu.cloud.pushsdk.**
-dontwarn com.vivo.push.**
-dontwarn com.xiaomi.mipush.**

# Keep Agora Chat interfaces and callbacks
-keep interface com.hyphenate.** { *; }
-keep class * implements com.hyphenate.** { *; }

# General Android push notifications
-keep class * extends android.app.Service { *; }
-keep class * extends android.content.BroadcastReceiver { *; }
