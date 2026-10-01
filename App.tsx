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

//Silent liveness threshold (iOS/Android): 0.85–0.95. Actual performance varies with camera and lighting—adjust based on scenario.
//iOS Android 静默活体通过阈值范围0.85到0.95，注意实际表现和摄像头&环境有关
const DEMO_FACE_ID = 'demo-user';
const DEMO_FACE_FEATURE = '0'.repeat(1024);
const DEMO_BASE64_IMAGE = 'demo_base64_image_string';
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
    subtitle: 'Explore face enrollment, verification, and liveness.',
    disconnected: 'SDK Not Connected',
    permissionError: 'Permission Error',
    cameraDenied: 'Camera permission is required for this feature.',
    failed: 'Failed',
    unknownError: 'Unknown error',
    enroll: 'Enroll Face via Camera',
    verify: 'Face Verify + Liveness',
    liveness: 'Liveness Detection',
    query: 'Query Face Feature',
    sync: 'Insert Custom Face Feature',
    imageEnroll: 'Enroll with Custom Base64 Image',
    remove: 'Delete Face Feature',
    email: 'Contact: FaceAISDK.Service@gmail.com',
  },
  zh: {
    title: '人脸识别 API 示例',
    subtitle: '体验人脸录入、比对与活体检测',
    disconnected: 'SDK 未连接',
    permissionError: '权限错误',
    cameraDenied: '需要相机权限才能使用此功能',
    failed: '失败',
    unknownError: '未知错误',
    enroll: '相机录入人脸',
    verify: '人脸比对 + 活体检测',
    liveness: '活体检测',
    query: '查询人脸特征',
    sync: '传入自定义人脸特征',
    imageEnroll: '传入自定义 Base64 图片录入',
    remove: '删除人脸特征',
    email: 'Email: FaceAISDK.Service@gmail.com',
  },
} as const;

type Language = keyof typeof labels;
type LabelKey = keyof (typeof labels)['en'];

type DemoAction = {
  labelKey: LabelKey;
  needsCamera?: boolean;
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
    run: () => insertFaceFeature(DEMO_FACE_ID, DEMO_FACE_FEATURE),
  },
  {
    labelKey: 'imageEnroll',
    run: () => addFaceByImage(DEMO_FACE_ID, DEMO_BASE64_IMAGE),
  },
  {
    labelKey: 'remove',
    run: () => deleteFaceFeature(DEMO_FACE_ID),
  },
];

async function requestCameraPermission() {
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
  const pluginReady = isFaceAIModuleAvailable();

  const runDemo = async (action: DemoAction) => {
    const title = t(action.labelKey);

    try {
      if (action.needsCamera && !(await requestCameraPermission())) {
        Alert.alert(t('permissionError'), t('cameraDenied'));
        return;
      }

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
              index === 0 && styles.primaryButton,
              pressed && styles.buttonPressed,
              !pluginReady && styles.buttonDisabled,
            ]}>
            <Text style={[styles.number, index === 0 && styles.primaryNumber]}>
              {String(index + 1).padStart(2, '0')}
            </Text>
            <Text
              style={[
                styles.buttonText,
                index === 0 && styles.primaryText,
                action.labelKey === 'remove' && styles.dangerText,
              ]}>
              {t(action.labelKey)}
            </Text>
            <Text style={[styles.arrow, index === 0 && styles.primaryText]}>
              ›
            </Text>
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
    fontSize: 28,
    fontWeight: '700',
    lineHeight: 36,
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
  primaryButton: {
    backgroundColor: '#2563EB',
    borderColor: '#2563EB',
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
  primaryNumber: {
    color: '#FFFFFF',
    backgroundColor: '#FFFFFF26',
  },
  primaryText: {
    color: '#FFFFFF',
  },
  dangerText: {
    color: '#B42318',
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
