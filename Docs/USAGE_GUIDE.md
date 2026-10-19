# Guía de Uso 🛠️

Esta guía explica cómo operar y mantener los datos de **Biked**.

## 1. Uso de la App iOS

### Búsqueda por Geometría
1. Abre la pestaña **Buscar**.
2. Introduce los valores de **Stack** y **Reach** (en mm).
3. Ajusta la **Tolerancia** (por defecto 10mm).
4. Pulsa "Buscar" para obtener los mejores matches ordenados por cercanía geométrica.

### Búsqueda Biométrica (Fit)
1. Activa el interruptor **"Usar mis medidas"**.
2. Introduce tu altura, entrepierna, tronco y brazo.
3. La app calculará automáticamente tu Stack/Reach objetivo y buscará los modelos que mejor se adapten a tu morfología.

### Explorar el Catálogo
- Usa la pestaña **Explorar** para ver todas las marcas y modelos disponibles en la base de datos de Supabase.

---

## 2. Actualización de Datos (Scrapers)

Para añadir nuevas bicicletas o actualizar precios e imágenes:

1. Ejecuta el script principal de Python:
   ```bash
   python Biked/Biked/Data/run_scrapers.py
   ```
2. El script detectará automáticamente los modelos en los sitios web de **Canyon**, **Specialized** y **Trek**.
3. Los datos nuevos se subirán a la tabla `models` y `geometries`.
4. Las imágenes se descargarán y subirán al bucket `bike-images` de Supabase, vinculando la URL pública automáticamente.

---

## 3. Mantenimiento de la Base de Datos

- Puedes gestionar los datos directamente desde el panel de control de **Supabase**.
- Si realizas cambios estructurales, recuerda actualizar la vista `bikes_view` ejecutando de nuevo el SQL en `Biked/Biked/Data/Database/bikes_view.sql`.
