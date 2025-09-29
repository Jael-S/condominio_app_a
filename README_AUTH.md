# Sistema de Autenticación - Condominio App

## Descripción
Sistema de autenticación completo para la aplicación móvil de condominio, conectado con el backend Django.

## Características Implementadas

### ✅ Autenticación
- Login con usuario y contraseña
- Logout seguro
- Persistencia de sesión
- Verificación de token
- Manejo de errores

### ✅ Navegación
- Splash screen con inicialización
- Redirección automática basada en autenticación
- Protección de rutas para residentes únicamente

### ✅ UI/UX
- Diseño moderno con Material 3
- Formularios validados
- Indicadores de carga
- Mensajes de error claros
- Tema personalizado

### ✅ Arquitectura
- Provider para manejo de estado
- Servicios separados para API y almacenamiento
- Modelos de datos tipados
- Configuración centralizada

## Estructura del Proyecto

```
lib/
├── config/
│   └── app_config.dart          # Configuración de la app
├── models/
│   └── user_model.dart          # Modelos de datos
├── services/
│   ├── api_service.dart         # Servicios de API
│   └── storage_service.dart     # Almacenamiento local
├── providers/
│   └── auth_provider.dart       # Estado de autenticación
├── features/
│   ├── auth/
│   │   └── pages/
│   │       └── login_page.dart  # Pantalla de login
│   ├── residente/
│   │   └── pages/
│   │       └── dashboard_residente.dart  # Dashboard principal
│   └── common/
│       └── splash_page.dart     # Pantalla de carga
├── widgets/
│   ├── custom_button.dart       # Botón personalizado
│   ├── custom_text_field.dart   # Campo de texto personalizado
│   └── loading_overlay.dart     # Overlay de carga
├── routes/
│   └── app_router.dart          # Configuración de rutas
└── main.dart                    # Punto de entrada
```

## Configuración

### Backend
1. Asegúrate de que el backend Django esté ejecutándose
2. La URL base está configurada en `lib/config/app_config.dart`
3. Por defecto: `http://192.168.0.23:8000/api`

### Flutter
1. Instala las dependencias:
   ```bash
   flutter pub get
   ```

2. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

## Endpoints del Backend

### Autenticación
- `POST /api/autenticacion/login/` - Login
- `POST /api/autenticacion/logout/` - Logout

### Respuesta del Login
```json
{
  "token": "string",
  "username": "string",
  "email": "string",
  "rol": "string",
  "user_id": "number",
  "residente_id": "number"
}
```

## Flujo de Autenticación

1. **Splash Screen**: Inicializa la app y verifica sesión existente
2. **Login**: Si no hay sesión, muestra pantalla de login
3. **Dashboard**: Si hay sesión válida de residente, muestra dashboard
4. **Logout**: Cierra sesión y limpia datos locales

## Restricciones

- Solo usuarios con rol "Residente" pueden acceder desde la app móvil
- Empleados y administradores deben usar el sistema web
- La sesión se mantiene hasta que el usuario haga logout o el token expire

## Próximos Pasos

1. Implementar funcionalidades del dashboard (comunicados, finanzas, etc.)
2. Agregar notificaciones push
3. Implementar recuperación de contraseña
4. Agregar biometría para login rápido

## Testing

Para probar la autenticación:

1. Crea un usuario residente en el backend Django
2. Ejecuta la app Flutter
3. Inicia sesión con las credenciales del residente
4. Verifica que puedas acceder al dashboard
5. Prueba el logout

## Troubleshooting

### Error de Conexión
- Verifica que el backend esté ejecutándose
- Confirma la URL en `app_config.dart`
- Revisa la configuración de CORS en Django

### Error de Autenticación
- Verifica que el usuario exista en la base de datos
- Confirma que el usuario tenga rol "Residente"
- Revisa los logs del backend para más detalles
