package com.anylife.fragment.scrolltextview;

import android.content.Intent;
import android.os.Build;
import androidx.appcompat.app.AppCompatActivity;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.PopupWindow;
import android.widget.SeekBar;
import android.widget.TextView;
import com.larswerkman.holocolorpicker.ColorPicker;
import anylife.scrolltextview.ScrollTextView;
import static com.anylife.fragment.scrolltextview.LauncherActivity.SCROLL_SIZE_KEY;
import static com.anylife.fragment.scrolltextview.LauncherActivity.SCROLL_SPEED_KEY;
import static com.anylife.fragment.scrolltextview.LauncherActivity.TEXT_BG_COLOR_KEY;
import static com.anylife.fragment.scrolltextview.LauncherActivity.TEXT_COLOR_KEY;
import static com.anylife.fragment.scrolltextview.LauncherActivity.TEXT_INPUT_KEY;

/**
 * 设置页面 Settings
 *
 */
public class SettingActivity extends AppCompatActivity {
    private ImageView closeBtn;
    private ScrollTextView scrollTextView;

    private int textColor, textBgColor;

    private int scrollSpeed = 5;
    private float scrollSize = 20f;
    private EditText editText;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        hideBottomUIMenu();
        setContentView(R.layout.activity_setting);
        scrollTextView = findViewById(R.id.scrollText);
        closeBtn = findViewById(R.id.close);
        editText = findViewById(R.id.text_input);

        scrollTextView.setTextSize(getIntent().getFloatExtra(SCROLL_SIZE_KEY, scrollSize));
        scrollTextView.setSpeed(getIntent().getIntExtra(SCROLL_SPEED_KEY, scrollSpeed));
        scrollTextView.setTextColor(getIntent().getIntExtra(TEXT_COLOR_KEY, 0));
        scrollTextView.setScrollTextBackgroundColor(getIntent().getIntExtra(TEXT_BG_COLOR_KEY, 0));

        if (!TextUtils.isEmpty(getIntent().getStringExtra(TEXT_INPUT_KEY))) {
            scrollTextView.setText(getIntent().getStringExtra(TEXT_INPUT_KEY));
            editText.setText(getIntent().getStringExtra(TEXT_INPUT_KEY));
        }

        closeBtn.setOnClickListener(v -> {
            Intent intent = new Intent();
            intent.putExtra(TEXT_INPUT_KEY, editText.getText().toString());
            intent.putExtra(SCROLL_SIZE_KEY, scrollTextView.getTextSize());
            intent.putExtra(SCROLL_SPEED_KEY, scrollSpeed);
            intent.putExtra(TEXT_COLOR_KEY, textColor);
            intent.putExtra(TEXT_BG_COLOR_KEY, textBgColor);
            setResult(RESULT_OK, intent);
            finish();
        });

        TextView textColorView = findViewById(R.id.text_color);
        textColorView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                selectColor(true);
            }
        });

        TextView textBgView = findViewById(R.id.bg_color);
        textBgView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                selectColor(false);
            }
        });

        SeekBar textSizeSeekBar = findViewById(R.id.text_size_seek_bar);
        textSizeSeekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                scrollTextView.setTextSize(progress);
                scrollSize = progress;
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
            }
        });

        SeekBar textSpeedSeekBar = findViewById(R.id.text_speed_seek_bar);
        textSpeedSeekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                scrollTextView.setSpeed(progress);
                scrollSpeed = progress;
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
            }
        });
    }

    PopupWindow mPopWindow;

    private void selectColor(final boolean isSetTextColor) {
        View contentView = LayoutInflater.from(SettingActivity.this).inflate(R.layout.color_pop_win, null);
        mPopWindow = new PopupWindow(contentView,
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT, true);

        //显示PopupWindow
        View rootView = LayoutInflater.from(SettingActivity.this).inflate(R.layout.activity_setting, null);
        mPopWindow.showAtLocation(rootView, Gravity.CENTER, 0, 0);

        final ColorPicker picker = contentView.findViewById(R.id.picker);
        Button confirm = contentView.findViewById(R.id.confirm);

        //To get the color
        picker.getColor();
        picker.setOldCenterColor(picker.getColor());

        picker.setOnColorChangedListener(new ColorPicker.OnColorChangedListener() {
            @Override
            public void onColorChanged(int color) {
                if (isSetTextColor) {
                    scrollTextView.setTextColor(picker.getColor());
                    textColor = picker.getColor();
                } else {
                    textBgColor = picker.getColor();
                    scrollTextView.setScrollTextBackgroundColor(textBgColor);
                }
            }
        });
        picker.setShowOldCenterColor(false);
        confirm.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mPopWindow.dismiss();
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


}
