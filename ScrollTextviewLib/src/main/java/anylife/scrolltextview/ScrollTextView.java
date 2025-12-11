package anylife.scrolltextview;

import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint.FontMetrics;
import android.graphics.PixelFormat;
import android.graphics.PorterDuff;
import android.os.Build;
import android.text.Layout;
import android.text.StaticLayout;
import android.text.TextPaint;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.util.Log;
import android.view.MotionEvent;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;

import androidx.annotation.ColorInt;

import java.util.ArrayList;
import java.util.List;

/**
 * Android 自动滚动字幕 (跑马灯/垂直轮播)
 * 性能优化版
 *
 * 改进点：
 * 1. 使用 StaticLayout 替代手动计算换行，大幅提升测量性能。
 * 2. 完善生命周期管理，防止后台运行耗电。
 * 3. 优化绘制循环与线程同步。
 *
 * @author FaceAISDK.Service@gmail.com
 */
public class ScrollTextView extends SurfaceView implements SurfaceHolder.Callback, Runnable {
    private static final String TAG = "ScrollTextView";

    // SurfaceHolder 用于控制 SurfaceView 的底层 Surface
    private SurfaceHolder surfaceHolder;
    private TextPaint paint; // 使用 TextPaint 提供更强的文字处理能力

    // 线程控制
    private Thread renderThread;
    private volatile boolean isRunning = false; // 线程运行标志
    private volatile boolean isPaused = false;  // 暂停标志
    private final Object pauseLock = new Object(); // 暂停锁

    // 配置参数
    private boolean clickEnable = false;
    private boolean isHorizontal = true;
    private float speed = 2f;
    private String text = "";
    private float textSize = 20f;
    private int textColor = Color.WHITE;
    // 滚动控制
    private int needScrollTimes = Integer.MAX_VALUE;
    private boolean isScrollForever = true;

    // 测量数据
    private int viewWidth = 0;
    private int viewHeight = 0;
    private float textWidth = 0f;
    private float textHeight = 0f;

    // 动态状态
    private float currentX = 0f;
    private float currentY = 0f;

    // 垂直滚动专用数据
    private final List<String> verticalLines = new ArrayList<>();
    private int currentLineIndex = 0;
    private float verticalCenterBaseline = 0f; // 垂直居中的基线Y坐标
    private long pauseStartTime = 0;
    private boolean isWaiting = false;
    private static final long WAIT_TIME_MS = 2000;

    public ScrollTextView(Context context) {
        this(context, null);
    }

    public ScrollTextView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init(context, attrs);
    }

    private void init(Context context, AttributeSet attrs) {
        surfaceHolder = this.getHolder();
        surfaceHolder.addCallback(this);

        paint = new TextPaint();
        paint.setAntiAlias(true);
        paint.setDither(true);

        if (attrs != null) {
            TypedArray arr = getContext().obtainStyledAttributes(attrs, R.styleable.ScrollTextView);
            clickEnable = arr.getBoolean(R.styleable.ScrollTextView_clickEnable, clickEnable);
            isHorizontal = arr.getBoolean(R.styleable.ScrollTextView_isHorizontal, isHorizontal);
            speed = arr.getFloat(R.styleable.ScrollTextView_speed, speed); // speed float更平滑
            text = arr.getString(R.styleable.ScrollTextView_text);
            textColor = arr.getColor(R.styleable.ScrollTextView_text_color, Color.BLACK);
            textSize = arr.getDimension(R.styleable.ScrollTextView_text_size, sp2px(context, 20));
            needScrollTimes = arr.getInteger(R.styleable.ScrollTextView_times, Integer.MAX_VALUE);
            isScrollForever = arr.getBoolean(R.styleable.ScrollTextView_isScrollForever, true);
            arr.recycle();
        }

        paint.setColor(textColor);
        paint.setTextSize(textSize);

        setZOrderOnTop(true);
        getHolder().setFormat(PixelFormat.TRANSLUCENT);
        setFocusable(true); // 响应点击事件

        if (text == null) text = "";
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
        viewWidth = MeasureSpec.getSize(widthMeasureSpec);
        int modeHeight = MeasureSpec.getMode(heightMeasureSpec);

        FontMetrics fm = paint.getFontMetrics();
        // 优化：文字高度计算，ceil防止显示不全
        textHeight = (float) Math.ceil(fm.descent - fm.ascent);

        if (modeHeight == MeasureSpec.AT_MOST || modeHeight == MeasureSpec.UNSPECIFIED) {
            viewHeight = (int) (textHeight + getPaddingTop() + getPaddingBottom());
            setMeasuredDimension(viewWidth, viewHeight);
        } else {
            viewHeight = MeasureSpec.getSize(heightMeasureSpec);
        }

        // 重新计算基线位置 (垂直居中)
        // 公式：centerY + (bottom - top)/2 - bottom
        verticalCenterBaseline = viewHeight / 2f - (fm.descent + fm.ascent) / 2f;

        remeasureText();
    }

    private void remeasureText() {
        if (viewWidth == 0 || TextUtils.isEmpty(text)) return;

        textWidth = paint.measureText(text);

        if (isHorizontal) {
            currentX = viewWidth;
            currentY = verticalCenterBaseline;
        } else {
            prepareVerticalLines();
            // 初始位置在 View 底部下方
            currentY = viewHeight + textHeight;
            currentLineIndex = 0;
            isWaiting = false;
        }
    }

    /**
     * 优化：使用 StaticLayout 进行高效分行
     */
    private void prepareVerticalLines() {
        verticalLines.clear();
        if (TextUtils.isEmpty(text)) return;

        // 构建 StaticLayout
        StaticLayout staticLayout;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            staticLayout = StaticLayout.Builder.obtain(text, 0, text.length(), paint, viewWidth)
                    .setAlignment(Layout.Alignment.ALIGN_NORMAL)
                    .setLineSpacing(0f, 1f)
                    .setIncludePad(false)
                    .build();
        } else {
            staticLayout = new StaticLayout(text, paint, viewWidth,
                    Layout.Alignment.ALIGN_NORMAL, 1.0f, 0.0f, false);
        }

        // 从 Layout 中提取每一行的文本
        for (int i = 0; i < staticLayout.getLineCount(); i++) {
            int start = staticLayout.getLineStart(i);
            int end = staticLayout.getLineEnd(i);
            // 去除末尾可能的换行符，防止绘制乱码
            String line = text.substring(start, end).trim();
            if (!TextUtils.isEmpty(line)) {
                verticalLines.add(line);
            }
        }
    }

    // --- Lifecycle Management ---

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        startThread();
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
        // onMeasure handle logic
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        stopThread();
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        stopThread(); // 确保 View 被移除时停止线程
    }

    @Override
    protected void onVisibilityChanged(View changedView, int visibility) {
        super.onVisibilityChanged(changedView, visibility);
        if (visibility == VISIBLE) {
            startThread();
        } else {
            stopThread();
        }
    }

    private synchronized void startThread() {
        if (isRunning) return;
        isRunning = true;
        renderThread = new Thread(this);
        renderThread.start();
        Log.d(TAG, "RenderThread Started");
    }

    private void stopThread() {
        if (!isRunning) return;
        isRunning = false;
        try {
            if (renderThread != null) {
                // 不建议 join，可能会卡 UI，interrupt 即可
                renderThread.interrupt();
                renderThread = null;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        Log.d(TAG, "RenderThread Stopped");
    }

    // --- Render Loop ---

    @Override
    public void run() {
        while (isRunning && !Thread.currentThread().isInterrupted()) {
            long startTime = System.currentTimeMillis();

            try {
                if (!isPaused && needScrollTimes > 0) {
                    updateLogic();
                    drawCanvas();
                } else {
                    // 暂停状态或次数用尽，依然绘制以保持画面，但降低刷新率
                    if (needScrollTimes <= 0 && isScrollForever) {
                        needScrollTimes = Integer.MAX_VALUE;
                    }
                    drawCanvas();
                    Thread.sleep(100); // 暂停时休眠更久，省电
                }

                long endTime = System.currentTimeMillis();
                long sleepTime = 16 - (endTime - startTime);

                if (sleepTime > 0) {
                    Thread.sleep(sleepTime);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt(); // 恢复中断状态
                break;
            } catch (Exception e) {
                Log.e(TAG, "Render Loop Error", e);
            }
        }
    }

    private void updateLogic() {
        if (isHorizontal) {
            currentX -= speed;
            // 优化：文字完全滚出左侧后才重置
            if (currentX < -textWidth) {
                currentX = viewWidth;
                if (!isScrollForever) {
                    needScrollTimes--;
                }
            }
        } else {
            if (verticalLines.isEmpty()) return;

            if (isWaiting) {
                if (System.currentTimeMillis() - pauseStartTime > WAIT_TIME_MS) {
                    isWaiting = false;
                }
                return;
            }

            currentY -= speed;

            // 垂直居中逻辑
            // 目标 Y 是基线位置
            float targetY = verticalCenterBaseline;

            // 判断是否到达中间位置 (使用区间判断防止跳过)
            if (currentY <= targetY && currentY + speed > targetY) {
                currentY = targetY;
                isWaiting = true;
                pauseStartTime = System.currentTimeMillis();
            }

            // 滚出顶部，准备下一行
            // 这里的判定阈值稍微大一点，确保文字完全消失
            if (currentY < -textHeight) {
                currentLineIndex++;
                if (currentLineIndex >= verticalLines.size()) {
                    currentLineIndex = 0;
                    if (!isScrollForever) {
                        needScrollTimes--;
                    }
                }
                // 重置到底部
                currentY = viewHeight + textHeight;
            }
        }
    }

    private void drawCanvas() {
        Canvas canvas = null;
        try {
            canvas = surfaceHolder.lockCanvas();
            if (canvas != null) {
                // 1. 清屏 (使用 CLEAR 模式处理透明背景)
                canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);



                // 2. 绘制文字
                if (isHorizontal) {
                    canvas.drawText(text, currentX, currentY, paint);
                } else {
                    if (!verticalLines.isEmpty() && currentLineIndex < verticalLines.size()) {
                        String line = verticalLines.get(currentLineIndex);
                        float textW = paint.measureText(line);
                        // 水平居中绘制
                        canvas.drawText(line, (viewWidth - textW) / 2f, currentY, paint);
                    }
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Draw Failed", e);
        } finally {
            if (canvas != null && surfaceHolder != null) {
                try {
                    surfaceHolder.unlockCanvasAndPost(canvas);
                } catch (Exception e) {
                    // Surface 丢失
                }
            }
        }
    }

    // --- Events ---

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        if (!clickEnable) return super.onTouchEvent(event);
        if (event.getAction() == MotionEvent.ACTION_DOWN) {
            isPaused = !isPaused;
            return true;
        }
        return super.onTouchEvent(event);
    }

    // --- Setters (触发重绘) ---

    public void setText(String newText) {
        this.text = newText == null ? "" : newText;
        remeasureText();
    }

    public void setTextColor(@ColorInt int color) {
        this.textColor = color;
        paint.setColor(color);
    }

    public void setTextSize(float spValue) {
        this.textSize = sp2px(getContext(), spValue);
        paint.setTextSize(textSize);
        requestLayout(); //触发 onMeasure
    }

    public void setSpeed(float speed) {
        this.speed = speed;
    }

    public void setScrollForever(boolean scrollForever) {
        isScrollForever = scrollForever;
    }

    public void setHorizontal(boolean horizontal) {
        this.isHorizontal = horizontal;
        requestLayout(); // 布局可能变化
        remeasureText();
    }


    public boolean isRunning() {
        return isRunning;
    }

    public boolean isPaused() {
        return isPaused;
    }

    public boolean isClickEnable() {
        return clickEnable;
    }

    public boolean isHorizontal() {
        return isHorizontal;
    }

    public float getSpeed() {
        return speed;
    }

    public String getText() {
        return text;
    }

    public float getTextSize() {
        return px2sp(getContext(),textSize);
    }

    public int getTextColor() {
        return textColor;
    }


    public int getNeedScrollTimes() {
        return needScrollTimes;
    }

    public boolean isScrollForever() {
        return isScrollForever;
    }

    public long getPauseStartTime() {
        return pauseStartTime;
    }

    public boolean isWaiting() {
        return isWaiting;
    }

    /**
     * 将可伸缩像素值 (sp)转为像素值 (px)。
     */
    private int sp2px(Context context, float spValue) {
        float fontScale = context.getResources().getDisplayMetrics().scaledDensity;
        return (int) (spValue * fontScale + 0.5f);
    }

    /**
     * 将像素值 (px) 转换为可伸缩像素值 (sp)。
     * 主要用于文本尺寸的转换。
     * @param context 当前应用的上下文。
     * @param pxValue 待转换的像素值。
     * @return 转换后的 sp 值。
     */
    private float px2sp(Context context, float pxValue) {
        // 获取系统的字形缩放比例 (Scaled Density)。
        // 这个比例考虑了用户在系统设置中调整的字体大小。
        float fontScale = context.getResources().getDisplayMetrics().scaledDensity;
        // 像素值除以字形缩放比例即得到 SP 值。
        return (pxValue / fontScale);
    }
}