# Guía de Configuración Inicial 🚀

Sigue estos pasos para configurar el entorno de desarrollo y pruebas de **Biked**.

---

## 1. Requisitos Previos

- **macOS** con **Xcode 15.0+** (recomendado Xcode 16+ para soporte completo de Swift 6).
- **Python 3.10+** (para scrapers e ingestión de datos).
- Cuenta en **Supabase** (opcional para desarrollo local con datos semilla).

---

## 2. Configuración de Supabase (Backend)

1. Crea un nuevo proyecto en tu organización de [Supabase](https://supabase.com).
2. Ejecuta los scripts SQL en el SQL Editor de Supabase en este orden exacto:
   - Primero: `Biked/Biked/Data/Database/DATABASE_SCHEMA.sql` (crea tablas y activa RLS).
   - Segundo: `Biked/Biked/Data/Database/bikes_view.sql` (crea la vista optimizada y las políticas de acceso).
3. Asegúrate de que el bucket `bike-images` en Supabase Storage esté marcado como **Público**.
4. Copia tu **URL del proyecto** y la **clave anónima (`anon key`)** para la app iOS.
5. Copia tu **clave secreta de servicio (`service_role key`)** exclusivamente para los scrapers de Python.

---

## 3. Configuración del Pipeline de Datos (Python)

1. Navega a la carpeta de datos:
   ```bash
   cd Biked/Biked/Data
   ```
2. Crea un entorno virtual e instala las dependencias:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```
3. Configura tus variables de entorno a partir del archivo de ejemplo:
   ```bash
   cp .env.example .env
   ```
4. Edita `.env` con tus credenciales reales:
   ```bash
   SUPABASE_URL=https://tu-proyecto.supabase.co
   SUPABASE_KEY=tu_clave_anon
   SUPABASE_SERVICE_ROLE_KEY=tu_clave_service_role_secreta
   ```
5. Si deseas poblar la base de datos con los 56 modelos iniciales:
   ```bash
   python seed_database.py
   ```

---

## 4. Configuración de la App iOS (Xcode)

1. Abre el proyecto en Xcode:
   ```bash
   open Biked/Biked.xcodeproj
   ```
2. **Dependencias (Swift Package Manager)**:
   - Xcode resolverá automáticamente el paquete `supabase-swift`.
   - Verifica en el Target **Biked** > pestaña **General** > **Frameworks, Libraries, and Embedded Content** que esté enlazado el módulo **Supabase**.
3. Revisa `Biked/Biked/Services/SupabaseConfig.swift` para confirmar que apunta a tu URL y clave pública anónima.
4. Limpia la carpeta de compilación (`Cmd + Shift + K`) y pulsa `Cmd + R` para ejecutar en el simulador.

---

## 5. Ejecución de la Suite de Pruebas Unitarias

Para ejecutar los tests de lógica biomecánica, conversión de unidades e integridad del catálogo:

```bash
swift Biked/BikedTests/BikedTests.swift
```

Si estás ejecutando en un entorno con sandbox o caché restringida:
```bash
mkdir -p build/ModuleCache && swift -module-cache-path build/ModuleCache Biked/BikedTests/BikedTests.swift
```

Deberás ver los 16 tests pasando con éxito (`0 fallos`).
