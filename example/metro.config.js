const path = require('path');
const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');

const projectRoot = __dirname;
const workspaceRoot = path.resolve(__dirname, '..');
const useLocalSdk = process.env.FACE_SDK_USE_LOCAL !== '0';

/**
 * Metro configuration
 * https://reactnative.dev/docs/metro
 *
 * @type {import('@react-native/metro-config').MetroConfig}
 */
const config = {
  watchFolders: [workspaceRoot],
  resolver: {
	...(useLocalSdk
	  ? {
		  extraNodeModules: {
			'@faceaisdk/react-native-face-sdk': workspaceRoot,
		  },
		}
	  : {}),
	nodeModulesPaths: [
	  path.resolve(projectRoot, 'node_modules'),
	  path.resolve(workspaceRoot, 'node_modules'),
	],
  },
};

module.exports = mergeConfig(getDefaultConfig(projectRoot), config);
