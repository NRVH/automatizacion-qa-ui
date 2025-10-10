#  Estrella Roja - Bot de Compra de Boletos
## Interfaz Gráfica Flutter para QA

[![Version](https://img.shields.io/badge/version-1.2.0-blue.svg)](https://github.com/NRVH/automatizacion-qa-ui/releases)
[![Flutter](https://img.shields.io/badge/Flutter-3.9.2+-02569B.svg?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-Windows-0078D6.svg?logo=windows)](https://www.microsoft.com/windows)

---

##  Cambios Recientes - Sistema de Auto-Actualización

### 🚀 **Nueva: Actualización Automática (v1.2.0)**
-  Sistema de verificación de actualizaciones integrado
-  Descarga e instalación automática desde GitHub
-  Notificación visual con badge cuando hay nueva versión
-  Changelog visible desde la app
-  Opción manual: Menú → "Buscar actualizaciones"
-  Sin necesidad de redistribuir manualmente

### ✅ **Sistema de Confiabilidad (v1.0.0)**

###  **Nueva Validación Pre-Ejecución**
Antes de ejecutar cualquier script, la aplicación ahora:
-  Verifica que todos los componentes estén presentes
-  Valida la estructura del workspace
-  Muestra errores críticos y advertencias
-  Bloquea ejecución si hay problemas graves

###  **Git Mejorado**
-  Timeout de 5 minutos en clone (evita cuelgues)
-  Manejo automático de conflictos (stash/pop)
-  Validación post-clone de estructura
-  Mensajes de error más claros

###  **Configuración Robusta**
-  Backup automático si config.json se corrompe
-  Regeneración automática con valores por defecto
-  Validación de estructura JSON

###  **Terminal Optimizado**
-  Límite de 5,000 líneas (evita lag)
-  Límite de 1MB de texto
-  Coloreo inteligente (rojo=error, verde=éxito)
-  Auto-scroll suave

###  **Widget de Salud**
-  Banner superior que muestra el estado del workspace
-  Indicadores visuales por color
-  Actualización automática

---

##  Descripción

Aplicación de escritorio Flutter para Windows que facilita la ejecución y gestión de scripts automatizados de compra de boletos de Estrella Roja usando Playwright.

###  Características Principales

-  **Ejecución de Scripts**: Ejecuta boletos Sencillo, Redondo y Abierto con un click
-  **Terminal Integrada**: Visualiza la salida de los scripts en tiempo real con colores
-  **Editor de Configuración**: Formulario visual para editar config.json
-  **Integración con Git**: Clone y actualiza el repositorio automáticamente
-  **Exportación de Logs**: Descarga los logs de ejecución
-  **Credenciales Seguras**: Almacenamiento encriptado para GitLab
-  **Validación Pre-Vuelo**: Verifica que todo esté listo antes de ejecutar
-  **Monitor de Salud**: Indicador visual del estado del workspace

---

##  Guía Rápida de Instalación

### 1 Requisitos Previos
- Windows 10/11
- Git instalado: https://git-scm.com/download/win
- Flutter SDK 3.9.2+: https://flutter.dev/

### 2 Instalar Dependencias
```powershell
cd D:\OneDrive\Escritorio\Automatizacion-QA-UI
flutter pub get
```

### 3 Generar Código
```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4 Ejecutar en Desarrollo
```powershell
flutter run -d windows
```

### 5 Compilar para Producción
```powershell
flutter build windows --release
```

El ejecutable estará en:
\\\
build\windows\x64\runner\Release\flutter_app.exe
\\\

---

##  Guía de Uso

### Paso 1: Configurar Git
1. Abre la aplicación
2. Ve a la pestaña **Git** (ícono de nube)
3. Ingresa tu usuario y contraseña de GitLab
4. Selecciona la rama (por defecto: \eature/mejoras-script-compra\)
5. Haz clic en **"Clonar Repositorio"**
6. Espera a que termine (verás el progreso en el log)

### Paso 2: Configurar Parámetros de Compra
1. Ve a la pestaña **Configuración** (ícono de engranaje)
2. Completa los campos:
   - **Navegador**: Configuración del navegador (headless, viewport)
   - **Búsqueda**: Origen, destino, fecha, venta anticipada
   - **Pasajero**: Nombre, apellidos, teléfono, email
   - **Pago**: Datos de tarjeta
   - **Login**: Credenciales de la plataforma
3. Haz clic en **"Guardar Configuración"**

### Paso 3: Ejecutar Compra de Boletos
1. Ve a la pestaña **Ejecutar** (ícono de play)
2. Verifica el banner superior:
   -  Verde = Listo para ejecutar
   -  Rojo = Hay problemas (revisar mensaje)
3. Selecciona el tipo de boleto:
   - **Sencillo**: Un viaje de A  B
   - **Redondo**: Ida y vuelta A  B
   - **Abierto**: Sin fecha específica
4. Haz clic en **"Ejecutar Compra"**
5. Revisa la validación pre-vuelo:
   -  Si todo está verde  **"Continuar"**
   -  Si hay errores  **"Cancelar"** y corregir
6. Observa la ejecución en el terminal
7. Si hay errores, descarga los logs con el botón ****

---

##  Interfaz Visual

### Banner de Salud (Superior)
| Color | Significado | Acción |
|-------|-------------|--------|
|  Verde | Todo funcional | Ejecutar libremente |
|  Naranja | Advertencias | Puedes continuar con precaución |
|  Rojo | Errores críticos | Corregir antes de ejecutar |
|  Azul | Información | Acción recomendada |

### Terminal
| Color | Tipo | Ejemplo |
|-------|------|---------|
|  Rojo | Error | ERROR: No se pudo conectar |
|  Verde | Éxito |  Boleto comprado exitosamente |
|  Azul | Separador |  |
|  Gris | Normal | Iniciando proceso... |

---

##  Tecnologías

- **Flutter 3.9.2+** - Framework de UI multiplataforma
- **Provider 6.1.5+** - Gestión de estado
- **Flutter Form Builder 10.2.0** - Formularios dinámicos
- **Flutter Secure Storage 9.2.2** - Almacenamiento seguro de credenciales
- **Process Run 1.2.0** - Ejecución de procesos externos
- **XTerm 4.0.0** - Emulador de terminal
- **File Picker 8.3.7** - Selección de archivos
- **Path Provider 2.1.5** - Gestión de rutas
- **Google Fonts 6.3.2** - Tipografías personalizadas

---

##  Solución de Problemas Comunes

###  "Error: Git no está instalado"
**Solución**: Instala Git desde https://git-scm.com/download/win

###  "Error: Repositorio no clonado"
**Solución**: Ve a la pestaña Git  Ingresa credenciales  Clona el repo

###  "Error: Node.js no encontrado"
**Solución**: El repo no se clonó bien. Intenta clonar de nuevo.

###  "Error: Credenciales inválidas"
**Solución**: Verifica tu usuario y contraseña de GitLab

###  "Tiempo de espera agotado"
**Solución**: Verifica tu conexión a internet y VPN

###  "Advertencia: package.json no encontrado"
**Solución**: Puedes continuar, o actualiza el repositorio con Git Pull

###  Terminal muestra "...truncado X caracteres..."
**Info**: Normal en ejecuciones largas. Descarga los logs completos.

---

##  Estructura del Proyecto

\\\
lib/
 constants/              # Configuraciones globales
    app_constants.dart  # URLs, timeouts, límites
 models/                 # Modelos de datos
    config_model.dart   # Estructura de config.json
 providers/              # Estado global
    app_state_provider.dart
 screens/                # Pantallas principales
    home_screen.dart
    execution_screen.dart
    config_editor_screen.dart
    git_settings_screen.dart
 services/               # Lógica de negocio
    config_service.dart
    git_service.dart
    script_executor_service.dart
 widgets/                # Componentes reutilizables
    workspace_health_widget.dart
 main.dart               # Punto de entrada
\\\

---

##  Documentación Adicional

- **INSTRUCCIONES.md**: Guía de compilación y empaquetado
- **MEJORAS_CONFIABILIDAD.md**: Detalles técnicos de validaciones

---

##  Seguridad

-  Credenciales de Git encriptadas con Flutter Secure Storage
-  No se almacenan contraseñas en texto plano
-  Config.json local (no se sube a Git)
-  URL con credenciales no se registra en logs

---

##  Filosofía de Diseño

**"Guiar, no bloquear"**
- Validaciones inteligentes que previenen errores
- Mensajes claros con soluciones sugeridas
- Recuperación automática cuando es posible
- Feedback visual inmediato

**"Todo debe ser obvio"**
- Botones con tooltips descriptivos
- Estados visuales con colores semafóricos
- Diálogos de confirmación antes de acciones críticas
- Logs con emojis para facilitar lectura

---

##  Soporte

- **Reportar bugs**: http://gitlab.estrellaroja.com.mx/java/estrella-roja-qa-automatizacion/-/issues
- **Contacto**: Equipo de Desarrollo de Estrella Roja

---

##  Changelog

### v1.2.0 (2025-10-10)
- 🚀 Sistema de auto-actualización con GitHub Releases
- 🔔 Notificación visual de actualizaciones disponibles
- 📥 Descarga e instalación automática
- 📝 Changelog visible desde la app
- 🔗 Integración con GitHub API
- ⚙️ Menú de ayuda con opciones adicionales
- 📊 Indicador de actualización en tiempo real

### v1.0.0 (2025-10-09)
-  Sistema de validación pre-ejecución
-  Widget de salud del workspace
-  Manejo robusto de Git (timeouts, stash, validaciones)
-  Protección contra config.json corrupto
-  Terminal optimizado (límites de memoria)
-  Diálogo de pre-flight check
-  Constantes centralizadas
-  Coloreo inteligente de logs
-  Fix: Memory leak en terminal largo
-  Fix: Cuelgue en git clone sin conexión
-  Fix: Crash por JSON malformado

---

##  Enlaces

- **Repositorio GitHub**: https://github.com/NRVH/automatizacion-qa-ui
- **Releases**: https://github.com/NRVH/automatizacion-qa-ui/releases
- **Cómo publicar updates**: [docs/HOW_TO_RELEASE.md](docs/HOW_TO_RELEASE.md)
- **Reportar bugs**: https://github.com/NRVH/automatizacion-qa-ui/issues

---

**Desarrollado con  para el equipo de QA de Estrella Roja**
