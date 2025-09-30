class NetworkConfig {
  // Configuraciones de red disponibles
  static const Map<String, String> networkConfigs = {
    // Reemplaza 192.168.0.15 con la IP local de tu PC en la misma red Wi‑Fi
    'local_ip': 'http://192.168.0.15:8000/api',
    'localhost': 'http://localhost:8000/api',
    'localhost_ip': 'http://127.0.0.1:8000/api',
    'android_emulator': 'http://10.0.2.2:8000/api', // Para emulador Android
    // 'railway': 'https://tu-proyecto.up.railway.app/api', // Producción en Railway (descomenta al desplegar)
    'test_server': 'https://jsonplaceholder.typicode.com', // Servidor de prueba
  };
  
  // Configuración actual (cambia esta para probar diferentes URLs)
  static const String currentConfig = 'local_ip';
  
  // URL base actual
  static String get baseUrl => networkConfigs[currentConfig] ?? networkConfigs['localhost']!;
  
  // Método para cambiar la configuración de red
  static String getUrlForConfig(String config) {
    return networkConfigs[config] ?? networkConfigs['localhost']!;
  }
  
  // Lista de configuraciones disponibles
  static List<String> get availableConfigs => networkConfigs.keys.toList();
}
