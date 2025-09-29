# Sistema de Reservas de Áreas Comunes - Flutter App

## 📱 Funcionalidades Implementadas

### CU10: Gestión y reserva de áreas comunes (desde móvil, opción de reservar rápido)

El sistema permite a los residentes:

1. **Acceder al módulo de áreas comunes** - Desde el dashboard principal
2. **Consultar disponibilidad del área deseada** - Ver horarios disponibles por fecha
3. **Seleccionar fecha y hora de la reserva** - Formulario intuitivo con validaciones
4. **Registrar la reserva y confirmar** - Creación y gestión de reservas
5. **Realizar pago correspondiente (si aplica)** - Campo de costo opcional
6. **El sistema confirma y registra la reserva en el calendario de áreas comunes** - Integración con eventos

## 🏗️ Arquitectura Implementada

### Backend (Django REST Framework)
- **Modelos**: `AreaComun`, `Reserva` con campos completos
- **API Endpoints**:
  - `GET /api/mantenimiento/areas-comunes/` - Listar áreas
  - `GET /api/mantenimiento/reservas/` - Listar reservas del usuario
  - `POST /api/mantenimiento/reservas/` - Crear nueva reserva
  - `GET /api/mantenimiento/reservas/disponibilidad/` - Verificar disponibilidad
  - `GET /api/mantenimiento/reservas/horarios_disponibles/` - Obtener horarios libres
  - `POST /api/mantenimiento/reservas/{id}/confirmar/` - Confirmar reserva
  - `POST /api/mantenimiento/reservas/{id}/cancelar/` - Cancelar reserva

### Frontend (Flutter)
- **Modelos**: `AreaComun`, `Reserva`, `HorarioDisponible`
- **Servicios**: `ReservasService` para comunicación con API
- **Pantallas**:
  - `ReservasPage` - Pantalla principal con tabs
  - `NuevaReservaPage` - Formulario de nueva reserva
  - `DisponibilidadPage` - Consulta de horarios disponibles

## 🚀 Cómo Probar

### 1. Preparar el Backend
```bash
cd backend_condominio_a
python manage.py runserver
```

### 2. Ejecutar la App Flutter
```bash
cd condominio_app
flutter run
```

### 3. Probar con Script Automatizado
```bash
cd condominio_app
python test_reservas.py
```

## 📱 Flujo de Usuario

### Para Residentes:

1. **Iniciar sesión** como residente
2. **Acceder al dashboard** - Ver opciones disponibles
3. **Tocar "Reservas"** - Ir a la pantalla de reservas
4. **Explorar áreas disponibles** - Ver todas las áreas comunes
5. **Consultar disponibilidad** - Seleccionar área y fecha
6. **Crear nueva reserva** - Llenar formulario con fecha, hora, motivo
7. **Gestionar reservas** - Ver, confirmar o cancelar reservas existentes

### Características Principales:

- **🎯 Reserva Rápida**: Botón flotante para crear reserva directamente
- **🔍 Consulta de Disponibilidad**: Ver horarios libres antes de reservar
- **📅 Selección Intuitiva**: Pickers nativos para fecha y hora
- **✅ Validaciones**: Verificación de conflictos de horario
- **🔄 Gestión Completa**: Confirmar, cancelar, editar reservas
- **💳 Costos Opcionales**: Campo para especificar costo de la reserva
- **📱 Diseño Responsivo**: Optimizado para móviles

## 🎨 Interfaz de Usuario

### Pantalla Principal de Reservas
- **Tab "Mis Reservas"**: Lista de reservas del usuario con estados
- **Tab "Áreas Disponibles"**: Grid de áreas comunes con iconos
- **Botones Flotantes**: "Disponibilidad" y "Nueva Reserva"

### Formulario de Nueva Reserva
- **Selector de Área**: Dropdown con áreas disponibles
- **Selector de Fecha**: DatePicker con validación de fechas futuras
- **Selectores de Hora**: TimePicker para inicio y fin
- **Campo de Motivo**: TextArea opcional
- **Campo de Costo**: Input numérico opcional

### Consulta de Disponibilidad
- **Selector de Área y Fecha**: Filtros para consulta
- **Grid de Horarios**: Botones con horarios disponibles
- **Reserva Directa**: Tocar horario para ir al formulario

## 🔧 Configuración Técnica

### Dependencias Flutter
```yaml
dependencies:
  intl: ^0.19.0  # Para formateo de fechas
  provider: ^6.1.1  # State management
  go_router: ^14.2.7  # Navegación
  http: ^1.1.0  # Peticiones HTTP
```

### Estructura de Archivos
```
lib/
├── models/
│   ├── area_comun_model.dart
│   ├── reserva_model.dart
│   └── horario_disponible_model.dart
├── services/
│   └── reservas_service.dart
├── features/residente/pages/
│   ├── reservas_page.dart
│   ├── nueva_reserva_page.dart
│   └── disponibilidad_page.dart
└── routes/
    └── app_router.dart
```

## 🎯 Casos de Uso Cubiertos

✅ **CU10**: Gestión y reserva de áreas comunes (desde móvil, opción de reservar rápido)
- Acceder al módulo de áreas comunes
- Consultar disponibilidad del área deseada
- Seleccionar fecha y hora de la reserva
- Registrar la reserva y confirmar
- Realizar pago correspondiente (si aplica)
- El sistema confirma y registra la reserva en el calendario de áreas comunes

## 🔄 Integración con Sistema Existente

- **Autenticación**: Usa el sistema de login existente
- **Roles**: Solo residentes pueden acceder a reservas
- **Eventos**: Las reservas confirmadas se integran con el calendario de administración
- **API**: Compatible con el backend Django existente

## 🚀 Próximos Pasos

1. **Pruebas de Integración**: Verificar conexión completa con backend
2. **Notificaciones**: Implementar notificaciones push para confirmaciones
3. **Pagos**: Integrar con sistema de pagos real
4. **Calendario**: Vista de calendario para visualizar reservas
5. **Reportes**: Estadísticas de uso de áreas comunes


