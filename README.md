# Compulsa - Asistente Tributario Inteligente

Una aplicación móvil desarrollada en Flutter que funciona como un asistente tributario inteligente, diseñado especialmente para contadores y pequeños empresarios en Perú.

## 🚀 Características Principales

- **Cálculo Automático de IGV**: Calcula el Impuesto General a las Ventas con precisión
- **Cálculo de Impuesto a la Renta**: Soporte para diferentes regímenes tributarios
- **Gestión de Empresas**: Administra múltiples empresas con sus respectivos regímenes
- **Declaraciones**: Genera y gestiona declaraciones mensuales
- **Saldos a Favor**: Manejo automático de saldos para períodos siguientes
- **Reportes**: Análisis tributario y reportes detallados
- **Interfaz Profesional**: Diseño moderno y fácil de usar

## 🏗️ Arquitectura del Proyecto

La aplicación está organizada con una arquitectura clara y escalable:

```
lib/
├── main.dart                    # Punto de entrada - Solo rutas
├── config/
│   └── routes.dart             # Configuración de rutas
├── core/
│   ├── theme/
│   │   ├── app_theme.dart      # Tema de la aplicación
│   │   └── app_colors.dart     # Paleta de colores
│   ├── constants/
│   │   └── app_constants.dart  # Constantes globales
│   └── utils/
│       └── format_utils.dart   # Utilidades de formato
├── models/
│   ├── empresa.dart            # Modelo de empresa
│   ├── calculo_igv.dart        # Modelo para cálculos de IGV
│   ├── calculo_renta.dart      # Modelo para cálculos de Renta
│   └── declaracion.dart        # Modelo de declaraciones
├── screens/
│   ├── home/
│   │   └── home_screen.dart    # Pantalla principal
│   ├── empresas/
│   │   ├── empresas_screen.dart
│   │   └── empresa_form_screen.dart
│   ├── calculos/
│   │   ├── calculos_screen.dart
│   │   ├── igv_screen.dart
│   │   └── renta_screen.dart
│   ├── declaraciones/
│   │   ├── declaraciones_screen.dart
│   │   └── declaracion_form_screen.dart
│   └── reportes/
│       └── reportes_screen.dart
└── widgets/
    ├── common/                 # Widgets comunes
    └── cards/
        └── dashboard_card.dart # Tarjetas del dashboard
```

## 🎨 Diseño y UI

### Paleta de Colores
- **Azul Profesional (#1565C0)**: Color principal para elementos importantes
- **Verde Éxito (#2E7D32)**: Para confirmaciones y saldos a favor
- **Naranja Alerta (#FF8F00)**: Para alertas y recordatorios
- **Índigo IGV (#3F51B5)**: Específico para cálculos de IGV
- **Púrpura Renta (#9C27B0)**: Específico para cálculos de Renta

### Funcionalidades por Pantalla

#### 🏠 Pantalla Principal (HomeScreen)
- Dashboard con resumen de actividades
- Acceso rápido a funciones principales
- Métricas importantes del mes actual
- Historial de actividad reciente

#### 🏢 Gestión de Empresas
- Lista de empresas registradas
- Formulario para crear/editar empresas
- Validación de RUC peruano
- Soporte para diferentes regímenes tributarios

#### 🧮 Cálculos Tributarios
- **IGV**: Cálculo automático con tasa del 18%
- **Renta**: Cálculos según régimen (General 29.5%, MYPE 10%, Especial 15%)
- Validaciones en tiempo real
- Guardar cálculos para referencias futuras

#### 📋 Declaraciones
- Gestión de declaraciones mensuales
- Estados: Borrador, Pendiente, Presentada, Observada
- Filtros por empresa y período
- Generación de formularios

#### 📊 Reportes
- Resumen mensual por empresa
- Evolución de impuestos
- Análisis de saldos a favor
- Métricas y estadísticas

## 🚀 Instalación y Uso

1. **Requisitos**:
   - Flutter SDK
   - Dart SDK
   - Android Studio / VS Code

2. **Instalación**:
   ```bash
   flutter pub get
   flutter run
   ```

3. **Primer Uso**:
   - Registra tu primera empresa
   - Selecciona el régimen tributario
   - Comienza a calcular impuestos

---

**Desarrollado con ❤️ en Flutter para contadores y empresarios peruanos**
