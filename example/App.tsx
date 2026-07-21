import {
  StatusBar,
  StyleSheet,
  View,
  TouchableOpacity,
  Text,
  Alert,
  Platform,
  ScrollView,
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

function App() {
  const demoFaceID = 'yourFaceID';
  const demoFeature = '0'.repeat(1024);

  const showResult = (title: string, result: FaceResult) => {
    Alert.alert(
      title,
      [
        `message: ${result.message}`,
        `faceID: ${result.faceID}`,
        `similarity: ${result.similarity}`,
        `liveness: ${result.liveness}`,
        `faceFeature长度: ${result.faceFeature?.length || 0}`,
        `faceBase64长度: ${result.faceBase64?.length || 0}`,
      ].join('\n'),
    );
  };

  const runAction = async (
    title: string,
    action: () => Promise<FaceResult>,
  ) => {
    try {
      const result = await action();
      showResult(title, result);
    } catch (error) {
      Alert.alert(
        `${title}失败`,
        error instanceof Error ? error.message : '未知错误',
      );
    }
  };

  const demoBase64 = 'demo_base64_image_string';

  return (
    <View style={styles.container}>
      <StatusBar barStyle="dark-content" />
      <Text style={styles.title}>人脸识别FaceSDK Demo</Text>
      <Text style={styles.subtitle}>
        {Platform.OS === 'ios' ? 'iOS' : 'Android'} · {isFaceAIModuleAvailable() ? '插件已连接' : '插件未连接'}
      </Text>
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContent}>
        <TouchableOpacity
          style={styles.button}
          onPress={() =>
            runAction('录入人脸结果', () =>
              addFaceBySDKCamera(demoFaceID, {
                mode: 1,
                showConfirm: true,
              }),
            )
          }>
          <Text style={styles.buttonText}>SDK相机录入人脸信息</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.button}
          onPress={() =>
            runAction('人脸识别结果', () =>
              faceVerify(demoFaceID, {
                threshold: 0.83,
                livenessType: 1,
                motionTypes: '1,2,3,4,5',
                timeout: 7,
                steps: 2,
                allowMultiFaces: true,
              }),
            )
          }>
          <Text style={styles.buttonText}>人脸识别+活体检测</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.button}
          onPress={() =>
            runAction('活体检测结果', () =>
              livenessVerify({
                livenessType: 4,
                motionTypes: '1,2,3,4,5',
                timeout: 7,
                steps: 2,
                allowMultiFaces: true,
              }),
            )
          }>
          <Text style={styles.buttonText}>检测人脸是否活体</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.button}
          onPress={() => runAction('查询人脸特征', () => getFaceFeature(demoFaceID))}>
          <Text style={styles.buttonText}>查询人脸特征信息</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.button}
          onPress={() =>
            runAction('同步人脸特征', () =>
              insertFaceFeature(demoFaceID, demoFeature),
            )
          }>
          <Text style={styles.buttonText}>同步人脸特征信息</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.button}
          onPress={() =>
            runAction('图片录入结果', () => addFaceByImage(demoFaceID, demoBase64))
          }>
          <Text style={styles.buttonText}>图片录入人脸信息</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.button}
          onPress={() => runAction('删除人脸特征', () => deleteFaceFeature(demoFaceID))}>
          <Text style={styles.buttonText}>删除人脸特征信息</Text>
        </TouchableOpacity>

      </ScrollView>
      <Text style={styles.footer}>Powered by FaceAISDK</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    paddingTop: 60,
    paddingBottom: 30,
  },
  title: {
    fontSize: 22,
    fontWeight: '700',
    color: '#333333',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 14,
    color: '#999999',
    marginBottom: 20,
  },
  scrollView: {
    flex: 1,
    width: '100%',
  },
  scrollContent: {
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  button: {
    backgroundColor: '#34C759',
    paddingHorizontal: 24,
    paddingVertical: 14,
    borderRadius: 8,
    marginVertical: 6,
    width: '100%',
    alignItems: 'center',
  },
  buttonSecondary: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 24,
    paddingVertical: 14,
    borderRadius: 8,
    marginVertical: 6,
    width: '100%',
    alignItems: 'center',
  },
  buttonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  footer: {
    fontSize: 12,
    color: '#999999',
    marginTop: 10,
  },
});

export default App;
