# ✅ CHECKLIST: Antes de Entregar al QA

## 📋 Pasos Finales Antes de Entregar

### **1. Compilar Versión Release**

```bash
# Limpiar todo
flutter clean

# Instalar dependencias
flutter pub get

# Generar código
flutter pub run build_runner build --delete-conflicting-outputs

# Compilar en Release
flutter build windows --release
```

**Ubicación**: `build\windows\x64\runner\Release\`

---

### **2. Verificar Compilación**

- [ ] Ejecutar `estrella_roja_qa_bot.exe` manualmente
- [ ] Verificar que abre sin errores
- [ ] Probar cada pestaña (Ejecutar, Configuración, Git)
- [ ] Verificar que no hay crashes
- [ ] Cerrar aplicación correctamente

---

### **3. Subir a GitHub**

```bash
# Inicializar (si no lo has hecho)
git init
git remote add origin git@github.com:NRVH/automatizacion-qa-ui.git

# Agregar archivos
git add .
git commit -m "Initial commit: Sistema de auto-actualización v1.2.0

- Sistema completo de auto-actualización desde GitHub
- Notificaciones visuales de updates disponibles
- Diálogo de actualización con changelog
- Descarga e instalación automática
- Verificación al iniciar y manual desde menú
- Documentación completa del sistema"

# Subir a GitHub
git branch -M main
git push -u origin main

# Crear tag de versión
git tag -a v1.2.0 -m "Versión inicial 1.2.0 con sistema de auto-actualización"
git push origin v1.2.0
```

---

### **4. Crear Release en GitHub**

1. **Crear ZIP**:
```bash
cd build\windows\x64\runner\Release
Compress-Archive -Path * -DestinationPath ..\estrella_roja_qa_bot_v1.2.0.zip
```

2. **Ir a GitHub**:
   - https://github.com/NRVH/automatizacion-qa-ui/releases
   - Click "Draft a new release"

3. **Completar formulario**:
   - **Tag**: `v1.2.0` (debe estar en el dropdown)
   - **Title**: `Versión 1.2.0 - Release Inicial con Auto-Actualización`
   - **Description**: (copia el template de abajo)
   - **Attach**: Sube `estrella_roja_qa_bot_v1.2.0.zip`
   - **Publish release** ✅

**Template de descripción**:
```markdown
## 🎉 Primera versión oficial

Estrella Roja - Bot de Compra de Boletos QA v1.2.0

### ✨ Características principales

- 🤖 **Ejecución automatizada** de scripts de compra de boletos (Sencillo, Redondo, Abierto)
- ⚙️ **Editor visual** de configuración (config.json)
- 📦 **Gestión integrada de Git** (clone, pull, cambio de rama)
- 🔔 **Sistema de auto-actualización** desde GitHub Releases
- ✅ **Validación pre-ejecución** del workspace
- 📊 **Monitor de salud** del entorno de trabajo
- 🖥️ **Terminal en tiempo real** con coloreo inteligente
- 🔐 **Almacenamiento seguro** de credenciales GitLab

### 🚀 Funcionalidades del Sistema de Actualización

- ✨ Verificación automática al iniciar la app
- 🔔 Notificación visual con badge cuando hay nueva versión
- 📥 Descarga e instalación con un solo clic
- 📝 Changelog visible desde la interfaz
- 🔄 Reinicio automático después de actualizar
- ⚙️ Opción manual: Menú → "Buscar actualizaciones"

### 📦 Instalación (Primera vez)

**Requisitos**:
- Windows 10/11
- Git instalado
- Conexión a internet

**Pasos**:
1. Descarga el archivo `estrella_roja_qa_bot_v1.2.0.zip`
2. Extrae en la ubicación deseada (ej: `C:\EstrellRojaQA\`)
3. Ejecuta `estrella_roja_qa_bot.exe`
4. Ve a la pestaña **Git** y configura credenciales
5. Clona el repositorio
6. Ve a **Configuración** y completa los datos
7. ¡Listo para usar!

### 🔄 Actualización (Si ya tienes una versión anterior)

**Método 1 - Automático** (Recomendado):
- La app detectará automáticamente esta versión
- Verás un ícono 🔔 con badge naranja
- Click en el ícono → "Actualizar ahora"
- Espera 2 minutos → Se reinicia automáticamente

**Método 2 - Manual**:
- Descarga el ZIP
- Cierra la app
- Extrae sobre la carpeta existente (reemplaza archivos)
- Abre la app de nuevo

### 📝 Primeros pasos

#### 1. Configurar Git
```
Pestaña Git → Ingresar usuario y token GitLab → Clonar repositorio
```

#### 2. Configurar parámetros
```
Pestaña Configuración → Completar formulario → Guardar
```

#### 3. Ejecutar script
```
Pestaña Ejecutar → Seleccionar script → Ejecutar
```

### 🐛 Solución de Problemas

**Error: "Git no está instalado"**
- Instala Git desde: https://git-scm.com/download/win
- Reinicia la app

**Error: "Repositorio no clonado"**
- Ve a pestaña Git → Configura credenciales → Clona

**Error: "Node.js no encontrado"**
- El repositorio no se clonó correctamente
- Intenta clonar de nuevo

**Advertencia: "package.json no encontrado"**
- Puedes continuar, o actualiza el repositorio con Git Pull

### 📚 Documentación

- [README.md](https://github.com/NRVH/automatizacion-qa-ui/blob/main/README.md) - Documentación completa
- [Cómo actualizar la app](https://github.com/NRVH/automatizacion-qa-ui/blob/main/docs/UPDATE_SYSTEM.md)
- [Sistema de updates (Demo)](https://github.com/NRVH/automatizacion-qa-ui/blob/main/docs/UPDATE_SYSTEM_DEMO.md)

### 🔗 Enlaces

- **Repositorio**: https://github.com/NRVH/automatizacion-qa-ui
- **Reportar bugs**: https://github.com/NRVH/automatizacion-qa-ui/issues
- **Releases**: https://github.com/NRVH/automatizacion-qa-ui/releases

---

**Desarrollado con ❤️ para el equipo de QA de Estrella Roja**

**Versión**: 1.2.0
**Fecha**: 10 de octubre, 2025
**Tamaño**: ~50 MB
```

4. **Verificar release publicado**:
   - [ ] Release visible en https://github.com/NRVH/automatizacion-qa-ui/releases
   - [ ] ZIP descargable
   - [ ] Changelog visible
   - [ ] Tag `v1.2.0` en la lista

---

### **5. Probar el Sistema de Actualización** (Opcional pero recomendado)

**Método 1 - Simulación local**:
```
1. En tu código, cambia temporalmente:
   AppConstants.appVersion = '1.0.0'
   
2. Compila y ejecuta

3. La app debe detectar que hay v1.2.0 disponible

4. Prueba el flujo completo de actualización

5. Revertir cambio y recompilar
```

**Método 2 - Crear v1.2.1 de prueba**:
```
1. Haz un cambio pequeño (ej: agregar un comentario)
2. Actualiza versión a 1.2.1
3. Crea tag v1.2.1
4. Crea release v1.2.1
5. Abre app v1.2.0
6. Debe detectar v1.2.1
7. Si funciona, borra release v1.2.1 (era solo prueba)
```

---

### **6. Preparar Paquete para QA**

**Opción A - Desde GitHub** (Recomendado):
```
1. Comparte el link del release:
   https://github.com/NRVH/automatizacion-qa-ui/releases/tag/v1.2.0

2. Instrucciones para QA:
   - Descargar ZIP
   - Extraer en C:\EstrellRojaQA\
   - Ejecutar estrella_roja_qa_bot.exe
```

**Opción B - ZIP directo**:
```
1. Descarga el ZIP del release de GitHub
2. Envía por email/shared folder
3. Incluye instrucciones de instalación
```

---

### **7. Documentación para Entregar**

Archivos para compartir con QA:

- [ ] Link al release de GitHub
- [ ] README.md (instrucciones de uso)
- [ ] docs/UPDATE_SYSTEM.md (cómo actualizar)
- [ ] Video/GIF demo (opcional)
- [ ] Documento de "Primeros Pasos" (opcional)

**Contenido mínimo del email**:
```
Asunto: Nueva Herramienta - Estrella Roja QA Bot v1.2.0

Hola equipo,

Les comparto la nueva herramienta para facilitar la ejecución de 
scripts de automatización de compra de boletos.

🔗 Descargar: 
https://github.com/NRVH/automatizacion-qa-ui/releases/tag/v1.2.0

📝 Instalación:
1. Descargar el archivo ZIP
2. Extraer en C:\EstrellRojaQA\
3. Ejecutar estrella_roja_qa_bot.exe
4. Seguir las instrucciones en pantalla

✨ Características:
- Interfaz gráfica fácil de usar
- Gestión de Git integrada
- Editor de configuración visual
- Sistema de actualización automática

🆕 Actualizaciones futuras:
La app se actualizará automáticamente. Verán una notificación 
cuando haya nueva versión disponible.

📚 Documentación completa:
https://github.com/NRVH/automatizacion-qa-ui/blob/main/README.md

¿Dudas? Pregunten en Slack o creen un issue en GitHub.

Saludos!
```

---

### **8. Checklist Final**

Antes de enviar:

#### **Técnico**:
- [ ] App compila sin errores
- [ ] App se ejecuta correctamente
- [ ] Todas las funcionalidades probadas
- [ ] No hay crashes visibles
- [ ] Código subido a GitHub
- [ ] Release v1.2.0 publicado
- [ ] ZIP descargable desde GitHub
- [ ] Tag v1.2.0 creado

#### **Documentación**:
- [ ] README.md actualizado
- [ ] Changelog incluido
- [ ] Instrucciones claras de instalación
- [ ] Documentación del sistema de updates
- [ ] HOW_TO_RELEASE.md para ti

#### **Comunicación**:
- [ ] Email preparado para QA
- [ ] Link al release verificado
- [ ] Instrucciones claras
- [ ] Canal de soporte definido (Slack/Email/Issues)

#### **Testing**:
- [ ] Probado en Windows 10/11
- [ ] Git clone funciona
- [ ] Ejecución de scripts funciona
- [ ] Configuración se guarda correctamente
- [ ] Terminal muestra output correcto

---

### **9. Post-Entrega**

Después de entregar:

- [ ] Monitorear si hay dudas/problemas
- [ ] Recopilar feedback del equipo
- [ ] Identificar mejoras para v1.2.1
- [ ] Crear issues en GitHub para bugs reportados
- [ ] Planear próxima actualización

---

### **10. Plan de Siguiente Actualización**

Cuando tengas cambios para v1.2.1:

```bash
# 1. Hacer cambios en código
# 2. Actualizar versión en:
#    - lib/constants/app_constants.dart → appVersion = '1.2.1'
#    - pubspec.yaml → version: 1.2.1+5

# 3. Commit y push
git add .
git commit -m "Release v1.2.1: Descripción de cambios"
git push

# 4. Tag
git tag -a v1.2.1 -m "Versión 1.2.1 - Mejoras y correcciones"
git push origin v1.2.1

# 5. Compilar
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build windows --release

# 6. Crear ZIP
cd build\windows\x64\runner\Release
Compress-Archive -Path * -DestinationPath ..\estrella_roja_qa_bot_v1.2.1.zip

# 7. Crear Release en GitHub
#    Los QAs verán automáticamente la notificación ✨
```

---

## 🎊 ¡Listo para Entregar!

Si completaste todos los items anteriores:

✅ **Tu app está lista para producción**
✅ **Sistema de updates funcionando**
✅ **Documentación completa**
✅ **Proceso de actualización establecido**

**¡Éxito en la entrega!** 🚀

---

## 📞 Contacto de Emergencia

Si algo falla el día de la entrega:

1. **Error de compilación**: 
   - `flutter clean && flutter pub get`
   - Verificar que todas las dependencias se instalaron

2. **Git/GitHub problemas**:
   - Verificar credenciales SSH/HTTPS
   - Probar clonar repo manualmente

3. **Release no aparece**:
   - Verificar que sea "Published" (no "Draft")
   - Verificar que el tag tenga la `v`

4. **QA no puede descargar**:
   - Verificar que el repo sea público
   - Enviar ZIP directamente como backup

---

**Última actualización**: 10 de octubre, 2025
