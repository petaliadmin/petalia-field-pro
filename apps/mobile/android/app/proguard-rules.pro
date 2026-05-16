# App specific rules
-keep class com.example.petaliacropassist.** { *; }

# Keep Flutter and its plugins
-keep class io.flutter.** { *; }
-keep class com.dexterous.** { *; }
-keep class com.tekartik.** { *; }

# Ignore missing Play Core and Flutter embedding classes
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
