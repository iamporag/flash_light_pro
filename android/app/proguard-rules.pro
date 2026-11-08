# Room resolves generated database implementations by name and instantiates
# them with a no-argument constructor. R8 removes that constructor otherwise,
# which crashes WorkManager startup with "Failed to create an instance of
# androidx.work.impl.WorkDatabase" in release builds.
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}
