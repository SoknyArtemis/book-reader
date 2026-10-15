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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// 临时修复：Flutter 3.47.7 默认 compileSdk 偏低(34)，而新版 file_picker 依赖的
// flutter_plugin_android_lifecycle 要求 compileSdk>=36。统一把所有 Android 子工程(含插件)
// 抬到 36，满足 AGP 的 AAR metadata 检查。升级 Flutter 后可移除。
subprojects {
    if (state.executed) {
        extensions.findByType(com.android.build.api.dsl.CommonExtension::class.java)?.let { it.compileSdk = 36 }
    } else {
        afterEvaluate {
            extensions.findByType(com.android.build.api.dsl.CommonExtension::class.java)?.let { it.compileSdk = 36 }
        }
    }
}
