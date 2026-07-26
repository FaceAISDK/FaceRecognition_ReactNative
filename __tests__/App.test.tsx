import React from 'react';
import renderer, {act} from 'react-test-renderer';
import {expect, it} from '@jest/globals';

import App, {resolveLanguage} from '../App';

it('renders the SDK demo', async () => {
  await act(async () => {
    renderer.create(<App />);
  });
});

it('uses Chinese for simplified and traditional Chinese locales', () => {
  expect(resolveLanguage('zh-Hans-CN')).toBe('zh');
  expect(resolveLanguage('zh-Hant-TW')).toBe('zh');
  expect(resolveLanguage('zh_HK')).toBe('zh');
  expect(resolveLanguage('en-US')).toBe('en');
  expect(resolveLanguage(undefined)).toBe('en');
});
