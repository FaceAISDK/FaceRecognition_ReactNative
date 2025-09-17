# About ScrollTextView

Class ScrollTextView extends SurfaceView implements SurfaceHolder.Callback

Android 滚动字幕，如新闻联播下面的，可以使用在广告机，滚动新闻信息，机场地铁等信息发布系统。
以前是在信息发布系统上使用过，作为动态布局的一部分，题外话，如果有想做像分众传媒或者类似的
电梯广告的可以参考一下.

You can use it in advisement player,TV news show or airport metro information public system App.

继承SurfaceView 实现，CPU 占用低，无内存抖动，以Nexus5X，Android 7.0 上测试流畅度很好，
大部分品牌手机测试兼容性良好。


# How to use

## Gradle 集成使用 (2.5.0 支持AndroidX，并且Target SDK=33)

```
 implementation 'io.github.anylifezlb:ScrollTextviewLib:2.5.0'
```

## 基础设置代码概要

```
    <anylife.scrolltextview.ScrollTextView
        android:id="@+id/textView2"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_alignParentRight="true"
        android:layout_toRightOf="@+id/imageView2"
        android:layout_marginRight="6dp"
        android:singleLine="true"
        customAttr:clickEnable="true"
        customAttr:isHorizontal="true"
        customAttr:speed="1"
        customAttr:text="ScrollTextView Auto Scroll.1234567890,"
        customAttr:text_size="14sp"
        customAttr:text_color="#ffffffff"
        customAttr:times="567" />
```

或者在代码中

```
    scrollText = findViewById(R.id.scrollText);
    scrollText.setSpeed(4);
    scrollText.setText("new text");
    scrollText.setTextColor(0xffad43ae);
```

# 关于提Issues

本库一直在持续维护中，但是能投入的时间不多，有issues 的同学说明一下以下内容

- 1.使用场景：         比如ViewPager+fragment 滑动切换出现XX和YY 问题
- 2.Android系统信息：    手机品牌或特殊设备描述，Android系统版本号等信息

.
## Any questions,please contact me at: anylife.zlb@gmail.com

视频看起来卡顿是录制调低了帧律以便快速上传和播放。


https://user-images.githubusercontent.com/15169396/208380192-b323699f-adc8-4116-8fbd-d90c83e91544.mp4


## 其他链接

经过2年的开发迭代，人脸识别SDK已经稳定并在多个项目上线 https://github.com/FaceAISDK/FaceAISDK_Android


![FaceAISDK](FaceAISDK.png)