# Biked - Bike Geometry Finder 🚲

**Biked** es una aplicación iOS premium diseñada para ciclistas que buscan su bicicleta ideal basándose en la ciencia de la geometría. Permite a los usuarios buscar en una base de datos curada de bicicletas de gama alta (2024/2025), comparar geometrías y recibir recomendaciones de talla personalizadas según sus medidas corporales.



## ✨ Características Principales

-   **Base de Datos en la Nube**: Integración completa con **Supabase** para datos de geometrías e imágenes en tiempo real.
-   **Recomendaciones Inteligentes**: Algoritmo de "Match" basado en Stack y Reach objetivo.
-   **Modo Biométrico**: Calcula tu stack/reach ideal introduciendo tus medidas (altura, entrepierna, tronco, brazo).
-   **Scrapers Automatizados**: Extracción avanzada de datos de marcas como **Canyon**, **Specialized** y **Trek**.
-   **Interfaz Moderna**: Diseño oscuro elegante con animaciones fluidas en SwiftUI.

## 📖 Documentación del Proyecto

Hemos consolidado toda la información técnica y de usuario en guías detalladas:

1.  🚀 **[Guía de Inicio Rápido](Docs/SETUP_GUIDE.md)**: Cómo configurar Supabase, Python y Xcode.
2.  🏗️ **[Arquitectura Técnica](Docs/ARCHITECTURE.md)**: Explicación de las capas MVVM, el esquema de DB y el pipeline de datos.
3.  🛠️ **[Guía de Uso](Docs/USAGE_GUIDE.md)**: Cómo usar la app y cómo ejecutar los scrapers de actualización.
4.  🧑‍💻 **[Guía de Contribución](Docs/CONTRIBUTING.md)**: Convenciones de código y procesos de desarrollo.

## 🚀 Instalación Rápida

1.  Clona el repositorio.
2.  Abre `Biked.xcodeproj` en Xcode.
3.  Configura tus credenciales en `SupabaseConfig.swift`.
4.  ¡Lanza y disfruta!

---
*Desarrollado con ❤️ para la comunidad ciclista.*
