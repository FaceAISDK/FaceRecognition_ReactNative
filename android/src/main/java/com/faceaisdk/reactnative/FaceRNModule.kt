package com.faceaisdk.reactnative

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.Manifest
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.facebook.react.modules.core.PermissionAwareActivity
import com.facebook.react.modules.core.PermissionListener
import com.faceAI.demo.FaceSDKConfig
import com.faceAI.demo.SysCamera.addFace.AddFaceFeatureActivity
import com.faceAI.demo.SysCamera.verify.FaceVerificationActivity
import com.faceAI.demo.SysCamera.verify.LivenessDetectActivity
import com.faceAI.demo.base.utils.BitmapUtils
import com.ai.face.faceSearch.search.Image2FaceFeature
import android.graphics.Bitmap
import android.text.TextUtils
import com.tencent.mmkv.MMKV

class FaceRNModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext), ActivityEventListener {

    companion object {
        const val NAME = "FaceRNModule"
        private const val REQ_CODE_ADD_FACE = 10086
        private const val REQ_CODE_VERIFY = 10087
        private const val REQ_CODE_LIVENESS = 10088
        private const val PERMISSION_REQUEST_CODE = 10010
    }

    private var mCallback: Callback? = null
    private var mCurrentFaceID: String = ""
    private var mPendingAction: (() -> Unit)? = null

    init {
        reactContext.addActivityEventListener(this)
    }

    override fun getName(): String = NAME

    /**
     * 检查并请求相机权限
     */
    private fun checkCameraPermission(action: () -> Unit) {
        val activity = reactApplicationContext.currentActivity ?: return
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA)
            == PackageManager.PERMISSION_GRANTED
        ) {
            action()
        } else {
            mPendingAction = action
            val permissionAwareActivity = activity as? PermissionAwareActivity
            permissionAwareActivity?.requestPermissions(
                arrayOf(Manifest.permission.CAMERA),
                PERMISSION_REQUEST_CODE,
                object : PermissionListener {
                    override fun onRequestPermissionsResult(
                        requestCode: Int,
                        permissions: Array<String>,
                        grantResults: IntArray
                    ): Boolean {
                        if (requestCode == PERMISSION_REQUEST_CODE) {
                            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                                mPendingAction?.invoke()
                            } else {
                                mCallback?.invoke(Arguments.createMap().apply {
                                    putInt("code", -1)
                                    putString("message", "相机权限被拒绝，请在设置中开启")
                                    putString("faceID", mCurrentFaceID)
                                })
                                mCallback = null
                            }
                            mPendingAction = null
                            return true
                        }
                        return false
                    }
                }
            )
        }
    }

    /**
     * 1. SDK相机录入人脸信息
     */
    @ReactMethod
    fun addFaceBySDKCamera(
        faceID: String,
        addFacePerformanceMode: Int,
        needShowConfirmDialog: Boolean,
        callback: Callback
    ) {
        val activity = reactApplicationContext.currentActivity ?: return
        mCallback = callback
        mCurrentFaceID = faceID

        checkCameraPermission {
            FaceSDKConfig.init(activity)
            val intent = Intent()
            intent.setClassName(
                activity,
                "com.faceAI.demo.SysCamera.addFace.AddFaceFeatureActivity"
            )
            intent.putExtra("ADD_FACE_IMAGE_TYPE_KEY", "FACE_VERIFY")
            intent.putExtra("USER_FACE_ID_KEY", faceID)
            intent.putExtra("NEED_CONFIRM_ADD_FACE", needShowConfirmDialog)
            intent.putExtra("ADD_FACE_PERFORMANCE_MODE", addFacePerformanceMode)
            activity.startActivityForResult(intent, REQ_CODE_ADD_FACE)
        }
    }

    /**
     * 2. 人脸识别+活体检测
     */
    @ReactMethod
    fun faceVerify(
        faceID: String,
        threshold: Double,
        faceLivenessType: Int,
        motionLivenessTypes: String,
        motionLivenessTimeOut: Int,
        motionLivenessSteps: Int,
        allowMultiFaces: Boolean,
        callback: Callback
    ) {
        val activity = reactApplicationContext.currentActivity ?: return
        mCallback = callback
        mCurrentFaceID = faceID

        checkCameraPermission {
            FaceSDKConfig.init(activity)
            val intent = Intent()
            intent.setClassName(
                activity,
                "com.faceAI.demo.SysCamera.verify.FaceVerificationActivity"
            )
            intent.putExtra(FaceVerificationActivity.USER_FACE_ID_KEY, faceID)
            intent.putExtra(FaceVerificationActivity.THRESHOLD_KEY, threshold.toFloat())
            intent.putExtra(FaceVerificationActivity.FACE_LIVENESS_TYPE, faceLivenessType)
            intent.putExtra(FaceVerificationActivity.MOTION_LIVENESS_TYPES, motionLivenessTypes)
            intent.putExtra(FaceVerificationActivity.MOTION_TIMEOUT, motionLivenessTimeOut)
            intent.putExtra(FaceVerificationActivity.MOTION_STEP_SIZE, motionLivenessSteps)
            intent.putExtra(FaceVerificationActivity.ALLOW_MULTI_FACES, allowMultiFaces)
            activity.startActivityForResult(intent, REQ_CODE_VERIFY)
        }
    }

    /**
     * 3. 活体检测
     */
    @ReactMethod
    fun livenessVerify(
        faceLivenessType: Int,
        motionLivenessTypes: String,
        motionLivenessTimeOut: Int,
        motionLivenessSteps: Int,
        allowMultiFaces: Boolean,
        callback: Callback
    ) {
        val activity = reactApplicationContext.currentActivity ?: return
        mCallback = callback
        mCurrentFaceID = ""

        checkCameraPermission {
            FaceSDKConfig.init(activity)
            val intent = Intent()
            intent.setClassName(
                activity,
                "com.faceAI.demo.SysCamera.verify.LivenessDetectActivity"
            )
            intent.putExtra(LivenessDetectActivity.FACE_LIVENESS_TYPE, faceLivenessType)
            intent.putExtra(LivenessDetectActivity.MOTION_LIVENESS_TYPES, motionLivenessTypes)
            intent.putExtra(LivenessDetectActivity.MOTION_TIMEOUT, motionLivenessTimeOut)
            intent.putExtra(LivenessDetectActivity.MOTION_STEP_SIZE, motionLivenessSteps)
            intent.putExtra(LivenessDetectActivity.ALLOW_MULTI_FACES, allowMultiFaces)
            activity.startActivityForResult(intent, REQ_CODE_LIVENESS)
        }
    }

    /**
     * 4. 查询人脸特征信息
     */
    @ReactMethod
    fun getFaceFeature(faceID: String, callback: Callback) {
        val context = reactApplicationContext.applicationContext
        FaceSDKConfig.init(context)

        val faceFeature = MMKV.defaultMMKV().decodeString(faceID)
        val result = Arguments.createMap()

        if (faceFeature.isNullOrEmpty()) {
            result.putInt("code", 0)
            result.putString("message", "Face Feature not exist")
            result.putString("faceFeature", "")
        } else if (faceFeature.length != 1024) {
            result.putInt("code", 0)
            result.putString("message", "Face Feature length should be 1024")
            result.putString("faceFeature", "")
        } else {
            result.putInt("code", 1)
            result.putString("message", "Face Feature exist")
            result.putString("faceFeature", faceFeature)
        }

        result.putString("faceID", faceID)
        result.putDouble("similarity", 0.0)
        result.putDouble("liveness", 0.0)
        result.putString("faceBase64", "")
        callback.invoke(result)
    }

    /**
     * 5. 同步人脸特征信息
     */
    @ReactMethod
    fun insertFaceFeature(faceID: String, faceFeature: String, callback: Callback) {
        val context = reactApplicationContext.applicationContext
        FaceSDKConfig.init(context)

        val result = Arguments.createMap()

        if (TextUtils.isEmpty(faceFeature)) {
            result.putInt("code", 0)
            result.putString("message", "Face Feature not exist")
        } else if (faceFeature.length != 1024) {
            result.putInt("code", 0)
            result.putString("message", "Face Feature length should be 1024")
        } else {
            MMKV.defaultMMKV().encode(faceID, faceFeature)
            result.putInt("code", 1)
            result.putString("message", "insert Face success")
        }

        result.putString("faceID", faceID)
        result.putDouble("similarity", 0.0)
        result.putDouble("liveness", 0.0)
        result.putString("faceFeature", "")
        result.putString("faceBase64", "")
        callback.invoke(result)
    }

    /**
     * 6. 通过图片录入人脸信息
     */
    @ReactMethod
    fun addFaceBySDKImage(faceID: String, base64FaceImage: String, callback: Callback) {
        val activity = reactApplicationContext.currentActivity ?: return
        FaceSDKConfig.init(activity)

        Image2FaceFeature.getInstance(activity)
            .getFaceFeatureByBase64(base64FaceImage, faceID, object : Image2FaceFeature.Callback {
                override fun onFailed(msg: String) {
                    val result = Arguments.createMap()
                    result.putInt("code", 0)
                    result.putString("message", msg)
                    result.putString("faceID", faceID)
                    result.putDouble("similarity", 0.0)
                    result.putDouble("liveness", 0.0)
                    result.putString("faceFeature", "")
                    result.putString("faceBase64", "")
                    callback.invoke(result)
                }

                override fun onSuccess(bitmap: Bitmap, returnFaceID: String, faceFeature: String) {
                    com.ai.face.core.engine.FaceAISDKEngine.getInstance(activity)
                        .saveCroppedFaceImage(bitmap, FaceSDKConfig.CACHE_BASE_FACE_DIR, faceID)
                    MMKV.defaultMMKV().encode(faceID, faceFeature)

                    val result = Arguments.createMap()
                    result.putInt("code", 1)
                    result.putString("message", "getFaceFeature Success")
                    result.putString("faceID", faceID)
                    result.putDouble("similarity", 0.0)
                    result.putDouble("liveness", 0.0)
                    result.putString("faceFeature", faceFeature)
                    result.putString("faceBase64", "")
                    callback.invoke(result)
                }
            })
    }

    /**
     * 7. 删除人脸特征信息
     */
    @ReactMethod
    fun deleteFaceFeature(faceID: String, callback: Callback) {
        val context = reactApplicationContext.applicationContext
        FaceSDKConfig.init(context)

        MMKV.defaultMMKV().removeValueForKey(faceID)
        Image2FaceFeature.getInstance(context)
            .deleteFaceImage(FaceSDKConfig.CACHE_BASE_FACE_DIR + faceID)

        val result = Arguments.createMap()
        result.putInt("code", 1)
        result.putString("message", "Delete Success")
        result.putString("faceID", faceID)
        result.putDouble("similarity", 0.0)
        result.putDouble("liveness", 0.0)
        result.putString("faceFeature", "")
        result.putString("faceBase64", "")
        callback.invoke(result)
    }

    override fun onActivityResult(
        activity: Activity,
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        if (mCallback == null) return
        if (requestCode != REQ_CODE_ADD_FACE && requestCode != REQ_CODE_VERIFY && requestCode != REQ_CODE_LIVENESS) {
            return
        }

        val result = Arguments.createMap()
        result.putString("faceID", mCurrentFaceID)
        result.putDouble("similarity", 0.0)
        result.putDouble("liveness", 0.0)
        result.putString("faceFeature", "")
        result.putString("faceBase64", "")

        if (data != null) {
            result.putInt("code", data.getIntExtra("code", 0))
            result.putString("message", data.getStringExtra("message"))

            when (requestCode) {
                REQ_CODE_ADD_FACE -> {
                    result.putString("faceFeature", data.getStringExtra("faceFeature") ?: "")
                    if (data.getIntExtra("code", 0) != 0) {
                        val base64 = BitmapUtils.bitmapToBase64(
                            FaceSDKConfig.CACHE_BASE_FACE_DIR + mCurrentFaceID
                        )
                        result.putString("faceBase64", base64 ?: "")
                    }
                }
                REQ_CODE_VERIFY -> {
                    result.putDouble(
                        "similarity",
                        data.getFloatExtra("similarity", 0f).toDouble()
                    )
                    result.putDouble(
                        "liveness",
                        data.getFloatExtra("livenessValue", 0f).toDouble()
                    )
                    if (data.getIntExtra("code", 0) == 1) {
                        val base64 = BitmapUtils.bitmapToBase64(
                            FaceSDKConfig.CACHE_FACE_LOG_DIR + "verifyBitmap"
                        )
                        result.putString("faceBase64", base64 ?: "")
                    }
                }
                REQ_CODE_LIVENESS -> {
                    result.putDouble(
                        "liveness",
                        data.getFloatExtra("livenessValue", 0f).toDouble()
                    )
                    if (data.getIntExtra("code", 0) == 10) {
                        val base64 = BitmapUtils.bitmapToBase64(
                            FaceSDKConfig.CACHE_FACE_LOG_DIR + "liveBitmap"
                        )
                        result.putString("faceBase64", base64 ?: "")
                    }
                }
            }
        }

        mCallback?.invoke(result)
        mCallback = null
        mCurrentFaceID = ""
    }

    override fun onNewIntent(intent: Intent) {}
}
