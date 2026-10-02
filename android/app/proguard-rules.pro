# Read by the Flutter Gradle plugin for release builds (R8).

# google_mlkit_text_recognition references the optional Chinese, Devanagari,
# Japanese and Korean recognisers. Only the Latin one is bundled (a National
# ID is printed in Latin script), so R8 must not fail on the others' absence.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep ML Kit and its Flutter plugins whole. R8 cannot see that ML Kit finds
# its components through manifest metadata and reflection; stripping or
# renaming them makes reading a National ID fail at runtime in release builds
# only (debug builds are not shrunk).
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_** { *; }
-keep class com.google.android.gms.mlkit.** { *; }
-keep class com.google_mlkit_** { *; }
