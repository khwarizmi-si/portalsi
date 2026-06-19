// Project-level build.gradle.kts

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    project.layout.buildDirectory.set(
        rootProject.layout.buildDirectory.dir(project.name)
    )
    afterEvaluate {
        val androidExtension = project.extensions.findByName("android")
        if (androidExtension is com.android.build.gradle.BaseExtension) {
            // Force a single, already-installed NDK across all plugin modules.
            // Some plugins (e.g. the :jni module) pin a different NDK; without
            // this Gradle tries to auto-install it and can leave a corrupt copy.
            androidExtension.ndkVersion = "27.0.12077973"

            // AGP 8 requires a namespace. Legacy plugins (move_to_background,
            // device_info, …) only declare `package` in their manifest — inject
            // it as the namespace so the build doesn't fail on them.
            if (androidExtension.namespace == null) {
                val manifest = project.file("src/main/AndroidManifest.xml")
                if (manifest.exists()) {
                    val pkg = Regex("package=\"(.+?)\"")
                        .find(manifest.readText())?.groupValues?.get(1)
                    if (pkg != null) androidExtension.namespace = pkg
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}