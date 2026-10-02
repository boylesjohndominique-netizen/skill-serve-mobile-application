# Read by the Flutter Gradle plugin for release builds (R8).

# google_mlkit_text_recognition references the optional Chinese, Devanagari,
# Japanese and Korean recognisers. Only the Latin one is bundled (a National
# ID is printed in Latin script), so R8 must not fail on the others' absence.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
