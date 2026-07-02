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
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Some legacy plugins (e.g. sentry_flutter 8.x) still declare Kotlin
// languageVersion 1.6, which the current Kotlin 2.2 toolchain rejects
// ("Language version 1.6 is no longer supported"). Raise any explicitly-set
// sub-1.9 language/api version to 1.9 so the project compiles under current
// Flutter, while leaving modules that use the compiler default untouched.
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompilationTask<*>>().configureEach {
        compilerOptions {
            val minVersion = org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_9
            if ((languageVersion.orNull ?: minVersion) < minVersion) {
                languageVersion.set(minVersion)
            }
            if ((apiVersion.orNull ?: minVersion) < minVersion) {
                apiVersion.set(minVersion)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
