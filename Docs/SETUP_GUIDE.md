# Guía de Configuración Inicial 🚀

Sigue estos pasos para configurar el entorno de desarrollo de **Biked**.

## 1. Requisitos Previos

- **macOS** con **Xcode 15+**.
- **Python 3.10+** (para los scrapers).
- Cuenta en **Supabase** (opcional si ya tienes las credenciales).

---

## 2. Configuración de Supabase (Backend)

1.  Crea un nuevo proyecto en Supabase.
2.  Ejecuta los scripts SQL ubicados en `Biked/Biked/Data/Database/`:
    - Primero `DATABASE_SCHEMA.sql` para crear las tablas.
    - Luego `bikes_view.sql` para crear la vista optimizada y las políticas de seguridad (RLS).
3.  Crea un Storage Bucket llamado `bike-images` y configúralo como **Público**.

---

## 3. Configuración de los Scrapers (Python)

1.  Navega a la carpeta de datos:
    ```bash
    cd Biked/Biked/Data
    ```
2.  Instala las dependencias:
    ```bash
    pip install requests local-supabase-client beautifulsoup4
    ```
3.  Configura las credenciales en `run_scrapers.py` (URL y API Key de Supabase).

---

## 4. Configuración de la App iOS (Xcode)

1.  Abre `Biked.xcodeproj`.
2.  **IMPORTANTE (Dependencias)**:
    - Ve al Target **Biked** > pestaña **General**.
    - En **Frameworks, Libraries, and Embedded Content**, asegúrate de añadir el producto **Supabase** del paquete `supabase-swift`.
3.  Configura `SupabaseConfig.swift` con tus credenciales de cliente.
4.  Limpia la build (Cmd + Shift + K) y compila.
