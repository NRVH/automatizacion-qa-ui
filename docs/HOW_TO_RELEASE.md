# 🚀 Guía: Cómo Publicar Actualizaciones

Esta guía te explica paso a paso cómo crear y publicar nuevas versiones de la aplicación para que el equipo de QA pueda actualizar automáticamente.

---

## 📋 **PROCESO COMPLETO**

### **Paso 1: Hacer Cambios en el Código**

1. Realiza tus cambios/mejoras en el código
2. Prueba que todo funciona correctamente
3. Actualiza la versión en los archivos necesarios

---

### **Paso 2: Actualizar Número de Versión**

Edita los siguientes archivos:

**`lib/constants/app_constants.dart`**:
```dart
static const String appVersion = '1.2.1'; // Cambiar aquí
```

**`pubspec.yaml`**:
```yaml
version: 1.2.1+4  # Formato: major.minor.patch+build
```

**Reglas de versionado**:
- **Major** (1.x.x): Cambios incompatibles o muy grandes
- **Minor** (x.2.x): Nuevas funcionalidades compatibles
- **Patch** (x.x.1): Correcciones de bugs

---

### **Paso 3: Commit y Push**

```bash
git add .
git commit -m "Release v1.2.1: Descripción de los cambios"
git push origin main
```

---

### **Paso 4: Crear Tag de Versión**

```bash
git tag -a v1.2.1 -m "Versión 1.2.1 - Descripción breve"
git push origin v1.2.1
```

⚠️ **Importante**: El tag DEBE empezar con `v` (ej: `v1.2.1`)

---

### **Paso 5: Compilar la Aplicación**

```powershell
# Limpiar builds anteriores
flutter clean

# Obtener dependencias
flutter pub get

# Generar código (modelos JSON)
flutter pub run build_runner build --delete-conflicting-outputs

# Compilar en modo Release
flutter build windows --release
```

**Ubicación del ejecutable**:
```
build\windows\x64\runner\Release\
```

---

### **Paso 6: Crear Archivo ZIP**

Navega a la carpeta Release y comprime TODO su contenido:

```powershell
cd build\windows\x64\runner\Release
Compress-Archive -Path * -DestinationPath ..\estrella_roja_qa_bot_v1.2.1.zip
```

O manualmente:
1. Selecciona todos los archivos en `Release\`
2. Click derecho → "Comprimir en archivo ZIP"
3. Nombra el archivo: `estrella_roja_qa_bot_v1.2.1.zip`

⚠️ **Importante**: Comprime el CONTENIDO, no la carpeta Release completa

---

### **Paso 7: Crear Release en GitHub**

#### **Opción A: Interfaz Web** (Recomendado para empezar)

1. Ve a tu repositorio: https://github.com/NRVH/automatizacion-qa-ui
2. Click en **"Releases"** (menú derecho)
3. Click en **"Draft a new release"**
4. Completa el formulario:

   **Tag**: `v1.2.1` (debe coincidir con el tag de Git)
   
   **Title**: `Versión 1.2.1 - Mejoras y Correcciones`
   
   **Description** (Changelog):
   ```markdown
   ## 🎉 Novedades
   
   - ✨ Nueva funcionalidad X
   - 🐛 Fix: Corrección del error Y
   - ⚡ Mejora: Optimización de Z
   
   ## 📦 Instalación
   
   1. Descarga el archivo ZIP
   2. Extrae en la ubicación deseada
   3. Ejecuta `estrella_roja_qa_bot.exe`
   
   ---
   
   **Actualización automática**: Si ya tienes una versión anterior, la app detectará esta actualización automáticamente.
   ```

5. **Attach binaries**: Arrastra el archivo `estrella_roja_qa_bot_v1.2.1.zip`
6. **Marcar como obligatoria** (opcional): Agrega `[MANDATORY]` en la descripción si quieres forzar la actualización
7. Click en **"Publish release"**

#### **Opción B: GitHub CLI** (Más rápido)

```bash
gh release create v1.2.1 \
  build\windows\x64\runner\estrella_roja_qa_bot_v1.2.1.zip \
  --title "Versión 1.2.1 - Mejoras y Correcciones" \
  --notes "Descripción de los cambios"
```

---

### **Paso 8: Verificar que Funciona**

1. Abre la aplicación (versión anterior)
2. Espera unos segundos (verifica automáticamente al iniciar)
3. Deberías ver el ícono 🔔 con badge naranja
4. Click en el ícono
5. Debe aparecer el diálogo con la nueva versión

O manualmente:
1. Click en el menú (⋮)
2. "Buscar actualizaciones"
3. Debe mostrar la nueva versión

---

## 🤖 **AUTOMATIZACIÓN CON GITHUB ACTIONS** (Opcional)

Si quieres que GitHub compile y publique automáticamente, crea este archivo:

**`.github/workflows/release.yml`**:
```yaml
name: Build and Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: windows-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.9.2'
          channel: 'stable'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Generate code
        run: flutter pub run build_runner build --delete-conflicting-outputs
      
      - name: Build Windows Release
        run: flutter build windows --release
      
      - name: Create ZIP
        run: |
          cd build/windows/x64/runner/Release
          Compress-Archive -Path * -DestinationPath ../estrella_roja_qa_bot_${{ github.ref_name }}.zip
      
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          files: build/windows/x64/runner/estrella_roja_qa_bot_${{ github.ref_name }}.zip
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Con esto activado**:
1. Solo haces: `git tag v1.2.1 && git push origin v1.2.1`
2. GitHub Actions compila y publica automáticamente
3. En ~10-15 minutos la release está lista

---

## 📝 **PLANTILLA DE CHANGELOG**

Usa esta plantilla para tus releases:

```markdown
## 🎉 Novedades

- ✨ [Nueva funcionalidad] Descripción
- 🐛 [Fix] Descripción del bug corregido
- ⚡ [Mejora] Descripción de la optimización
- 📝 [Documentación] Cambios en docs
- 🔒 [Seguridad] Corrección de seguridad

## 📦 Instalación

**Usuarios nuevos**:
1. Descarga el archivo ZIP
2. Extrae en `C:\EstrellRojaQA\` (o donde prefieras)
3. Ejecuta `estrella_roja_qa_bot.exe`

**Actualización**:
- La app detectará automáticamente esta versión
- Click en el ícono 🔔 → "Actualizar ahora"

---

**Versión completa**: 1.2.1
**Fecha**: 10 de octubre, 2025
**Tamaño**: ~50 MB
```

---

## ⚠️ **CHECKLIST ANTES DE PUBLICAR**

Antes de crear cada release, verifica:

- [ ] Versión actualizada en `app_constants.dart`
- [ ] Versión actualizada en `pubspec.yaml`
- [ ] Código compilado sin errores
- [ ] Probado en Windows
- [ ] Changelog escrito
- [ ] Tag creado en Git
- [ ] ZIP creado correctamente
- [ ] Nombre del archivo: `estrella_roja_qa_bot_vX.Y.Z.zip`

---

## 🆘 **SOLUCIÓN DE PROBLEMAS**

### **"La app no detecta la actualización"**

1. Verifica que el tag empiece con `v` (ej: `v1.2.1`)
2. Verifica que el release esté publicado (no draft)
3. Verifica que el ZIP esté adjunto
4. Espera 1-2 minutos y vuelve a verificar

### **"Error al descargar la actualización"**

1. Verifica que el archivo ZIP sea accesible públicamente
2. Si el repo es privado, considera hacerlo público o usar tokens

### **"La actualización se descarga pero no se instala"**

1. Asegúrate de que el usuario tenga permisos de escritura
2. Verifica que no haya antivirus bloqueando el script PowerShell
3. Revisa los logs en la carpeta de la app

---

## 📚 **RECURSOS ADICIONALES**

- **GitHub Releases**: https://docs.github.com/en/repositories/releasing-projects-on-github
- **Semantic Versioning**: https://semver.org/
- **GitHub CLI**: https://cli.github.com/

---

## 💡 **TIPS**

1. **Releases frecuentes**: Es mejor hacer releases pequeños frecuentemente
2. **Beta testing**: Puedes marcar releases como "Pre-release" para pruebas
3. **Rollback**: Si algo sale mal, puedes borrar el release y crear uno nuevo
4. **Comunicación**: Avisa al equipo cuando publiques actualizaciones importantes

---

**¿Necesitas ayuda?** Crea un issue en GitHub o contacta al equipo de desarrollo.
