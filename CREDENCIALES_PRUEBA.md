# Credenciales de Prueba - Condominio App

## Backend
- **URL**: http://localhost:8000/api
- **Estado**: ✅ Funcionando correctamente

## Usuarios de Prueba

### 1. Administrador
- **Usuario**: `admin`
- **Contraseña**: `admin123`
- **Rol**: Administrador
- **Dashboard**: No disponible en app móvil (solo web)

### 2. Residente
- **Usuario**: `residente1`
- **Contraseña**: `admin123`
- **Rol**: Residente
- **Dashboard**: Portal Residente

### 3. Empleado
- **Usuario**: `empleado1`
- **Contraseña**: `admin123`
- **Rol**: Empleado
- **Dashboard**: Portal Empleado

### 4. Seguridad
- **Usuario**: `seguridad1`
- **Contraseña**: `admin123`
- **Rol**: Seguridad
- **Dashboard**: Portal Seguridad

## Instrucciones de Prueba

1. **Asegúrate de que el backend esté corriendo**:
   ```bash
   cd backend_condominio_a
   .\env\Scripts\Activate.ps1
   python manage.py runserver
   ```

2. **Ejecuta Flutter**:
   ```bash
   cd condominio_app
   flutter run -d [ID_DISPOSITIVO]
   ```

3. **Prueba el login** con cualquiera de las credenciales de arriba

4. **Verifica que cada rol** redirija al dashboard correspondiente

## Funcionalidades por Rol

### Residente
- Ver comunicados
- Gestionar reservas de áreas comunes
- Ver finanzas personales
- Historial de pagos

### Empleado
- Gestionar comunicados
- Ver reservas
- Gestionar mantenimiento
- Ver reportes

### Seguridad
- Control de acceso
- Registro de visitas
- Monitoreo de áreas comunes
- Reportes de seguridad

## Notas
- Todos los usuarios tienen la misma contraseña: `admin123`
- El backend está configurado para desarrollo (CORS habilitado)
- La app móvil solo permite acceso a residentes, empleados y seguridad
- Los administradores deben usar la interfaz web





