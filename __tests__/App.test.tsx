/**
 * @format
 */

import 'react-native';
import React from 'react';
import App, {normalizeFaceResult, resolveLanguage} from '../App';

// Note: import explicitly to use the types shipped with jest.
import {expect, it} from '@jest/globals';

// Note: test renderer must be required after react-native.
import renderer, {act} from 'react-test-renderer';

it('renders correctly', async () => {
  await act(async () => {
    renderer.create(<App />);
  });
});

it('uses Chinese only for Chinese system locales', () => {
  expect(resolveLanguage('zh-Hans-CN')).toBe('zh');
  expect(resolveLanguage('zh_TW')).toBe('zh');
  expect(resolveLanguage('ja-JP')).toBe('en');
  expect(resolveLanguage(undefined)).toBe('en');
});

it('normalizes native object results', () => {
  expect(
    normalizeFaceResult({
      code: '1',
      message: 'success',
      faceId: 'user001',
      score: '0.91',
      livenessScore: 0.88,
      feature: 'feature-value',
      imageBase64: 'base64-value',
    }),
  ).toEqual({
    code: 1,
    msg: 'success',
    faceID: 'user001',
    similarity: 0.91,
    liveness: 0.88,
    faceFeature: 'feature-value',
    faceBase64: 'base64-value',
  });
});

it('normalizes JSON string and nested results', () => {
  expect(
    normalizeFaceResult(
      JSON.stringify({
        data: {
          resultCode: 10,
          msg: 'liveness passed',
          faceID: 'user001',
          similarity: 0.93,
        },
      }),
    ),
  ).toMatchObject({
    code: 10,
    msg: 'liveness passed',
    faceID: 'user001',
    similarity: 0.93,
  });
});
