export type FaceResultCode =
  | -1
  | 0
  | 1
  | 2
  | 3
  | 4
  | 5
  | 6
  | 7
  | 8
  | 9
  | 10
  | 11
  | 12
  | 13;

export interface FaceResult {
  code: FaceResultCode | number;
  message: string;
  faceID: string;
  similarity: number;
  liveness: number;
  faceFeature: string;
  faceBase64: string;
}

export interface AddFaceBySDKCameraOptions {
  mode?: 1 | 2;
  showConfirm?: boolean;
}

export interface FaceVerifyOptions {
  threshold?: number;
  livenessType?: 1 | 2 | 3 | 4;
  motionTypes?: string;
  timeout?: number;
  steps?: number;
  allowMultiFaces?: boolean;
}

export interface LivenessVerifyOptions {
  livenessType?: 1 | 2 | 3 | 4;
  motionTypes?: string;
  timeout?: number;
  steps?: number;
  allowMultiFaces?: boolean;
}

export interface FaceNativeModule {
  addFaceBySDKCamera(
    faceID: string,
    mode: number,
    showConfirm: boolean,
    callback: (result: FaceResult) => void,
  ): void;
  faceVerify(
    faceID: string,
    threshold: number,
    livenessType: number,
    motionTypes: string,
    timeout: number,
    steps: number,
    allowMultiFaces: boolean,
    callback: (result: FaceResult) => void,
  ): void;
  livenessVerify(
    livenessType: number,
    motionTypes: string,
    timeout: number,
    steps: number,
    allowMultiFaces: boolean,
    callback: (result: FaceResult) => void,
  ): void;
  getFaceFeature(faceID: string, callback: (result: FaceResult) => void): void;
  insertFaceFeature(
    faceID: string,
    faceFeature: string,
    callback: (result: FaceResult) => void,
  ): void;
  addFaceBySDKImage(
    faceID: string,
    base64Image: string,
    callback: (result: FaceResult) => void,
  ): void;
  deleteFaceFeature(faceID: string, callback: (result: FaceResult) => void): void;
}
