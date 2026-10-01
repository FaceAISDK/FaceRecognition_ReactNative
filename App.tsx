import React from 'react';
import {
  Alert,
  NativeModules,
  PermissionsAndroid,
  Platform,
  Pressable,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import {
  addFaceByImage,
  addFaceBySDKCamera,
  deleteFaceFeature,
  faceVerify,
  getFaceFeature,
  insertFaceFeature,
  isFaceAIModuleAvailable,
  livenessVerify,
  type FaceResult,
} from '@faceaisdk/react-native-face-sdk';

// Reuse this ID for enrollment, verification, lookup, and deletion.
const DEMO_FACE_ID = 'demo-user';
// Set real data to enable these APIs; inserting a feature overwrites this ID.
const DEMO_FACE_FEATURE = '';
const DEMO_BASE64_IMAGE = '';
// Shared settings for face verification and standalone liveness detection.
const LIVENESS_OPTIONS = {
  livenessType: 1 as const,
  motionTypes: '1,2,3,4,5',
  timeout: 7,
  steps: 2,
  allowMultiFaces: true,
};

const labels = {
  en: {
    title: 'Face Recognition API Demo',
    subtitle: 'Face enrollment, verification, and liveness detection',
    disconnected: 'SDK unavailable',
    permissionError: 'Camera permission required',
    cameraDenied: 'Camera permission is required for this feature.',
    failed: 'failed',
    unknownError: 'Unknown error',
    dataRequired: 'Set valid demo data in App.tsx before using this API.',
    enroll: 'Enroll face with camera',
    verify: 'Face verification + liveness',
    liveness: 'Liveness detection',
    query: 'Query face feature',
    sync: 'Insert custom face feature',
    imageEnroll: 'Enroll face from Base64 image',
    remove: 'Delete face feature',
    email: 'Email: FaceAISDK.Service@gmail.com',
  },
  zh: {
    title: '人脸识别 API 示例',
    subtitle: '体验人脸录入、比对与活体检测',
    disconnected: 'SDK 不可用',
    permissionError: '需要相机权限',
    cameraDenied: '需要相机权限才能使用此功能',
    failed: '失败',
    unknownError: '未知错误',
    dataRequired: '请先在 App.tsx 中配置真实演示数据。',
    enroll: '相机录入人脸',
    verify: '人脸比对 + 活体检测',
    liveness: '活体检测',
    query: '查询人脸特征',
    sync: '传入自定义人脸特征',
    imageEnroll: 'Base64图片录入人脸',
    remove: '删除人脸特征',
    email: '邮箱：FaceAISDK.Service@gmail.com',
  },
} as const;

type Language = keyof typeof labels;
type LabelKey = keyof (typeof labels)['en'];

type DemoAction = {
  labelKey: LabelKey;
  needsCamera?: boolean;
  input?: string;
  run: () => Promise<FaceResult>;
};

function readSystemLocale() {
  const settings = NativeModules.SettingsManager?.settings;
  const iosLocale =
    settings?.AppleLocale ??
    (Array.isArray(settings?.AppleLanguages) ? settings.AppleLanguages[0] : '');
  const androidLocale = NativeModules.I18nManager?.localeIdentifier;
  const intlLocale = Intl.DateTimeFormat().resolvedOptions().locale;

  return [iosLocale, androidLocale, intlLocale].find(
    locale => typeof locale === 'string' && locale.length > 0,
  );
}

export function resolveLanguage(locale?: string): Language {
  return locale?.toLowerCase().replace('_', '-').startsWith('zh') ? 'zh' : 'en';
}

const language = resolveLanguage(readSystemLocale());
const t = (key: LabelKey) => labels[language][key];

const actions: DemoAction[] = [
  {
    labelKey: 'enroll',
    needsCamera: true,
    run: () => addFaceBySDKCamera(DEMO_FACE_ID, {mode: 1, showConfirm: true}),
  },
  {
    labelKey: 'verify',
    needsCamera: true,
    run: () => faceVerify(DEMO_FACE_ID, LIVENESS_OPTIONS),
  },
  {
    labelKey: 'liveness',
    needsCamera: true,
    run: () => livenessVerify(LIVENESS_OPTIONS),
  },
  {
    labelKey: 'query',
    run: () => getFaceFeature(DEMO_FACE_ID),
  },
  {
    labelKey: 'sync',
    input: DEMO_FACE_FEATURE,
    run: () => insertFaceFeature(DEMO_FACE_ID, DEMO_FACE_FEATURE),
  },
  {
    labelKey: 'imageEnroll',
    input: DEMO_BASE64_IMAGE,
    run: () => addFaceByImage(DEMO_FACE_ID, DEMO_BASE64_IMAGE),
  },
  {
    labelKey: 'remove',
    run: () => deleteFaceFeature(DEMO_FACE_ID),
  },
];

async function requestCameraPermission() {
  // The native SDK handles camera permission on iOS.
  if (Platform.OS !== 'android') {
    return true;
  }

  return (
    (await PermissionsAndroid.request(
      PermissionsAndroid.PERMISSIONS.CAMERA,
    )) === PermissionsAndroid.RESULTS.GRANTED
  );
}

function formatResult(result: FaceResult) {
  // Show lengths only: feature strings and Base64 images can be large.
  return [
    `code: ${result.code}`,
    `message: ${result.message}`,
    `faceID: ${result.faceID}`,
    `similarity: ${result.similarity}`,
    `liveness: ${result.liveness}`,
    `faceFeature length: ${result.faceFeature.length}`,
    `faceBase64 length: ${result.faceBase64.length}`,
  ].join('\n');
}

function App() {
  // Module availability checks native linking, not the outcome of an SDK call.
  const pluginReady = isFaceAIModuleAvailable();

  const runDemo = async (action: DemoAction) => {
    const title = t(action.labelKey);

    try {
      // Unconfigured imports must not overwrite a face already enrolled by camera.
      if (action.input !== undefined && !action.input.trim()) {
        Alert.alert(title, t('dataRequired'));
        return;
      }

      if (action.needsCamera && !(await requestCameraPermission())) {
        Alert.alert(t('permissionError'), t('cameraDenied'));
        return;
      }

      // SDK business failures are returned in code/message, not necessarily thrown.
      const result = await action.run();
      Alert.alert(title, formatResult(result));
    } catch (error) {
      Alert.alert(
        `${title} ${t('failed')}`,
        error instanceof Error ? error.message : t('unknownError'),
      );
    }
  };

  return (
    <View style={styles.container}>
      <StatusBar
        barStyle="dark-content"
        backgroundColor={styles.container.backgroundColor}
      />
      <ScrollView
        contentInsetAdjustmentBehavior="automatic"
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.content}>
        <View style={styles.header}>
          <Text style={styles.brand}>FACEAISDK</Text>
          <Text style={styles.title}>{t('title')}</Text>
          <Text style={styles.subtitle}>{t('subtitle')}</Text>
        </View>

        {!pluginReady && (
          <Text style={styles.disconnected}>{t('disconnected')}</Text>
        )}

        {actions.map((action, index) => (
          <Pressable
            key={action.labelKey}
            accessibilityRole="button"
            accessibilityLabel={t(action.labelKey)}
            accessibilityState={{disabled: !pluginReady}}
            disabled={!pluginReady}
            onPress={() => runDemo(action)}
            style={({pressed}) => [
              styles.button,
              pressed && styles.buttonPressed,
              !pluginReady && styles.buttonDisabled,
            ]}>
            <Text style={styles.number}>
              {String(index + 1).padStart(2, '0')}
            </Text>
            <Text style={styles.buttonText}>{t(action.labelKey)}</Text>
            <Text style={styles.arrow}>›</Text>
          </Pressable>
        ))}

        <Text style={styles.footer}>{t('email')}</Text>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F4F6FA',
  },
  content: {
    width: '100%',
    maxWidth: 560,
    alignSelf: 'center',
    paddingHorizontal: 20,
    paddingTop: Platform.OS === 'android' ? 28 : 20,
    paddingBottom: 32,
  },
  header: {
    marginBottom: 24,
  },
  brand: {
    color: '#2563EB',
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 2,
    marginBottom: 10,
  },
  title: {
    color: '#17243B',
    fontSize: 22,
    fontWeight: '700',
    lineHeight: 30,
    marginBottom: 8,
  },
  subtitle: {
    color: '#64748B',
    fontSize: 14,
    lineHeight: 22,
  },
  disconnected: {
    color: '#B42318',
    backgroundColor: '#FEECEB',
    borderRadius: 12,
    padding: 12,
    marginBottom: 16,
  },
  button: {
    flexDirection: 'row',
    alignItems: 'center',
    minHeight: 60,
    backgroundColor: '#FFFFFF',
    borderColor: '#E3E9F2',
    borderWidth: 1,
    borderRadius: 16,
    marginBottom: 10,
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  buttonPressed: {
    opacity: 0.7,
  },
  buttonDisabled: {
    opacity: 0.45,
  },
  buttonText: {
    flex: 1,
    color: '#24344D',
    fontSize: 15,
    fontWeight: '600',
    lineHeight: 22,
  },
  number: {
    color: '#2563EB',
    backgroundColor: '#EDF3FF',
    borderRadius: 10,
    overflow: 'hidden',
    fontSize: 12,
    fontWeight: '700',
    lineHeight: 32,
    width: 32,
    marginRight: 14,
    textAlign: 'center',
  },
  arrow: {
    color: '#94A3B8',
    fontSize: 24,
    marginLeft: 12,
  },
  footer: {
    marginTop: 20,
    color: '#64748B',
    fontSize: 12,
    lineHeight: 20,
    textAlign: 'center',
  },
});

export default App;
