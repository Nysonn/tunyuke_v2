allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory = file("../build")
subprojects {
    project.layout.buildDirectory = file("${rootProject.layout.buildDirectory.get().asFile}/${project.name}")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}