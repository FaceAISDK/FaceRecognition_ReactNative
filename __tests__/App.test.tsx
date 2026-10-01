import React from 'react';
import renderer, {act} from 'react-test-renderer';
import {Alert} from 'react-native';
import {afterEach, beforeEach, expect, it, jest} from '@jest/globals';
import {
  addFaceByImage,
  getFaceFeature,
  insertFaceFeature,
  isFaceAIModuleAvailable,
} from '@faceaisdk/react-native-face-sdk';

import App, {resolveLanguage} from '../App';

jest.mock('@faceaisdk/react-native-face-sdk');

beforeEach(() => {
  jest.mocked(isFaceAIModuleAvailable).mockReturnValue(true);
});

afterEach(() => {
  jest.clearAllMocks();
  jest.restoreAllMocks();
});

async function renderDemo() {
  let tree: renderer.ReactTestRenderer;
  await act(async () => {
    tree = renderer.create(<App />);
  });
  return tree!;
}

function menuButtons(tree: renderer.ReactTestRenderer) {
  return tree.root.findAll(
    node =>
      node.props.accessibilityRole === 'button' &&
      typeof node.props.onPress === 'function',
  );
}

it('renders the Base64 face enrollment menu', async () => {
  const tree = await renderDemo();
  expect(JSON.stringify(tree.toJSON())).toMatch(
    /"Base64图片录入人脸"|"Enroll face from Base64 image"/,
  );
});

it.each([
  {name: 'feature', index: 4},
  {name: 'Base64 image', index: 5},
])('blocks an unconfigured $name import', async ({index}) => {
  const alert = jest.spyOn(Alert, 'alert').mockImplementation(() => {});
  const tree = await renderDemo();
  const button = menuButtons(tree)[index];
  expect(button.props.disabled).toBe(false);

  await act(async () => {
    await button.props.onPress();
  });

  expect(alert).toHaveBeenCalledWith(
    expect.any(String),
    expect.stringContaining('App.tsx'),
  );
  expect(insertFaceFeature).not.toHaveBeenCalled();
  expect(addFaceByImage).not.toHaveBeenCalled();
});

it('still queries the enrolled face', async () => {
  jest.mocked(getFaceFeature).mockResolvedValue({
    code: 1,
    message: 'Face feature exists',
    faceID: 'demo-user',
    similarity: 0,
    liveness: 0,
    faceFeature: 'feature',
    faceBase64: '',
  });
  const alert = jest.spyOn(Alert, 'alert').mockImplementation(() => {});
  const tree = await renderDemo();
  await act(async () => {
    await menuButtons(tree)[3].props.onPress();
  });

  expect(getFaceFeature).toHaveBeenCalledWith('demo-user');
  expect(alert).toHaveBeenCalledWith(
    expect.any(String),
    expect.stringContaining('code: 1'),
  );
});

it('uses Chinese for simplified and traditional Chinese locales', () => {
  expect(resolveLanguage('zh-Hans-CN')).toBe('zh');
  expect(resolveLanguage('zh-Hant-TW')).toBe('zh');
  expect(resolveLanguage('zh_HK')).toBe('zh');
  expect(resolveLanguage('en-US')).toBe('en');
  expect(resolveLanguage(undefined)).toBe('en');
});
