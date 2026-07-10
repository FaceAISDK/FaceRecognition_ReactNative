const mockAddFaceBySDKCamera = jest.fn();
const mockFaceVerify = jest.fn();
const mockLivenessVerify = jest.fn();
const mockGetFaceFeature = jest.fn();
const mockInsertFaceFeature = jest.fn();
const mockAddFaceBySDKImage = jest.fn();
const mockDeleteFaceFeature = jest.fn();

function loadSdk() {
  jest.resetModules();
  jest.doMock('react-native', () => ({
    NativeModules: {
      FaceRNModule: {
        addFaceBySDKCamera: mockAddFaceBySDKCamera,
        faceVerify: mockFaceVerify,
        livenessVerify: mockLivenessVerify,
        getFaceFeature: mockGetFaceFeature,
        insertFaceFeature: mockInsertFaceFeature,
        addFaceBySDKImage: mockAddFaceBySDKImage,
        deleteFaceFeature: mockDeleteFaceFeature,
      },
    },
    Platform: {
      OS: 'ios',
      select: (options: Record<string, string>) => options.ios ?? options.default,
    },
  }));

  return require('../src');
}

describe('react-native-face-sdk public API', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('reports the native module as available', () => {
    const {isFaceAIModuleAvailable} = loadSdk();

    expect(isFaceAIModuleAvailable()).toBe(true);
  });

  it('wraps faceVerify with defaults and normalizes the result', async () => {
    const {faceVerify} = loadSdk();

    mockFaceVerify.mockImplementation(
      (
        faceID,
        threshold,
        livenessType,
        motionTypes,
        timeout,
        steps,
        allowMultiFaces,
        callback,
      ) => {
        expect(faceID).toBe('user-001');
        expect(threshold).toBe(0.83);
        expect(livenessType).toBe(1);
        expect(motionTypes).toBe('1,2,3,4,5');
        expect(timeout).toBe(7);
        expect(steps).toBe(2);
        expect(allowMultiFaces).toBe(true);
        callback({code: 1, message: 'ok', faceID});
      },
    );

    const result = await faceVerify('user-001');

    expect(result).toEqual({
      code: 1,
      message: 'ok',
      faceID: 'user-001',
      similarity: 0,
      liveness: 0,
      faceFeature: '',
      faceBase64: '',
    });
  });

  it('passes custom params for livenessVerify', async () => {
    const {livenessVerify} = loadSdk();

    mockLivenessVerify.mockImplementation(
      (
        livenessType,
        motionTypes,
        timeout,
        steps,
        allowMultiFaces,
        callback,
      ) => {
        expect(livenessType).toBe(4);
        expect(motionTypes).toBe('3,5');
        expect(timeout).toBe(10);
        expect(steps).toBe(1);
        expect(allowMultiFaces).toBe(false);
        callback({code: 10, message: 'done', liveness: 0.98});
      },
    );

    const result = await livenessVerify({
      livenessType: 4,
      motionTypes: '3,5',
      timeout: 10,
      steps: 1,
      allowMultiFaces: false,
    });

    expect(result.liveness).toBe(0.98);
    expect(result.faceID).toBe('');
  });

  it('exposes the remaining CRUD style methods as promises', async () => {
    const {
      addFaceByImage,
      addFaceBySDKCamera,
      deleteFaceFeature,
      getFaceFeature,
      insertFaceFeature,
    } = loadSdk();

    mockAddFaceBySDKCamera.mockImplementation((faceID, mode, showConfirm, callback) => {
      expect(faceID).toBe('user-002');
      expect(mode).toBe(2);
      expect(showConfirm).toBe(false);
      callback({code: 1, message: 'added', faceID, faceFeature: 'abc'});
    });
    mockGetFaceFeature.mockImplementation((faceID, callback) => {
      callback({code: 1, message: 'feature', faceID, faceFeature: 'abc'});
    });
    mockInsertFaceFeature.mockImplementation((faceID, faceFeature, callback) => {
      callback({code: 1, message: `${faceID}:${faceFeature.length}`});
    });
    mockAddFaceBySDKImage.mockImplementation((faceID, base64Image, callback) => {
      callback({code: 0, message: base64Image, faceID});
    });
    mockDeleteFaceFeature.mockImplementation((faceID, callback) => {
      callback({code: 1, message: 'deleted', faceID});
    });

    await expect(
      addFaceBySDKCamera('user-002', {mode: 2, showConfirm: false}),
    ).resolves.toMatchObject({code: 1, faceFeature: 'abc'});
    await expect(getFaceFeature('user-002')).resolves.toMatchObject({
      faceFeature: 'abc',
    });
    await expect(insertFaceFeature('user-002', 'x'.repeat(1024))).resolves.toMatchObject({
      message: 'user-002:1024',
    });
    await expect(addFaceByImage('user-002', 'base64-demo')).resolves.toMatchObject({
      message: 'base64-demo',
    });
    await expect(deleteFaceFeature('user-002')).resolves.toMatchObject({
      message: 'deleted',
    });
  });
});
