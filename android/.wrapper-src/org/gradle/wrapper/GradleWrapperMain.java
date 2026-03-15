package org.gradle.wrapper;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.StandardCopyOption;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Properties;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public final class GradleWrapperMain {
  private GradleWrapperMain() {}

  public static void main(String[] args) throws Exception {
    Path projectDir = Paths.get(System.getProperty("user.dir")).toAbsolutePath();
    Path propertiesPath = projectDir.resolve("gradle/wrapper/gradle-wrapper.properties");
    if (!Files.exists(propertiesPath)) {
      throw new IOException("Missing gradle-wrapper.properties at " + propertiesPath);
    }

    Properties props = new Properties();
    try (InputStream in = Files.newInputStream(propertiesPath)) {
      props.load(in);
    }

    String distributionUrl = require(props, "distributionUrl");
    String distributionBase = props.getProperty("distributionBase", "GRADLE_USER_HOME");
    String distributionPath = props.getProperty("distributionPath", "wrapper/dists");

    Path baseDir = resolveBaseDir(projectDir, distributionBase);
    Path installRoot = baseDir.resolve(distributionPath);
    Files.createDirectories(installRoot);

    String zipName = distributionUrl.substring(distributionUrl.lastIndexOf('/') + 1);
    String distLabel = zipName.replaceFirst("\\.zip$", "");
    Path distributionDir = installRoot.resolve(distLabel);
    Path zipTarget = distributionDir.resolve(zipName);
    Path marker = distributionDir.resolve(".installed");

    Files.createDirectories(distributionDir);
    if (!Files.exists(marker)) {
      download(distributionUrl, zipTarget);
      unzip(zipTarget, distributionDir);
      Path gradleExecutable = findGradleExecutable(distributionDir);
      if (!isWindows()) {
        gradleExecutable.toFile().setExecutable(true);
      }
      Files.writeString(marker, "ok");
    }

    Path gradleExecutable = findGradleExecutable(distributionDir);
    if (!isWindows()) {
      gradleExecutable.toFile().setExecutable(true);
    }

    List<String> command = new ArrayList<>();
    if (isWindows()) {
      command.add("cmd");
      command.add("/c");
      command.add(gradleExecutable.toString());
    } else {
      command.add(gradleExecutable.toString());
    }
    for (String arg : args) {
      command.add(arg);
    }

    ProcessBuilder builder = new ProcessBuilder(command);
    builder.directory(projectDir.toFile());
    builder.inheritIO();
    Process process = builder.start();
    int code = process.waitFor();
    System.exit(code);
  }

  private static String require(Properties props, String key) {
    String value = props.getProperty(key);
    if (value == null || value.isBlank()) {
      throw new IllegalStateException("Missing required property: " + key);
    }
    return value;
  }

  private static Path resolveBaseDir(Path projectDir, String distributionBase) {
    if ("PROJECT".equalsIgnoreCase(distributionBase)) {
      return projectDir;
    }
    String home = System.getProperty("user.home");
    if (home == null || home.isBlank()) {
      throw new IllegalStateException("user.home is not available");
    }
    return Paths.get(home, ".gradle");
  }

  private static void download(String urlString, Path target) throws Exception {
    Files.createDirectories(target.getParent());
    HttpURLConnection connection = (HttpURLConnection) URI.create(urlString).toURL().openConnection();
    connection.setInstanceFollowRedirects(true);
    connection.setConnectTimeout(30000);
    connection.setReadTimeout(30000);
    connection.setRequestProperty("User-Agent", "JumpTrack-Gradle-Wrapper");

    try (InputStream in = connection.getInputStream(); OutputStream out = Files.newOutputStream(target)) {
      byte[] buffer = new byte[8192];
      int read;
      while ((read = in.read(buffer)) >= 0) {
        out.write(buffer, 0, read);
      }
    }
  }

  private static void unzip(Path zipFile, Path destination) throws Exception {
    try (ZipInputStream zis = new ZipInputStream(Files.newInputStream(zipFile))) {
      ZipEntry entry;
      while ((entry = zis.getNextEntry()) != null) {
        Path output = destination.resolve(entry.getName()).normalize();
        if (!output.startsWith(destination)) {
          throw new IOException("Bad zip entry: " + entry.getName());
        }
        if (entry.isDirectory()) {
          Files.createDirectories(output);
        } else {
          Files.createDirectories(output.getParent());
          Files.copy(zis, output, StandardCopyOption.REPLACE_EXISTING);
        }
        zis.closeEntry();
      }
    }
  }

  private static Path findGradleExecutable(Path root) throws Exception {
    final String expected = isWindows() ? "gradle.bat" : "gradle";
    final Path[] result = new Path[1];
    Files.walkFileTree(root, new SimpleFileVisitor<>() {
      @Override
      public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) {
        if (file.getFileName().toString().equals(expected) && file.getParent() != null && file.getParent().getFileName().toString().equals("bin")) {
          result[0] = file;
          return FileVisitResult.TERMINATE;
        }
        return FileVisitResult.CONTINUE;
      }
    });
    if (result[0] == null) {
      throw new IOException("Unable to locate Gradle executable in " + root);
    }
    return result[0];
  }

  private static boolean isWindows() {
    return System.getProperty("os.name", "").toLowerCase(Locale.US).contains("win");
  }
}
