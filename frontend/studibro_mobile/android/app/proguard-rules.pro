# ML Kit text recognition rules
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
-keepclassmembers class com.google.mlkit.vision.text.** { *; }
-keepclasseswithmembernames class com.google.mlkit.vision.text.** { *; }

# Google MLKit Commons
-keep class com.google_mlkit_commons.** { *; }
-keepclassmembers class com.google_mlkit_commons.** { *; }

# Google Play Services ML Kit
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }
-keepclassmembers class com.google.android.gms.** { *; }
-keepclassmembers class com.google.firebase.** { *; }

# Keep all inner classes
-keepclasseswithmembers class ** {
    *** *(...);
}

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
