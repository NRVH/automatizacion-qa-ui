# 🎯 Guía Rápida: Sistema de Actualizaciones

## Para el Usuario (QA)

### ¿Cómo actualizar la app?

**Método 1: Automático (Recomendado)**
1. Abre la aplicación
2. Si hay actualización, verás un ícono 🔔 con un punto naranja
3. Haz clic en el ícono
4. Lee las novedades
5. Click en "Actualizar ahora"
6. Espera a que descargue e instale
7. La app se reiniciará automáticamente

**Método 2: Manual**
1. Click en el menú (⋮) en la parte superior derecha
2. Selecciona "Buscar actualizaciones"
3. Si hay una nueva versión, sigue los pasos del Método 1

**Método 3: Descarga directa**
1. Ve a: https://github.com/NRVH/automatizacion-qa-ui/releases
2. Descarga el archivo ZIP más reciente
3. Cierra la aplicación actual
4. Extrae el ZIP sobre la carpeta existente
5. Abre la aplicación de nuevo

---

## Para el Desarrollador

### ¿Cómo publicar una actualización?

**Proceso rápido**:
```bash
# 1. Actualizar versión en app_constants.dart y pubspec.yaml
# 2. Commit y push
git add .
git commit -m "Release v1.2.1: Descripción"
git push

# 3. Crear tag
git tag -a v1.2.1 -m "Versión 1.2.1"
git push origin v1.2.1

# 4. Compilar
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build windows --release

# 5. Crear ZIP
cd build\windows\x64\runner\Release
Compress-Archive -Path * -DestinationPath ..\estrella_roja_qa_bot_v1.2.1.zip

# 6. Ir a GitHub y crear Release con el ZIP
```

**Ver guía completa**: [docs/HOW_TO_RELEASE.md](HOW_TO_RELEASE.md)

---

## Versionado

Usamos **Semantic Versioning**: `MAJOR.MINOR.PATCH`

- **MAJOR** (1.x.x): Cambios incompatibles
- **MINOR** (x.2.x): Nuevas funcionalidades compatibles
- **PATCH** (x.x.1): Correcciones de bugs

Ejemplos:
- `1.2.0` → `1.2.1`: Corrección de bugs
- `1.2.0` → `1.3.0`: Nueva funcionalidad
- `1.2.0` → `2.0.0`: Cambio incompatible mayor

---

## Actualizaciones Obligatorias

Si una actualización es **crítica** (ej: fix de seguridad), marca el release como obligatorio:

1. En la descripción del release, incluye: `[MANDATORY]`
2. La app no permitirá cerrar el diálogo de actualización
3. El usuario DEBE actualizar antes de usar la app

Ejemplo:
```markdown
## Corrección Crítica de Seguridad

[MANDATORY]

- 🔒 Fix: Vulnerabilidad en almacenamiento de credenciales
- Esta actualización es obligatoria por seguridad
```

---

## Troubleshooting

**"No veo el ícono de actualización"**
- Espera 5 minutos después de publicar el release
- Reinicia la app
- Verifica tu conexión a internet

**"La actualización falla al instalar"**
- Cierra la app y ábrela como administrador
- Verifica que no haya antivirus bloqueando
- Desactiva temporalmente Windows Defender durante la actualización

**"Cómo volver a una versión anterior"**
- Ve a GitHub Releases
- Descarga la versión anterior
- Extrae sobre la carpeta actual

---

## FAQ

**¿Cuándo se verifica si hay actualizaciones?**
- Al iniciar la app
- Cada 4 horas mientras está abierta
- Manualmente desde el menú

**¿La descarga es segura?**
- Sí, descarga directamente desde GitHub (propiedad de Microsoft)
- La URL siempre será: `github.com/NRVH/automatizacion-qa-ui`

**¿Puedo desactivar las actualizaciones automáticas?**
- Actualmente no, pero puedes ignorar la notificación
- La app seguirá funcionando con versiones antiguas (excepto updates obligatorios)

**¿Cuánto pesa una actualización?**
- Aproximadamente 40-60 MB
- Se muestra el tamaño exacto en el diálogo

---

## Contacto

- **Issues**: https://github.com/NRVH/automatizacion-qa-ui/issues
- **Releases**: https://github.com/NRVH/automatizacion-qa-ui/releases
