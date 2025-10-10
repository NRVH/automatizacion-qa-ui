# 📦 Instrucciones: Subir Código a GitHub

## Paso 1: Inicializar Git (si no lo has hecho)

```bash
cd "d:\OneDrive\Programacion\Proyectos\EstrellaRoja\Automatizacion-QA-UI"
git init
```

## Paso 2: Agregar remote de GitHub

```bash
git remote add origin git@github.com:NRVH/automatizacion-qa-ui.git
```

Si usas HTTPS en lugar de SSH:
```bash
git remote add origin https://github.com/NRVH/automatizacion-qa-ui.git
```

## Paso 3: Configurar .gitignore

Ya tienes un archivo `.gitignore` estándar de Flutter, pero verifica que incluya:

```
# Flutter/Dart
.dart_tool/
.packages
build/
*.g.dart

# IDE
.idea/
.vscode/
*.iml

# Windows
*.exe (excepto en releases)
```

## Paso 4: Hacer el commit inicial

```bash
git add .
git commit -m "Initial commit: Sistema de auto-actualización v1.2.0"
```

## Paso 5: Subir a GitHub

```bash
git branch -M main
git push -u origin main
```

## Paso 6: Crear el primer tag

```bash
git tag -a v1.2.0 -m "Versión inicial 1.2.0 con sistema de auto-actualización"
git push origin v1.2.0
```

## Paso 7: Compilar y crear el primer Release

```bash
# Limpiar y compilar
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build windows --release

# Crear ZIP
cd build\windows\x64\runner\Release
Compress-Archive -Path * -DestinationPath ..\estrella_roja_qa_bot_v1.2.0.zip

# El archivo ZIP estará en: build\windows\x64\runner\estrella_roja_qa_bot_v1.2.0.zip
```

## Paso 8: Crear Release en GitHub

1. Ve a: https://github.com/NRVH/automatizacion-qa-ui/releases
2. Click en "Draft a new release"
3. **Tag**: Selecciona `v1.2.0`
4. **Title**: `Versión 1.2.0 - Release Inicial`
5. **Description**:
```markdown
## 🎉 Primera versión oficial

Estrella Roja - Bot de Compra de Boletos QA v1.2.0

### ✨ Características principales

- 🤖 Ejecución automatizada de scripts de compra de boletos
- ⚙️ Editor visual de configuración (config.json)
- 📦 Gestión integrada de Git (clone, pull, cambio de rama)
- 🔔 **Sistema de auto-actualización** desde GitHub
- ✅ Validación pre-ejecución del workspace
- 📊 Monitor de salud del entorno
- 🖥️ Terminal en tiempo real con colores
- 🔐 Almacenamiento seguro de credenciales

### 📦 Instalación

1. Descarga el archivo `estrella_roja_qa_bot_v1.2.0.zip`
2. Extrae en la ubicación deseada (ej: `C:\EstrellRojaQA\`)
3. Ejecuta `estrella_roja_qa_bot.exe`

### 🚀 Primeros pasos

1. Ve a la pestaña **Git**
2. Ingresa tus credenciales de GitLab
3. Clona el repositorio
4. Ve a **Configuración** y completa los datos
5. Ve a **Ejecutar** y selecciona el script deseado

### 📝 Documentación

- [README.md](https://github.com/NRVH/automatizacion-qa-ui/blob/main/README.md)
- [Cómo actualizar la app](https://github.com/NRVH/automatizacion-qa-ui/blob/main/docs/UPDATE_SYSTEM.md)

---

**Desarrollado para el equipo de QA de Estrella Roja** ❤️
```

6. **Attach binary**: Arrastra el archivo `estrella_roja_qa_bot_v1.2.0.zip`
7. Click en **"Publish release"**

## ✅ Verificación

Después de publicar:

1. Abre la app (si ya la tienes corriendo, ciérrala y ábrela de nuevo)
2. Espera unos segundos
3. NO deberías ver notificación (porque ya estás en v1.2.0)
4. Prueba manualmente: Menú (⋮) → "Buscar actualizaciones"
5. Debe decir: "No hay actualizaciones disponibles. Tienes la última versión."

## 🎯 Próximos pasos

Cuando hagas cambios y quieras liberar v1.2.1:

1. Actualiza versión en código
2. `git commit` y `git push`
3. `git tag v1.2.1 && git push origin v1.2.1`
4. Compila y crea ZIP
5. Crea Release en GitHub
6. La app de los usuarios detectará automáticamente la actualización 🎉

---

## 🔧 Comandos útiles

```bash
# Ver remote configurado
git remote -v

# Ver tags
git tag

# Borrar un tag (si te equivocaste)
git tag -d v1.2.0
git push origin --delete v1.2.0

# Ver estado
git status

# Ver historial
git log --oneline
```

---

## 📞 ¿Problemas?

Si algo falla:
1. Verifica que el remote esté configurado: `git remote -v`
2. Verifica tu autenticación con GitHub
3. Si usas SSH, asegúrate de tener tu llave SSH configurada
4. Si usas HTTPS, puede que necesites un Personal Access Token

---

**¡Listo! Tu app ya tiene sistema de auto-actualización profesional** 🚀
