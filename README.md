# Biked - Bike Geometry Finder 🚲

**Biked** es una aplicación iOS premium diseñada para ciclistas y biomecánicos que buscan la bicicleta ideal basándose en la ciencia de la geometría. Permite buscar en una base de datos curada de bicicletas de gama alta, comparar modelos cara a cara, obtener prescripciones biomecánicas (ajustes de espaciadores y longitud de potencia) y recibir recomendaciones de talla personalizadas según medidas corporales y estilos de conducción.

---

## ✨ Características Principales

- 📐 **Motor Biomecánico Avanzado**: Algoritmo de regresión antropométrica que calcula el Stack y Reach diana según altura, entrepierna, tronco, brazo y postura seleccionada (*Aero/Racing*, *Equilibrada/Sport*, *Gran Fondo/Confort*).
- 📋 **Prescripción de Puesto de Conducción (Cockpit)**: Cálculo automático de espaciadores recomendados (en saltos de 5mm), longitud de potencia sugerida y ratio Stack-to-Reach (STR), exportable mediante tarjeta compartible.
- ⚖️ **Comparador de Geometría Cara a Cara**: Comparativa milimétrica directa entre dos modelos o tallas con cálculo automático de diferencias vertical/horizontal y veredicto postural.
- 🔄 **Soporte Bimodal Métrico e Imperial**: Alternancia instantánea entre mm/cm y pulgadas con sincronización y conversión matemática bidireccional en tiempo real.
- 🛡️ **Seguridad Blindada (Supabase RLS)**: Acceso público de solo lectura (`SELECT`) protegido por Row Level Security; operaciones de administración e ingesta restringidas a `service_role`.
- ⚡ **Arquitectura Reactiva y Concurrente**: Modelo MVVM en SwiftUI con macros `@Observable`, ViewModels aislados en `@MainActor` y capa de servicios encapsulada en `actor` libre de condiciones de carrera (Data Races).
- 💾 **Estrategia Local-First Fiable**: Caché en disco con persistencia entre reinicios y fallback automático a bundle estático; recarga interactiva (*pull-to-refresh*).
- 🕷️ **Pipeline de Datos Automatizado**: Scrapers en Python para catálogos y geometrías de marcas líderes (**Canyon**, **Specialized**, **Trek**).
- 🧪 **Suite de Pruebas Unitarias**: Verificación automatizada de fórmulas matemáticas, rangos biomecánicos e integridad del catálogo.

---

## 📖 Documentación del Proyecto

Hemos consolidado toda la información técnica y operativa en guías detalladas:

1. 🚀 **[Guía de Inicio Rápido](Docs/SETUP_GUIDE.md)**: Configuración de Supabase, entorno Python, Xcode y ejecución de tests.
2. 🏗️ **[Arquitectura Técnica](Docs/ARCHITECTURE.md)**: Explicación de la arquitectura MVVM, aislamiento de concurrencia, esquema relacional y pipeline.
3. 🛠️ **[Guía de Uso](Docs/USAGE_GUIDE.md)**: Modos de búsqueda, comparador, prescripción biomecánica y actualización de datos.
4. 🧑‍💻 **[Guía de Contribución](Docs/CONTRIBUTING.md)**: Convenciones de código, estándares de concurrencia y flujo de desarrollo.

---

## 🚀 Instalación Rápida

1. Clona el repositorio:
   ```bash
   git clone https://github.com/GitGa/BikeGeometryFinder.git
   cd BikeGeometryFinder
   ```
2. Abre el proyecto en Xcode:
   ```bash
   open Biked/Biked.xcodeproj
   ```
3. Verifica tus credenciales públicas en `SupabaseConfig.swift`.
4. Ejecuta la suite de pruebas del dominio central:
   ```bash
   swift Biked/BikedTests/BikedTests.swift
   ```
5. ¡Compila y ejecuta en el simulador o dispositivo físico!

---
*Desarrollado con ❤️ y rigor biomecánico para la comunidad ciclista.*
