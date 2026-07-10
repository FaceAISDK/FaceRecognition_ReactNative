import {NativeModules, Platform} from 'react-native';

import type {
  AddFaceBySDKCameraOptions,
  FaceNativeModule,
  FaceResult,
  FaceVerifyOptions,
  LivenessVerifyOptions,
} from './types';

const MODULE_NAME = 'FaceRNModule';

const LINKING_ERROR =
  `The native module \`${MODULE_NAME}\` is not linked. Make sure that:\n\n` +
  Platform.select({
    ios: "- you ran 'pod install' in the iOS project\n",
    default: '',
  }) +
  '- you rebuilt the app after installing the package\n' +
  '- you are not running inside a plain Jest/Node environment without mocks';

const nativeModule = NativeModules[MODULE_NAME] as FaceNativeModule | undefined;

function getNativeModule(): FaceNativeModule {
  if (!nativeModule) {
    throw new Error(LINKING_ERROR);
  }

  return nativeModule;
}

type LegacyFaceResult = Partial<FaceResult> & {
  msg?: string;
};

function normalizeResult(result: LegacyFaceResult | undefined): FaceResult {
  return {
    code: result?.code ?? 0,
    message: result?.message ?? result?.msg ?? '',
    faceID: result?.faceID ?? '',
    similarity: result?.similarity ?? 0,
    liveness: result?.liveness ?? 0,
    faceFeature: result?.faceFeature ?? '',
    faceBase64: result?.faceBase64 ?? '',
  };
}

function invokeWithPromise(
  call: (callback: (result: FaceResult) => void) => void,
): Promise<FaceResult> {
  return new Promise(resolve => {
    call(result => resolve(normalizeResult(result)));
  });
}

export function isFaceAIModuleAvailable(): boolean {
  return Boolean(nativeModule);
}

export function addFaceBySDKCamera(
  faceID: string,
  options: AddFaceBySDKCameraOptions = {},
): Promise<FaceResult> {
  const {mode = 1, showConfirm = true} = options;

  return invokeWithPromise(callback => {
    getNativeModule().addFaceBySDKCamera(faceID, mode, showConfirm, callback);
  });
}

export function faceVerify(
  faceID: string,
  options: FaceVerifyOptions = {},
): Promise<FaceResult> {
  const {
    threshold = 0.83,
    livenessType = 1,
    motionTypes = '1,2,3,4,5',
    timeout = 7,
    steps = 2,
    allowMultiFaces = true,
  } = options;

  return invokeWithPromise(callback => {
    getNativeModule().faceVerify(
      faceID,
      threshold,
      livenessType,
      motionTypes,
      timeout,
      steps,
      allowMultiFaces,
      callback,
    );
  });
}

export function livenessVerify(
  options: LivenessVerifyOptions = {},
): Promise<FaceResult> {
  const {
    livenessType = 2,
    motionTypes = '1,2,3,4,5',
    timeout = 7,
    steps = 2,
    allowMultiFaces = true,
  } = options;

  return invokeWithPromise(callback => {
    getNativeModule().livenessVerify(
      livenessType,
      motionTypes,
      timeout,
      steps,
      allowMultiFaces,
      callback,
    );
  });
}

export function getFaceFeature(faceID: string): Promise<FaceResult> {
  return invokeWithPromise(callback => {
    getNativeModule().getFaceFeature(faceID, callback);
  });
}

export function insertFaceFeature(
  faceID: string,
  faceFeature: string,
): Promise<FaceResult> {
  return invokeWithPromise(callback => {
    getNativeModule().insertFaceFeature(faceID, faceFeature, callback);
  });
}

export function addFaceByImage(
  faceID: string,
  base64Image: string,
): Promise<FaceResult> {
  return invokeWithPromise(callback => {
    getNativeModule().addFaceBySDKImage(faceID, base64Image, callback);
  });
}

export function deleteFaceFeature(faceID: string): Promise<FaceResult> {
  return invokeWithPromise(callback => {
    getNativeModule().deleteFaceFeature(faceID, callback);
  });
}

export type {
  AddFaceBySDKCameraOptions,
  FaceResult,
  FaceVerifyOptions,
  LivenessVerifyOptions,
} from './types';

export default {
  addFaceBySDKCamera,
  faceVerify,
  livenessVerify,
  getFaceFeature,
  insertFaceFeature,
  addFaceByImage,
  deleteFaceFeature,
  isFaceAIModuleAvailable,
};
