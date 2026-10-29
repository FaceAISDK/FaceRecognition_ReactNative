#!/usr/bin/env node
'use strict';

// Read-only checks: no downloads, dependency updates, or device changes.
const {spawnSync} = require('node:child_process');
const {existsSync, readFileSync} = require('node:fs');
const {homedir} = require('node:os');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const sdkName = '@faceaisdk/react-native-face-sdk';
const args = process.argv.slice(2);
if (args.some(arg => !['--android', '--ios'].includes(arg))) {
  console.error('Usage: npm run doctor -- [--android] [--ios]');
  process.exit(2);
}
const android = args.length === 0 || args.includes('--android');
const ios =
  args.includes('--ios') ||
  (args.length === 0 && process.platform === 'darwin');
let failures = 0;
let warnings = 0;

function report(status, name, detail) {
  if (status === 'FAIL') {
    failures++;
  } else if (status === 'WARN') {
    warnings++;
  }
  console.log(`[${status}] ${name}: ${detail}`);
}

function read(relative) {
  const file = path.join(root, relative);
  return existsSync(file) ? readFileSync(file, 'utf8') : '';
}

function json(relative) {
  const content = read(relative);
  try {
    return content ? JSON.parse(content) : null;
  } catch {
    report(
      'FAIL',
      relative,
      'Invalid JSON; restore the file before continuing.',
    );
    return null;
  }
}

function command(name, executable, commandArgs, hint) {
  const result = spawnSync(executable, commandArgs, {
    cwd: root,
    encoding: 'utf8',
    timeout: 10000,
    windowsHide: true,
  });
  if (result.error || result.status !== 0) {
    report('FAIL', name, hint);
    return '';
  }
  return `${result.stdout || ''}\n${result.stderr || ''}`.trim();
}

function equal(name, actual, expected, hint) {
  const matches = Boolean(actual && expected && actual === expected);
  report(
    matches ? 'OK' : 'FAIL',
    name,
    matches
      ? actual
      : `${actual || 'missing'}; expected ${
          expected || 'a declared version'
        }. ${hint}`,
  );
}

console.log('FaceAISDK demo environment check\n');
const pkg = json('package.json');
const lock = json('package-lock.json');
const declared = pkg?.dependencies?.[sdkName];
if (!/^\d+\.\d+\.\d+$/.test(declared || '')) {
  report(
    'FAIL',
    'Plugin pin',
    'Use an exact plugin version in package.json, without ^ or ~.',
  );
}
equal(
  'Lockfile declaration',
  lock?.packages?.['']?.dependencies?.[sdkName],
  declared,
  'Regenerate and commit package-lock.json with the intended plugin version.',
);
equal(
  'Locked plugin',
  lock?.packages?.[`node_modules/${sdkName}`]?.version,
  declared,
  'Update package.json and package-lock.json together.',
);
const installed = json(`node_modules/${sdkName}/package.json`);
equal('Installed plugin', installed?.version, declared, 'Run npm ci.');
for (const dependency of ['react-native', '@react-native-community/cli']) {
  equal(
    dependency,
    json(`node_modules/${dependency}/package.json`)?.version,
    lock?.packages?.[`node_modules/${dependency}`]?.version,
    'Run npm ci.',
  );
}

const [nodeMajor, nodeMinor] = process.versions.node.split('.').map(Number);
report(
  nodeMajor > 22 || (nodeMajor === 22 && nodeMinor >= 11) ? 'OK' : 'FAIL',
  'Node.js',
  `${process.version}; requires >=22.11.0, verified with 26.0.0.`,
);
const npm = command(
  'npm',
  process.platform === 'win32' ? process.env.ComSpec || 'cmd.exe' : 'npm',
  process.platform === 'win32'
    ? ['/d', '/s', '/c', 'npm --version']
    : ['--version'],
  'Install npm; verified with 11.12.1.',
);
if (npm) {
  const verified = pkg?.packageManager?.replace(/^npm@/, '');
  report(
    npm === verified ? 'OK' : 'WARN',
    'npm',
    `${npm}; verified with ${verified}.`,
  );
}

if (android) {
  console.log('\nAndroid');
  const java = process.env.JAVA_HOME
    ? path.join(
        process.env.JAVA_HOME,
        'bin',
        process.platform === 'win32' ? 'java.exe' : 'java',
      )
    : 'java';
  const javaVersion = command(
    'JDK',
    java,
    ['-version'],
    'Install JDK 17 and set JAVA_HOME.',
  );
  if (javaVersion) {
    report(
      /version "17[."]/.test(javaVersion) ? 'OK' : 'FAIL',
      'JDK',
      javaVersion.split('\n')[0] + '; use JDK 17.',
    );
  }
  const gradle = read('android/build.gradle');
  const sdkVersion = gradle.match(/compileSdkVersion\s*=\s*(\d+)/)?.[1];
  const buildTools = gradle.match(/buildToolsVersion\s*=\s*"([^"]+)"/)?.[1];
  const ndk = gradle.match(/ndkVersion\s*=\s*"([^"]+)"/)?.[1];
  const localSdk = read('android/local.properties')
    .match(/^sdk\.dir=(.+)$/m)?.[1]
    ?.trim()
    .replace(/\\([\\ :])/g, '$1');
  const fallback =
    process.platform === 'darwin'
      ? path.join(homedir(), 'Library/Android/sdk')
      : process.platform === 'win32'
      ? path.join(
          process.env.LOCALAPPDATA || path.join(homedir(), 'AppData/Local'),
          'Android/Sdk',
        )
      : path.join(homedir(), 'Android/Sdk');
  const androidHome =
    localSdk ||
    process.env.ANDROID_HOME ||
    process.env.ANDROID_SDK_ROOT ||
    fallback;
  report(
    existsSync(androidHome) ? 'OK' : 'FAIL',
    'Android SDK',
    `${androidHome}; configure ANDROID_HOME or android/local.properties.`,
  );
  for (const [name, relative] of [
    [
      'Android platform',
      sdkVersion && `platforms/android-${sdkVersion}/android.jar`,
    ],
    [
      'Build Tools',
      buildTools && `build-tools/${buildTools}/source.properties`,
    ],
    ['NDK', ndk && `ndk/${ndk}/source.properties`],
    ['CMake (React Native app default)', 'cmake/3.22.1/source.properties'],
  ]) {
    report(
      relative && existsSync(path.join(androidHome, relative)) ? 'OK' : 'FAIL',
      name,
      `${
        relative || 'missing Gradle declaration'
      }; install the matching component in Android Studio SDK Manager.`,
    );
  }
  const wrapper = read(
    'android/gradle/wrapper/gradle-wrapper.properties',
  ).match(/gradle-([^/]+)-(?:bin|all)\.zip/)?.[1];
  report(
    wrapper ? 'OK' : 'FAIL',
    'Gradle wrapper',
    `${wrapper || 'missing'}; build with android/gradlew.`,
  );
  if (installed) {
    const native = read(`node_modules/${sdkName}/android/build.gradle`).match(
      /io\.github\.faceaisdk:Android:([^'"\s]+)/,
    )?.[1];
    report(
      native ? 'OK' : 'FAIL',
      'Android native SDK declaration',
      native ||
        'Cannot read the installed plugin Gradle dependency. Run npm ci.',
    );
  }
  const adb = path.join(
    androidHome,
    'platform-tools',
    process.platform === 'win32' ? 'adb.exe' : 'adb',
  );
  const devices = command(
    'adb',
    adb,
    ['devices'],
    'Install Android SDK Platform-Tools.',
  );
  if (devices) {
    const lines = devices
      .split('\n')
      .slice(1)
      .filter(line => line.trim());
    const connected = lines.filter(line => /\sdevice\s*$/.test(line));
    report(
      connected.length ? 'OK' : 'WARN',
      'Android device',
      connected.length
        ? `${connected.length} authorized device(s).`
        : 'Connect and unlock a physical device, enable USB debugging, and accept its authorization prompt.',
    );
    if (lines.some(line => /unauthorized|offline/.test(line))) {
      report(
        'WARN',
        'Android device authorization',
        'An unauthorized or offline device is connected; check the device prompt and USB connection.',
      );
    }
  }
}

if (ios) {
  console.log('\niOS');
  if (process.platform !== 'darwin') {
    report('FAIL', 'macOS', 'Build iOS on a Mac with Xcode installed.');
  } else {
    const xcode = command(
      'Xcode',
      'xcodebuild',
      ['-version'],
      'Install Xcode and select it with xcode-select. Verified with Xcode 26.6 (17F113).',
    );
    if (xcode) {
      report(
        /^Xcode 26\.6\b/.test(xcode) ? 'OK' : 'WARN',
        'Xcode',
        `${xcode.replace(/\n/g, ' / ')}; verified with 26.6 (17F113).`,
      );
    }
    const pod = command(
      'CocoaPods',
      'pod',
      ['--version'],
      'Install CocoaPods 1.16.2.',
    );
    if (pod) {
      const version = pod.match(/^\d+\.\d+\.\d+$/m)?.[0];
      report(
        version === '1.16.2' ? 'OK' : 'WARN',
        'CocoaPods',
        `${version || pod}; verified with 1.16.2.`,
      );
    }
    const podfile = read('ios/Podfile');
    const podLock = read('ios/Podfile.lock');
    equal(
      'Locked iOS plugin',
      podLock.match(/- react-native-face-sdk \(([^)]+)\)/)?.[1],
      declared,
      'Update the plugin and Pods lockfiles together.',
    );
    if (installed) {
      const core = read(
        `node_modules/${sdkName}/react-native-face-sdk.podspec`,
      ).match(/dependency\s+['"]FaceAISDK_Core['"],\s*['"]([^'"]+)['"]/)?.[1];
      equal(
        'iOS Core Git tag',
        podfile.match(
          /pod ['"]FaceAISDK_Core['"].*:tag\s*=>\s*['"]([^'"]+)['"]/,
        )?.[1],
        core,
        'Align ios/Podfile with the installed plugin podspec.',
      );
      equal(
        'Locked iOS Core',
        podLock.match(/- FaceAISDK_Core \(([^)]+)\)/)?.[1],
        core,
        'Update ios/Podfile.lock for the intended Core version.',
      );
    }
    const manifest = read('ios/Pods/Manifest.lock');
    report(
      !manifest ? 'WARN' : manifest === podLock ? 'OK' : 'FAIL',
      'Installed Pods',
      !manifest
        ? 'Not installed yet. Run cd ios && pod install --deployment.'
        : manifest === podLock
        ? 'Matches ios/Podfile.lock.'
        : 'Pods differ from ios/Podfile.lock. Run cd ios && pod install --deployment.',
    );
    console.log(
      '[INFO] Select your own Development Team in Xcode before a signed device build.',
    );
  }
}

console.log(`\n${failures} failure(s), ${warnings} warning(s).`);
process.exitCode = failures ? 1 : 0;
