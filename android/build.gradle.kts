allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    // Some plugins still declare compileSdk 34. Their AndroidX dependencies require 36.
    afterEvaluate {
        val android = extensions.findByName("android") ?: return@afterEvaluate
        val setCompileSdk = android.javaClass.methods.firstOrNull {
            it.name == "setCompileSdk" && it.parameterTypes.size == 1
        }
        setCompileSdk?.invoke(android, 36)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
