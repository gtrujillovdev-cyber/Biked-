# Arquitectura del Proyecto: Biked 🚲

Este documento describe la estructura técnica y el flujo de datos de **Biked**, una plataforma para encontrar la geometría perfecta de bicicletas de carretera y triatlón.

## 🏗️ Visión General

El ecosistema de Biked consta de tres componentes principales:
1.  **Apps iOS (SwiftUI + MVVM)**: La interfaz de usuario nativa.
2.  **Backend (Supabase)**: Base de datos PostgreSQL, Storage para imágenes y Auth.
3.  **Pipeline de Datos (Python Scrapers)**: Automatización para extraer geometrías y sincronizar con la nube.

---

## 📱 App iOS (Frontend)

### Capas de la Aplicación
-   **Views**: Interfaces declarativas en SwiftUI. 
    -   `SearchView`: Corazón de la app con lógica de matching en tiempo real.
    -   `ExploreView`: Galería visual alimentada por Supabase.
-   **ViewModels**: Gestión de estado con el macro `@Observable`.
    -   `SearchViewModel`: Realiza los cálculos de comparación de geometría y fit biométrico.
-   **Services**:
    -   `SupabaseService`: Cliente para PostgREST y Storage.
    -   `BikeAPIService`: Capa de abstracción que maneja el fetch de datos y el fallback local/caché.

---

## ☁️ Backend (Supabase)

### Base de Datos (PostgreSQL)
El esquema está normalizado para manejar la complejidad de las marcas y tallas:
-   `brands`: Marcas (Canyon, Specialized, Trek, etc.)
-   `models`: Modelos específicos vinculados a una marca.
-   `geometries`: La "verdad" técnica. Stack, Reach y otros valores por cada talla.
-   `builds`: Montajes específicos (ej. SRAM Red, Shimano Ultegra) con sus precios e imágenes.

### Vistas SQL
-   `bikes_view`: Una vista optimizada que une marcas, modelos y geometrías para que la App pueda realizar búsquedas con una sola petición.

---

## 🕷️ Scrapers (Data Pipeline)

Ubicados en `Biked/Biked/Data/Scrapers/`.

### Funcionamiento
1.  **Crawl**: Recorre los catálogos oficiales de las marcas.
2.  **Extract**:
    -   **Canyon**: Parseo de tablas HTML (Demandware).
    -   **Specialized**: Reconstrucción de estado JSON desde fragmentos Next.js (`__next_f`).
    -   **Trek**: Consumo de APIs internas de tallaje (SAP OCC).
3.  **Sync**: Sube los datos a PostgreSQL y las imágenes al Bucket `bike-images` de Supabase.

---

## 🔄 Flujo de Datos

1.  El scraper extrae datos y los sube a Supabase.
2.  La App iOS solicita `bikes_view` al iniciar o al buscar.
3.  `SearchViewModel` recibe los datos y aplica el algoritmo de distancia euclidiana para encontrar el "Match" más cercano basado en el Stack y Reach objetivo del usuario.
4.  Las imágenes se sirven directamente desde el CDN de Supabase Storage.
