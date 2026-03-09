# Flutter Local Notifications rules
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.crypto.tink.** { *; }
-keep class com.google.gson.** { *; }
-keep class com.example.emotion_tracker.** { *; }

# Keep the models that are being serialized
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * extends java.lang.reflect.Type
