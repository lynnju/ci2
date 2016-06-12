uniform.project("test", "au.com.cba.omnia.test")

uniformDependencySettings

strictDependencySettings

updateOptions := updateOptions.value.withCachedResolution(true)

libraryDependencies ++=
  depend.omnia("omnia-test", "0.4.3-20160404081116-ec9a1e5") ++
  depend.testing()                                           ++
  Seq(
    "ch.qos.logback" % "logback-classic"    % "1.1.3",
    "com.wix"       %% "accord-specs2-3-x"  % "0.5" % "test"
  )
