# Arquitectura del Proyecto: Biked 🚲

Este documento describe la estructura técnica, las decisiones de diseño y el flujo de datos de **Biked**, una plataforma para encontrar la geometría perfecta de bicicletas de carretera y triatlón.

---

## 🏗️ Visión General

El ecosistema de Biked consta de tres capas principales:
1. **App iOS (SwiftUI + MVVM + Swift 6 Concurrency)**: Interfaz de usuario nativa declarativa con persistencia local y offline-first.
2. **Backend (Supabase / PostgreSQL)**: Base de datos relacional, Row Level Security (RLS) estricto, Storage para imágenes y PostgREST API.
3. **Pipeline de Datos (Python Scrapers & Ingestión)**: Scripts de extracción y sincronización usando credenciales seguras de servicio.

```mermaid
flowchart TD
    subgraph iOS ["App iOS (SwiftUI + iOS 17+)"]
        V["SwiftUI Views\n(SearchView, ExploreView, CompareView)"]
        VM["ViewModels (@MainActor + @Observable)\n(Search, Explore, Favorites)"]
        SD["SwiftData ModelContext\n(Favoritos / Garaje)"]
        A["actor BikeAPIService\n(Sincronización & Caché)"]
        V --> VM
        VM --> SD
        VM --> A
    end

    subgraph StorageLayer ["Persistencia Local"]
        DC["bikes_cache.json\n(Persistencia en Disco)"]
        BN["bikes.json\n(Bundle Semilla)"]
        A -->|1. Prioridad| DC
        A -->|2. Fallback| BN
    end

    subgraph Backend ["Supabase (PostgreSQL)"]
        BV["bikes_view (SQL Aggregation)"]
        TB["Tablas RLS: brands, models, geometries, builds"]
        ST["Bucket: bike-images"]
        BV --> TB
    end

    subgraph Scrapers ["Data Pipeline (Python)"]
        SC["run_scrapers.py\n(Canyon, Specialized, Trek)"]
        SRK["SUPABASE_SERVICE_ROLE_KEY\n(Bypass seguro de RLS)"]
        SC --> SRK
        SC -->|Escritura Directa| TB
        SC -->|Upload de Fotos| ST
    end

    A -->|3. Fetch Seguro (Anon Key - Solo SELECT)| BV
    A -.->|Escritura en segundo plano| DC
```

---

## 📱 App iOS (Frontend)

### Patrón Arquitectónico: MVVM Reactivo Concurrente
- **Views**: Interfaces SwiftUI optimizadas con feedback háptico (`Haptics`), animaciones con interpolación de resortes (`.spring()`) y soporte para accesibilidad.
  - `SearchView`: Núcleo de cálculo biomecánico, filtrado por disciplina y prescripción de talla.
  - `ExploreView`: Feed con recarga interactiva (*pull-to-refresh*), filtrado categorizado e indicadores de novedad.
  - `CompareBikesView`: Comparador cara a cara de modelos y tallas con cálculo automático de diferencias verticales y horizontales.
  - `BikeDetailView`: Ficha técnica completa con informe de diagnóstico postural, opciones de montaje y botón para compartir prescripción.
- **ViewModels (`@MainActor` + `@Observable`)**:
  - `SearchViewModel`: Gestiona las variables de entrada métricas/imperiales, el motor de regresión postural y el filtrado por distancia euclidiana.
  - `FavoritesViewModel`: Maneja la persistencia de favoritos con SwiftData (`FavoriteBike`), asegurando que todas las operaciones sobre `ModelContext` ocurran estrictamente en el hilo principal.
  - `ExploreViewModel`: Controla la carga y el refresco forzado del catálogo.
- **Servicios**:
  - `actor BikeAPIService`: Singleton concurrente encapsulado como `actor` para evitar condiciones de carrera (Data Races). Gestiona la precedencia de datos:
    1. Memoria RAM (`cachedBikes`).
    2. Disco persistente (`bikes_cache.json`).
    3. Bundle estático (`bikes.json`).
    4. Sincronización remota con Supabase con timeout de seguridad (3.0s).
  - `SupabaseConfig`: Define el endpoint y la clave anónima pública de consulta.
  - `AppSettings`: Gestor de preferencias de usuario con conversión matemática bidireccional entre sistemas Métrico e Imperial.

---

## ☁️ Backend y Seguridad (Supabase)

### Base de Datos Relacional
El esquema está normalizado para modelar con precisión la jerarquía del ciclismo moderno:
- `brands`: Marcas fabricantes (Canyon, Specialized, Trek, etc.).
- `models`: Modelos específicos vinculados a una marca y disciplina (`ROAD`, `TT`, `MTB`, `GRAVEL`, `OTHER`).
- `geometries`: Stack (mm), Reach (mm) y dimensiones por cada talla disponible.
- `builds`: Montajes comerciales con grupos, ruedas, precios estimados y URLs de imágenes.
- `contributions`: Solicitudes comunitarias de adición de nuevos modelos (estado `PENDING` obligatorio).

### Modelo de Seguridad (Row Level Security - RLS)
- **Clientes Públicos (Anon Key)**:
  - Solo tienen permisos de lectura (`SELECT`) sobre `brands`, `models`, `geometries`, `builds` y objetos del bucket público `bike-images`.
  - Pueden insertar propuestas en `contributions` únicamente si `status = 'PENDING'`.
  - **Prohibido el `INSERT` o `UPDATE` anónimo** para proteger la integridad del catálogo contra vandalismo o inyecciones.
- **Pipeline de Ingestión**:
  - Utiliza la clave privada `SUPABASE_SERVICE_ROLE_KEY` en entornos protegidos de servidor o ejecución local vía variables de entorno.

### Vista de Rendimiento (`bikes_view`)
Una vista agregada en PostgreSQL que condensa las relaciones 1:N de modelos con geometrías y montajes en un documento JSON unificado, permitiendo al cliente iOS hidratar todo el catálogo con una única petición HTTP/PostgREST.

---

## 🕷️ Pipeline de Datos (Python Scrapers)

Ubicados en `Biked/Biked/Data/Scrapers/`.

### Mecanismos de Extracción
1. **Canyon**: Extracción mediante el endpoint interno Demandware `Product-IncludeGeometry`.
2. **Specialized**: Reconstrucción del árbol de componentes desde las cargas útiles de SSR de Next.js (`__next_f`).
3. **Trek**: Consumo estructurado de las APIs OCC (SAP) de especificaciones de tallaje.

### Sincronización
- Los scrapers suben los registros normalizados a Supabase y almacenan las imágenes procesadas en el bucket `bike-images`.
- Las respuestas HTTP y consultas de fallback están blindadas con comprobaciones de longitud para garantizar tolerancia a fallos.

---

## 🧪 Pruebas Automatizadas

Ubicadas en `Biked/BikedTests/BikedTests.swift`:
- **Geometría**: Verificación matemática del cálculo de distancia euclidiana $\sqrt{\Delta\text{Stack}^2 + \Delta\text{Reach}^2}$.
- **Unidades**: Comprobación de conversiones métrico/imperial sin pérdida de precisión.
- **Biomecánica**: Validación de factores de regresión según postura y disciplina.
- **Cockpit**: Verificación de las recomendaciones de espaciadores y longitud de potencia.
- **Integridad de Datos**: Validación de 56 modelos y más de 200 geometrías en `bikes.json`.
