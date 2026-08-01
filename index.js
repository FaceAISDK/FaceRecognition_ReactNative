/**
 * Silent liveness threshold (iOS/Android): 0.85–0.95. Actual performance varies with camera and lighting—adjust based on scenario.
 * iOS Android 静默活体通过阈值范围0.85到0.95，注意实际表现和摄像头&环境有关
 */

import {AppRegistry} from 'react-native';
import App from './App';
import {name as appName} from './app.json';

AppRegistry.registerComponent(appName, () => App);
