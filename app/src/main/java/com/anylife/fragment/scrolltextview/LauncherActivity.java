package com.anylife.fragment.scrolltextview;

import android.content.Intent;
import android.os.Build;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import anylife.scrolltextview.ScrollTextView;

/**
 * 跑马灯设置
 *
 */
public class LauncherActivity extends AppCompatActivity {
    public static final String TEXT_INPUT_KEY = "textInput";
    public static final String SCROLL_SIZE_KEY = "scrollSize";
    public static final String SCROLL_SPEED_KEY = "scrollSpeed";
    public static final String TEXT_COLOR_KEY = "textColor";
    public static final String TEXT_BG_COLOR_KEY = "textBgColor";

    public static final int REQUEST_SETTING_CODE = 0x0001;
    
    private ScrollTextView scrollTextView;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        hideBottomUIMenu();
        setContentView(R.layout.activity_launcher);
        scrollTextView = findViewById(R.id.scrollText);

        findViewById(R.id.setting).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(LauncherActivity.this, SettingActivity.class);

                intent.putExtra(TEXT_INPUT_KEY, scrollTextView.getText());
                intent.putExtra(SCROLL_SIZE_KEY, scrollTextView.getTextSize());
                intent.putExtra(SCROLL_SPEED_KEY, scrollTextView.getSpeed());
                intent.putExtra(TEXT_COLOR_KEY, scrollTextView.getTextColor());
                intent.putExtra(TEXT_BG_COLOR_KEY, scrollTextView.getBackgroundColor());

                startActivityForResult(intent, REQUEST_SETTING_CODE);
            }
        });
        

    }



    /**
     * 隐藏虚拟按键，并且全屏
     */
    protected void hideBottomUIMenu() {
        //隐藏虚拟按键，并且全屏
        if (Build.VERSION.SDK_INT > 11 && Build.VERSION.SDK_INT < 19) {
            View v = this.getWindow().getDecorView();
            v.setSystemUiVisibility(View.GONE);
        } else if (Build.VERSION.SDK_INT >= 19) {
            //for new api versions.
            View decorView = getWindow().getDecorView();
            int uiOptions = View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY | View.SYSTEM_UI_FLAG_FULLSCREEN;
            decorView.setSystemUiVisibility(uiOptions);
        }
    }


    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putString(TEXT_INPUT_KEY, scrollTextView.getText());
        outState.putFloat(SCROLL_SIZE_KEY, scrollTextView.getTextSize());
        outState.putInt(SCROLL_SPEED_KEY, scrollTextView.getSpeed());
        outState.putInt(TEXT_COLOR_KEY, scrollTextView.getTextColor());
        outState.putInt(TEXT_BG_COLOR_KEY, scrollTextView.getBackgroundColor());
    }

    @Override
    protected void onRestoreInstanceState(Bundle savedInstanceState) {
        super.onRestoreInstanceState(savedInstanceState);

        scrollTextView.setText(savedInstanceState.getString(TEXT_INPUT_KEY));
        scrollTextView.setTextSize(savedInstanceState.getFloat(SCROLL_SIZE_KEY));
        scrollTextView.setSpeed(savedInstanceState.getInt(SCROLL_SPEED_KEY));
        scrollTextView.setTextColor(savedInstanceState.getInt(TEXT_COLOR_KEY));
        scrollTextView.setBackgroundColor(savedInstanceState.getInt(TEXT_BG_COLOR_KEY));
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        scrollTextView.setPauseScroll(false);  //防止设置了暂停影响演示

        if (requestCode == REQUEST_SETTING_CODE && resultCode == RESULT_OK) {
            int scrollSpeed = data.getIntExtra(SCROLL_SPEED_KEY, 0);
            if (0 != scrollSpeed) {
                scrollTextView.setSpeed(scrollSpeed);
            }

            float scrollSize = data.getFloatExtra(SCROLL_SIZE_KEY, 0f);
            if (0 != scrollSize) {
                scrollTextView.setTextSize(scrollSize);
            }

            int textColor = data.getIntExtra(TEXT_COLOR_KEY, 0);
            if (0 != textColor) {
                scrollTextView.setTextColor(textColor);
            }

            int textBgColor = data.getIntExtra(TEXT_BG_COLOR_KEY, 0);
            if (0 != textColor) {
                scrollTextView.setScrollTextBackgroundColor(textBgColor);
            }

            if (!TextUtils.isEmpty(data.getStringExtra(TEXT_INPUT_KEY))) {
                scrollTextView.setText(data.getStringExtra(TEXT_INPUT_KEY));
            }
        }
    }




}
