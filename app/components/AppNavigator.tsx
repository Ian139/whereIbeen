import { createStackNavigator } from '@react-navigation/stack';
import Index from '../index';
import DefaultMap from '../(tabs)/DefaultMap';

const Stack = createStackNavigator();

export default function AppNavigator() {
  return (
    <Stack.Navigator>
      <Stack.Screen name="Home" component={Index} />
      <Stack.Screen name="Map" component={ExamplePage} />
    </Stack.Navigator>
  );
}
